import 'package:PiliPlus/common/widgets/image/network_img_layer.dart';
import 'package:PiliPlus/models/common/video/video_quality.dart';
import 'package:PiliPlus/models/common/video/audio_quality.dart';
import 'package:PiliPlus/pages/music_player/controller.dart';
import 'package:PiliPlus/utils/page_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:media_kit_video/media_kit_video.dart';

class MusicPlayerPage extends StatefulWidget {
  const MusicPlayerPage({super.key});

  @override
  State<MusicPlayerPage> createState() => _MusicPlayerPageState();
}

class _MusicPlayerPageState extends State<MusicPlayerPage> {
  late final MusicPlayerController controller;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    controller = Get.put(MusicPlayerController());
    _pageController = PageController(
      initialPage: controller.showMV.value ? 1 : 0,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(theme),
            Expanded(
              child: _buildSwipeableContent(theme, size),
            ),
            _buildSongInfo(theme),
            _buildProgressBar(theme),
            _buildControls(theme),
            _buildBottomBar(theme),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_down, size: 28),
            onPressed: Get.back,
          ),
          Obx(
            () => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildPageIndicator(!controller.showMV.value, '封面'),
                const SizedBox(width: 8),
                _buildPageIndicator(controller.showMV.value, 'MV'),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.music_note_outlined),
            onPressed: _navigateToMusicZone,
            tooltip: '音乐分区',
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicator(bool isActive, String label) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isActive
            ? theme.colorScheme.primary.withValues(alpha: 0.2)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isActive
              ? theme.colorScheme.primary
              : theme.colorScheme.outline,
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildSwipeableContent(ThemeData theme, Size size) {
    return PageView(
      controller: _pageController,
      onPageChanged: (index) {
        if (index == 0 && controller.showMV.value) {
          controller.toggleMVDisplay();
        } else if (index == 1 && !controller.showMV.value) {
          controller.toggleMVDisplay();
        }
      },
      children: [
        _buildCoverView(theme, size),
        _buildMVView(theme, size),
      ],
    );
  }

  Widget _buildCoverView(ThemeData theme, Size size) {
    return Obx(() {
      final music = controller.currentMusic.value;
      if (music == null) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.music_note,
                size: 80,
                color: theme.colorScheme.outline,
              ),
              const SizedBox(height: 16),
              Text(
                '暂无播放内容',
                style: TextStyle(color: theme.colorScheme.outline),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _navigateToMusicZone,
                icon: const Icon(Icons.library_music),
                label: const Text('浏览音乐分区'),
              ),
            ],
          ),
        );
      }
      final coverSize = size.width * 0.75;
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: coverSize,
              height: coverSize,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.shadow.withValues(alpha: 0.3),
                    blurRadius: 30,
                    offset: const Offset(0, 15),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    NetworkImgLayer(
                      src: music.cover,
                      width: coverSize,
                      height: coverSize,
                    ),
                    if (controller.isLoadingVideo.value ||
                        controller.isBuffering.value)
                      ColoredBox(
                        color: Colors.black.withValues(alpha: 0.3),
                        child: const CircularProgressIndicator(
                          color: Colors.white,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.swipe, size: 16, color: theme.colorScheme.outline),
                const SizedBox(width: 4),
                Text(
                  '左滑查看MV',
                  style: TextStyle(
                    color: theme.colorScheme.outline,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _buildMVView(ThemeData theme, Size size) {
    return Obx(() {
      final music = controller.currentMusic.value;
      if (music == null) return _buildCoverView(theme, size);

      final videoCtrl = controller.videoController;
      final isAlbumRatio = controller.isAlbumRatio.value;

      // 16:9模式：宽度为屏幕90%，高度按比例
      // 2:3模式：高度为可用空间的70%，宽度按2:3比例计算
      final double videoWidth;
      final double videoHeight;

      if (isAlbumRatio) {
        // 2:3裁切模式：以高度为基准
        videoHeight = size.height * 0.55;
        videoWidth = videoHeight * (2 / 3);
      } else {
        // 16:9模式
        videoWidth = size.width * 0.9;
        videoHeight = videoWidth * 0.5625;
      }

      return Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildRatioButton(theme, '16:9', !isAlbumRatio),
                    const SizedBox(width: 12),
                    _buildRatioButton(theme, '2:3', isAlbumRatio),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => _goToFullVideoPage(music),
                child: Container(
                  width: videoWidth,
                  height: videoHeight,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.black,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (videoCtrl != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: isAlbumRatio
                              ? _buildAlbumRatioVideo(
                                  videoCtrl,
                                  videoWidth,
                                  videoHeight,
                                )
                              : Video(
                                  controller: videoCtrl,
                                  controls: NoVideoControls,
                                  fill: Colors.black,
                                ),
                        )
                      else
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: NetworkImgLayer(
                            src: music.cover,
                            width: videoWidth,
                            height: videoHeight,
                          ),
                        ),
                      if (controller.isLoadingVideo.value ||
                          controller.isBuffering.value)
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const SizedBox(
                            width: double.infinity,
                            height: double.infinity,
                            child: Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      Positioned(
                        right: 8,
                        bottom: 8,
                        child: IconButton(
                          icon: const Icon(
                            Icons.fullscreen,
                            color: Colors.white,
                            size: 28,
                          ),
                          onPressed: () => _goToFullVideoPage(music),
                          tooltip: '全屏播放',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.swipe, size: 16, color: theme.colorScheme.outline),
                  const SizedBox(width: 4),
                  Text(
                    '右滑查看封面',
                    style: TextStyle(
                      color: theme.colorScheme.outline,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildAlbumRatioVideo(
    VideoController videoCtrl,
    double containerWidth,
    double containerHeight,
  ) {
    // 2:3 裁切模式：保持视频原始纵向内容，只裁切横向多余部分
    // 原视频是16:9，目标显示区域是2:3
    // 策略：让视频高度填满容器，宽度按16:9比例计算，然后居中裁切
    const videoAspectRatio = 16 / 9;

    // 视频实际渲染尺寸：高度=容器高度，宽度按16:9计算
    final videoHeight = containerHeight;
    final videoWidth = videoHeight * videoAspectRatio;

    // 容器宽度就是目标显示宽度（2:3比例）
    // containerWidth = containerHeight * (2/3)，由调用方传入

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: containerWidth,
        height: containerHeight,
        child: OverflowBox(
          alignment: Alignment.center,
          minWidth: videoWidth,
          maxWidth: videoWidth,
          minHeight: videoHeight,
          maxHeight: videoHeight,
          child: Video(
            controller: videoCtrl,
            controls: NoVideoControls,
            fill: Colors.black,
            // 不指定fit，让视频自然填充OverflowBox的尺寸
          ),
        ),
      ),
    );
  }

  Widget _buildRatioButton(ThemeData theme, String label, bool isActive) {
    return GestureDetector(
      onTap: () => controller.toggleVideoRatio(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? theme.colorScheme.primary
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurface,
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  void _goToFullVideoPage(MusicItem music) {
    if (music.mvBvid != null) {
      controller.pause();
      controller.player?.stop();
      PageUtils.toVideoPage(
        bvid: music.mvBvid!,
        cid: music.mvCid ?? 0,
        aid: music.mvAid,
        cover: music.cover,
        title: music.title,
      );
    }
  }

  Widget _buildSongInfo(ThemeData theme) {
    return Obx(() {
      final music = controller.currentMusic.value;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          children: [
            Text(
              music?.title ?? '未知歌曲',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              music?.artist ?? '未知艺术家',
              style: TextStyle(color: theme.colorScheme.outline, fontSize: 14),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      );
    });
  }

  Widget _buildProgressBar(ThemeData theme) {
    return Obx(() {
      final currentProgress = controller.progress.value;
      final totalDuration = controller.duration.value;

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            SliderTheme(
              data: SliderThemeData(
                trackHeight: 4,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                activeTrackColor: theme.colorScheme.primary,
                inactiveTrackColor: theme.colorScheme.outline.withValues(
                  alpha: 0.2,
                ),
                thumbColor: theme.colorScheme.primary,
              ),
              child: Slider(
                value: currentProgress.clamp(
                  0.0,
                  totalDuration > 0 ? totalDuration : 1.0,
                ),
                max: totalDuration > 0 ? totalDuration : 1.0,
                onChanged: controller.seekTo,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDuration(currentProgress),
                    style: TextStyle(
                      color: theme.colorScheme.outline,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    _formatDuration(totalDuration),
                    style: TextStyle(
                      color: theme.colorScheme.outline,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildControls(ThemeData theme) {
    return Obx(() {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: Icon(
                Icons.shuffle,
                color: controller.isShuffleMode.value
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline,
              ),
              onPressed: controller.toggleShuffle,
            ),
            IconButton(
              icon: const Icon(Icons.skip_previous, size: 36),
              onPressed: controller.playPrevious,
            ),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.primary,
              ),
              child: controller.isLoadingVideo.value
                  ? Center(
                      child: CircularProgressIndicator(
                        color: theme.colorScheme.onPrimary,
                        strokeWidth: 2,
                      ),
                    )
                  : IconButton(
                      icon: Icon(
                        controller.isPlaying.value
                            ? Icons.pause
                            : Icons.play_arrow,
                        size: 32,
                        color: theme.colorScheme.onPrimary,
                      ),
                      onPressed: controller.togglePlay,
                    ),
            ),
            IconButton(
              icon: const Icon(Icons.skip_next, size: 36),
              onPressed: controller.playNext,
            ),
            IconButton(
              icon: Icon(
                _getRepeatIcon(),
                color: controller.repeatMode.value > 0
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline,
              ),
              onPressed: controller.toggleRepeatMode,
            ),
          ],
        ),
      );
    });
  }

  IconData _getRepeatIcon() {
    switch (controller.repeatMode.value) {
      case 1:
        return Icons.repeat_one;
      case 2:
        return Icons.repeat;
      default:
        return Icons.repeat;
    }
  }

  Widget _buildBottomBar(ThemeData theme) {
    return Obx(() {
      final music = controller.currentMusic.value;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: const Icon(Icons.favorite_border),
              onPressed: music != null
                  ? () => _showFavFolderSheet(theme)
                  : null,
              tooltip: '收藏到收藏夹',
            ),
            IconButton(
              icon: const Icon(Icons.queue_music),
              onPressed: () => _showPlaylist(theme),
              tooltip: '播放列表',
            ),
            IconButton(
              icon: const Icon(Icons.folder_open),
              onPressed: () => Get.toNamed('/fav'),
              tooltip: '我的收藏',
            ),
            IconButton(
              icon: Icon(
                Icons.equalizer,
                color: controller.audioEffectMode.value > 0
                    ? theme.colorScheme.primary
                    : null,
              ),
              onPressed: () => _showAudioEffectSheet(theme),
              tooltip: '音效设置',
            ),
            IconButton(
              icon: const Icon(Icons.download_outlined),
              onPressed: () => _showCacheSheet(theme),
              tooltip: '缓存管理',
            ),
          ],
        ),
      );
    });
  }

  void _showAudioEffectSheet(ThemeData theme) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) =>
          _AudioEffectSheet(controller: controller, theme: theme),
    );
  }

  void _showCacheSheet(ThemeData theme) {
    controller.loadCachedItems();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => _CacheSheet(controller: controller, theme: theme),
    );
  }

  void _showFavFolderSheet(ThemeData theme) {
    controller.loadFavFolders();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) =>
          _FavFolderSelectSheet(controller: controller, theme: theme),
    );
  }

  void _showPlaylist(ThemeData theme) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) =>
          _PlaylistSheet(controller: controller, theme: theme),
    );
  }

  void _navigateToMusicZone() => Get.toNamed('/musicZone');

  String _formatDuration(double seconds) {
    final duration = Duration(seconds: seconds.toInt());
    final minutes = duration.inMinutes;
    final secs = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}

