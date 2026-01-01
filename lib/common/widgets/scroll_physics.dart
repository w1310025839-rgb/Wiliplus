import 'package:PiliPlus/utils/storage_pref.dart';
import 'package:flutter/material.dart';

Widget videoTabBarView({
  required List<Widget> children,
  TabController? controller,
}) => TabBarView(
  physics: const CustomTabBarViewScrollPhysics(
    parent: ClampingScrollPhysics(),
  ),
  controller: controller,
  children: children,
);

Widget tabBarView({
  required List<Widget> children,
  TabController? controller,
}) => TabBarView(
  physics: const CustomTabBarViewScrollPhysics(),
  controller: controller,
  children: children,
);

SpringDescription _customSpringDescription() {
  final List<double> springDescription = Pref.springDescription;
  return SpringDescription(
    mass: springDescription[0],
    stiffness: springDescription[1],
    damping: springDescription[2],
  );
}

class CustomTabBarViewScrollPhysics extends ScrollPhysics {
  const CustomTabBarViewScrollPhysics({super.parent});

  @override
  CustomTabBarViewScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return CustomTabBarViewScrollPhysics(parent: buildParent(ancestor));
  }

  static final _springDescription = _customSpringDescription();

  @override
  SpringDescription get spring => _springDescription;

  @override
  double get minFlingVelocity => 100.0;

  @override
  double get maxFlingVelocity => 5000.0;

  @override
  double get dragStartDistanceMotionThreshold => 3.5;
}

class OptimizedScrollPhysics extends BouncingScrollPhysics {
  const OptimizedScrollPhysics({super.parent});

  @override
  OptimizedScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return OptimizedScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  double get minFlingVelocity => 100.0;

  @override
  double get maxFlingVelocity => 5000.0;

  @override
  double get dragStartDistanceMotionThreshold => 3.5;

  @override
  SpringDescription get spring => SpringDescription.withDampingRatio(
    mass: 0.3,
    stiffness: 200.0,
    ratio: 0.9,
  );
}

mixin ReloadMixin {
  late bool reload = false;
}

class ReloadScrollPhysics extends AlwaysScrollableScrollPhysics {
  const ReloadScrollPhysics({super.parent, required this.controller});

  final ReloadMixin controller;

  @override
  ReloadScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return ReloadScrollPhysics(
      parent: buildParent(ancestor),
      controller: controller,
    );
  }

  @override
  double adjustPositionForNewDimensions({
    required ScrollMetrics oldPosition,
    required ScrollMetrics newPosition,
    required bool isScrolling,
    required double velocity,
  }) {
    if (controller.reload) {
      controller.reload = false;
      return 0;
    }
    return super.adjustPositionForNewDimensions(
      oldPosition: oldPosition,
      newPosition: newPosition,
      isScrolling: isScrolling,
      velocity: velocity,
    );
  }
}
