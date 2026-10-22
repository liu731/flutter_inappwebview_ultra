import 'dart:io' show Platform;

/// iOS reports versions as `Version 17.5.1 (Build 21F79)` or `17.5.1`.
/// A named persistent website data store exists from iOS 17.
bool currentIosSupportsPersistentProfile() {
  if (!Platform.isIOS) return false;
  return iosSupportsPersistentProfile(Platform.operatingSystemVersion);
}

/// Visible for tests. The first number is the major version.
bool iosSupportsPersistentProfile(String operatingSystemVersion) {
  final match = RegExp(r'(\d+)').firstMatch(operatingSystemVersion);
  final major = int.tryParse(match?.group(1) ?? '');
  return major != null && major >= 17;
}
