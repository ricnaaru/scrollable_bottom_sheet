import 'package:flutter/material.dart';

typedef AnimationCallback = void Function(double value);

enum ScrollDirection { none, up, down }

class ScrollableBottomSheet extends StatefulWidget {
  /// The Bottom Sheet's height when first open
  /// Must not be null
  final double initialHeight;

  /// The content inside Bottom Sheet
  /// Must not be null
  final Widget child;

  /// If this true, if user drag Bottom Sheet in between [initialHeight] and
  /// maximum height, the Bottom Sheet will be snapped according to last scroll
  /// direction user made
  ///
  /// If this false, there will be no snapping automatically
  ///
  /// Note : this will only affect between [initialHeight] and maximum height
  ///        between 0.0 pixel (or minimumHeight) and initialHeight will
  ///        always be snapped according to last scroll direction
  ///
  /// See [ScrollDirection], [minimumHeight]
  final bool snapAbove;

  /// If this value is not null, this value will replace 0.0 as minimum height,
  /// and there will be no automatic popping when user scroll Bottom Sheet
  /// between [initialHeight] and [minimumHeight]
  ///
  /// You can pop it manually by using [Navigator]
  ///
  /// ```
  /// Navigator.pop(context);
  /// ```
  ///
  /// See [initialHeight]
  final double minimumHeight;

  const ScrollableBottomSheet(
      {Key key,
      @required this.initialHeight,
      @required this.child,
      bool snapAbove,
      this.minimumHeight})
      : assert(initialHeight > 0),
        assert(child != null),
        assert(minimumHeight == null || minimumHeight >= 0),
        this.snapAbove = snapAbove ?? true,
        super(key: key);

  @override
  State<StatefulWidget> createState() => ScrollableBottomSheetState();
}

class ScrollableBottomSheetState extends State<ScrollableBottomSheet>
    with TickerProviderStateMixin {
  double _currentHeight;
  double _minimumHeight;
  bool _autoPop = true;
  bool _requestToFull = false;
  double _fullHeight;
  VoidCallback _fullCallback;
  ScrollController _scrollController = ScrollController();

  ScrollDirection _lastScrollDirection = ScrollDirection.none;

  @override
  void initState() {
    super.initState();
    _currentHeight = widget.initialHeight;
    _minimumHeight = widget.minimumHeight ?? 0.0;
    _autoPop = widget.minimumHeight == null;
  }

  @override
  Widget build(BuildContext context) {
    _scrollController = ScrollController();

    if (_requestToFull) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _animateTo(_fullHeight, () {
          _fullHeight = null;
          _requestToFull = false;
          if (_fullCallback != null) _fullCallback();
          _fullCallback = null;
        });
      });
    }

    Widget child = LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
      double _maxHeight = constraints.maxHeight;

      if (_requestToFull) _fullHeight = _maxHeight;
      if (_currentHeight < 0) _currentHeight = 0;

      return Container(
          height: _currentHeight,
          child: GestureDetector(
              onVerticalDragEnd: (DragEndDetails details) {
                double targetHeight;
                if (_currentHeight <= widget.initialHeight) {
                  if (_lastScrollDirection == ScrollDirection.down) {
                    targetHeight = _minimumHeight;
                  } else {
                    targetHeight = widget.initialHeight;
                  }
                } else {
                  if (widget.snapAbove &&
                      _scrollController.hasClients &&
                      _scrollController.position.pixels <= 0) {
                    if (_lastScrollDirection == ScrollDirection.down) {
                      targetHeight = widget.initialHeight;
                    } else {
                      targetHeight = _maxHeight;
                    }
                  }
                }

                if (targetHeight != null) {
                  _animateTo(targetHeight, () {
                    if ((targetHeight == 0.0 ||
                            targetHeight == _minimumHeight) &&
                        _autoPop) Navigator.pop(context);
                  });
                }

                _lastScrollDirection = ScrollDirection.none;
              },
              onVerticalDragUpdate: (DragUpdateDetails details) {
                if (details.primaryDelta > 0) {
                  // scroll downward
                  _lastScrollDirection = ScrollDirection.down;

                  if (_scrollController.offset > 0.0) {
                    _scrollController.jumpTo(
                        _scrollController.offset + details.primaryDelta * -1);
                  } else {
                    if (_currentHeight > 0.0) {
                      if (this.mounted) {
                        setState(() {
                          _currentHeight += details.primaryDelta * -1;
                        });
                      }
                    }
                  }
                } else if (details.primaryDelta < 0) {
                  // scroll upward
                  _lastScrollDirection = ScrollDirection.up;

                  if (_currentHeight <= _maxHeight) {
                    if (this.mounted) {
                      setState(() {
                        _currentHeight += details.primaryDelta * -1;
                      });
                    }
                  } else {
                    _scrollController.jumpTo(
                        _scrollController.offset + details.primaryDelta * -1);
                  }
                }
              },
              child: SingleChildScrollView(
                  controller: _scrollController,
                  physics: NeverScrollableScrollPhysics(),
                  child: widget.child)));
    });

    return child;
  }

  /// animate current Bottom Sheet to [minimumHeight] (if specified)
  /// you can call this method from Global Key
  ///
  /// See [example/main.dart] for example
  animateToMinimum(BuildContext context,
      {bool willPop = false, VoidCallback callback}) {
    if (widget.minimumHeight == null) return;

    _animateTo(_minimumHeight, () {
      if (willPop) Navigator.pop(context);
      if (callback != null) callback();
    });
  }

  /// animate current Bottom Sheet to 0.0
  /// you can call this method from Global Key
  ///
  /// See [example/main.dart] for example
  animateToZero(BuildContext context,
      {bool willPop = false, VoidCallback callback}) {
    _animateTo(0.0, () {
      if (willPop) Navigator.pop(context);
      if (callback != null) callback();
    });
  }

  /// animate current Bottom Sheet to maximum height available
  /// you can call this method from Global Key
  ///
  /// See [example/main.dart] for example
  animateToFull(BuildContext context, {VoidCallback callback}) {
    setState(() {
      _requestToFull = true;
      _fullCallback = callback;
    });
  }

  _animateTo(double targetHeight, VoidCallback animationComplete) {
    if (_scrollController.hasClients && _scrollController.position.pixels > 0) {
      _scrollController.animateTo(0.0, duration: Duration(milliseconds: 200), curve: Curves.ease);
    }

    AnimationController animationController = AnimationController(
        duration: const Duration(milliseconds: 200), vsync: this);

    var animation = CurvedAnimation(
      parent: animationController,
      curve: Interval(
        0.0,
        1.0,
        curve: Curves.ease,
      ),
    );

    Animation<double> zeroScale =
        Tween<double>(begin: _currentHeight, end: targetHeight)
            .animate(animation);

    animationController.forward();

    zeroScale.addListener(() {
      if (this.mounted) {
        setState(() {
          _currentHeight = zeroScale.value;
          if (zeroScale.value == targetHeight) {
            animationComplete();
          }
        });
      }
    });
  }
}
