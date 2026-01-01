import 'package:flutter/material.dart';

class AppTheme {
  final String id;
  final String name;
  final Color backgroundColor;
  final Color statusBarColor;
  final Color textColor;
  final Color iconColor;
  final bool isCustom;

  const AppTheme({
    required this.id,
    required this.name,
    required this.backgroundColor,
    required this.statusBarColor,
    required this.textColor,
    required this.iconColor,
    this.isCustom = false,
  });

  // 预设主题
  static const List<AppTheme> presetThemes = [
    AppTheme(
      id: 'classic_white',
      name: '经典白',
      backgroundColor: Color(0xFFFFFFFF),
      statusBarColor: Color(0xFFF5F5F7),
      textColor: Color(0xFF111827),
      iconColor: Color(0xFF1F2937),
    ),
    AppTheme(
      id: 'classic_black',
      name: '经典黑',
      backgroundColor: Color(0xFF0B0F14),
      statusBarColor: Color(0xFF070A0F),
      textColor: Color(0xFFF9FAFB),
      iconColor: Color(0xFFE5E7EB),
    ),
    AppTheme(
      id: 'fresh_blue',
      name: '清新蓝',
      backgroundColor: Color(0xFFF3F8FF),
      statusBarColor: Color(0xFF1E40AF),
      textColor: Color(0xFF0F172A),
      iconColor: Color(0xFF2563EB),
    ),
    AppTheme(
      id: 'pink',
      name: '粉色',
      backgroundColor: Color(0xFFFFF5F8),
      statusBarColor: Color(0xFFDB2777),
      textColor: Color(0xFF3F1D2B),
      iconColor: Color(0xFFBE185D),
    ),
    AppTheme(
      id: 'dark_green',
      name: '墨绿',
      backgroundColor: Color(0xFFF2FBF7),
      statusBarColor: Color(0xFF064E3B),
      textColor: Color(0xFF052E2B),
      iconColor: Color(0xFF047857),
    ),
    AppTheme(
      id: 'elegant_red',
      name: '典雅红',
      backgroundColor: Color(0xFFFFF5F4),
      statusBarColor: Color(0xFF991B1B),
      textColor: Color(0xFF2D0B0B),
      iconColor: Color(0xFFB91C1C),
    ),
    AppTheme(
      id: 'black_gold',
      name: '黑金',
      backgroundColor: Color(0xFF0B0B0D),
      statusBarColor: Color(0xFF121216),
      textColor: Color(0xFFF5F1E6),
      iconColor: Color(0xFFD4AF37),
    ),
    AppTheme(
      id: 'orange_yellow',
      name: '橙黄',
      backgroundColor: Color(0xFFFFF7E6),
      statusBarColor: Color(0xFFD97706),
      textColor: Color(0xFF3B2A00),
      iconColor: Color(0xFFF59E0B),
    ),
  ];

  // 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'backgroundColor': backgroundColor.toARGB32(),
      'statusBarColor': statusBarColor.toARGB32(),
      'textColor': textColor.toARGB32(),
      'iconColor': iconColor.toARGB32(),
      'isCustom': isCustom,
    };
  }

  // 从 JSON 创建
  factory AppTheme.fromJson(Map<String, dynamic> json) {
    return AppTheme(
      id: json['id'] as String,
      name: json['name'] as String,
      backgroundColor: Color(json['backgroundColor'] as int),
      statusBarColor: Color(json['statusBarColor'] as int),
      textColor: Color(json['textColor'] as int),
      iconColor: Color(json['iconColor'] as int),
      isCustom: json['isCustom'] as bool? ?? false,
    );
  }

  // 判断是否为深色主题
  bool get isDark {
    return backgroundColor.computeLuminance() < 0.5;
  }

  // 生成 ColorScheme
  ColorScheme toColorScheme() {
    final isDarkTheme = isDark;

    return ColorScheme(
      brightness: isDarkTheme ? Brightness.dark : Brightness.light,
      primary: iconColor,
      onPrimary: isDarkTheme ? Colors.black : Colors.white,
      primaryContainer: iconColor.withValues(alpha: 0.2),
      onPrimaryContainer: textColor,
      secondary: statusBarColor,
      onSecondary: isDarkTheme ? Colors.black : Colors.white,
      secondaryContainer: statusBarColor.withValues(alpha: 0.2),
      onSecondaryContainer: textColor,
      tertiary: iconColor,
      onTertiary: isDarkTheme ? Colors.black : Colors.white,
      tertiaryContainer: iconColor.withValues(alpha: 0.15),
      onTertiaryContainer: textColor,
      error: isDarkTheme ? const Color(0xFFEF4444) : const Color(0xFFDC2626),
      onError: Colors.white,
      errorContainer: isDarkTheme
          ? const Color(0xFF7F1D1D)
          : const Color(0xFFFEE2E2),
      onErrorContainer: isDarkTheme
          ? const Color(0xFFFEE2E2)
          : const Color(0xFF7F1D1D),
      surface: backgroundColor,
      onSurface: textColor,
      surfaceContainerHighest: isDarkTheme
          ? backgroundColor.withValues(alpha: 0.9)
          : statusBarColor.withValues(alpha: 0.05),
      onSurfaceVariant: textColor.withValues(alpha: 0.7),
      outline: textColor.withValues(alpha: 0.3),
      outlineVariant: textColor.withValues(alpha: 0.1),
      shadow: Colors.black.withValues(alpha: 0.1),
      scrim: Colors.black.withValues(alpha: 0.5),
      inverseSurface: isDarkTheme ? Colors.white : Colors.black,
      onInverseSurface: isDarkTheme ? Colors.black : Colors.white,
      inversePrimary: isDarkTheme
          ? iconColor.withValues(alpha: 0.7)
          : iconColor,
      surfaceTint: iconColor,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppTheme && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
