import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:watch_your_money/core/theme/app_colors.dart';

class UpdateHelper {
  UpdateHelper._();

  static const String _owner = 'Nobecuy';
  static const String _repo = 'WatchYourMoney';
  static const String _apiUrl =
      'https://api.github.com/repos/$_owner/$_repo/releases/latest';

  /// Check GitHub Releases for a newer version.
  /// Pass [showNoUpdateDialog] = true for manual check (from profile screen).
  static Future<void> checkForUpdates(
    BuildContext context, {
    bool showNoUpdateDialog = false,
  }) async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

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

      final hasUpdate = isNewerVersion(latestTag, currentVersion);

      if (!context.mounted) return;

      if (hasUpdate) {
        _showUpdateDialog(context, latestTag, releaseUrl, releaseNotes);
      } else if (showNoUpdateDialog) {
        _showNoUpdateDialog(context, currentVersion);
      }
    } catch (_) {
      // Silent fail — update check is non-critical
    }
  }

  /// Public for unit testing. Returns true if [latest] is newer than [current].
  static bool isNewerVersion(String latest, String current) {
    try {
      final l = latest.split('.').map(int.parse).toList();
      final c = current.split('.').map(int.parse).toList();
      final len = l.length > c.length ? l.length : c.length;
      for (int i = 0; i < len; i++) {
        final lv = i < l.length ? l[i] : 0;
        final cv = i < c.length ? c[i] : 0;
        if (lv > cv) return true;
        if (lv < cv) return false;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  static void _showUpdateDialog(
    BuildContext context,
    String newVersion,
    String releaseUrl,
    String releaseNotes,
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
              Icons.system_update_rounded,
              color: Color(0xFF34D399),
              size: 22,
            ),
            SizedBox(width: 10),
            Text(
              'Update Tersedia 🎉',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Versi baru: v$newVersion',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
            if (releaseNotes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                releaseNotes.length > 200
                    ? '${releaseNotes.substring(0, 200)}...'
                    : releaseNotes,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'Nanti',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF34D399),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              if (releaseUrl.isNotEmpty) {
                await launchUrl(
                  Uri.parse(releaseUrl),
                  mode: LaunchMode.externalApplication,
                );
              }
            },
            child: const Text(
              'Update Sekarang',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  static void _showNoUpdateDialog(BuildContext context, String currentVersion) {
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
          'Kamu sudah menggunakan versi terbaru (v$currentVersion)',
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
