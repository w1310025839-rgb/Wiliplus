import 'package:PiliPlus/common/constants.dart';
import 'package:PiliPlus/common/skeleton/video_card_v.dart';
import 'package:PiliPlus/common/widgets/flutter/refresh_indicator.dart';
import 'package:PiliPlus/common/widgets/loading_widget/http_error.dart';
import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/models/model_hot_video_item.dart';
import 'package:PiliPlus/models/model_owner.dart';
import 'package:PiliPlus/models_new/fav/fav_detail/media.dart';
import 'package:PiliPlus/pages/music_player/controller.dart';
import 'package:PiliPlus/pages/music_zone/controller.dart';
import 'package:PiliPlus/utils/grid.dart';
import 'package:PiliPlus/utils/page_utils.dart';
import 'package:PiliPlus/utils/storage_pref.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';

class MusicZonePage extends StatefulWidget {
  const MusicZonePage({super.key});

  @override
  State<MusicZonePage> createState() => _MusicZonePageState();
}

class _MusicZonePageState extends State<MusicZonePage> {
  late final MusicZoneController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(MusicZoneController());
  }

  @override
  void dispose() {
    Get.delete<MusicZoneController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.viewPaddingOf(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('音乐分区'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showHelpDialog,
            tooltip: '使用帮助',
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _navigateToSearch,
            tooltip: '搜索音乐',
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.only(left: padding.left, right: padding.right),
        child: refreshIndicator(
          onRefresh: controller.onRefresh,
          child: CustomScrollView(
            controller: controller.scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(StyleString.safeSpace),
                sliver: Obx(() => _buildBody(controller.loadingState.value)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToSearch() {
    Get.toNamed('/musicSearch');
  }

  void _showHelpDialog() {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.help_outline, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            const Text('使用帮助'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHelpSection(
                theme,
                '如何添加视频到播放列表',
                [
                  '方法一：在音乐分区',
                  '• 长按任意视频卡片',
                  '• 选择"添加到播放列表"',
                  '• 如有多个分P，可选择"选择分P导入"批量添加',
                  '',
                  '方法二：在视频播放器中',
                  '• 点击右上角菜单按钮（三个点）',
                  '• 选择"添加到音乐播放列表"',
                  '• 对于多P视频或合集，可批量选择添加',
                  '',
                  '方法三：从收藏夹导入',
                  '• 进入"我的"-"我的收藏"',
                  '• 打开收藏夹后长按视频',
                  '• 选择添加到播放列表',
                ],
              ),
              const SizedBox(height: 16),
              _buildHelpSection(
                theme,
                '播放列表管理',
                [
                  '• 点击视频直接跳转到视频播放器观看',
                  '• 长按视频可添加到音乐播放列表',
                  '• 播放列表支持记忆功能，下次打开自动恢复',
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('知道了'),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpSection(ThemeData theme, String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              item,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ),
      ],
    );
  }

  late final gridDelegate = SliverGridDelegateWithExtentAndRatio(
    mainAxisSpacing: StyleString.cardSpace,
    crossAxisSpacing: StyleString.cardSpace,
    maxCrossAxisExtent: Pref.recommendCardWidth,
    childAspectRatio: StyleString.aspectRatio,
    mainAxisExtent: MediaQuery.textScalerOf(context).scale(90),
  );

  Widget _buildBody(LoadingState<List<dynamic>?> loadingState) {
    return switch (loadingState) {
      Loading() => _buildSkeleton,
      Success(:final response) =>
        response != null && response.isNotEmpty
            ? SliverGrid.builder(
                gridDelegate: gridDelegate,
                itemBuilder: (context, index) {
                  if (index == response.length - 1) {
                    controller.onLoadMore();
                  }
                  final item = response[index];
                  return RepaintBoundary(
                    child: GestureDetector(
                      onTap: () => _playVideo(item),
                      onLongPress: () => _onVideoLongPress(item, index),
                      child: _buildVideoCard(item),
                    ),
                  );
                },
                itemCount: response.length,
              )
            : HttpError(onReload: controller.onReload),
      Error(:final errMsg) => HttpError(
        errMsg: errMsg,
        onReload: controller.onReload,
      ),
    };
  }

  Widget _buildVideoCard(dynamic item) {
    if (item is! HotVideoItemModel) return const SizedBox.shrink();

    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  item.cover ?? '',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => ColoredBox(
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: const Icon(Icons.music_note),
                  ),
                ),
                Positioned(
                  right: 4,
                  bottom: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _formatDuration(item.duration),
                      style: const TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  Text(
                    item.owner.name ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    final duration = Duration(seconds: seconds);
    final minutes = duration.inMinutes;
    final secs = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  void _onVideoLongPress(dynamic item, int index) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.outline.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.playlist_add),
              title: const Text('添加到播放列表'),
              onTap: () {
                Navigator.pop(context);
                _addToPlaylist(item);
              },
            ),
            ListTile(
              leading: const Icon(Icons.playlist_add_check),
              title: const Text('选择分P导入'),
              onTap: () {
                Navigator.pop(context);
                _showPartSelector(item);
              },
            ),
            ListTile(
              leading: const Icon(Icons.play_arrow),
              title: const Text('立即播放'),
              onTap: () {
                Navigator.pop(context);
                _playVideo(item);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _showPartSelector(dynamic item) async {
    if (item is! HotVideoItemModel || item.bvid == null) {
      SmartDialog.showToast('无法获取视频信息');
      return;
    }

    MusicPlayerController musicController;
    try {
      musicController = Get.find<MusicPlayerController>();
    } catch (e) {
      musicController = Get.put(MusicPlayerController());
    }

    final parts = await musicController.loadVideoParts(item.bvid!);
    if (parts == null || parts.length <= 1) {
      _addToPlaylist(item);
      return;
    }

    // 显示分P选择对话框
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => _PartSelectorSheet(
        item: item,
        controller: musicController,
        theme: Theme.of(context),
      ),
    );
  }

  void _playVideo(dynamic item) {
    if (item is HotVideoItemModel) {
      // 点击直接跳转到视频播放器
      PageUtils.toVideoPage(
        bvid: item.bvid,
        aid: item.aid,
        cid: item.cid ?? 0,
        cover: item.cover,
        title: item.title,
      );
    }
  }

  void _addToPlaylist(dynamic item) {
    try {
      MusicPlayerController musicController;
      try {
        musicController = Get.find<MusicPlayerController>();
      } catch (e) {
        musicController = Get.put(MusicPlayerController());
      }

      if (item is HotVideoItemModel) {
        final musicItem = MusicItem(
          musicId: item.bvid ?? (item.aid?.toString() ?? ''),
          title: item.title,
          artist: item.owner.name ?? '未知作者',
          cover: item.cover ?? '',
          mvAid: item.aid,
          mvBvid: item.bvid,
          mvCid: item.cid,
        );
        musicController.addToPlaylist(musicItem);
        SmartDialog.showToast('已添加到播放列表');
      }
    } catch (e) {
      SmartDialog.showToast('添加失败');
    }
  }

  Widget get _buildSkeleton => SliverGrid.builder(
    gridDelegate: gridDelegate,
    itemBuilder: (context, index) => const VideoCardVSkeleton(),
    itemCount: 10,
  );
}

// 分P选择器组件
class _PartSelectorSheet extends StatelessWidget {
  final HotVideoItemModel item;
  final MusicPlayerController controller;
  final ThemeData theme;

  const _PartSelectorSheet({
    required this.item,
    required this.controller,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.outline.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '选择分P - ${item.title}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Obx(
                    () => TextButton(
                      onPressed: controller.selectedPartIndices.isEmpty
                          ? null
                          : () {
                              final favItem = FavDetailItemModel(
                                id: item.aid,
                                bvid: item.bvid,
                                title: item.title,
                                cover: item.cover,
                                upper: Owner(name: item.owner.name),
                              );
                              controller.importSelectedParts(favItem);
                              Navigator.pop(context);
                            },
                      child: Text(
                        '导入(${controller.selectedPartIndices.length})',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Obx(
                    () => Checkbox(
                      value:
                          controller.selectedPartIndices.length ==
                          controller.videoParts.length,
                      tristate: true,
                      onChanged: (_) => controller.toggleSelectAllParts(),
                    ),
                  ),
                  Obx(
                    () => Text(
                      '全选 (${controller.videoParts.length}个分P)',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: Obx(() {
                final parts = controller.videoParts;
                if (parts.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                return ListView.builder(
                  controller: scrollController,
                  itemCount: parts.length,
                  itemBuilder: (context, index) {
                    final part = parts[index];
                    final duration = Duration(seconds: part.duration ?? 0);
                    final durationStr =
                        '${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}';

                    return Obx(() {
                      final isSelected = controller.selectedPartIndices
                          .contains(index);
                      return CheckboxListTile(
                        value: isSelected,
                        onChanged: (_) => controller.togglePartSelection(index),
                        title: Text(
                          'P${index + 1} ${part.part ?? ''}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isSelected
                                ? theme.colorScheme.primary
                                : null,
                          ),
                        ),
                        subtitle: Text(durationStr),
                        secondary: IconButton(
                          icon: const Icon(Icons.play_circle_outline),
                          tooltip: '单独添加此分P',
                          onPressed: () {
                            final favItem = FavDetailItemModel(
                              id: item.aid,
                              bvid: item.bvid,
                              title: item.title,
                              cover: item.cover,
                              upper: Owner(name: item.owner.name),
                            );
                            controller.importSinglePart(favItem, index, part);
                          },
                        ),
                      );
                    });
                  },
                );
              }),
            ),
          ],
        );
      },
    );
  }
}
