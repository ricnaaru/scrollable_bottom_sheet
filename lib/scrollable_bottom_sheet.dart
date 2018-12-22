import 'package:flutter/material.dart';

typedef AnimationCallback = void Function(double value);
typedef StateCallback = void Function(ScrollState state);

enum ScrollDirection { none, up, down }
enum ScrollState { full, half, minimum }

const double _kScrollTolerance = 100.0;

class ScrollableBottomSheet extends StatefulWidget {
  /// The Bottom Sheet's height when first open
  /// Must not be null
  final double halfHeight;

  /// The content inside Bottom Sheet
  /// Must not be null
  final Widget child;

  /// If this true, if user drag Bottom Sheet in between [halfHeight] and
  /// maximum height, the Bottom Sheet will be snapped according to last scroll
  /// direction user made
  ///
  /// If this false, there will be no snapping automatically
  ///
  /// See [ScrollDirection], [minimumHeight]
  final bool snapAbove;

  /// If this true, if user drag Bottom Sheet in between [halfHeight] and
  /// [minimumHeight], the Bottom Sheet will be snapped according to last scroll
  /// direction user made
  ///
  /// If this false, there will be no snapping automatically
  ///
  /// See [ScrollDirection], [minimumHeight]
  final bool snapBelow;

  /// If this true, if user drag Bottom Sheet until [minimumHeight],
  /// Navigation.pop will be called automatically
  ///
  /// If this false, there will be no popping automatically
  ///
  /// See [minimumHeight]
  final bool autoPop;

  /// If this value is not null, this value will replace 0.0 as minimum height,
  /// and there will be no automatic popping when user scroll Bottom Sheet
  /// between [halfHeight] and [minimumHeight]
  ///
  /// You can pop it manually by using [Navigator]
  ///
  /// ```
  /// Navigator.pop(context);
  /// ```
  ///
  /// See [halfHeight]
  final double minimumHeight;

  /// Scroll State callback, it triggered every time bottom sheet reach for
  /// fullHeight / [halfHeight] / [minimumHeight]
  ///
  /// See [ScrollState], [halfHeight], [minimumHeight]
  final StateCallback callback;

  /// To determine which position the bottom sheet should be in the first push
  /// between fullHeight / [halfHeight] / [minimumHeight]
  ///
  /// See [ScrollState], [halfHeight], [minimumHeight]
  final ScrollState firstScrollTo;

  const ScrollableBottomSheet(
      {Key key,
      @required this.halfHeight,
      @required this.child,
      bool snapAbove,
      bool snapBelow,
      bool autoPop,
      double minimumHeight,
      this.callback,
      ScrollState scrollTo})
      : assert(halfHeight > 0),
        assert(child != null),
        this.minimumHeight = minimumHeight ?? 0.0,
        this.snapAbove = snapAbove ?? true,
        this.snapBelow = snapBelow ?? true,
        this.autoPop = autoPop ?? true,
        this.firstScrollTo = scrollTo ?? ScrollState.half,
        super(key: key);

  @override
  State<StatefulWidget> createState() => ScrollableBottomSheetState();
}

