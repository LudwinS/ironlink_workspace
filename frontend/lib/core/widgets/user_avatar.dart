import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class UserAvatar extends StatelessWidget {
  final String? avatarUrl;
  final String? avatarColor;
  final String name;
  final double size;
  final bool showBorder;
  final Color? borderColor;
  final double borderWidth;
  final double? fontSize;

  const UserAvatar({
    super.key,
    this.avatarUrl,
    this.avatarColor,
    required this.name,
    this.size = 36,
    this.showBorder = false,
    this.borderColor,
    this.borderWidth = 1.5,
    this.fontSize,
  });

  Color _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return AppColors.cyan;
    try {
      final clean = hex.replaceAll('#', '');
      return Color(int.parse('0xFF$clean'));
    } catch (_) {
      return AppColors.cyan;
    }
  }

  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : 'U';
  }

  @override
  Widget build(BuildContext context) {
    final fallbackColor = _parseColor(avatarColor);
    final initials = _getInitials(name);
    final computedFontSize = fontSize ?? (size * 0.38);

    Widget fallbackWidget() {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: fallbackColor.withValues(alpha: 0.2),
          border: showBorder
              ? Border.all(color: borderColor ?? fallbackColor, width: borderWidth)
              : Border.all(color: fallbackColor.withValues(alpha: 0.5), width: 1),
        ),
        child: Center(
          child: Text(
            initials,
            style: TextStyle(
              color: fallbackColor,
              fontWeight: FontWeight.bold,
              fontSize: computedFontSize,
            ),
          ),
        ),
      );
    }

    if (avatarUrl != null && avatarUrl!.trim().isNotEmpty) {
      final url = avatarUrl!.trim();
      if (url.startsWith('data:image/') || url.contains(';base64,')) {
        try {
          final base64Content = url.contains(',') ? url.split(',').last : url;
          final Uint8List bytes = base64Decode(base64Content);
          return Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: showBorder
                  ? Border.all(color: borderColor ?? AppColors.border, width: borderWidth)
                  : null,
            ),
            child: ClipOval(
              child: Image.memory(
                bytes,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => fallbackWidget(),
              ),
            ),
          );
        } catch (_) {
          return fallbackWidget();
        }
      } else if (url.startsWith('http://') || url.startsWith('https://')) {
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: showBorder
                ? Border.all(color: borderColor ?? AppColors.border, width: borderWidth)
                : null,
          ),
          child: ClipOval(
            child: Image.network(
              url,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => fallbackWidget(),
            ),
          ),
        );
      }
    }

    return fallbackWidget();
  }
}
