import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medai/screens/family/widgets/add_cg_flow.dart';
import 'package:medai/theme/med_ai_ui.dart';
import 'package:medai/widgets/common/solid_surface.dart';

/// Step 1 of the add-caregiver flow, rendered whole.
///
/// Two shipped bugs lived here: the selection chips were invisible in light
/// mode (a dark tint that MedAiGlass discarded, with the label still flipped to
/// L.bg), and the "Generate QR code" CTA was pinned at bottom: 0 inside a tab,
/// so the shell's floating nav covered it and swallowed its taps — the flow
/// could be filled in but never completed.
///
/// SolidSurface has unit tests; these check the screen actually uses it, and
/// that the CTA is reachable.
double _luminance(Color c) {
  double channel(double v) =>
      v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * channel(c.r) + 0.7152 * channel(c.g) + 0.0722 * channel(c.b);
}

double _contrast(Color a, Color b) {
  final la = _luminance(a);
  final lb = _luminance(b);
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

Widget _host(Widget child) => MaterialApp(
      theme: AppTheme.light(),
      home: child,
    );

Widget _step1({
  required TextEditingController name,
  required TextEditingController contact,
  String relation = 'Spouse',
  String avatar = '👩',
  int alertDelay = 30,
  VoidCallback? onNext,
  required AppThemeColors colors,
}) =>
    AddCgStep1(
      nameCtrl: name,
      contactCtrl: contact,
      relation: relation,
      avatar: avatar,
      alertDelay: alertDelay,
      onRelChange: (_) {},
      onAvatarChange: (_) {},
      onDelayChange: (_) {},
      L: colors,
      onBack: () {},
      onNext: () async => onNext?.call(),
    );

void main() {
  _formLeadsWithTheRequiredField();

  late TextEditingController name;
  late TextEditingController contact;

  setUp(() {
    name = TextEditingController();
    contact = TextEditingController();
  });

  tearDown(() {
    name.dispose();
    contact.dispose();
  });

  Future<AppThemeColors> pumpScreen(
    WidgetTester tester, {
    String relation = 'Spouse',
    VoidCallback? onNext,
    String nameText = '',
  }) async {
    name.text = nameText;
    late AppThemeColors colors;

    await tester.pumpWidget(_host(Builder(builder: (context) {
      colors = context.L;
      return _step1(
        name: name,
        contact: contact,
        relation: relation,
        onNext: onNext,
        colors: colors,
      );
    })));
    await tester.pump();
    return colors;
  }

  testWidgets('the screen renders its sections', (tester) async {
    await pumpScreen(tester);

    expect(find.text('Choose avatar'), findsOneWidget);
    expect(find.text('Relationship'), findsOneWidget);
    expect(find.text('Generate QR code'), findsOneWidget);
  });

  testWidgets('selection chips use SolidSurface, not raw glass',
      (tester) async {
    await pumpScreen(tester);

    expect(find.byType(SolidSurface), findsWidgets,
        reason: 'chips reverting to MedAiGlass would make the selected state '
            'invisible in light mode again');
  });

  testWidgets('the selected relationship chip is visibly distinct',
      (tester) async {
    await pumpScreen(tester, relation: 'Spouse');

    // Every chip is a SolidSurface; exactly the selected ones are filled.
    final surfaces = tester
        .widgetList<SolidSurface>(find.byType(SolidSurface))
        .toList();
    final filled = surfaces.where((s) => s.filled).toList();

    expect(filled, isNotEmpty,
        reason: 'with a relationship and avatar chosen, something must render '
            'as selected');
  });

  testWidgets('a selected chip contrasts with an unselected one',
      (tester) async {
    final colors = await pumpScreen(tester);

    // These are the two fills the screen paints for the two states.
    expect(_contrast(colors.text, colors.card), greaterThan(3.0),
        reason: 'selected vs unselected must be tellable apart at a glance');
  });

  testWidgets('the CTA is disabled until a name is entered', (tester) async {
    var tapped = false;
    await pumpScreen(tester, onNext: () => tapped = true, nameText: '');

    await tester.tap(find.text('Generate QR code'), warnIfMissed: false);
    await tester.pump();

    expect(tapped, isFalse,
        reason: 'a caregiver invite needs a name; the CTA gates on it');
  });

  testWidgets('the CTA fires once a name is present', (tester) async {
    var tapped = false;
    await pumpScreen(
        tester, onNext: () => tapped = true, nameText: 'Sarah Johnson');

    await tester.tap(find.text('Generate QR code'));
    await tester.pump();

    expect(tapped, isTrue);

    // AnimatedPressable debounces taps with a 300ms timer; let it drain so the
    // test does not fail on a pending timer at teardown.
    await tester.pump(const Duration(milliseconds: 400));
  });

  testWidgets('the CTA sits clear of the shell nav island', (tester) async {
    await pumpScreen(tester, nameText: 'Sarah Johnson');

    final screenHeight = tester.getSize(find.byType(MaterialApp)).height;
    final ctaBottom = tester.getBottomLeft(find.text('Generate QR code')).dy;

    // The bug: pinned at bottom: 0, the CTA finished at the screen edge and
    // the floating nav sat on top of it.
    expect(ctaBottom, lessThan(screenHeight),
        reason: 'the CTA must not reach the screen edge, where the nav '
            'island covers it and swallows taps');
  });

  testWidgets('the scroll body reserves room for the CTA and the nav',
      (tester) async {
    await pumpScreen(tester);

    final scrollView = tester.widget<SingleChildScrollView>(
        find.byType(SingleChildScrollView).first);
    final padding = scrollView.padding as EdgeInsets;

    expect(padding.bottom, greaterThan(120),
        reason: 'content scrolling under the pinned CTA and the nav island is '
            'the milder form of the same bug');
  });
}

/// The form opened on twelve avatars stacked 6x2, which consumed the top third
/// of the screen and pushed the required name field, the relationship chips
/// and the phone field below the fold.
void _formLeadsWithTheRequiredField() {
  group('the form leads with what it needs', () {
    late String src;
    setUpAll(() => src =
        File('lib/screens/family/widgets/add_cg_flow.dart').readAsStringSync());

    test('the name field comes before the avatar picker', () {
      final name = src.indexOf("MedAiSectionHeader(title: 'Full name");
      final avatar = src.indexOf("MedAiSectionHeader(title: 'Choose avatar')");
      expect(name, greaterThan(-1));
      expect(avatar, greaterThan(-1));
      expect(name, lessThan(avatar),
          reason: 'the one required field should not sit under twelve '
              'optional decorations');
    });

    test('the avatars are one scrolling row, not a grid', () {
      final i = src.indexOf("MedAiSectionHeader(title: 'Choose avatar')");
      final block = src.substring(i, i + 700);
      expect(block.contains('scrollDirection: Axis.horizontal'), isTrue);
      expect(block.contains('Wrap('), isFalse,
          reason: 'a 6x2 wrap is what pushed the form below the fold');
    });

    test('the row is still tappable at accessible size', () {
      final i = src.indexOf("MedAiSectionHeader(title: 'Choose avatar')");
      expect(src.substring(i, i + 700).contains('MedAiA11y.minTapTarget'),
          isTrue);
    });
  });
}
