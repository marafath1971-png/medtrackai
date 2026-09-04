import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medai/screens/app_shell.dart';
import 'package:medai/theme/med_ai_ui.dart';
import 'package:medai/widgets/shared/shared_widgets.dart';

/// The invite error rendered on top of the "Generate QR code" button and under
/// the scan FAB: bottom was a bare 115, while the furniture it had to clear is
/// an 80px island lifted 16px off the safe area with a 58px FAB floating 12px
/// above that.
void main() {
  testWidgets('the toast clears the nav island and the FAB', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light(),
      home: const Scaffold(
        body: Stack(
          children: [AppToast(message: 'Could not create the invite.')],
        ),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 400));

    final screen = tester.getSize(find.byType(MaterialApp)).height;
    final toastBottom = tester.getRect(find.byType(AppToast)).bottom;
    final gapFromBottom = screen - toastBottom;

    expect(gapFromBottom, greaterThanOrEqualTo(kShellNavIslandInset),
        reason: 'the toast must sit above the island and the FAB, not on them');
  });

  test('it paints after the FAB in the shell stack', () {
    // Position alone is not enough: stacked before the FAB the toast is drawn
    // underneath it wherever it sits.
    final src = File('lib/screens/app_shell.dart').readAsStringSync();
    final fab = src.indexOf('_ScanFab(onTap: _openScan)');
    final toast = src.indexOf('AppToast(message: toast');

    expect(fab, greaterThan(-1));
    expect(toast, greaterThan(fab),
        reason: 'the toast must come after the FAB to paint over it');
  });

  test('the offset is derived, not a magic number', () {
    final src =
        File('lib/widgets/shared/shared_widgets.dart').readAsStringSync();
    expect(src.contains('kShellNavIslandInset'), isTrue,
        reason: 'a literal drifts the next time the island or FAB changes');
    expect(src.contains('bottomPadding + 115'), isFalse);
  });
}
