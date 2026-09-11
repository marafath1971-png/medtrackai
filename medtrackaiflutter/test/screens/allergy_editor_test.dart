import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medai/screens/home/widgets/settings/allergy_editor.dart';
import 'package:medai/theme/app_theme.dart';

/// The editor is the only way to change allergies after onboarding, and what it
/// stores is fed to the scanner's ingredient cross-reference — so these cover
/// the add/remove round-trip and the guards on free-text input.
void main() {
  /// Hosts the editor with real state so edits round-trip the way they do in
  /// the profile tab.
  Widget host({
    List<String> initial = const [],
    required ValueChanged<List<String>> onChanged,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: _Harness(initial: initial, onChanged: onChanged),
      ),
    );
  }

  testWidgets('renders the presets as chips', (tester) async {
    await tester.pumpWidget(host(onChanged: (_) {}));

    expect(find.text('Penicillin'), findsOneWidget);
    expect(find.text('Sulfa drugs'), findsOneWidget);
    expect(find.text('NSAIDs (Ibuprofen)'), findsOneWidget);
    expect(find.text('Aspirin'), findsOneWidget);
  });

  testWidgets('tapping a preset adds it', (tester) async {
    List<String>? result;
    await tester.pumpWidget(host(onChanged: (v) => result = v));

    await tester.tap(find.text('Penicillin'));
    await tester.pump();

    expect(result, ['Penicillin']);
  });

  testWidgets('tapping a selected preset removes it', (tester) async {
    List<String>? result;
    await tester.pumpWidget(
      host(initial: const ['Penicillin'], onChanged: (v) => result = v),
    );

    await tester.tap(find.text('Penicillin'));
    await tester.pump();

    expect(result, isEmpty);
  });

  testWidgets('free text adds an allergy outside the presets', (tester) async {
    List<String>? result;
    await tester.pumpWidget(host(onChanged: (v) => result = v));

    await tester.enterText(find.byType(TextField), 'Codeine');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    expect(result, ['Codeine']);
  });

  testWidgets('blank free text is ignored', (tester) async {
    var calls = 0;
    await tester.pumpWidget(host(onChanged: (_) => calls++));

    await tester.enterText(find.byType(TextField), '   ');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    expect(calls, 0);
  });

  testWidgets('a duplicate of an existing entry is not added twice',
      (tester) async {
    List<String>? result;
    await tester.pumpWidget(
      host(initial: const ['Codeine'], onChanged: (v) => result = v),
    );

    await tester.enterText(find.byType(TextField), 'codeine');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    expect(result, ['Codeine']);
  });

  testWidgets('free-text entries render as removable chips', (tester) async {
    await tester.pumpWidget(
      host(initial: const ['Codeine'], onChanged: (_) {}),
    );

    expect(find.text('Codeine'), findsOneWidget);
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);
  });
}

/// Minimal stateful wrapper so a tap actually updates what the editor renders.
class _Harness extends StatefulWidget {
  final List<String> initial;
  final ValueChanged<List<String>> onChanged;

  const _Harness({required this.initial, required this.onChanged});

  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness> {
  late List<String> _value = widget.initial;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: AllergyEditor(
        allergies: _value,
        onChanged: (next) {
          setState(() => _value = next);
          widget.onChanged(next);
        },
        L: AppThemeColors.fromColorScheme(
          Theme.of(context).colorScheme,
          Theme.of(context).brightness,
        ),
      ),
    );
  }
}
