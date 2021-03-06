// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'package:flutter_tools/src/version.dart';

import '../context.dart';
import '../common.dart';
import 'flutter_command_test.dart';

void main() {
  group('FlutterCommandRunner', () {
    testUsingContext('checks that Flutter installation is up-to-date', () async {
      final MockFlutterVersion version = FlutterVersion.instance;
      bool versionChecked = false;
      when(version.checkFlutterVersionFreshness()).thenAnswer((_) async {
        versionChecked = true;
      });

      await createTestCommandRunner(new DummyFlutterCommand(shouldUpdateCache: false))
          .run(<String>['dummy']);

      expect(versionChecked, isTrue);
    });
  });
}
