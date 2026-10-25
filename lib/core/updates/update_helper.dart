import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:watch_your_money/core/theme/app_colors.dart';

class UpdateHelper {
  UpdateHelper._();

  static const String _owner = 'Nobecuy';
  static const String _repo = 'WatchYourMoney';
  static const String _apiUrl =
      'https://api.github.com/repos/$_owner/$_repo/releases/latest';
  static const String _prefsKeyLastCheckedVersion = 'last_checked_version';
  static const String _prefsKeyLastCheckedBuild = 'last_checked_build';
  static const String _prefsKeySkipVersion = 'skip_version';
  static const String _prefsKeySkipBuild = 'skip_build';

  /// Check GitHub Releases for a newer version.
  /// Pass [showNoUpdateDialog] = true for manual check (from profile screen).
  static Future<void> checkForUpdates(
    BuildContext context, {
    bool showNoUpdateDialog = false,
    bool forceCheck = false,
  }) async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      final currentBuild = int.tryParse(packageInfo.buildNumber) ?? 0;

      // Skip check if user dismissed this exact version+build (unless forced)
      if (!forceCheck) {
        final prefs = await SharedPreferences.getInstance();
        final skippedVersion = prefs.getString(_prefsKeySkipVersion);
        final skippedBuild = prefs.getInt(_prefsKeySkipBuild) ?? 0;
        if (skippedVersion == currentVersion && skippedBuild == currentBuild) {
          return;
        }
      }

      final response = await http
          .get(
            Uri.parse(_apiUrl),
            headers: {'Accept': 'application/vnd.github+json'},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final latestTag = (data['tag_name'] as String? ?? '')
          .replaceAll('v', '')
          .trim();
      final releaseUrl = data['html_url'] as String? ?? '';
      final releaseNotes = data['body'] as String? ?? '';
      final assets = (data['assets'] as List? ?? []);

      // Find APK asset
      String? apkDownloadUrl;
      for (final asset in assets) {
        final name = (asset['name'] as String? ?? '').toLowerCase();
        if (name.endsWith('.apk')) {
          apkDownloadUrl = asset['browser_download_url'] as String?;
          break;
        }
      }

      final hasUpdate = _isNewerVersion(
        latestTag,
        currentVersion,
        currentBuild,
      );

      if (!context.mounted) return;

      if (hasUpdate) {
        _showUpdateDialog(
          context,
          latestTag,
          releaseUrl,
          releaseNotes,
          apkDownloadUrl,
          currentVersion,
          currentBuild,
        );
      } else if (showNoUpdateDialog) {
        _showNoUpdateDialog(context, currentVersion, currentBuild);
        // Update last checked version on successful manual check
        await _saveLastCheckedVersion(currentVersion, currentBuild);
      }
    } catch (_) {
      // Silent fail — update check is non-critical
    }
  }

  /// Compare versions considering both version string and build number.
  /// Returns true if [latestVersion] + [latestBuild] is newer than [currentVersion] + [currentBuild].
  static bool _isNewerVersion(
    String latestVersion,
    String currentVersion, [
    int currentBuild = 0,
    int latestBuild = 0,
  ]) {
    try {
      final l = latestVersion.split('.').map(int.parse).toList();
      final c = currentVersion.split('.').map(int.parse).toList();
      final len = l.length > c.length ? l.length : c.length;
      for (int i = 0; i < len; i++) {
        final lv = i < l.length ? l[i] : 0;
        final cv = i < c.length ? c[i] : 0;
        if (lv > cv) return true;
        if (lv < cv) return false;
      }
      // Versions are equal, compare build numbers
      if (latestBuild > currentBuild) return true;
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Public for unit testing. Returns true if [latest] is newer than [current].
  @Deprecated('Use _isNewerVersion with build numbers instead')
  static bool isNewerVersion(String latest, String current) {
    return _isNewerVersion(latest, current);
  }

  static Future<void> _saveLastCheckedVersion(String version, int build) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKeyLastCheckedVersion, version);
    await prefs.setInt(_prefsKeyLastCheckedBuild, build);
  }

  static void _showUpdateDialog(
    BuildContext context,
    String newVersion,
    String releaseUrl,
    String releaseNotes,
    String? apkDownloadUrl,
    String currentVersion,
    int currentBuild,
  ) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _UpdateDialog(
        newVersion: newVersion,
        releaseUrl: releaseUrl,
        releaseNotes: releaseNotes,
        apkDownloadUrl: apkDownloadUrl,
        currentVersion: currentVersion,
        currentBuild: currentBuild,
      ),
    );
  }

  static void _showNoUpdateDialog(
    BuildContext context,
    String currentVersion,
    int currentBuild,
  ) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0x1AFFFFFF)),
        ),
        title: const Row(
          children: [
            Icon(
              Icons.check_circle_rounded,
              color: AppColors.positive,
              size: 22,
            ),
            SizedBox(width: 10),
            Text(
              'Sudah Terkini',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        content: Text(
          'Kamu sudah menggunakan versi terbaru (v$currentVersion${currentBuild > 0 ? '+$currentBuild' : ''})',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.surfaceContainerHigh,
              foregroundColor: AppColors.textPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Oke'),
          ),
        ],
      ),
    );
  }
}

