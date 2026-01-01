import 'package:PiliPlus/models/common/app_theme.dart';
import 'package:PiliPlus/utils/storage.dart';
import 'package:PiliPlus/utils/storage_key.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class ThemeColorSetting extends StatefulWidget {
  const ThemeColorSetting({super.key});

  @override
  State<ThemeColorSetting> createState() => _ThemeColorSettingState();
}

class _ThemeColorSettingState extends State<ThemeColorSetting> {
  late List<AppTheme> customThemes = [];
  late String currentThemeId = '';

  @override
  void initState() {
    super.initState();
    _loadCustomThemes();
    _loadCurrentTheme();
  }

  void _loadCustomThemes() {
    final customThemesData =
        GStorage.setting.get(
              SettingBoxKey.customThemes,
              defaultValue: <Map<String, dynamic>>[],
            )
            as List;

    customThemes = customThemesData
        .map((e) => AppTheme.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  void _loadCurrentTheme() {
    currentThemeId =
        GStorage.setting.get(
              SettingBoxKey.currentThemeId,
              defaultValue: 'classic_white',
            )
            as String;
  }

  void _saveCustomThemes() {
    GStorage.setting.put(
      SettingBoxKey.customThemes,
      customThemes.map((e) => e.toJson()).toList(),
    );
  }

  void _applyTheme(AppTheme theme) {
    setState(() {
      currentThemeId = theme.id;
    });

    GStorage.setting.put(SettingBoxKey.currentThemeId, theme.id);

    // 应用主题
    final colorScheme = theme.toColorScheme();
    Get.changeTheme(
      ThemeData(
        colorScheme: colorScheme,
        useMaterial3: true,
      ),
    );

    // 更新状态栏颜色
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: theme.statusBarColor,
        statusBarIconBrightness: theme.isDark
            ? Brightness.light
            : Brightness.dark,
        systemNavigationBarColor: theme.backgroundColor,
        systemNavigationBarIconBrightness: theme.isDark
            ? Brightness.light
            : Brightness.dark,
      ),
    );
  }

  void _showAddCustomThemeDialog() {
    final nameController = TextEditingController();
    final bgController = TextEditingController(text: 'FFFFFF');
    final statusBarController = TextEditingController(text: 'F5F5F7');
    final textController = TextEditingController(text: '111827');
    final iconController = TextEditingController(text: '1F2937');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加自定义主题'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: '主题名称',
                  hintText: '例如：我的主题',
                ),
              ),
              const SizedBox(height: 16),
              _buildColorField(bgController, '系统背景', 'FFFFFF'),
              const SizedBox(height: 12),
              _buildColorField(statusBarController, '状态栏', 'F5F5F7'),
              const SizedBox(height: 12),
              _buildColorField(textController, '系统字体', '111827'),
              const SizedBox(height: 12),
              _buildColorField(iconController, '系统图标', '1F2937'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              if (nameController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('请输入主题名称')),
                );
                return;
              }

              try {
                final theme = AppTheme(
                  id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
                  name: nameController.text,
                  backgroundColor: _parseColor(bgController.text),
                  statusBarColor: _parseColor(statusBarController.text),
                  textColor: _parseColor(textController.text),
                  iconColor: _parseColor(iconController.text),
                  isCustom: true,
                );

                setState(() {
                  customThemes.add(theme);
                });
                _saveCustomThemes();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('自定义主题已添加')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('颜色格式不正确，请输入6位16进制颜色代码')),
                );
              }
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }

  Widget _buildColorField(
    TextEditingController controller,
    String label,
    String hint,
  ) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixText: '#',
        suffixIcon: ValueListenableBuilder(
          valueListenable: controller,
          builder: (context, value, child) {
            Color? color;
            try {
              color = _parseColor(value.text);
            } catch (_) {}

            return Container(
              width: 40,
              height: 40,
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color ?? Colors.grey,
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(4),
              ),
            );
          },
        ),
      ),
      maxLength: 6,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9A-Fa-f]')),
      ],
    );
  }

  Color _parseColor(String hex) {
    hex = hex.replaceAll('#', '').toUpperCase();
    if (hex.length == 6) {
      return Color(int.parse('FF$hex', radix: 16));
    }
    throw const FormatException('Invalid color format');
  }

  void _deleteCustomTheme(AppTheme theme) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除主题'),
        content: Text('确定要删除主题"${theme.name}"吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                customThemes.remove(theme);
              });
              _saveCustomThemes();

              // 如果删除的是当前主题，切换到默认主题
              if (currentThemeId == theme.id) {
                _applyTheme(AppTheme.presetThemes.first);
              }

              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('主题已删除')),
              );
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final padding = MediaQuery.viewPaddingOf(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('主题色设置'),
      ),
      body: ListView(
        padding: EdgeInsets.only(
          left: padding.left,
          right: padding.right,
          bottom: padding.bottom + 100,
        ),
        children: [
          // 预设主题
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              '预设主题',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ...AppTheme.presetThemes.map(_buildThemeCard),

          // 自定义主题
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '自定义主题',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  onPressed: _showAddCustomThemeDialog,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('添加'),
                ),
              ],
            ),
          ),
          if (customThemes.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Text(
                  '暂无自定义主题',
                  style: TextStyle(
                    color: theme.colorScheme.outline,
                    fontSize: 14,
                  ),
                ),
              ),
            )
          else
            ...customThemes.map(_buildThemeCard),
        ],
      ),
    );
  }

  Widget _buildThemeCard(AppTheme appTheme) {
    final isSelected = currentThemeId == appTheme.id;
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: () => _applyTheme(appTheme),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // 颜色预览
              Column(
                children: [
                  Row(
                    children: [
                      _buildColorBox(appTheme.backgroundColor, '背景'),
                      const SizedBox(width: 4),
                      _buildColorBox(appTheme.statusBarColor, '状态栏'),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _buildColorBox(appTheme.textColor, '字体'),
                      const SizedBox(width: 4),
                      _buildColorBox(appTheme.iconColor, '图标'),
                    ],
                  ),
                ],
              ),

              const SizedBox(width: 16),

              // 主题名称
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appTheme.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (appTheme.isCustom)
                      Text(
                        '自定义',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.outline,
                        ),
                      ),
                  ],
                ),
              ),

              // 选中标记和删除按钮
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: theme.colorScheme.primary,
                )
              else if (appTheme.isCustom)
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  onPressed: () => _deleteCustomTheme(appTheme),
                  color: theme.colorScheme.error,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildColorBox(Color color, String label) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color,
            border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 10),
        ),
      ],
    );
  }
}
