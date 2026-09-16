import 'package:flutter_test/flutter_test.dart';

import 'package:pdfly/main.dart';

void main() {
  testWidgets('Home screen shows all four tools', (WidgetTester tester) async {
    await tester.pumpWidget(const PdfToolkitApp());
    await tester.pump();

    expect(find.text('Compress PDF'), findsOneWidget);
    expect(find.text('Merge PDFs'), findsOneWidget);
    expect(find.text('Split PDF'), findsOneWidget);
    expect(find.text('Images to PDF'), findsOneWidget);
  });
}
