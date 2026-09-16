import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:integration_test/integration_test.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdfly/services/pdf_service.dart';

Future<File> _writePdfFixture(String name, int pageCount) async {
  final doc = pw.Document();
  for (var i = 0; i < pageCount; i++) {
    doc.addPage(
      pw.Page(
        build: (context) => pw.Center(
          child: pw.Text('Fixture page ${i + 1}', style: const pw.TextStyle(fontSize: 40)),
        ),
      ),
    );
  }
  final file = File('${Directory.systemTemp.path}/$name');
  await file.writeAsBytes(await doc.save());
  return file;
}

Future<File> _writeImageFixture(String name, int r, int g, int b) async {
  final image = img.Image(width: 400, height: 300);
  img.fill(image, color: img.ColorRgb8(r, g, b));
  final file = File('${Directory.systemTemp.path}/$name');
  await file.writeAsBytes(img.encodePng(image));
  return file;
}

/// A large, high-entropy embedded-image PDF, standing in for a real
/// scanned/photographed page without depending on device storage
/// permissions or a pre-pushed fixture file.
Future<File> _writePhotoLikePdfFixture(String name) async {
  final image = img.Image(width: 1600, height: 2000);
  final random = math.Random(42);
  for (final pixel in image) {
    pixel
      ..r = random.nextInt(256)
      ..g = random.nextInt(256)
      ..b = random.nextInt(256);
  }
  final pngBytes = img.encodePng(image);

  final doc = pw.Document();
  doc.addPage(
    pw.Page(build: (context) => pw.Image(pw.MemoryImage(pngBytes), fit: pw.BoxFit.fill)),
  );
  final file = File('${Directory.systemTemp.path}/$name');
  await file.writeAsBytes(await doc.save());
  return file;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final service = PdfService.instance;

  testWidgets('getPageCount reports the correct number of pages', (tester) async {
    final fixture = await _writePdfFixture('count_fixture.pdf', 3);
    final count = await service.getPageCount(fixture);
    expect(count, 3);
  });

  testWidgets('compressPdf never returns a file larger than the original', (tester) async {
    final fixture = await _writePdfFixture('compress_fixture.pdf', 2);
    final originalSize = await fixture.length();

    final compressed = await service.compressPdf(fixture, quality: CompressionQuality.low);

    expect(await compressed.exists(), isTrue);
    expect(await service.getPageCount(compressed), 2);
    final compressedSize = await compressed.length();
    // Rasterizing a near-empty text page as JPEG would normally blow up the
    // size; the service should detect that and fall back to the original.
    expect(compressedSize, lessThanOrEqualTo(originalSize));
    print('compress: original=$originalSize bytes, compressed=$compressedSize bytes');
  });

  testWidgets('splitPdf extracts the requested page range', (tester) async {
    final fixture = await _writePdfFixture('split_fixture.pdf', 5);

    final split = await service.splitPdf(fixture, fromPage: 1, toPage: 3);

    expect(await split.exists(), isTrue);
    expect(await service.getPageCount(split), 3);
  });

  testWidgets('mergePdfs combines page counts from all inputs', (tester) async {
    final a = await _writePdfFixture('merge_a.pdf', 2);
    final b = await _writePdfFixture('merge_b.pdf', 3);

    final merged = await service.mergePdfs([a, b]);

    expect(await merged.exists(), isTrue);
    expect(await service.getPageCount(merged), 5);
  });

  testWidgets('compressPdf meaningfully shrinks a photo-heavy PDF', (tester) async {
    final realistic = await _writePhotoLikePdfFixture('photo_fixture.pdf');
    final originalSize = await realistic.length();

    final compressed = await service.compressPdf(realistic, quality: CompressionQuality.low);
    final compressedSize = await compressed.length();

    print('photo compress: original=$originalSize bytes, compressed=$compressedSize bytes '
        '(${(100 * compressedSize / originalSize).toStringAsFixed(1)}%)');
    expect(compressedSize, lessThan(originalSize));
  });

  testWidgets('imagesToPdf produces one page per image', (tester) async {
    final img1 = await _writeImageFixture('img1.png', 255, 0, 0);
    final img2 = await _writeImageFixture('img2.png', 0, 255, 0);
    final img3 = await _writeImageFixture('img3.png', 0, 0, 255);

    final pdf = await service.imagesToPdf([img1, img2, img3]);

    expect(await pdf.exists(), isTrue);
    expect(await service.getPageCount(pdf), 3);
  });
}
