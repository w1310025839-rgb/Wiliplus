import 'package:PiliPlus/common/widgets/flutter/refresh_indicator.dart';
import 'package:PiliPlus/common/widgets/image/network_img_layer.dart';
import 'package:PiliPlus/common/widgets/loading_widget/http_error.dart';
import 'package:PiliPlus/common/widgets/scroll_physics.dart';
import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/models/common/image_type.dart';
import 'package:PiliPlus/pages/friends/controller.dart';
import 'package:PiliPlus/pages/friends/widgets/friend_dynamics_tab.dart';
import 'package:PiliPlus/pages/friends/widgets/friend_whisper_tab.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class FriendsPage extends StatefulWidget {
  const FriendsPage({super.key});

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {
  late final FriendsController _controller = Get.put(FriendsController());

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        primary: false,
        toolbarHeight: 50,
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false, // 移除默认的drawer按钮
        title: SizedBox(
          height: 50,
          child: TabBar(
            controller: _controller.tabController,
            isScrollable: true,
            dividerColor: Colors.transparent,
            dividerHeight: 0,
            tabAlignment: TabAlignment.center,
            indicatorColor: theme.colorScheme.primary,
            labelColor: theme.colorScheme.primary,
            unselectedLabelColor: theme.colorScheme.onSurface,
            labelStyle:
                TabBarTheme.of(context).labelStyle?.copyWith(fontSize: 13) ??
                const TextStyle(fontSize: 13),
            tabs: const [
              Tab(text: '动态'),
              Tab(text: '消息'),
            ],
          ),
        ),
      ),
      // 使用Row布局，左侧常驻好友列表，右侧是内容区
      body: Row(
        children: [
          // 常驻好友侧栏
          _buildFriendsSidebar(theme),
          // 垂直分割线
          VerticalDivider(width: 1, thickness: 1, color: theme.dividerColor),
          // 主内容区
          Expanded(
            child: tabBarView(
              controller: _controller.tabController,
              children: const [
                FriendDynamicsTab(),
                FriendWhisperTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 常驻好友侧栏
  Widget _buildFriendsSidebar(ThemeData theme) {
    return SizedBox(
      width: 80,
      child: Column(
        children: [
          const SizedBox(height: 8),
          Text(
            '好友',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          // 筛选按钮
          Obx(
            () => _buildFilterChips(theme),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),
          Expanded(
            child: Obx(
              () => _buildFriendsList(
                _controller.friendsState.value,
                theme,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        children: FriendFilterType.values.map((type) {
          final isSelected = _controller.filterType.value == type;
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: InkWell(
              onTap: () => _controller.setFilterType(type),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.primaryContainer
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  _controller.getFilterTypeName(type),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    color: isSelected
                        ? theme.colorScheme.onPrimaryContainer
                        : theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFriendsList(
    LoadingState<List<FriendInfo>?> state,
    ThemeData theme,
  ) {
    return switch (state) {
      Loading() => const Center(child: CircularProgressIndicator()),
      Success(:final response) =>
        response != null && response.isNotEmpty
            ? refreshIndicator(
                onRefresh: _controller.onRefresh,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: response.length,
                  itemBuilder: (context, index) {
                    final item = response[index];
                    return _buildFriendItem(item, theme);
                  },
                ),
              )
            : _buildEmptyState(theme),
      Error(:final errMsg) => HttpError(
        errMsg: errMsg,
        onReload: _controller.loadFriendsFromWhisper,
      ),
    };
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 48,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: 8),
          Text(
            '暂无好友',
            style: TextStyle(
              color: theme.colorScheme.outline,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendItem(FriendInfo item, ThemeData theme) {
    return InkWell(
      onTap: () => Get.toNamed(
        '/whisperDetail',
        parameters: {
          'talkerId': item.uid.toString(),
          'name': item.name,
          'face': item.face,
        },
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        child: Column(
          children: [
            Stack(
              children: [
                // 点击头像跳转到用户动态页面
                GestureDetector(
                  onTap: () => Get.toNamed(
                    '/memberDynamics',
                    parameters: {'mid': item.uid.toString()},
                  ),
                  child: NetworkImgLayer(
                    width: 40,
                    height: 40,
                    src: item.face,
                    type: ImageType.avatar,
                  ),
                ),
                if (item.isLive)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: theme.colorScheme.surface,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              item.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 9),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