class ScrollableBottomSheetState extends State<ScrollableBottomSheet>
    with TickerProviderStateMixin {
  double _currentHeight;
  double _minimumHeight;
  bool _requestToFull = false;
  double _fullHeight;
  ScrollController _scrollController = ScrollController();
  ScrollState _currentState;

  ScrollDirection _lastScrollDirection = ScrollDirection.none;

  @override
  void initState() {
    super.initState();
    _minimumHeight = widget.minimumHeight ?? 0.0;
  }

  @override
  Widget build(BuildContext context) {
    if (_requestToFull) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _animateTo(_fullHeight);
      });
      _requestToFull = false;
    }

    if (_currentHeight == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _currentState = widget.firstScrollTo;
        if (widget.callback != null) widget.callback(_currentState);
      });
    }

    Widget child = LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
      _fullHeight = constraints.maxHeight;

      //for the first run
      if (_currentHeight == null) {
        _currentHeight = widget.firstScrollTo == ScrollState.half
            ? widget.halfHeight
            : widget.firstScrollTo == ScrollState.full
                ? _fullHeight
                : widget.minimumHeight;
      } else if (_currentHeight < widget.minimumHeight) {
        _currentHeight = widget.minimumHeight;
      }

      _currentHeight = _currentHeight.clamp(widget.minimumHeight, _fullHeight);

      return Container(
          height: _currentHeight,
          child: GestureDetector(
              onTapDown: (TapDownDetails details) {
                if (_scrollController.hasClients) {
                  _scrollController.animateTo(_scrollController.position.pixels,
                      duration: Duration(milliseconds: 200),
                      curve: Curves.ease);
                }
              },
              onVerticalDragEnd: (DragEndDetails details) {
                double targetHeight;
                if (_currentHeight <= widget.halfHeight) {
                  if (widget.snapBelow &&
                      _scrollController.hasClients &&
                      _scrollController.position.pixels <= 0) {
                    if (_lastScrollDirection == ScrollDirection.down) {
                      targetHeight = _minimumHeight;
                    } else {
                      targetHeight = widget.halfHeight;
                    }
                  }
                } else {
                  if (widget.snapAbove &&
                      _scrollController.hasClients &&
                      _scrollController.position.pixels <= 0) {
                    if (_lastScrollDirection == ScrollDirection.down) {
                      targetHeight = widget.halfHeight;
                    } else {
                      targetHeight = _fullHeight;
                    }
                  }
                }

                if (targetHeight != null) {
                  _animateTo(targetHeight, onComplete: () {
                    if ((targetHeight == 0.0 ||
                            targetHeight == _minimumHeight) &&
                        widget.autoPop) Navigator.pop(context);
                  });
                } else {
                  if (_currentHeight >= _fullHeight &&
                      details.velocity.pixelsPerSecond.dy != 0.0) {
                    if (_scrollController.hasClients) {
                      double currentScroll = _scrollController.position.pixels;
                      double veloc = details.velocity.pixelsPerSecond.dy * 0.2;
                      double targetScroll = (currentScroll + (veloc * -1))
                          .clamp(
                              0.0,
                              _scrollController.position.maxScrollExtent +
                                  _kScrollTolerance);

                      _scrollController.animateTo(targetScroll,
                          duration: Duration(milliseconds: 1000),
                          curve: Curves.fastOutSlowIn);
                    }
                  }
                }

                _lastScrollDirection = ScrollDirection.none;

                if (_currentHeight >= _fullHeight &&
                    _currentState != ScrollState.full) {
                  _currentState = ScrollState.full;
                  if (widget.callback != null) widget.callback(_currentState);
                } else if (_currentState == ScrollState.full &&
                    _currentHeight <= widget.halfHeight) {
                  _currentState = ScrollState.half;
                  if (widget.callback != null) widget.callback(_currentState);
                } else if (_currentState == ScrollState.minimum &&
                    _currentHeight >= widget.halfHeight) {
                  _currentState = ScrollState.half;
                  if (widget.callback != null) widget.callback(_currentState);
                } else if (_currentHeight <= widget.minimumHeight &&
                    _currentState != ScrollState.minimum) {
                  _currentState = ScrollState.minimum;
                  if (widget.callback != null) widget.callback(_currentState);
                }
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

                  if (_currentHeight <= _fullHeight) {
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
                  child: Column(children: [
                    widget.child,
                    Container(
                      height: widget.minimumHeight,
                      color: Colors.transparent,
                    )
                  ]))));
    });

    return child;
  }

  /// animate current Bottom Sheet to [minimumHeight] (if specified)
  /// you can call this method from Global Key
  ///
  /// See [example/main.dart] for example
  animateToMinimum(BuildContext context, {bool willPop = false}) {
    if (widget.minimumHeight == null) return;

    _animateTo(_minimumHeight, onComplete: () {
      if (willPop) Navigator.pop(context);
    });
  }

  /// animate current Bottom Sheet to 0.0
  /// you can call this method from Global Key
  ///
  /// See [example/main.dart] for example
  animateToZero(BuildContext context, {bool willPop = false}) {
    _animateTo(0.0, onComplete: () {
      if (willPop) Navigator.pop(context);
    });
  }

  /// animate current Bottom Sheet to initialHeight
  /// you can call this method from Global Key
  ///
  /// See [example/main.dart] for example
  animateToHalf(BuildContext context) {
    _animateTo(widget.halfHeight);
  }

  /// animate current Bottom Sheet to maximum height available
  /// you can call this method from Global Key
  ///
  /// See [example/main.dart] for example
  animateToFull(BuildContext context) {
    setState(() {
      _requestToFull = true;
    });
  }

  _animateTo(double targetHeight, {VoidCallback onComplete}) {
    if (_scrollController.hasClients && _scrollController.position.pixels > 0) {
      _scrollController.animateTo(0.0,
          duration: Duration(milliseconds: 200), curve: Curves.ease);
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

    var listener = () {
      if (this.mounted) {
        setState(() {
          _currentHeight = zeroScale.value;
          if (zeroScale.value == targetHeight &&
              zeroScale.status == AnimationStatus.completed) {
            if (targetHeight == _fullHeight) {
              _currentState = ScrollState.full;
            } else if (targetHeight == widget.halfHeight) {
              _currentState = ScrollState.half;
            } else if (targetHeight == widget.minimumHeight) {
              _currentState = ScrollState.minimum;
            }

            if (onComplete != null) onComplete();
            animationController.dispose();

            if (widget.callback != null) widget.callback(_currentState);
          }
        });
      }
    };

    zeroScale.addListener(listener);
  }
}
