import 'package:flutter/material.dart';

enum PdfTool { compress, merge, split, imagesToPdf }

extension PdfToolInfo on PdfTool {
  String get title => switch (this) {
        PdfTool.compress => 'Compress PDF',
        PdfTool.merge => 'Merge PDFs',
        PdfTool.split => 'Split PDF',
        PdfTool.imagesToPdf => 'Images to PDF',
      };

  String get subtitle => switch (this) {
        PdfTool.compress => 'Reduce file size',
        PdfTool.merge => 'Combine multiple files',
        PdfTool.split => 'Extract pages',
        PdfTool.imagesToPdf => 'Convert photos to PDF',
      };

  IconData get icon => switch (this) {
        PdfTool.compress => Icons.compress,
        PdfTool.merge => Icons.merge_type,
        PdfTool.split => Icons.call_split,
        PdfTool.imagesToPdf => Icons.image,
      };
}
