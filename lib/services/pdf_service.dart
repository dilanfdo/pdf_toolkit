import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

enum CompressionQuality { low, medium, high }

/// All PDF manipulation goes through page rasterization: every source PDF
/// page is rendered to a bitmap (via the platform's native PDF renderer,
/// exposed by `printing`) and re-assembled into a new PDF with the `pdf`
/// package, which can only *generate* PDFs, not parse/edit existing ones.
/// This is what makes compression possible (re-encode at lower DPI/JPEG
/// quality) but it also means output pages are images: no selectable text,
/// and merge/split of text-heavy PDFs will be larger than the vector
/// originals. Good enough for a scan/photo-style PDF utility; if
/// text-fidelity merge/split matters later, swap this layer for a proper
/// PDF-editing library.
class PdfService {
  PdfService._();
  static final PdfService instance = PdfService._();

  double _dpiFor(CompressionQuality quality) => switch (quality) {
        CompressionQuality.low => 72,
        CompressionQuality.medium => 120,
        CompressionQuality.high => 180,
      };

  int _jpegQualityFor(CompressionQuality quality) => switch (quality) {
        CompressionQuality.low => 40,
        CompressionQuality.medium => 65,
        CompressionQuality.high => 85,
      };

  static const double _probeDpi = 20;
  static const double _maxRenderDimension = 3000;

  /// Rendering at a fixed DPI can request an enormous bitmap for a PDF with
  /// an unusually large physical page size (a poster, architectural
  /// drawing, or just an oversized MediaBox some PDF producers emit) — the
  /// *native* PDF renderer then throws a fatal OutOfMemoryError that
  /// crashes the whole app before any Dart try/catch can run. This probes
  /// each page's rendered size at a cheap low DPI first and caps the real
  /// DPI so no page's bitmap exceeds [_maxRenderDimension] on its longest
  /// side, regardless of the page's physical size.
  Future<double> _safeDpi(
    Uint8List bytes,
    double requestedDpi, {
    List<int>? pages,
  }) async {
    var safeDpi = requestedDpi;
    await for (final probe in Printing.raster(bytes, dpi: _probeDpi, pages: pages)) {
      final widthAtRequested = probe.width / _probeDpi * requestedDpi;
      final heightAtRequested = probe.height / _probeDpi * requestedDpi;
      final longestSide =
          widthAtRequested > heightAtRequested ? widthAtRequested : heightAtRequested;
      if (longestSide > _maxRenderDimension) {
        final pageSafeDpi = requestedDpi * (_maxRenderDimension / longestSide);
        if (pageSafeDpi < safeDpi) safeDpi = pageSafeDpi;
      }
    }
    return safeDpi;
  }

