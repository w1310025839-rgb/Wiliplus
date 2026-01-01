import 'dart:io';

import 'package:PiliPlus/utils/storage.dart';
import 'package:PiliPlus/utils/storage_key.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';

class AppIconSettingPage extends StatefulWidget {
  const AppIconSettingPage({super.key});

  @override
  State<AppIconSettingPage> createState() => _AppIconSettingPageState();
}

class _AppIconSettingPageState extends State<AppIconSettingPage> {
  static const _iconCount = 8;
  static const _defaultIconIndex = 3; // icon3.png 为默认图标

  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = GStorage.setting.get(
      SettingBoxKey.appIconIndex,
      defaultValue: _defaultIconIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('更换App图标'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              '选择你喜欢的App图标',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1,
              ),
              itemCount: _iconCount,
              itemBuilder: (context, index) {
                final iconIndex = index + 1;
                final isSelected = _selectedIndex == iconIndex;
                final isDefault = iconIndex == _defaultIconIndex;

                return GestureDetector(
                  onTap: () => _selectIcon(iconIndex),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outline.withValues(alpha: 0.2),
                        width: isSelected ? 3 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: theme.colorScheme.primary.withValues(
                                  alpha: 0.3,
                                ),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.asset(
                            'assets/icons/icon$iconIndex.png',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return ColoredBox(
                                color:
                                    theme.colorScheme.surfaceContainerHighest,
                                child: Icon(
                                  Icons.image_not_supported,
                                  color: theme.colorScheme.outline,
                                ),
                              );
                            },
                          ),
                        ),
                        if (isSelected)
                          Positioned(
                            right: 4,
                            top: 4,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.check,
                                size: 14,
                                color: theme.colorScheme.onPrimary,
                              ),
                            ),
                          ),
                        if (isDefault)
                          Positioned(
                            left: 4,
                            bottom: 4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.secondaryContainer,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '默认',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: theme.colorScheme.onSecondaryContainer,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 18,
                        color: theme.colorScheme.outline,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          Platform.isAndroid
                              ? '更换图标需要重启App才能生效，部分设备可能不支持动态图标'
                              : '更换图标功能仅在Android设备上可用',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _applyIcon,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('应用图标'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _selectIcon(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _applyIcon() async {
    if (!Platform.isAndroid) {
      SmartDialog.showToast('此功能仅在Android设备上可用');
      return;
    }

    try {
      // 保存选择的图标索引
      await GStorage.setting.put(SettingBoxKey.appIconIndex, _selectedIndex);

      // 调用原生方法更换图标
      const platform = MethodChannel('com.example.piliplus/app_icon');
      await platform.invokeMethod('changeAppIcon', {
        'iconIndex': _selectedIndex,
      });

      SmartDialog.showToast('图标已更换，重启App后生效');
    } on PlatformException catch (e) {
      SmartDialog.showToast('更换图标失败: ${e.message}');
    } catch (e) {
      SmartDialog.showToast('更换图标失败: $e');
    }
  }
}
