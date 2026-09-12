import 'dart:async';
import 'dart:math' as math;

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
    // 鍒濆椤甸潰: 0=灏侀潰, 1=姝岃瘝, 2=MV
    int initialPage = 0;
    if (controller.showLyrics.value) {
      initialPage = 1;
    } else if (controller.showMV.value) {
      initialPage = 2;
    }
    _pageController = PageController(initialPage: initialPage);
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
                _buildPageIndicator(
                  !controller.showMV.value && !controller.showLyrics.value,
                  '灏侀潰',
                ),
                const SizedBox(width: 8),
                _buildPageIndicator(controller.showLyrics.value, '姝岃瘝'),
                const SizedBox(width: 8),
                _buildPageIndicator(controller.showMV.value, 'MV'),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.music_note_outlined),
            onPressed: _navigateToMusicZone,
            tooltip: '闊充箰鍒嗗尯',
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
        // 0=灏侀潰, 1=姝岃瘝, 2=MV
        if (index == 0) {
          controller.showLyrics.value = false;
          if (controller.showMV.value) {
            controller.toggleMVDisplay();
          }
        } else if (index == 1) {
          controller.showLyrics.value = true;
          if (controller.showMV.value) {
            controller.toggleMVDisplay();
          }
          // 鍔犺浇姝岃瘝
          if (controller.lyrics.isEmpty) {
            controller.loadLyrics();
          }
        } else if (index == 2) {
          controller.showLyrics.value = false;
          if (!controller.showMV.value) {
            controller.toggleMVDisplay();
          }
        }
      },
      children: [
        _buildCoverView(theme, size),
        _buildLyricsPage(theme, size),
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
                '鏆傛棤鎾斁鍐呭',
                style: TextStyle(color: theme.colorScheme.outline),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _navigateToMusicZone,
                icon: const Icon(Icons.library_music),
                label: const Text('娴忚闊充箰鍒嗗尯'),
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
                  '宸︽粦鏌ョ湅姝岃瘝',
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

  // 姝岃瘝椤甸潰锛堢嫭绔嬬殑婊戝姩椤甸潰锛?
  Widget _buildLyricsPage(ThemeData theme, Size size) {
    return Obx(() {
      final music = controller.currentMusic.value;
      if (music == null) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lyrics_outlined,
                size: 64,
                color: theme.colorScheme.outline,
              ),
              const SizedBox(height: 16),
              Text(
                '鏆傛棤鎾斁鍐呭',
                style: TextStyle(color: theme.colorScheme.outline),
              ),
            ],
          ),
        );
      }

      if (controller.isLoadingLyrics.value) {
        return const Center(child: CircularProgressIndicator());
      }

      final lyrics = controller.lyrics;
      if (lyrics.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lyrics_outlined,
                size: 64,
                color: theme.colorScheme.outline,
              ),
              const SizedBox(height: 16),
              Text(
                '鏆傛棤姝岃瘝',
                style: TextStyle(color: theme.colorScheme.outline),
              ),
              const SizedBox(height: 8),
              Text(
                '该视频没有字幕信息',
                style: TextStyle(
                  color: theme.colorScheme.outline,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      }

      return Stack(
        children: [
          // 闊冲緥娉㈠舰鑳屾櫙
          Positioned.fill(
            child: _AudioWaveformBackground(
              controller: controller,
              theme: theme,
            ),
          ),
          // 姝岃瘝婊氬姩瑙嗗浘
          _LyricsScrollView(
            controller: controller,
            theme: theme,
          ),
        ],
      );
    });
  }

  Widget _buildMVView(ThemeData theme, Size size) {
    return Obx(() {
      final music = controller.currentMusic.value;
      if (music == null) return _buildCoverView(theme, size);

      final videoCtrl = controller.videoController;
      final isAlbumRatio = controller.isAlbumRatio.value;

      // 16:9妯″紡锛氬搴︿负灞忓箷90%锛岄珮搴︽寜姣斾緥
      // 2:3妯″紡锛氶珮搴︿负鍙敤绌洪棿鐨?0%锛屽搴︽寜2:3姣斾緥璁＄畻
      final double videoWidth;
      final double videoHeight;

      if (isAlbumRatio) {
        // 2:3瑁佸垏妯″紡锛氫互楂樺害涓哄熀鍑?
        videoHeight = size.height * 0.55;
        videoWidth = videoHeight * (2 / 3);
      } else {
        // 16:9妯″紡
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
                          tooltip: '鍏ㄥ睆鎾斁',
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
                    '鍙虫粦鏌ョ湅灏侀潰',
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
    // 2:3 瑁佸垏妯″紡锛氫繚鎸佽棰戝師濮嬬旱鍚戝唴瀹癸紝鍙鍒囨í鍚戝浣欓儴鍒?
    // 鍘熻棰戞槸16:9锛岀洰鏍囨樉绀哄尯鍩熸槸2:3
    // 绛栫暐锛氳瑙嗛楂樺害濉弧瀹瑰櫒锛屽搴︽寜16:9姣斾緥璁＄畻锛岀劧鍚庡眳涓鍒?
    const videoAspectRatio = 16 / 9;

    // 瑙嗛瀹為檯娓叉煋灏哄锛氶珮搴?瀹瑰櫒楂樺害锛屽搴︽寜16:9璁＄畻
    final videoHeight = containerHeight;
    final videoWidth = videoHeight * videoAspectRatio;

    // 瀹瑰櫒瀹藉害灏辨槸鐩爣鏄剧ず瀹藉害锛?:3姣斾緥锛?
    // containerWidth = containerHeight * (2/3)锛岀敱璋冪敤鏂逛紶鍏?

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
            // 涓嶆寚瀹歠it锛岃瑙嗛鑷劧濉厖OverflowBox鐨勫昂瀵?
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
      // 姝岃瘝椤甸潰鏃堕殣钘忔爣棰樺拰浣滆€呬俊鎭?
      if (controller.showLyrics.value) {
        return const SizedBox(height: 16);
      }
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          children: [
            // 浣跨敤婊氬姩鍔ㄧ敾鏄剧ず闀挎爣棰?
            SizedBox(
              height: 28,
              child: _MarqueeText(
                text: music?.title ?? '鏈煡姝屾洸',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        child: Wrap(
          alignment: WrapAlignment.center,
          runAlignment: WrapAlignment.center,
          spacing: 2,
          runSpacing: 6,
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
            IconButton(
              icon: const _SeekSecondsIcon(
                icon: Icons.replay,
                label: '15',
              ),
              tooltip: '后退15秒',
              onPressed: () => controller.seekBy(-15),
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
              icon: const _SeekSecondsIcon(
                icon: Icons.forward,
                label: '15',
              ),
              tooltip: '前进15秒',
              onPressed: () => controller.seekBy(15),
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
              tooltip: '鏀惰棌鍒版敹钘忓す',
            ),
            IconButton(
              icon: const Icon(Icons.queue_music),
              onPressed: () => _showPlaylist(theme),
              tooltip: '鎾斁鍒楄〃',
            ),
            IconButton(
              icon: const Icon(Icons.folder_open),
              onPressed: () => Get.toNamed('/fav'),
              tooltip: '鎴戠殑鏀惰棌',
            ),
            IconButton(
              icon: Icon(
                Icons.equalizer,
                color: controller.audioEffectMode.value > 0
                    ? theme.colorScheme.primary
                    : null,
              ),
              onPressed: () => _showAudioEffectSheet(theme),
              tooltip: '闊虫晥璁剧疆',
            ),
            IconButton(
              icon: const Icon(Icons.download_outlined),
              onPressed: () => _showCacheSheet(theme),
              tooltip: '缂撳瓨绠＄悊',
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
                    '娣诲姞鍒版敹钘忓す',
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
                          '璇峰厛鐧诲綍璐﹀彿',
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
                      '鎾斁鍒楄〃 (${controller.playlist.length})',
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
                              ? '鍏抽棴璁板繂'
                              : '开启记忆',
                          onPressed: controller.togglePlaylistMemory,
                        ),
                      ),
                      TextButton(
                        onPressed: controller.clearPlaylist,
                        child: const Text('娓呯┖'),
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
                          '鎾斁鍒楄〃涓虹┖',
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
                    return _PlaylistInfoStrip(
                      music: music,
                      isPlaying: isPlaying,
                      theme: theme,
                      onTap: () => controller.playMusic(index),
                      onRemove: () => controller.removeFromPlaylist(index),
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

class _PlaylistInfoStrip extends StatelessWidget {
  final MusicItem music;
  final bool isPlaying;
  final ThemeData theme;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _PlaylistInfoStrip({
    required this.music,
    required this.isPlaying,
    required this.theme,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          height: 64,
          decoration: BoxDecoration(
            color: isPlaying
                ? colorScheme.primary.withValues(alpha: 0.10)
                : colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isPlaying
                  ? colorScheme.primary.withValues(alpha: 0.35)
                  : colorScheme.outline.withValues(alpha: 0.10),
            ),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 4,
                height: double.infinity,
                decoration: BoxDecoration(
                  color: isPlaying ? colorScheme.primary : Colors.transparent,
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: NetworkImgLayer(
                  src: music.cover,
                  width: 44,
                  height: 44,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      music.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isPlaying
                            ? colorScheme.primary
                            : colorScheme.onSurface,
                        fontWeight: isPlaying
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      music.artist,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              if (isPlaying)
                const Icon(Icons.equalizer, size: 20)
              else
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  visualDensity: VisualDensity.compact,
                  onPressed: onRemove,
                ),
              const SizedBox(width: 6),
            ],
          ),
        ),
      ),
    );
  }
}

class _SeekSecondsIcon extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SeekSecondsIcon({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      height: 32,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(icon, size: 30),
          Positioned(
            bottom: 7,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                height: 1,
              ),
            ),
          ),
        ],
      ),
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
                    '缂撳瓨绠＄悊',
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
            // 缂撳瓨璁剧疆鍖哄煙
            _buildCacheSettings(context),
            const Divider(height: 1),
            // 缂撳瓨褰撳墠鎸夐挳
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: controller.currentMusic.value != null
                      ? controller.cacheCurrentVideo
                      : null,
                  icon: const Icon(Icons.download),
                  label: const Text('缂撳瓨褰撳墠鎾斁'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
            const Divider(height: 1),
            // 宸茬紦瀛樺垪琛ㄦ爣棰?
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
                      '宸茬紦瀛?(${controller.cachedItems.length})',
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
                      SmartDialog.showToast('宸插叏閮ㄦ坊鍔犲埌鎾斁鍒楄〃');
                    },
                    child: const Text('鍏ㄩ儴娣诲姞'),
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
                          '鏆傛棤缂撳瓨',
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
                              SmartDialog.showToast('宸叉坊鍔犲埌鎾斁鍒楄〃');
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            tooltip: '鍒犻櫎缂撳瓨',
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
            '缂撳瓨璁剧疆',
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
                  label: '瑙嗛鐢昏川',
                  icon: Icons.video_settings,
                  currentValue: controller.cacheQuality.value.desc,
                  onTap: () => _showVideoQualityPicker(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQualitySelector(
                  context,
                  label: '闊抽闊宠川',
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
                      label == '瑙嗛鐢昏川'
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
                '閫夋嫨瑙嗛鐢昏川',
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
                '閫夋嫨闊抽闊宠川',
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
                    '闊虫晥璁剧疆',
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
                    '棰勮闊虫晥',
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
                        _buildEffectChip(context, 0, '鍏抽棴', Icons.volume_off),
                        _buildEffectChip(context, 1, '浣庨煶澧炲己', Icons.speaker),
                        _buildEffectChip(context, 2, '浜哄０澧炲己', Icons.mic),
                        _buildEffectChip(
                          context,
                          3,
                          '3D鐜粫',
                          Icons.surround_sound,
                        ),
                        _buildEffectChip(
                          context,
                          4,
                          '娓呮櫚浜哄０',
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
                          '鑷畾涔夊潎琛″櫒',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildSlider(
                          context,
                          '浣庨煶',
                          controller.bassBoost.value,
                          controller.setBassBoost,
                        ),
                        const SizedBox(height: 12),
                        _buildSlider(
                          context,
                          '楂橀煶',
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
                              '闊虫晥璇存槑',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '鈥?浣庨煶澧炲己锛氬寮?0-120Hz棰戞锛岄€傚悎鐢靛瓙闊充箰\n'
                          '鈥?浜哄０澧炲己锛氬寮?-4kHz棰戞锛岀獊鍑轰汉澹癨n'
                          '鈥?3D鐜粫锛氭ā鎷熺珛浣撳０鐜粫鏁堟灉\n'
                          '鈥?娓呮櫚浜哄０锛氳繃婊よ儗鏅櫔闊筹紝绐佸嚭浜哄０',
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

// 闊冲緥娉㈠舰鑳屾櫙缁勪欢
class _AudioWaveformBackground extends StatefulWidget {
  final MusicPlayerController controller;
  final ThemeData theme;

  const _AudioWaveformBackground({
    required this.controller,
    required this.theme,
  });

  @override
  State<_AudioWaveformBackground> createState() =>
      _AudioWaveformBackgroundState();
}

class _AudioWaveformBackgroundState extends State<_AudioWaveformBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    // 闄嶄綆鍔ㄧ敾閫熷害锛?绉掍竴涓懆鏈?
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Obx(() {
          final isPlaying = widget.controller.isPlaying.value;
          return CustomPaint(
            painter: _BeatBlocksPainter(
              primary: widget.theme.colorScheme.primary,
              secondary: widget.theme.colorScheme.secondary,
              isPlaying: isPlaying,
              animationValue: _animationController.value,
              progress: widget.controller.progress.value,
            ),
            size: Size.infinite,
          );
        });
      },
    );
  }
}

class _BeatBlocksPainter extends CustomPainter {
  final Color primary;
  final Color secondary;
  final bool isPlaying;
  final double animationValue;
  final double progress;

  _BeatBlocksPainter({
    required this.primary,
    required this.secondary,
    required this.isPlaying,
    required this.animationValue,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final center = Offset(size.width / 2, size.height / 2);
    final maxHeight = math.min(size.height * 0.56, 220.0);
    final minHeight = math.max(14.0, maxHeight * 0.08);
    const blockCount = 9;
    final blockWidth = (size.width * 0.035).clamp(10.0, 18.0);
    final gap = blockWidth * 0.72;
    final totalWidth = blockCount * blockWidth + (blockCount - 1) * gap;
    final left = center.dx - totalWidth / 2;
    final baseY = center.dy + maxHeight * 0.34;
    final beat = animationValue * math.pi * 2;
    final glowPaint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
    final blockPaint = Paint();

    // 鍩轰簬鎾斁杩涘害鐢熸垚浼殢鏈虹瀛愶紝浣挎尝褰㈤殢闊充箰鍙樺寲
    final seed = progress * 0.13;
    for (int i = 0; i < blockCount; i++) {
      final distanceFromCenter = (i - (blockCount - 1) / 2).abs();
      final centerWeight = 1 - distanceFromCenter / ((blockCount - 1) / 2);
      final phase = beat * (1.0 + i * 0.035) + i * 0.82 + seed;
      final pulse = _ease((math.sin(phase) + 1) / 2);
      final accent = _ease(
        (math.sin(beat * 1.8 + i * 1.37 + seed * 2) + 1) / 2,
      );
      final idleHeight = minHeight * (1.0 + centerWeight * 1.2);
      final activeHeight =
          minHeight +
          (maxHeight - minHeight) *
              (0.22 + centerWeight * 0.28 + pulse * 0.36 + accent * 0.14);
      final height = isPlaying ? activeHeight : idleHeight;
      final x = left + i * (blockWidth + gap);
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, baseY - height, blockWidth, height),
        Radius.circular(blockWidth * 0.32),
      );
      final blockColor = Color.lerp(primary, secondary, i / (blockCount - 1))!;
      final opacity = isPlaying ? 0.18 + pulse * 0.26 : 0.08;

      glowPaint.color = blockColor.withValues(alpha: opacity * 0.38);
      canvas.drawRRect(rect, glowPaint);

      blockPaint.shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          blockColor.withValues(alpha: isPlaying ? 0.52 : 0.18),
          blockColor.withValues(alpha: isPlaying ? 0.20 : 0.08),
        ],
      ).createShader(rect.outerRect);
      canvas.drawRRect(rect, blockPaint);
      blockPaint.shader = null;
    }
  }

  double _ease(double value) {
    final v = value.clamp(0.0, 1.0);
    return v * v * (3 - 2 * v);
  }

  @override
  bool shouldRepaint(covariant _BeatBlocksPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.isPlaying != isPlaying ||
        oldDelegate.progress != progress ||
        oldDelegate.primary != primary ||
        oldDelegate.secondary != secondary;
  }
}

// 姝岃瘝婊氬姩瑙嗗浘缁勪欢
class _LyricsScrollView extends StatefulWidget {
  final MusicPlayerController controller;
  final ThemeData theme;

  const _LyricsScrollView({
    required this.controller,
    required this.theme,
  });

  @override
  State<_LyricsScrollView> createState() => _LyricsScrollViewState();
}

class _LyricsScrollViewState extends State<_LyricsScrollView> {
  final ScrollController _scrollController = ScrollController();
  int _lastIndex = -1;
  bool _isUserScrolling = false;
  Timer? _scrollResetTimer;

  @override
  void initState() {
    super.initState();
    // 鐩戝惉姝岃瘝绱㈠紩鍙樺寲
    ever(widget.controller.currentLyricIndex, _onLyricIndexChanged);
  }

  @override
  void dispose() {
    _scrollResetTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _onLyricIndexChanged(int index) {
    if (index != _lastIndex &&
        _scrollController.hasClients &&
        !_isUserScrolling) {
      _lastIndex = index;
      // 璁＄畻婊氬姩浣嶇疆锛屼娇褰撳墠姝岃瘝灞呬腑
      final viewportHeight = _scrollController.position.viewportDimension;
      final targetOffset = (index * 60.0) - (viewportHeight / 2) + 30;
      _scrollController.animateTo(
        targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _onScrollStart() {
    _isUserScrolling = true;
    _scrollResetTimer?.cancel();
  }

  void _onScrollEnd() {
    _scrollResetTimer?.cancel();
    _scrollResetTimer = Timer(const Duration(seconds: 3), () {
      _isUserScrolling = false;
      // 鎭㈠鑷姩婊氬姩鍒板綋鍓嶆瓕璇?
      _onLyricIndexChanged(widget.controller.currentLyricIndex.value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final lyrics = widget.controller.lyrics;

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollStartNotification) {
          _onScrollStart();
        } else if (notification is ScrollEndNotification) {
          _onScrollEnd();
        }
        return false;
      },
      child: ListView.builder(
        controller: _scrollController,
        padding: EdgeInsets.symmetric(
          vertical: MediaQuery.sizeOf(context).height * 0.25,
          horizontal: 24,
        ),
        itemCount: lyrics.length,
        itemBuilder: (context, index) {
          return Obx(() {
            final isCurrentLine =
                widget.controller.currentLyricIndex.value == index;
            final lyric = lyrics[index];

            return GestureDetector(
              onTap: () => widget.controller.seekToLyric(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 8,
                ),
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  style: TextStyle(
                    fontSize: isCurrentLine ? 20 : 15,
                    fontWeight: isCurrentLine
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: isCurrentLine
                        ? widget.theme.colorScheme.primary
                        : widget.theme.colorScheme.onSurface.withValues(
                            alpha: 0.5,
                          ),
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                  child: Text(
                    lyric.content,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            );
          });
        },
      ),
    );
  }
}

// 婊氬姩鏂囧瓧缁勪欢锛堢敤浜庨暱鏍囬锛?
class _MarqueeText extends StatefulWidget {
  final String text;
  final TextStyle? style;

  const _MarqueeText({
    required this.text,
    this.style,
  });

  @override
  State<_MarqueeText> createState() => _MarqueeTextState();
}

class _MarqueeTextState extends State<_MarqueeText>
    with SingleTickerProviderStateMixin {
  late ScrollController _scrollController;
  late AnimationController _animationController;
  bool _needsScroll = false;
  double _textWidth = 0;
  double _containerWidth = 0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkIfNeedsScroll();
    });
  }

  @override
  void didUpdateWidget(covariant _MarqueeText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _animationController.stop();
      _scrollController.jumpTo(0);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkIfNeedsScroll();
      });
    }
  }

  void _checkIfNeedsScroll() {
    if (!mounted) return;

    final textPainter = TextPainter(
      text: TextSpan(text: widget.text, style: widget.style),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout();

    _textWidth = textPainter.width;

    if (_scrollController.hasClients) {
      _containerWidth = _scrollController.position.viewportDimension;
      _needsScroll = _textWidth > _containerWidth;

      if (_needsScroll) {
        _startScrollAnimation();
      }
    }
  }

  void _startScrollAnimation() {
    if (!mounted || !_needsScroll) return;

    final scrollDistance = _textWidth - _containerWidth + 40; // 棰濆40鍍忕礌杈硅窛
    final duration = Duration(
      milliseconds: (scrollDistance * 30).toInt().clamp(3000, 15000),
    );

    _animationController.duration = duration;
    _animationController.forward().then((_) {
      if (!mounted) return;
      // 鏆傚仠2绉掑悗杩斿洖
      Future.delayed(const Duration(seconds: 2), () {
        if (!mounted) return;
        _scrollController
            .animateTo(
              0,
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
            )
            .then((_) {
              if (!mounted) return;
              // 鏆傚仠3绉掑悗閲嶆柊寮€濮?
              Future.delayed(const Duration(seconds: 3), () {
                if (!mounted) return;
                _animationController.reset();
                _startScrollAnimation();
              });
            });
      });
    });

    _animationController.addListener(() {
      if (_scrollController.hasClients && _needsScroll) {
        final scrollDistance = _textWidth - _containerWidth + 40;
        _scrollController.jumpTo(_animationController.value * scrollDistance);
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      child: Text(
        widget.text,
        style: widget.style,
        maxLines: 1,
      ),
    );
  }
}
