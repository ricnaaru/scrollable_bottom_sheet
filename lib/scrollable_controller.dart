import 'package:flutter/material.dart';

abstract class ScrollableInterface {
  //re-set minimum height to make [ScrollableBottomSheetByContent] possible
  void setMinimumHeight(double newMinimumHeight);

  //re-set half height to make [ScrollableBottomSheetByContent] possible
  void setHalfHeight(double newHalfHeight);

  /// animate current Bottom Sheet to [minimumHeight] (if specified)
  /// you can call this method from Global Key
  ///
  /// See [example/main.dart] for example
  void animateToMinimum(BuildContext context, {bool willPop = false});

  /// animate current Bottom Sheet to 0.0
  /// you can call this method from Global Key
  ///
  /// See [example/main.dart] for example
  void animateToZero(BuildContext context, {bool willPop = false});

  /// animate current Bottom Sheet to initialHeight
  /// you can call this method from Global Key
  ///
  /// See [example/main.dart] for example
  void animateToHalf(BuildContext context);

  /// animate current Bottom Sheet to maximum height available
  /// you can call this method from Global Key
  ///
  /// See [example/main.dart] for example
  void animateToFull(BuildContext context);
}

class ScrollableController {
  ScrollableInterface _interface;

  set interface(ScrollableInterface value) {
    _interface = value;
  }

  //re-set minimum height to make [ScrollableBottomSheetByContent] possible
  void setMinimumHeight(double newMinimumHeight) {
    if (_interface != null) _interface.setMinimumHeight(newMinimumHeight);
  }

  //re-set half height to make [ScrollableBottomSheetByContent] possible
  void setHalfHeight(double newHalfHeight) {
    if (_interface != null) _interface.setHalfHeight(newHalfHeight);
  }

  /// animate current Bottom Sheet to [minimumHeight] (if specified)
  /// you can call this method from Global Key
  ///
  /// See [example/main.dart] for example
  void animateToMinimum(BuildContext context, {bool willPop = false}) {
    if (_interface != null) _interface.animateToMinimum(context, willPop: willPop);
  }

  /// animate current Bottom Sheet to 0.0
  /// you can call this method from Global Key
  ///
  /// See [example/main.dart] for example
  void animateToZero(BuildContext context, {bool willPop = false}) {
    if (_interface != null) _interface.animateToZero(context, willPop: willPop);
  }

  /// animate current Bottom Sheet to initialHeight
  /// you can call this method from Global Key
  ///
  /// See [example/main.dart] for example
  void animateToHalf(BuildContext context) {
    if (_interface != null) _interface.animateToHalf(context);
  }

  /// animate current Bottom Sheet to maximum height available
  /// you can call this method from Global Key
  ///
  /// See [example/main.dart] for example
  void animateToFull(BuildContext context) {
    if (_interface != null) _interface.animateToFull(context);
  }
}