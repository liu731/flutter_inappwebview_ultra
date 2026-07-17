# Flutter InAppWebView Ultra

[![License: Apache 2.0](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)
[![Upstream: 6.2.0-beta.3](https://img.shields.io/badge/upstream-6.2.0--beta.3-02569B.svg)](https://pub.dev/packages/flutter_inappwebview)

An iOS stability fork of
[`flutter_inappwebview`](https://github.com/pichillilorenzo/flutter_inappwebview),
based on upstream `6.2.0-beta.3`. It keeps the original Dart package names,
imports, and public API unchanged.

This fork is intended for applications affected by WebKit crashes while
evaluating JavaScript on iOS. It is not an official upstream release. Other
platform implementations continue to use the upstream packages unless you
override them separately.

## What this fork fixes

- Prevents `evaluateJavascript` from taking a crashing content-world path in
  popup WebViews created with `windowId` on iOS 14–17. This includes the fix from
  [upstream PR #2776](https://github.com/pichillilorenzo/flutter_inappwebview/pull/2776).
- Prevents the equivalent popup `callAsyncJavaScript` crash on iOS 14.3–17 by
  forcing the safe page world.
- Uses a safe compatibility path for page-world `callAsyncJavaScript` calls in
  regular WebViews before iOS 18.
- Delivers compatibility-path results through a dedicated
  `WKScriptMessageHandler`, so async calls also work when
  `javaScriptBridgeEnabled` is `false`.
- Returns structured JavaScript and serialization errors through
  `CallAsyncJavaScriptResult.error` instead of crashing or silently losing the
  completion callback.
- Adds regression coverage for ordinary WebViews, custom content worlds, and
  popup WebViews.

The relevant fix revisions are
[`25983d411`](https://github.com/liu731/flutter_inappwebview_ultra/commit/25983d4110964cf4bbb2e5cbef31d87ef47120e2)
and
[`1aec83b55`](https://github.com/liu731/flutter_inappwebview_ultra/commit/1aec83b55f8d5f6d9e2691904b99a76e4175b101).

## Installation

Because `flutter_inappwebview` is a federated plugin, pointing only the main
package at this repository is not enough: Pub would still resolve the hosted
`flutter_inappwebview_ios` package. Override the iOS implementation as well.

For reproducible application builds, pin both Git dependencies to the tested
fix revision:

```yaml
dependencies:
  flutter_inappwebview:
    git:
      url: https://github.com/liu731/flutter_inappwebview_ultra.git
      ref: 1aec83b55f8d5f6d9e2691904b99a76e4175b101
      path: flutter_inappwebview

dependency_overrides:
  flutter_inappwebview_ios:
    git:
      url: https://github.com/liu731/flutter_inappwebview_ultra.git
      ref: 1aec83b55f8d5f6d9e2691904b99a76e4175b101
      path: flutter_inappwebview_ios
```

Then resolve the dependency graph:

```bash
flutter pub get
```

Check `pubspec.lock` before committing it. The
`flutter_inappwebview_ios` entry must use `source: git`, reference this
repository, and resolve to the pinned revision. You can use `ref: main` while
testing unreleased changes, but it makes builds non-reproducible.

## Compatibility notes

| Scenario | Behavior |
| --- | --- |
| Regular WebView, `ContentWorld.PAGE`, iOS 12–17 | Uses the safe compatibility path. |
| Regular WebView, custom-world request, iOS 12–14.2 | Falls back to page-world semantics. |
| Regular WebView, custom world, iOS 14.3–15.x and 16.1–17.x | Preserves native content-world isolation. |
| Regular WebView, custom world, iOS 16.0.x | Returns an explicit unsupported error in `CallAsyncJavaScriptResult.error`. |
| Popup/`windowId` `evaluateJavascript`, iOS 14–17 | Forces the page world; custom-world isolation is not preserved. |
| Popup/`windowId` `callAsyncJavaScript`, iOS 12–14.2 | Not guaranteed; avoid this combination. |
| Popup/`windowId` `callAsyncJavaScript`, iOS 14.3–17 | Forces the page world; custom-world isolation is not preserved. |
| iOS 18+ | Uses the native WebKit async JavaScript API with the requested content world. |

On affected iOS versions, prefer `ContentWorld.PAGE` and always inspect the
async result before consuming its value:

```dart
final result = await controller.callAsyncJavaScript(
  functionBody: 'return 42;',
  contentWorld: ContentWorld.PAGE,
);

if (result?.error != null) {
  // Handle or report result!.error.
} else {
  final value = result?.value;
}
```

## Requirements

| Component | Requirement |
| --- | --- |
| Upstream plugin baseline | `flutter_inappwebview 6.2.0-beta.3` |
| Dart | `^3.8.0` |
| Flutter | `>=3.32.0` |
| iOS | 12.0+ |
| Xcode | 15.0+ |

The monorepo also contains the upstream Android, macOS, Windows, Linux, and Web
implementations. See the upstream
[platform setup guide](https://inappwebview.dev/docs/intro/) for those targets.
For Linux source dependencies and backend selection, see
[`flutter_inappwebview_linux/WPE_BACKEND.md`](flutter_inappwebview_linux/WPE_BACKEND.md).

## Local development and verification

The example application uses local overrides for all packages in this
monorepo:

```bash
cd flutter_inappwebview/example
flutter pub get
flutter run -d <ios-device-id>
```

The iOS regressions are covered in:

- [`javascript_code_evaluation.dart`](flutter_inappwebview/example/integration_test/in_app_webview/javascript_code_evaluation.dart)
- [`webview_windows.dart`](flutter_inappwebview/example/integration_test/in_app_webview/webview_windows.dart)

To run the complete integration suite, start the repository test server in one
terminal:

```bash
cd test_node_server
npm ci
node index.js
```

From the repository root in another terminal, write the server address into
the generated test environment and start the driver on an iOS simulator or
physical device:

```bash
NODE_SERVER_IP=<host-ip> dart tool/env.dart
cd flutter_inappwebview/example
flutter pub get
flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/webview_flutter_test.dart \
  --device-id=<ios-device-id>
```

## Upstream documentation

- [Official documentation](https://inappwebview.dev/docs/intro/)
- [Dart API reference](https://pub.dev/documentation/flutter_inappwebview/latest/)
- [Upstream repository](https://github.com/pichillilorenzo/flutter_inappwebview)
- [Upstream package README](flutter_inappwebview/README.md)
- [Upstream examples](https://github.com/pichillilorenzo/flutter_inappwebview_examples)

## Issues and contributions

Report fork-specific iOS regressions in this repository's
[issue tracker](https://github.com/liu731/flutter_inappwebview_ultra/issues).
For behavior that is also reproducible with the official package, use the
[upstream issue tracker](https://github.com/pichillilorenzo/flutter_inappwebview/issues).

This project retains the upstream Apache 2.0 license and builds on the work of
the [upstream contributors](https://github.com/pichillilorenzo/flutter_inappwebview#contributors-).
See [LICENSE](LICENSE) for details.
