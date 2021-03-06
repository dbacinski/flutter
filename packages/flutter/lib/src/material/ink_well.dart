// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'debug.dart';
import 'ink_highlight.dart';
import 'ink_splash.dart';
import 'material.dart';
import 'theme.dart';

/// An area of a [Material] that responds to touch. Has a configurable shape and
/// can be configured to clip splashes that extend outside its bounds or not.
///
/// For a variant of this widget that is specialized for rectangular areas that
/// always clip splashes, see [InkWell].
///
/// Must have an ancestor [Material] widget in which to cause ink reactions.
///
/// If a Widget uses this class directly, it should include the following line
/// at the top of its [build] function to call [debugCheckHasMaterial]:
///
///     assert(debugCheckHasMaterial(context));
class InkResponse extends StatefulWidget {
  /// Creates an area of a [Material] that responds to touch.
  ///
  /// Must have an ancestor [Material] widget in which to cause ink reactions.
  InkResponse({
    Key key,
    this.child,
    this.onTap,
    this.onDoubleTap,
    this.onLongPress,
    this.onHighlightChanged,
    this.containedInkWell: false,
    this.highlightShape: BoxShape.circle,
    this.radius,
    this.borderRadius: BorderRadius.zero,
    this.highlightColor,
    this.splashColor,
  }) : super(key: key);

  /// The widget below this widget in the tree.
  final Widget child;

  /// Called when the user taps this part of the material
  final GestureTapCallback onTap;

  /// Called when the user double taps this part of the material.
  final GestureTapCallback onDoubleTap;

  /// Called when the user long-presses on this part of the material.
  final GestureLongPressCallback onLongPress;

  /// Called when this part of the material either becomes highlighted or stops behing highlighted.
  ///
  /// The value passed to the callback is true if this part of the material has
  /// become highlighted and false if this part of the material has stopped
  /// being highlighted.
  final ValueChanged<bool> onHighlightChanged;

  /// Whether this ink response should be clipped its bounds.
  final bool containedInkWell;

  /// The shape (e.g., circle, rectangle) to use for the highlight drawn around this part of the material.
  final BoxShape highlightShape;

  /// The radius of the ink splash.
  final double radius;

  /// The clipping radius of the containing rect.
  final BorderRadius borderRadius;

  /// The highlight color of the ink response. If this property is null then the
  /// highlight color of the theme will be used.
  final Color highlightColor;

  /// The splash color of the ink response. If this property is null then the
  /// splash color of the theme will be used.
  final Color splashColor;

  /// The rectangle to use for the highlight effect and for clipping
  /// the splash effects if [containedInkWell] is true.
  ///
  /// This method is intended to be overridden by descendants that
  /// specialize [InkResponse] for unusual cases. For example,
  /// [TableRowInkWell] implements this method to return the rectangle
  /// corresponding to the row that the widget is in.
  ///
  /// The default behavior returns null, which is equivalent to
  /// returning the referenceBox argument's bounding box (though
  /// slightly more efficient).
  RectCallback getRectCallback(RenderBox referenceBox) => null;

  /// Asserts that the given context satisfies the prerequisites for
  /// this class.
  ///
  /// This method is intended to be overridden by descendants that
  /// specialize [InkResponse] for unusual cases. For example,
  /// [TableRowInkWell] implements this method to verify that the widget is
  /// in a table.
  @mustCallSuper
  bool debugCheckContext(BuildContext context) {
    assert(debugCheckHasMaterial(context));
    return true;
  }

  @override
  _InkResponseState<InkResponse> createState() => new _InkResponseState<InkResponse>();
}

class _InkResponseState<T extends InkResponse> extends State<T> {

  Set<InkSplash> _splashes;
  InkSplash _currentSplash;
  InkHighlight _lastHighlight;

  void updateHighlight(bool value) {
    if (value == (_lastHighlight != null && _lastHighlight.active))
      return;
    if (value) {
      if (_lastHighlight == null) {
        final RenderBox referenceBox = context.findRenderObject();
        _lastHighlight = new InkHighlight(
          controller: Material.of(context),
          referenceBox: referenceBox,
          color: config.highlightColor ?? Theme.of(context).highlightColor,
          shape: config.highlightShape,
          borderRadius: config.borderRadius,
          rectCallback: config.getRectCallback(referenceBox),
          onRemoved: () {
            assert(_lastHighlight != null);
            _lastHighlight = null;
          },
        );
      } else {
        _lastHighlight.activate();
      }
    } else {
      _lastHighlight.deactivate();
    }
    assert(value == (_lastHighlight != null && _lastHighlight.active));
    if (config.onHighlightChanged != null)
      config.onHighlightChanged(value);
  }

