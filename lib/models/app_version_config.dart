/// Remote version gate (app_config/version), written by the maintainer in the
/// Firebase console. Used for the rare full-APK update outside Shorebird.
class AppVersionConfig {
  const AppVersionConfig({
    required this.latestBuild,
    required this.apkUrl,
    required this.required,
  });

  final int latestBuild;
  final String apkUrl;
  final bool required;

  factory AppVersionConfig.fromMap(Map<String, dynamic> m) => AppVersionConfig(
        latestBuild: (m['latestBuild'] as num?)?.toInt() ?? 0,
        apkUrl: (m['apkUrl'] ?? '') as String,
        required: (m['required'] as bool?) ?? false,
      );
}
