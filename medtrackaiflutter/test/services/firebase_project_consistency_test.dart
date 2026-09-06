import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

/// Three files carry the Firebase project id, and they are generated
/// separately. When they disagree the app connects to one project and deploys
/// go to another — which is exactly how two rules deploys reached nothing.
String? _idFrom(String s, RegExp re) => re.firstMatch(s)?.group(1);

void main() {
  test('every config file names the same project', () {
    final opts = File('lib/firebase_options.dart').readAsStringSync();
    final gs = File('android/app/google-services.json').readAsStringSync();

    final fromOpts =
        _idFrom(opts, RegExp(r"projectId:\s*'([a-z0-9-]+)'"));
    final fromGs =
        _idFrom(gs, RegExp(r'"project_id":\s*"([a-z0-9-]+)"'));

    expect(fromOpts, isNotNull, reason: 'firebase_options.dart has no projectId');
    expect(fromGs, isNotNull, reason: 'google-services.json has no project_id');
    expect(fromOpts, fromGs,
        reason: 'firebase_options.dart says $fromOpts but '
            'google-services.json says $fromGs — regenerate with '
            '`flutterfire configure`');
  });

  test('the deploy target matches the app config', () {
    // .firebaserc decides where `firebase deploy` sends rules. If it names a
    // different project than the app connects to, rules land somewhere the
    // app never reads and the failure looks like a rules bug.
    final rc = File('.firebaserc');
    expect(rc.existsSync(), isTrue,
        reason: 'without .firebaserc a deploy has no default project');

    final rcId = _idFrom(rc.readAsStringSync(),
        RegExp(r'"default":\s*"([a-z0-9-]+)"'));
    final appId = _idFrom(File('lib/firebase_options.dart').readAsStringSync(),
        RegExp(r"projectId:\s*'([a-z0-9-]+)'"));

    expect(rcId, appId,
        reason: 'deploys go to $rcId but the app talks to $appId');
  });

  test('the bundle id is consistent across platforms', () {
    final gradle = File('android/app/build.gradle.kts').readAsStringSync();
    final gs = File('android/app/google-services.json').readAsStringSync();

    final appId =
        _idFrom(gradle, RegExp(r'applicationId\s*=\s*"([a-zA-Z0-9_.]+)"'));
    expect(appId, isNotNull);
    expect(gs.contains('"package_name": "$appId"'), isTrue,
        reason: 'google-services.json has no entry for $appId, so Firebase '
            'will not initialise on Android');
  });
}
