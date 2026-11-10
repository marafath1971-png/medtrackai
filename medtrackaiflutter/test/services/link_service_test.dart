import 'package:flutter_test/flutter_test.dart';
import 'package:medai/services/link_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LinkService linkService;

  setUp(() {
    linkService = LinkService();
  });

  group('LinkService Universal and Custom Scheme Deeplink Parsing', () {
    test('parses join code from universal link path segment', () {
      String? detectedCode;
      linkService.onJoinCodeDetected = (code) => detectedCode = code;

      linkService.handleUri(Uri.parse('https://medai.app/j/AB3K9P'));
      expect(detectedCode, equals('AB3K9P'));

      detectedCode = null;
      linkService.handleUri(Uri.parse('https://medai.app/join/XY77ZZ'));
      expect(detectedCode, equals('XY77ZZ'));
    });

    test('parses join code from query parameter (universal & custom)', () {
      String? detectedCode;
      linkService.onJoinCodeDetected = (code) => detectedCode = code;

      linkService.handleUri(Uri.parse('https://medai.app/j?code=CLINIC1'));
      expect(detectedCode, equals('CLINIC1'));

      detectedCode = null;
      linkService.handleUri(Uri.parse('medai://join?code=FAM456'));
      expect(detectedCode, equals('FAM456'));
    });

    test('parses referral code from path and query parameter', () {
      String? detectedRef;
      linkService.onReferralDetected = (code) => detectedRef = code;

      linkService.handleUri(Uri.parse('https://medai.app/ref/SUMMER26'));
      expect(detectedRef, equals('SUMMER26'));

      detectedRef = null;
      linkService.handleUri(Uri.parse('https://medai.app/r?code=VIP_BONUS'));
      expect(detectedRef, equals('VIP_BONUS'));

      detectedRef = null;
      linkService.handleUri(Uri.parse('medai://ref?code=REWARD30'));
      expect(detectedRef, equals('REWARD30'));
    });

    test('triggers voice command callback from deep links', () {
      bool voiceFired = false;
      linkService.onVoiceCommandDetected = () => voiceFired = true;

      linkService.handleUri(Uri.parse('medai://voice'));
      expect(voiceFired, isTrue);

      voiceFired = false;
      linkService.handleUri(Uri.parse('https://medai.app/voice_log'));
      expect(voiceFired, isTrue);
    });
  });
}
