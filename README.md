# Flutter InAppWebView Ultra

[![License: Apache 2.0](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)
[![Upstream: 6.2.0-beta.3](https://img.shields.io/badge/upstream-6.2.0--beta.3-02569B.svg)](https://pub.dev/packages/flutter_inappwebview)

An iOS stability fork of
[`flutter_inappwebview`](https://github.com/pichillilorenzo/flutter_inappwebview),
based on upstream `6.2.0-beta.3`. The public Dart API is unchanged; the
packages are renamed so the fork can be published to pub.dev and consumed as a
regular hosted dependency:

| Package | Source | Role |
| --- | --- | --- |
| [`flutter_inappwebview_ultra`](https://pub.dev/packages/flutter_inappwebview_ultra) | this fork | app-facing package (was `flutter_inappwebview`) |
| [`flutter_inappwebview_ultra_ios`](https://pub.dev/packages/flutter_inappwebview_ultra_ios) | this fork | iOS implementation with the stability fixes (was `flutter_inappwebview_ios`) |
| `flutter_inappwebview_android` / `_macos` / `_web` / `_windows` / `_linux` | upstream pub.dev | unchanged platform implementations, endorsed as-is |

This fork is intended for applications affected by WebKit crashes while
evaluating JavaScript on iOS. It is not an official upstream release.

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
- Releases the Dart-side headless webview controller state when a
  `HeadlessInAppWebView` is converted to an `InAppWebView` widget, fixing a
  per-conversion memory leak. The fix is in this repository for iOS, macOS,
  Android and Windows, but only the iOS package is published — consumers
  receive it on iOS only, since the other platforms resolve to unchanged
  upstream packages.
- Documents the destructive, process-wide scope of the deprecated
  `InAppWebViewController.clearCache` so callers do not mistake it for a
  cache-only purge.

The relevant fix revisions are
[`25983d411`](https://github.com/liu731/flutter_inappwebview_ultra/commit/25983d4110964cf4bbb2e5cbef31d87ef47120e2),
[`1aec83b55`](https://github.com/liu731/flutter_inappwebview_ultra/commit/1aec83b55f8d5f6d9e2691904b99a76e4175b101)
and
[`4583371ee`](https://github.com/liu731/flutter_inappwebview_ultra/commit/4583371ee).

## Installation

Add the hosted package:

```yaml
dependencies:
  flutter_inappwebview_ultra: ^1.0.0
```

and use the new import everywhere:

```dart
import 'package:flutter_inappwebview_ultra/flutter_inappwebview_ultra.dart';
```

No `dependency_overrides` are needed: `flutter_inappwebview_ultra` endorses
`flutter_inappwebview_ultra_ios` as its iOS implementation, and the other
platforms resolve to the upstream packages automatically.

### Migrating from the git-reference setup

If you previously consumed this fork through git dependencies, remove the
`flutter_inappwebview` git block **and** every `flutter_inappwebview_*`
entry from `dependency_overrides`, then add the hosted dependency above and
rewrite the imports:

```bash
grep -rl --include="*.dart" "package:flutter_inappwebview/" . | xargs sed -i '' \
  's|package:flutter_inappwebview/flutter_inappwebview.dart|package:flutter_inappwebview_ultra/flutter_inappwebview_ultra.dart|g'
```

The Dart API is unchanged, so no other code changes are required. Web storage
(cookies, localStorage) is keyed to the app sandbox by the OS, so an ordinary
app update along with this migration does not log users out of webview
sessions.

### Consuming from git instead

For testing unreleased changes you can still reference the repository
directly. Note the dependency keys use the new package names:

```yaml
dependencies:
  flutter_inappwebview_ultra:
    git:
      url: https://github.com/liu731/flutter_inappwebview_ultra.git
      ref: main
      path: flutter_inappwebview

dependency_overrides:
  flutter_inappwebview_ultra_ios:
    git:
      url: https://github.com/liu731/flutter_inappwebview_ultra.git
      ref: main
      path: flutter_inappwebview_ios
```

Pin `ref` to a commit or tag for reproducible builds.

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
