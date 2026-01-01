import 'package:PiliPlus/plugin/pl_player/controller.dart';
import 'package:PiliPlus/plugin/pl_player/utils/danmaku_options.dart';
import 'package:PiliPlus/utils/storage.dart';
import 'package:PiliPlus/utils/storage_key.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DanmakuSettingsPanel extends StatefulWidget {
  final PlPlayerController plPlayerController;

  const DanmakuSettingsPanel({
    super.key,
    required this.plPlayerController,
  });

  @override
  State<DanmakuSettingsPanel> createState() => _DanmakuSettingsPanelState();
}

class _DanmakuSettingsPanelState extends State<DanmakuSettingsPanel> {
  PlPlayerController get plPlayerController => widget.plPlayerController;

  void setOptions() {
    DanmakuOptions.save();
    plPlayerController.danmakuController?.updateOption(
      DanmakuOptions.get(
        notFullscreen: !plPlayerController.isFullScreen.value,
        speed: plPlayerController.playbackSpeed,
      ),
    );
  }

  void updateOpacity(double val) {
    plPlayerController.danmakuOpacity.value = val;
    if (!plPlayerController.tempPlayerConf) {
      GStorage.setting.put(SettingBoxKey.danmakuOpacity, val);
    }
    setState(() {});
  }

  void updateShowArea(double val) {
    DanmakuOptions.danmakuShowArea = val;
    setState(() {});
    setOptions();
  }

  void onUpdateBlockType(int blockType, bool blocked) {
    if (blocked) {
      DanmakuOptions.blockTypes.remove(blockType);
    } else {
      DanmakuOptions.blockTypes.add(blockType);
    }
    DanmakuOptions.blockColorful = DanmakuOptions.blockTypes.contains(6);
    setState(() {});
    setOptions();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final blockTypesList = [
      {'label': '滚动', 'value': 1},
      {'label': '顶部', 'value': 5},
      {'label': '底部', 'value': 4},
      {'label': '彩色', 'value': 6},
    ];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: theme.colorScheme.outline.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Center(
            child: Text(
              '弹幕设置',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 不透明度
          Text(
            '不透明度 ${(plPlayerController.danmakuOpacity.value * 100).toInt()}%',
            style: theme.textTheme.bodyMedium,
          ),
          Obx(
            () => Slider(
              min: 0.0,
              max: 1.0,
              value: plPlayerController.danmakuOpacity.value,
              divisions: 10,
              label:
                  '${(plPlayerController.danmakuOpacity.value * 100).toInt()}%',
              onChanged: updateOpacity,
            ),
          ),
          const SizedBox(height: 16),

          // 显示区域
          Text(
            '显示区域 ${(DanmakuOptions.danmakuShowArea * 100).toInt()}%',
            style: theme.textTheme.bodyMedium,
          ),
          Slider(
            min: 0.1,
            max: 1.0,
            value: DanmakuOptions.danmakuShowArea,
            divisions: 9,
            label: '${(DanmakuOptions.danmakuShowArea * 100).toInt()}%',
            onChanged: updateShowArea,
          ),
          const SizedBox(height: 16),

          // 按类型屏蔽
          Text(
            '按类型屏蔽',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: blockTypesList.map((e) {
              final blocked = DanmakuOptions.blockTypes.contains(e['value']);
              return FilterChip(
                label: Text(e['label'] as String),
                selected: blocked,
                onSelected: (selected) {
                  onUpdateBlockType(e['value'] as int, blocked);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // 海量弹幕
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('海量弹幕'),
            value: DanmakuOptions.massiveMode,
            onChanged: (value) {
              DanmakuOptions.massiveMode = value;
              if (!plPlayerController.tempPlayerConf) {
                GStorage.setting.put(
                  SettingBoxKey.danmakuMassiveMode,
                  value,
                );
              }
              setState(() {});
              setOptions();
            },
          ),

          // 滚动弹幕固定速度
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('滚动弹幕固定速度'),
            value: DanmakuOptions.scrollFixedVelocity,
            onChanged: (value) {
              DanmakuOptions.scrollFixedVelocity = value;
              if (!plPlayerController.tempPlayerConf) {
                GStorage.setting.put(
                  SettingBoxKey.danmakuFixedV,
                  value,
                );
              }
              setState(() {});
              setOptions();
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
