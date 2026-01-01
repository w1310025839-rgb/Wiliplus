import 'package:PiliPlus/grpc/bilibili/app/im/v1.pb.dart';
import 'package:PiliPlus/grpc/im.dart';
import 'package:PiliPlus/http/follow.dart';
import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/models_new/follow/data.dart';
import 'package:PiliPlus/services/account_service.dart';
import 'package:PiliPlus/utils/accounts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';

enum FriendFilterType { all, special, mutual }

class FriendInfo {
  final int uid;
  final String name;
  final String face;
  final bool isLive;
  final Session? session;
  final bool isSpecialFollow;
  final bool isMutualFollow;

  FriendInfo({
    required this.uid,
    required this.name,
    required this.face,
    this.isLive = false,
    this.session,
    this.isSpecialFollow = false,
    this.isMutualFollow = false,
  });
}

class FriendsController extends GetxController
    with GetSingleTickerProviderStateMixin {
  late TabController tabController;
  final AccountService accountService = Get.find<AccountService>();

  final Rx<LoadingState<List<FriendInfo>?>> friendsState = Rx(
    LoadingState.loading(),
  );
  final RxList<FriendInfo> friendsList = <FriendInfo>[].obs;
  final RxList<FriendInfo> allFriendsList = <FriendInfo>[].obs;
  final RxList<Session> sessionList = <Session>[].obs;
  final RxList<Session> allSessionList = <Session>[].obs;
  final RxSet<int> friendMids = <int>{}.obs;
  final Rx<FriendFilterType> filterType = FriendFilterType.all.obs;

  final RxSet<int> specialFollowMids = <int>{}.obs;
  final RxSet<int> mutualFollowMids = <int>{}.obs;

  @override
  void onInit() {
    super.onInit();
    tabController = TabController(length: 2, vsync: this);
    if (accountService.isLogin.value) {
      _loadAllData();
    } else {
      friendsState.value = const Success(null);
    }
  }

  @override
  void onClose() {
    tabController.dispose();
    super.onClose();
  }

  Future<void> _loadAllData() async {
    friendsState.value = LoadingState.loading();
    specialFollowMids.clear();
    mutualFollowMids.clear();

    await _loadFollowRelations();
    await loadFriendsFromWhisper();
  }

  Future<void> _loadFollowRelations() async {
    if (!Accounts.main.isLogin) return;

    try {
      int pn = 1;
      bool hasMore = true;
      int totalLoaded = 0;

      while (hasMore && pn <= 20) {
        final res = await FollowHttp.followings(
          vmid: Accounts.main.mid,
          pn: pn,
          ps: 50,
        );

        if (res is Success<FollowData>) {
          final list = res.response.list;
          if (list.isNotEmpty) {
            for (final item in list) {
              final attr = item.attribute ?? 0;
              // B站API: attribute=6 表示互相关注, special=1 表示特别关注
              if (attr == 6) {
                mutualFollowMids.add(item.mid);
              }
              if (item.special == 1) {
                specialFollowMids.add(item.mid);
              }
              // 打印每个关注的详细信息
              debugPrint(
                'Follow: ${item.uname} mid=${item.mid} attr=$attr special=${item.special}',
              );
            }
            totalLoaded += list.length;
            pn++;
            hasMore = list.length >= 50;
          } else {
            hasMore = false;
          }
        } else if (res is Error) {
          debugPrint('FollowHttp error: ${res.errMsg}');
          hasMore = false;
        } else {
          hasMore = false;
        }
      }

      debugPrint('=== Follow Relations Summary ===');
      debugPrint('Total followings: $totalLoaded');
      debugPrint('Mutual follows count: ${mutualFollowMids.length}');
      debugPrint('Special follows count: ${specialFollowMids.length}');
    } catch (e) {
      debugPrint('Load follow relations error: $e');
    }
  }

  Future<void> loadFriendsFromWhisper() async {
    friendsList.clear();
    allFriendsList.clear();
    sessionList.clear();
    allSessionList.clear();
    friendMids.clear();

    try {
      final res = await ImGrpc.sessionMain();

      if (res is Success<SessionMainReply>) {
        final sessions = res.response.sessions;
        debugPrint('=== Sessions Loaded: ${sessions.length} ===');

        for (final session in sessions) {
          if (!session.id.privateId.hasTalkerUid()) continue;

          final uid = session.id.privateId.talkerUid.toInt();
          friendMids.add(uid);
          final sessionInfo = session.sessionInfo;

          String face = '';
          if (sessionInfo.avatar.fallbackLayers.layers.isNotEmpty) {
            final resource =
                sessionInfo.avatar.fallbackLayers.layers.first.resource;
            if (resource.hasResImage()) {
              face = resource.resImage.imageSrc.remote.url;
            } else if (resource.hasResAnimation()) {
              face = resource.resAnimation.webpSrc.remote.url;
            }
          }

          final isSpecial = specialFollowMids.contains(uid);
          final isMutual = mutualFollowMids.contains(uid);

          final friend = FriendInfo(
            uid: uid,
            name: sessionInfo.sessionName,
            face: face,
            isLive: sessionInfo.isLive,
            session: session,
            isSpecialFollow: isSpecial,
            isMutualFollow: isMutual,
          );

          allFriendsList.add(friend);
          allSessionList.add(session);

          debugPrint(
            'Session: ${sessionInfo.sessionName} uid=$uid special=$isSpecial mutual=$isMutual',
          );
        }

        _applyFilter();
        friendsState.value = Success(
          friendsList.isNotEmpty ? friendsList : null,
        );

        final specialCount = allFriendsList
            .where((f) => f.isSpecialFollow)
            .length;
        final mutualCount = allFriendsList
            .where((f) => f.isMutualFollow)
            .length;
        debugPrint('=== Final Summary ===');
        debugPrint('Total sessions: ${allFriendsList.length}');
        debugPrint('Special in sessions: $specialCount');
        debugPrint('Mutual in sessions: $mutualCount');
      } else if (res is Error) {
        friendsState.value = Error(res.errMsg);
      }
    } catch (e) {
      friendsState.value = Error(e.toString());
    }
  }

  void setFilterType(FriendFilterType type) {
    filterType.value = type;
    _applyFilter();
    friendsState.refresh();
    SmartDialog.showToast('${getFilterTypeName(type)}: ${friendsList.length}人');
  }

  void _applyFilter() {
    friendsList.clear();
    sessionList.clear();

    for (int i = 0; i < allFriendsList.length; i++) {
      final friend = allFriendsList[i];
      bool shouldInclude = false;

      switch (filterType.value) {
        case FriendFilterType.all:
          shouldInclude = true;
        case FriendFilterType.special:
          shouldInclude = friend.isSpecialFollow;
        case FriendFilterType.mutual:
          shouldInclude = friend.isMutualFollow;
      }

      if (shouldInclude) {
        friendsList.add(friend);
        if (i < allSessionList.length) {
          sessionList.add(allSessionList[i]);
        }
      }
    }
  }

  Future<void> onRefresh() async {
    await _loadAllData();
  }

  String getFilterTypeName(FriendFilterType type) {
    switch (type) {
      case FriendFilterType.all:
        return '全部';
      case FriendFilterType.special:
        return '特别关注';
      case FriendFilterType.mutual:
        return '互相关注';
    }
  }
}