class _UpdateDialog extends StatefulWidget {
  final String newVersion;
  final String releaseUrl;
  final String releaseNotes;
  final String? apkDownloadUrl;
  final String currentVersion;
  final int currentBuild;

  const _UpdateDialog({
    required this.newVersion,
    required this.releaseUrl,
    required this.releaseNotes,
    this.apkDownloadUrl,
    required this.currentVersion,
    required this.currentBuild,
  });

  @override
  State<_UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<_UpdateDialog> {
  double _downloadProgress = 0.0;
  bool _isDownloading = false;
  bool _isInstalling = false;
  String? _errorMessage;
  final Dio _dio = Dio();

  @override
  Widget build(BuildContext context) {
    final canAutoInstall = widget.apkDownloadUrl != null && !_isDownloading;

    return AlertDialog(
      backgroundColor: AppColors.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0x1AFFFFFF)),
      ),
      title: Row(
        children: [
          const Icon(
            Icons.system_update_rounded,
            color: Color(0xFF34D399),
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Update Telah Tersedia',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Versi baru: v${widget.newVersion}',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          if (widget.releaseNotes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              widget.releaseNotes.length > 200
                  ? '${widget.releaseNotes.substring(0, 200)}...'
                  : widget.releaseNotes,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
            ),
          ],
          if (_isDownloading) ...[
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: _downloadProgress,
              backgroundColor: AppColors.surfaceContainerHigh,
              valueColor: const AlwaysStoppedAnimation(Color(0xFF34D399)),
              minHeight: 6,
              borderRadius: BorderRadius.circular(3),
            ),
            const SizedBox(height: 8),
            Text(
              'Mengunduh... ${(_downloadProgress * 100).toStringAsFixed(0)}%',
              style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
            ),
          ] else if (_isInstalling) ...[
            const SizedBox(height: 16),
            const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF34D399),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Center(
              child: Text(
                'Memasang update...',
                style: TextStyle(color: AppColors.textMuted, fontSize: 11),
              ),
            ),
          ] else if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF43F5E).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0x33F43F5E)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: Color(0xFFF43F5E),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                        color: Color(0xFFF43F5E),
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isDownloading || _isInstalling
              ? null
              : () => Navigator.of(context).pop(),
          child: Text(
            'Nanti',
            style: TextStyle(
              color: _isDownloading || _isInstalling
                  ? AppColors.textMuted.withValues(alpha: 0.5)
                  : AppColors.textMuted,
            ),
          ),
        ),
        if (canAutoInstall)
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF34D399),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: _downloadAndInstallApk,
            child: const Text(
              'Unduh & Pasang',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          )
        else if (widget.apkDownloadUrl == null)
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF34D399),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              Navigator.of(context).pop();
              if (widget.releaseUrl.isNotEmpty) {
                await launchUrl(
                  Uri.parse(widget.releaseUrl),
                  mode: LaunchMode.externalApplication,
                );
              }
            },
            child: const Text(
              'Update di Browser',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          )
        else
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF34D399),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: _retryDownload,
            child: const Text(
              'Coba Lagi',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        TextButton(
          onPressed: _isDownloading || _isInstalling
              ? null
              : () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString(
                    UpdateHelper._prefsKeySkipVersion,
                    widget.currentVersion,
                  );
                  await prefs.setInt(
                    UpdateHelper._prefsKeySkipBuild,
                    widget.currentBuild,
                  );
                  if (context.mounted) Navigator.of(context).pop();
                },
          child: Text(
            'Lewati Versi Ini',
            style: TextStyle(
              color: _isDownloading || _isInstalling
                  ? AppColors.textMuted.withValues(alpha: 0.5)
                  : AppColors.textMuted,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _downloadAndInstallApk() async {
    if (widget.apkDownloadUrl == null) return;

    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
      _errorMessage = null;
    });

    try {
      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/watch_your_money_update.apk';

      await _dio.download(
        widget.apkDownloadUrl!,
        filePath,
        onReceiveProgress: (received, total) {
          if (total > 0 && mounted) {
            setState(() {
              _downloadProgress = received / total;
            });
          }
        },
      );

      if (!mounted) return;

      setState(() {
        _isDownloading = false;
        _isInstalling = true;
      });

      // Use the free function from open_file_plus package
      final result = await OpenFilex.open(filePath);

      if (!mounted) return;

      if (result.type != ResultType.done) {
        setState(() {
          _isInstalling = false;
          _errorMessage = 'Gagal memasang update: ${result.message}';
        });
        return;
      }

      // If install succeeded, app will be replaced and restart
      // Save current version as last checked to avoid prompt loop
      await UpdateHelper._saveLastCheckedVersion(
        widget.currentVersion,
        widget.currentBuild,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isDownloading = false;
        _isInstalling = false;
        _errorMessage = 'Gagal mengunduh update: $e';
      });
    }
  }

  Future<void> _retryDownload() async {
    setState(() {
      _errorMessage = null;
    });
    await _downloadAndInstallApk();
  }
}