  void _handleTapDown(TapDownDetails details) {
    final RenderBox referenceBox = context.findRenderObject();
    final RectCallback rectCallback = config.getRectCallback(referenceBox);
    InkSplash splash;
    splash = new InkSplash(
      controller: Material.of(context),
      referenceBox: referenceBox,
      position: referenceBox.globalToLocal(details.globalPosition),
      color: config.splashColor ?? Theme.of(context).splashColor,
      containedInkWell: config.containedInkWell,
      rectCallback: config.containedInkWell ? rectCallback : null,
      radius: config.radius,
      borderRadius: config.borderRadius ?? BorderRadius.zero,
      onRemoved: () {
        if (_splashes != null) {
          assert(_splashes.contains(splash));
          _splashes.remove(splash);
          if (_currentSplash == splash)
            _currentSplash = null;
        } // else we're probably in deactivate()
      }
    );
    _splashes ??= new HashSet<InkSplash>();
    _splashes.add(splash);
    _currentSplash = splash;
    updateHighlight(true);
  }

  void _handleTap() {
    _currentSplash?.confirm();
    _currentSplash = null;
    updateHighlight(false);
    if (config.onTap != null)
      config.onTap();
  }

  void _handleTapCancel() {
    _currentSplash?.cancel();
    _currentSplash = null;
    updateHighlight(false);
  }

  void _handleDoubleTap() {
    _currentSplash?.confirm();
    _currentSplash = null;
    if (config.onDoubleTap != null)
      config.onDoubleTap();
  }

  void _handleLongPress() {
    _currentSplash?.confirm();
    _currentSplash = null;
    if (config.onLongPress != null)
      config.onLongPress();
  }

  @override
  void deactivate() {
    if (_splashes != null) {
      final Set<InkSplash> splashes = _splashes;
      _splashes = null;
      for (InkSplash splash in splashes)
        splash.dispose();
      _currentSplash = null;
    }
    assert(_currentSplash == null);
    _lastHighlight?.dispose();
    _lastHighlight = null;
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    assert(config.debugCheckContext(context));
    final ThemeData themeData = Theme.of(context);
    _lastHighlight?.color = config.highlightColor ?? themeData.highlightColor;
    _currentSplash?.color = config.splashColor ?? themeData.splashColor;
    final bool enabled = config.onTap != null || config.onDoubleTap != null || config.onLongPress != null;
    return new GestureDetector(
      onTapDown: enabled ? _handleTapDown : null,
      onTap: enabled ? _handleTap : null,
      onTapCancel: enabled ? _handleTapCancel : null,
      onDoubleTap: config.onDoubleTap != null ? _handleDoubleTap : null,
      onLongPress: config.onLongPress != null ? _handleLongPress : null,
      behavior: HitTestBehavior.opaque,
      child: config.child
    );
  }

}

/// A rectangular area of a [Material] that responds to touch.
///
/// Must have an ancestor [Material] widget in which to cause ink reactions.
///
/// If a Widget uses this class directly, it should include the following line
/// at the top of its [build] function to call [debugCheckHasMaterial]:
///
///     assert(debugCheckHasMaterial(context));
class InkWell extends InkResponse {
  /// Creates an ink well.
  ///
  /// Must have an ancestor [Material] widget in which to cause ink reactions.
  InkWell({
    Key key,
    Widget child,
    GestureTapCallback onTap,
    GestureTapCallback onDoubleTap,
    GestureLongPressCallback onLongPress,
    ValueChanged<bool> onHighlightChanged,
    Color highlightColor,
    Color splashColor,
    BorderRadius borderRadius,
  }) : super(
    key: key,
    child: child,
    onTap: onTap,
    onDoubleTap: onDoubleTap,
    onLongPress: onLongPress,
    onHighlightChanged: onHighlightChanged,
    containedInkWell: true,
    highlightShape: BoxShape.rectangle,
    highlightColor: highlightColor,
    splashColor: splashColor,
    borderRadius: borderRadius,
  );
}
