import 'package:PiliPlus/common/skeleton/whisper_item.dart';
import 'package:PiliPlus/common/widgets/flutter/refresh_indicator.dart';
import 'package:PiliPlus/common/widgets/loading_widget/http_error.dart';
import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/pages/friends/controller.dart';
import 'package:PiliPlus/pages/whisper/widgets/item.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class FriendWhisperTab extends StatefulWidget {
  const FriendWhisperTab({super.key});

  @override
  State<FriendWhisperTab> createState() => _FriendWhisperTabState();
}

class _FriendWhisperTabState extends State<FriendWhisperTab>
    with AutomaticKeepAliveClientMixin {
  late final FriendsController _friendsController;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _friendsController = Get.find<FriendsController>();
  }

  Future<void> _onRefresh() async {
    await _friendsController.onRefresh();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);

    return Obx(() => _buildBody(_friendsController.friendsState.value, theme));
  }

  Widget _buildBody(LoadingState<List<FriendInfo>?> state, ThemeData theme) {
    late final divider = Divider(
      indent: 72,
      endIndent: 20,
      height: 1,
      color: Colors.grey.withValues(alpha: 0.1),
    );

    return switch (state) {
      Loading() => ListView.builder(
        itemCount: 8,
        itemBuilder: (context, index) => const WhisperItemSkeleton(),
      ),
      Success() =>
        _friendsController.sessionList.isNotEmpty
            ? refreshIndicator(
                onRefresh: _onRefresh,
                child: ListView.separated(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.paddingOf(context).bottom + 100,
                  ),
                  itemCount: _friendsController.sessionList.length,
                  separatorBuilder: (_, _) => divider,
                  itemBuilder: (context, index) {
                    final item = _friendsController.sessionList[index];
                    return WhisperSessionItem(
                      item: item,
                      onSetTop: (isTop, id) {},
                      onSetMute: (isMuted, talkerUid) {},
                      onRemove: (talkerId) {
                        _friendsController.sessionList.removeWhere(
                          (s) => s.id.privateId.talkerUid.toInt() == talkerId,
                        );
                      },
                    );
                  },
                ),
              )
            : _buildEmptyState(theme),
      Error(:final errMsg) => HttpError(
        errMsg: errMsg,
        onReload: _friendsController.loadFriendsFromWhisper,
      ),
    };
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            '暂无好友消息',
            style: TextStyle(color: theme.colorScheme.outline),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _onRefresh,
            child: const Text('刷新'),
          ),
        ],
      ),
    );
  }
}
