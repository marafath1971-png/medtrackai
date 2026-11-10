import 'package:flutter_test/flutter_test.dart';
import 'package:medai/screens/scan/scanner_hub_screen.dart';

void main() {
  test('ScanMode enum order matches swipe sequence', () {
    // Sequence allows fluid Cal AI-style horizontal swipe:
    // Camera -> Barcode -> Search -> Voice
    expect(ScanMode.values, [
      ScanMode.camera,
      ScanMode.barcode,
      ScanMode.search,
      ScanMode.voice,
    ]);
  });
}
