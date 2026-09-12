import 'package:PiliPlus/models/model_owner.dart';

class FollowingsFollowedUpper {
  List<Owner>? items;
  String? jumpUrl;

  FollowingsFollowedUpper({this.items, this.jumpUrl});

  factory FollowingsFollowedUpper.fromJson(Map<String, dynamic> json) =>
      FollowingsFollowedUpper(
        items: (json['items'] as List?)
            ?.map((e) => Owner.fromJson(e as Map<String, dynamic>))
            .toList(),
        jumpUrl: json['jump_url'] as String?,
      );
}
