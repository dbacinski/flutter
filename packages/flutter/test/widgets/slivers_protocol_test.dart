// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

void verifyPaintPosition(GlobalKey key, Offset ideal) {
  final RenderObject target = key.currentContext.findRenderObject();
  expect(target.parent, const isInstanceOf<RenderViewport>());
  final SliverPhysicalParentData parentData = target.parentData;
  final Offset actual = parentData.paintOffset;
  expect(actual, ideal);
}

void main() {
  testWidgets('Sliver protocol', (WidgetTester tester) async {
    GlobalKey key1, key2, key3, key4, key5;
    await tester.pumpWidget(
      new CustomScrollView(
        slivers: <Widget>[
          new BigSliver(key: key1 = new GlobalKey()),
          new OverlappingSliver(key: key2 = new GlobalKey()),
          new OverlappingSliver(key: key3 = new GlobalKey()),
          new BigSliver(key: key4 = new GlobalKey()),
          new BigSliver(key: key5 = new GlobalKey()),
        ],
      ),
    );
    final ScrollPosition position = tester.state<ScrollableState>(find.byType(Scrollable)).position;
    final double max = RenderBigSliver.height * 3.0 + (RenderOverlappingSliver.totalHeight) * 2.0 - 600.0; // 600 is the height of the test viewport
    assert(max < 10000.0);
    expect(max, 1450.0);
    expect(position.pixels, 0.0);
    expect(position.minScrollExtent, 0.0);
    expect(position.maxScrollExtent, max);
    position.animateTo(10000.0, curve: Curves.linear, duration: const Duration(minutes: 1));
    await tester.pumpAndSettle(const Duration(milliseconds: 10));
    expect(position.pixels, max);
    expect(position.minScrollExtent, 0.0);
    expect(position.maxScrollExtent, max);
    verifyPaintPosition(key1, const Offset(0.0, 0.0));
    verifyPaintPosition(key2, const Offset(0.0, 0.0));
    verifyPaintPosition(key3, const Offset(0.0, 0.0));
    verifyPaintPosition(key4, const Offset(0.0, 0.0));
    verifyPaintPosition(key5, const Offset(0.0, 50.0));
  });
}

class RenderBigSliver extends RenderSliver {
  static const double height = 550.0;
  double get paintExtent => (height - constraints.scrollOffset).clamp(0.0, constraints.remainingPaintExtent);

  @override
  void performLayout() {
    geometry = new SliverGeometry(
      scrollExtent: height,
      paintExtent: paintExtent,
      maxPaintExtent: height,
    );
  }
}

class BigSliver extends LeafRenderObjectWidget {
  BigSliver({ Key key }) : super(key: key);
  @override
  RenderBigSliver createRenderObject(BuildContext context) {
    return new RenderBigSliver();
  }
}

class RenderOverlappingSliver extends RenderSliver {
  static const double totalHeight = 200.0;
  static const double fixedHeight = 100.0;

  double get paintExtent {
    return math.min(
             math.max(
               fixedHeight,
               totalHeight - constraints.scrollOffset,
             ),
             constraints.remainingPaintExtent,
           );
  }

  double get layoutExtent {
    return (totalHeight - constraints.scrollOffset).clamp(0.0, constraints.remainingPaintExtent);
  }

  @override
  void performLayout() {
    geometry = new SliverGeometry(
      scrollExtent: totalHeight,
      paintExtent: paintExtent,
      layoutExtent: layoutExtent,
      maxPaintExtent: totalHeight,
    );
  }
}

class OverlappingSliver extends LeafRenderObjectWidget {
  OverlappingSliver({ Key key }) : super(key: key);
  @override
  RenderOverlappingSliver createRenderObject(BuildContext context) {
    return new RenderOverlappingSliver();
  }
}
