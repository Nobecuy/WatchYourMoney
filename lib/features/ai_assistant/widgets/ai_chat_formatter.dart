// AI chat text formatter for rich text rendering.

import 'package:flutter/material.dart';
import 'package:watch_your_money/core/theme/app_colors.dart';

class AIChatFormatter {
  static Widget buildRichLine(String text) {
    final parts = <TextSpan>[];
    final regex = RegExp(r'\*\*(.*?)\*\*');
    int last = 0;
    for (final match in regex.allMatches(text)) {
      if (match.start > last) {
        parts.add(
          TextSpan(
            text: text.substring(last, match.start),
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13.5,
              height: 1.5,
            ),
          ),
        );
      }
      parts.add(
        TextSpan(
          text: match.group(1),
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            height: 1.5,
          ),
        ),
      );
      last = match.end;
    }
    if (last < text.length) {
      parts.add(
        TextSpan(
          text: text.substring(last),
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 13.5,
            height: 1.5,
          ),
        ),
      );
    }
    return RichText(
      text: TextSpan(
        children: parts.isEmpty
            ? [
                TextSpan(
                  text: text,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13.5,
                    height: 1.5,
                  ),
                ),
              ]
            : parts,
      ),
    );
  }

  static Widget buildFormattedText(String text) {
    final lines = text.split('\n');
    final widgets = <Widget>[];
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.isEmpty) {
        widgets.add(const SizedBox(height: 6));
      } else if (line.startsWith('- ') || line.startsWith('• ')) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 7),
                  child: CircleAvatar(
                    radius: 2.5,
                    backgroundColor: AppColors.positive,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(child: buildRichLine(line.substring(2))),
              ],
            ),
          ),
        );
      } else if (RegExp(r'^\d+\.').hasMatch(line)) {
        final match = RegExp(r'^(\d+)\.\s*(.*)').firstMatch(line);
        if (match != null) {
          widgets.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${match.group(1)}.',
                    style: const TextStyle(
                      color: AppColors.positive,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: buildRichLine(match.group(2) ?? '')),
                ],
              ),
            ),
          );
        }
      } else if (line.isNotEmpty &&
          !line.contains(':') &&
          line.length < 40 &&
          (i == 0 || lines[i - 1].isEmpty)) {
        widgets.add(
          Padding(
            padding: EdgeInsets.only(top: i > 0 ? 8 : 0, bottom: 4),
            child: Text(
              line.replaceAll(RegExp(r'\*\*(.*?)\*\*'), r'$1'),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.1,
              ),
            ),
          ),
        );
      } else {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: buildRichLine(line),
          ),
        );
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }
}