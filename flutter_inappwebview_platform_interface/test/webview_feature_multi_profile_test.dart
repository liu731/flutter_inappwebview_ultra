import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview_platform_interface/src/multi_profile_support_io.dart';
import 'package:flutter_inappwebview_platform_interface/flutter_inappwebview_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('MULTI_PROFILE is sent to Android as the native feature name', () {
    expect(WebViewFeature.MULTI_PROFILE.toNativeValue(), 'MULTI_PROFILE');
    expect(WebViewFeature.MULTI_PROFILE.name(), 'MULTI_PROFILE');
    expect(
      WebViewFeature.byName('MULTI_PROFILE'),
      WebViewFeature.MULTI_PROFILE,
    );
    expect(
      WebViewFeature.fromNativeValue('MULTI_PROFILE'),
      WebViewFeature.MULTI_PROFILE,
    );
    expect(WebViewFeature.values, contains(WebViewFeature.MULTI_PROFILE));

    expect(
      AndroidWebViewFeature.MULTI_PROFILE.toNativeValue(),
      'MULTI_PROFILE',
    );
    expect(
      AndroidWebViewFeature.byName('MULTI_PROFILE'),
      AndroidWebViewFeature.MULTI_PROFILE,
    );
    expect(
      AndroidWebViewFeature.values,
      contains(AndroidWebViewFeature.MULTI_PROFILE),
    );
  });

  test('profileName is one setting for both platforms', () {
    final settings = InAppWebViewSettings(profileName: '1688');
    expect(settings.toMap()['profileName'], '1688');
    final restored = InAppWebViewSettings.fromMap(settings.toMap())!;
    expect(restored.profileName, '1688');
    expect(
      InAppWebViewSettings.isPropertySupported(
        InAppWebViewSettingsProperty.profileName,
        platform: TargetPlatform.android,
      ),
      isTrue,
    );
    expect(
      InAppWebViewSettings.isPropertySupported(
        InAppWebViewSettingsProperty.profileName,
        platform: TargetPlatform.iOS,
      ),
      isTrue,
    );
  });

  test('iOS keeps a second profile from version 17', () {
    expect(
      iosSupportsPersistentProfile('Version 16.7.10 (Build 20H350)'),
      isFalse,
    );
    expect(iosSupportsPersistentProfile('Version 17.0 (Build 21A329)'), isTrue);
    expect(iosSupportsPersistentProfile('26.6.2'), isTrue);
    expect(iosSupportsPersistentProfile(''), isFalse);
  });
}
