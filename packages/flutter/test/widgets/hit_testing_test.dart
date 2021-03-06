// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

void main() {
  testWidgets('toString control test', (WidgetTester tester) async {
    await tester.pumpWidget(new Center(child: new Text('Hello')));
    final HitTestResult result = tester.hitTestOnBinding(Point.origin);
    expect(result, hasOneLineDescription);
    expect(result.path.first, hasOneLineDescription);
  });
}