class _FavFolderSelectSheet extends StatelessWidget {
  final MusicPlayerController controller;
  final ThemeData theme;
  const _FavFolderSelectSheet({required this.controller, required this.theme});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.8,
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
                  Text(
                    '添加到收藏夹',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () => Get.toNamed('/createFav'),
                    child: const Text('新建收藏夹'),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: Obx(() {
                if (controller.isLoadingFolders.value) {
                  return const Center(child: CircularProgressIndicator());
                }
                final folders = controller.favFolders;
                if (folders.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.folder_open,
                          size: 64,
                          color: theme.colorScheme.outline,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '暂无收藏夹',
                          style: TextStyle(color: theme.colorScheme.outline),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '请先登录账号',
                          style: TextStyle(
                            color: theme.colorScheme.outline,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  controller: scrollController,
                  itemCount: folders.length,
                  itemBuilder: (context, index) {
                    final folder = folders[index];
                    return ListTile(
                      leading: Icon(
                        folder.attr == 0
                            ? Icons.folder_outlined
                            : Icons.lock_outline,
                        color: theme.colorScheme.primary,
                      ),
                      title: Text(folder.title),
                      subtitle: Text('${folder.mediaCount}个内容'),
                      onTap: () async {
                        Navigator.pop(context);
                        final result = await controller.addToFavFolder(
                          folder.id,
                        );
                        SmartDialog.showToast(
                          result ? '已添加到「${folder.title}」' : '添加失败',
                        );
                      },
                    );
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

class _PlaylistSheet extends StatelessWidget {
  final MusicPlayerController controller;
  final ThemeData theme;
  const _PlaylistSheet({required this.controller, required this.theme});

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
                  Obx(
                    () => Text(
                      '播放列表 (${controller.playlist.length})',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Obx(
                        () => IconButton(
                          icon: Icon(
                            controller.playlistMemoryEnabled.value
                                ? Icons.bookmark
                                : Icons.bookmark_border,
                            color: controller.playlistMemoryEnabled.value
                                ? theme.colorScheme.primary
                                : null,
                          ),
                          tooltip: controller.playlistMemoryEnabled.value
                              ? '关闭记忆'
                              : '开启记忆',
                          onPressed: controller.togglePlaylistMemory,
                        ),
                      ),
                      TextButton(
                        onPressed: controller.clearPlaylist,
                        child: const Text('清空'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: Obx(() {
                if (controller.playlist.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.queue_music,
                          size: 64,
                          color: theme.colorScheme.outline,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '播放列表为空',
                          style: TextStyle(color: theme.colorScheme.outline),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '从音乐分区添加内容',
                          style: TextStyle(
                            color: theme.colorScheme.outline,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  controller: scrollController,
                  itemCount: controller.playlist.length,
                  itemBuilder: (context, index) {
                    final music = controller.playlist[index];
                    final isPlaying = controller.currentIndex.value == index;
                    return ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: NetworkImgLayer(
                          src: music.cover,
                          width: 48,
                          height: 48,
                        ),
                      ),
                      title: Text(
                        music.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isPlaying ? theme.colorScheme.primary : null,
                          fontWeight: isPlaying ? FontWeight.bold : null,
                        ),
                      ),
                      subtitle: Text(
                        music.artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: isPlaying
                          ? Icon(
                              Icons.equalizer,
                              color: theme.colorScheme.primary,
                            )
                          : IconButton(
                              icon: const Icon(Icons.close, size: 20),
                              onPressed: () =>
                                  controller.removeFromPlaylist(index),
                            ),
                      onTap: () => controller.playMusic(index),
                    );
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

class _CacheSheet extends StatelessWidget {
  final MusicPlayerController controller;
  final ThemeData theme;
  const _CacheSheet({required this.controller, required this.theme});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      minChildSize: 0.3,
      maxChildSize: 0.95,
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
                  Text(
                    '缓存管理',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => Get.toNamed('/download'),
                    icon: const Icon(Icons.folder_open, size: 18),
                    label: const Text('缓存文件夹'),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // 缓存设置区域
            _buildCacheSettings(context),
            const Divider(height: 1),
            // 缓存当前按钮
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: controller.currentMusic.value != null
                      ? controller.cacheCurrentVideo
                      : null,
                  icon: const Icon(Icons.download),
                  label: const Text('缓存当前播放'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
            const Divider(height: 1),
            // 已缓存列表标题
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.download_done,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Obx(
                    () => Text(
                      '已缓存 (${controller.cachedItems.length})',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      for (final item in controller.cachedItems) {
                        controller.addToPlaylist(item);
                      }
                      SmartDialog.showToast('已全部添加到播放列表');
                    },
                    child: const Text('全部添加'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Obx(() {
                if (controller.isLoadingCache.value) {
                  return const Center(child: CircularProgressIndicator());
                }
                final items = controller.cachedItems;
                if (items.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.download_done,
                          size: 64,
                          color: theme.colorScheme.outline,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '暂无缓存',
                          style: TextStyle(color: theme.colorScheme.outline),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '点击上方按钮缓存当前播放的视频',
                          style: TextStyle(
                            color: theme.colorScheme.outline,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  controller: scrollController,
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: NetworkImgLayer(
                          src: item.cover,
                          width: 48,
                          height: 48,
                        ),
                      ),
                      title: Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        item.artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.playlist_add),
                            tooltip: '添加到播放列表',
                            onPressed: () {
                              controller.addToPlaylist(item);
                              SmartDialog.showToast('已添加到播放列表');
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            tooltip: '删除缓存',
                            onPressed: () async =>
                                controller.deleteCachedItem(item),
                          ),
                        ],
                      ),
                      onTap: () {
                        controller.playLocalCache(item);
                        Navigator.pop(context);
                      },
                    );
                  },
                );
              }),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCacheSettings(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '缓存设置',
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildQualitySelector(
                  context,
                  label: '视频画质',
                  icon: Icons.video_settings,
                  currentValue: controller.cacheQuality.value.desc,
                  onTap: () => _showVideoQualityPicker(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQualitySelector(
                  context,
                  label: '音频音质',
                  icon: Icons.music_note,
                  currentValue: controller.cacheAudioQuality.value.desc,
                  onTap: () => _showAudioQualityPicker(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQualitySelector(
    BuildContext context, {
    required String label,
    required IconData icon,
    required String currentValue,
    required VoidCallback onTap,
  }) {
    return Obx(
      () => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.3),
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.outline,
                      ),
                    ),
                    Text(
                      label == '视频画质'
                          ? controller.cacheQuality.value.desc
                          : controller.cacheAudioQuality.value.desc,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_drop_down,
                color: theme.colorScheme.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showVideoQualityPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                '选择视频画质',
                style: theme.textTheme.titleMedium,
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: VideoQuality.values.length,
                itemBuilder: (context, index) {
                  final quality = VideoQuality.values[index];
                  final isSelected = controller.cacheQuality.value == quality;
                  return ListTile(
                    title: Text(quality.desc),
                    trailing: isSelected
                        ? Icon(Icons.check, color: theme.colorScheme.primary)
                        : null,
                    onTap: () {
                      controller.setCacheQuality(quality);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAudioQualityPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                '选择音频音质',
                style: theme.textTheme.titleMedium,
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: AudioQuality.values.length,
                itemBuilder: (context, index) {
                  final quality = AudioQuality.values[index];
                  final isSelected =
                      controller.cacheAudioQuality.value == quality;
                  return ListTile(
                    title: Text(quality.desc),
                    trailing: isSelected
                        ? Icon(Icons.check, color: theme.colorScheme.primary)
                        : null,
                    onTap: () {
                      controller.setCacheAudioQuality(quality);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AudioEffectSheet extends StatelessWidget {
  final MusicPlayerController controller;
  final ThemeData theme;

  const _AudioEffectSheet({required this.controller, required this.theme});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.8,
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
                  Text(
                    '音效设置',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Obx(
                    () => Text(
                      controller.getAudioEffectName(
                        controller.audioEffectMode.value,
                      ),
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    '预设音效',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Obx(
                    () => Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildEffectChip(context, 0, '关闭', Icons.volume_off),
                        _buildEffectChip(context, 1, '低音增强', Icons.speaker),
                        _buildEffectChip(context, 2, '人声增强', Icons.mic),
                        _buildEffectChip(
                          context,
                          3,
                          '3D环绕',
                          Icons.surround_sound,
                        ),
                        _buildEffectChip(
                          context,
                          4,
                          '清晰人声',
                          Icons.record_voice_over,
                        ),
                        _buildEffectChip(context, 5, '自定义', Icons.tune),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Obx(() {
                    if (controller.audioEffectMode.value != 5) {
                      return const SizedBox.shrink();
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '自定义均衡器',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildSlider(
                          context,
                          '低音',
                          controller.bassBoost.value,
                          controller.setBassBoost,
                        ),
                        const SizedBox(height: 12),
                        _buildSlider(
                          context,
                          '高音',
                          controller.trebleBoost.value,
                          controller.setTrebleBoost,
                        ),
                      ],
                    );
                  }),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 16,
                              color: theme.colorScheme.outline,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '音效说明',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '• 低音增强：增强60-120Hz频段，适合电子音乐\n'
                          '• 人声增强：增强1-4kHz频段，突出人声\n'
                          '• 3D环绕：模拟立体声环绕效果\n'
                          '• 清晰人声：过滤背景噪音，突出人声',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.outline,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEffectChip(
    BuildContext context,
    int mode,
    String label,
    IconData icon,
  ) {
    final isSelected = controller.audioEffectMode.value == mode;
    return FilterChip(
      selected: isSelected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isSelected
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurface,
          ),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      onSelected: (_) => controller.setAudioEffect(mode),
      selectedColor: theme.colorScheme.primary,
      checkmarkColor: theme.colorScheme.onPrimary,
      labelStyle: TextStyle(
        color: isSelected
            ? theme.colorScheme.onPrimary
            : theme.colorScheme.onSurface,
      ),
    );
  }

  Widget _buildSlider(
    BuildContext context,
    String label,
    double value,
    ValueChanged<double> onChanged,
  ) {
    return Row(
      children: [
        SizedBox(
          width: 50,
          child: Text(
            label,
            style: TextStyle(color: theme.colorScheme.onSurface),
          ),
        ),
        Expanded(
          child: Slider(
            value: value,
            min: -10,
            max: 10,
            divisions: 20,
            label: value.toStringAsFixed(1),
            onChanged: onChanged,
          ),
        ),
        SizedBox(
          width: 40,
          child: Text(
            value.toStringAsFixed(1),
            style: TextStyle(
              color: theme.colorScheme.outline,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}
