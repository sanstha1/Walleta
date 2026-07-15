import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:walleta/common/ui/custom_ui_helper.dart';

const double _kActivityIndicatorRadius = 14.0;
const double _kActivityIndicatorMargin = 16.0;

class CustomLoader extends StatelessWidget {
  final double? width;
  final double? height;
  final EdgeInsets? padding;
  final Color? background;
  final Color? foreground;

  const CustomLoader({
    super.key,
    this.width,
    this.height,
    this.padding,
    this.background,
    this.foreground,
  });

  factory CustomLoader.minimal({Color? foreground}) {
    return CustomLoader(
      height: 20,
      width: 20,
      padding: EdgeInsets.zero,
      foreground: foreground,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: background ?? Colors.transparent,
      width: width ?? widthFactor(context),
      height: height ?? heightFactor(context),
      child: Center(
        child: Container(
          padding: padding ?? lPadding,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
          child: SizedBox(
            height: 20,
            width: 20,
            child: CupertinoActivityIndicator(color: foreground),
          ),
        ),
      ),
    );
  }
}

class CustomSliverRefreshControl extends StatelessWidget {
  final Future<void> Function()? onRefresh;
  final bool customBuilder;
  final Color? color;

  const CustomSliverRefreshControl({
    super.key,
    this.onRefresh,
    this.customBuilder = false,
    this.color,
  });

  static Widget buildRefreshIndicator(
    BuildContext context,
    RefreshIndicatorMode refreshState,
    double pulledExtent,
    double refreshTriggerPullDistance,
    double refreshIndicatorExtent,
    Color? color,
  ) {
    final double percentageComplete = clampDouble(
      pulledExtent / refreshTriggerPullDistance,
      0.0,
      1.0,
    );

    return Center(
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          Positioned(
            top: _kActivityIndicatorMargin,
            left: 0.0,
            right: 0.0,
            child: _buildIndicatorForRefreshState(
              refreshState,
              _kActivityIndicatorRadius,
              percentageComplete,
              color,
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildIndicatorForRefreshState(
    RefreshIndicatorMode refreshState,
    double radius,
    double percentageComplete,
    Color? color,
  ) {
    switch (refreshState) {
      case RefreshIndicatorMode.drag:
        const Curve opacityCurve = Interval(0.0, 0.35, curve: Curves.easeInOut);
        return Opacity(
          opacity: opacityCurve.transform(percentageComplete),
          child: CupertinoActivityIndicator.partiallyRevealed(
            radius: radius,
            progress: percentageComplete,
            color: color,
          ),
        );
      case RefreshIndicatorMode.armed:
      case RefreshIndicatorMode.refresh:
        return CupertinoActivityIndicator(radius: radius, color: color);
      case RefreshIndicatorMode.done:
        return CupertinoActivityIndicator(
          radius: radius * percentageComplete,
          color: color,
        );
      case RefreshIndicatorMode.inactive:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoSliverRefreshControl(
      onRefresh: onRefresh,
      builder:
          (
            BuildContext context,
            RefreshIndicatorMode refreshState,
            double pulledExtent,
            double refreshTriggerPullDistance,
            double refreshIndicatorExtent,
          ) {
            if (!customBuilder) {
              return buildRefreshIndicator(
                context,
                refreshState,
                pulledExtent,
                refreshTriggerPullDistance,
                refreshIndicatorExtent,
                color,
              );
            }

            final double percentageComplete = clampDouble(
              pulledExtent / refreshTriggerPullDistance,
              0.0,
              1.0,
            );

            const Curve opacityCurve = Interval(
              0.0,
              0.35,
              curve: Curves.easeInOut,
            );

            return Center(
              child: Stack(
                clipBehavior: Clip.none,
                children: <Widget>[
                  Positioned(
                    bottom: -32.0,
                    left: 0.0,
                    right: 0.0,
                    child: Opacity(
                      opacity: opacityCurve.transform(percentageComplete),
                      child: CupertinoActivityIndicator.partiallyRevealed(
                        radius: 14,
                        progress: percentageComplete,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
    );
  }
}