  Future<File> _saveDocument(pw.Document doc, String filename) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$filename');
    return file.writeAsBytes(await doc.save(), flush: true);
  }

  Future<Uint8List> _rasterToJpeg(PdfRaster raster, int jpegQuality) async {
    final uiImage = await raster.toImage();
    final byteData =
        await uiImage.toByteData(format: ui.ImageByteFormat.rawRgba);
    final image = img.Image.fromBytes(
      width: uiImage.width,
      height: uiImage.height,
      bytes: byteData!.buffer,
      numChannels: 4,
      order: img.ChannelOrder.rgba,
    );
    return img.encodeJpg(image, quality: jpegQuality);
  }

  /// Counts pages by rasterizing at a throwaway-low DPI. There is no
  /// lightweight page-count API available without parsing the PDF, so this
  /// is the cheapest correct option in this stack.
  Future<int> getPageCount(File pdf) async {
    final bytes = await pdf.readAsBytes();
    var count = 0;
    await for (final _ in Printing.raster(bytes, dpi: 30)) {
      count++;
    }
    return count;
  }

  Future<File> imagesToPdf(
    List<File> images, {
    String filename = 'images_to_pdf.pdf',
  }) async {
    final doc = pw.Document();
    for (final imageFile in images) {
      final bytes = await imageFile.readAsBytes();
      final image = pw.MemoryImage(bytes);
      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (context) => pw.Center(
            child: pw.Image(image, fit: pw.BoxFit.contain),
          ),
        ),
      );
    }
    return _saveDocument(doc, filename);
  }

  Future<File> mergePdfs(
    List<File> pdfs, {
    CompressionQuality quality = CompressionQuality.high,
    String filename = 'merged.pdf',
  }) async {
    final doc = pw.Document();
    final requestedDpi = _dpiFor(quality);
    final jpegQuality = _jpegQualityFor(quality);

    for (final pdfFile in pdfs) {
      final bytes = await pdfFile.readAsBytes();
      final dpi = await _safeDpi(bytes, requestedDpi);
      await for (final raster in Printing.raster(bytes, dpi: dpi)) {
        final jpegBytes = await _rasterToJpeg(raster, jpegQuality);
        final image = pw.MemoryImage(jpegBytes);
        doc.addPage(
          pw.Page(
            pageFormat: PdfPageFormat(raster.width * 72 / dpi,
                raster.height * 72 / dpi),
            build: (context) => pw.Image(image, fit: pw.BoxFit.fill),
          ),
        );
      }
    }
    return _saveDocument(doc, filename);
  }

  /// [fromPage]/[toPage] are 0-indexed and inclusive.
  Future<File> splitPdf(
    File pdf, {
    required int fromPage,
    required int toPage,
    CompressionQuality quality = CompressionQuality.high,
    String filename = 'split.pdf',
  }) async {
    final doc = pw.Document();
    final requestedDpi = _dpiFor(quality);
    final jpegQuality = _jpegQualityFor(quality);
    final bytes = await pdf.readAsBytes();
    final pageIndices = [for (var i = fromPage; i <= toPage; i++) i];
    final dpi = await _safeDpi(bytes, requestedDpi, pages: pageIndices);

    await for (final raster
        in Printing.raster(bytes, dpi: dpi, pages: pageIndices)) {
      final jpegBytes = await _rasterToJpeg(raster, jpegQuality);
      final image = pw.MemoryImage(jpegBytes);
      doc.addPage(
        pw.Page(
          pageFormat:
              PdfPageFormat(raster.width * 72 / dpi, raster.height * 72 / dpi),
          build: (context) => pw.Image(image, fit: pw.BoxFit.fill),
        ),
      );
    }
    return _saveDocument(doc, filename);
  }

  Future<File> compressPdf(
    File pdf, {
    required CompressionQuality quality,
    String filename = 'compressed.pdf',
  }) async {
    final doc = pw.Document();
    final requestedDpi = _dpiFor(quality);
    final jpegQuality = _jpegQualityFor(quality);
    final bytes = await pdf.readAsBytes();
    final dpi = await _safeDpi(bytes, requestedDpi);

    await for (final raster in Printing.raster(bytes, dpi: dpi)) {
      final jpegBytes = await _rasterToJpeg(raster, jpegQuality);
      final image = pw.MemoryImage(jpegBytes);
      doc.addPage(
        pw.Page(
          pageFormat:
              PdfPageFormat(raster.width * 72 / dpi, raster.height * 72 / dpi),
          build: (context) => pw.Image(image, fit: pw.BoxFit.fill),
        ),
      );
    }
    final compressed = await _saveDocument(doc, filename);

    // Rasterizing a page can end up *larger* than the source, e.g. a
    // text/vector-only PDF re-encoded as a JPEG image. Never hand back a
    // "compressed" file that's bigger than what the user started with.
    if (await compressed.length() >= await pdf.length()) {
      final dir = await getApplicationDocumentsDirectory();
      final fallback = File('${dir.path}/$filename');
      await compressed.delete();
      await pdf.copy(fallback.path);
      return fallback;
    }
    return compressed;
  }
}
