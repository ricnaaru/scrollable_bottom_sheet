import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

typedef AnimationCallback = void Function(double value);
typedef StateCallback = void Function(ScrollState state);

enum ScrollDirection { none, up, down }
enum ScrollState { full, half, minimum }

class ScrollableBottomSheetByContent extends StatefulWidget {
  final Widget header;
  final Widget content;
  final GlobalKey<ScrollableBottomSheetState> scrollableKey;
  final StateCallback callback;
  final bool snapAbove;
  final bool snapBelow;
  final bool autoPop;
  final ScrollState scrollTo;

  ScrollableBottomSheetByContent(this.header, this.content,
      {Key key,
      bool snapAbove,
      bool snapBelow,
      bool autoPop,
      this.callback,
      ScrollState scrollTo})
      : scrollableKey = key is GlobalKey<ScrollableBottomSheetState>
            ? key
            : GlobalKey<ScrollableBottomSheetState>(),
        this.snapAbove = snapAbove ?? true,
        this.snapBelow = snapBelow ?? true,
        this.autoPop = autoPop ?? true,
        this.scrollTo = scrollTo ?? ScrollState.minimum;

  @override
  State<StatefulWidget> createState() => _ScrollableBottomSheetByContentState();
}

class _ScrollableBottomSheetByContentState
    extends State<ScrollableBottomSheetByContent> {
  BuildContext _headerContext;
  BuildContext _contentContext;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.scrollableKey.currentState.minimumHeight =
          _headerContext.size.height;
      widget.scrollableKey.currentState.halfHeight =
          _headerContext.size.height + _contentContext.size.height;
      if (widget.scrollTo == ScrollState.minimum) {
        widget.scrollableKey.currentState.animateToMinimum(context);
      } else if (widget.scrollTo == ScrollState.half) {
        widget.scrollableKey.currentState.animateToHalf(context);
      } else if (widget.scrollTo == ScrollState.full) {
        widget.scrollableKey.currentState.animateToFull(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ScrollableBottomSheet(
      key: widget.scrollableKey,
      snapAbove: widget.snapAbove,
      snapBelow: widget.snapBelow,
      autoPop: widget.autoPop,
      callback: widget.callback,
      child: Column(children: [
        Builder(
          builder: (BuildContext context) {
            _headerContext = context;
            return widget.header;
          },
        ),
        Builder(
          builder: (BuildContext context) {
            _contentContext = context;
            return widget.content;
          },
        ),
      ]),
      halfHeight: 0.0,
    );
  }
}

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

  /// If this true, fullHeight won't exceed child's height
  ///
  /// If this false, it'll always scrollable to fullscreen height
  ///
  /// See [_fullHeight]
  final bool mayExceedChildHeight;

  const ScrollableBottomSheet(
      {Key key,
      @required this.halfHeight,
      @required this.child,
      bool snapAbove,
      bool snapBelow,
      bool autoPop,
      double minimumHeight,
      this.callback,
      ScrollState scrollTo,
      bool mayExceedChildHeight})
      : assert(child != null),
        this.minimumHeight = minimumHeight ?? 0.0,
        this.snapAbove = snapAbove ?? true,
        this.snapBelow = snapBelow ?? true,
        this.autoPop = autoPop ?? true,
        this.firstScrollTo = scrollTo ?? ScrollState.half,
        this.mayExceedChildHeight = mayExceedChildHeight ?? false,
        super(key: key);

  @override
  State<StatefulWidget> createState() => ScrollableBottomSheetState();
}

class ScrollableBottomSheetState extends State<ScrollableBottomSheet>
    with TickerProviderStateMixin {
  double _currentHeight;
  double _minimumHeight;
  double _halfHeight;
  bool _requestToFull = false;
  double _fullHeight;
  double _childHeight;
  ScrollController _scrollController = ScrollController();
  ScrollState _currentState;
  BuildContext _headerContext;

  //re-set minimum height to make [ScrollableBottomSheetByContent] possible
  set minimumHeight(double newMinimumHeight) {
    _minimumHeight = newMinimumHeight;
  }

  //re-set half height to make [ScrollableBottomSheetByContent] possible
  set halfHeight(double newHalfHeight) {
    _halfHeight = newHalfHeight;
  }

  ScrollDirection _lastScrollDirection = ScrollDirection.none;

  @override
  void initState() {
    super.initState();
    _minimumHeight = widget.minimumHeight ?? 0.0;
    _halfHeight = widget.halfHeight ?? 0.0;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _childHeight = _headerContext.size.height;

      _currentState = widget.firstScrollTo;
      if (widget.callback != null) widget.callback(_currentState);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_requestToFull) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _animateTo(_fullHeight);
      });
      _requestToFull = false;
    }

    Widget child = LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
      if (widget.mayExceedChildHeight) {
        _fullHeight = constraints.maxHeight;
      } else {
        _fullHeight =
            math.min(_childHeight ?? _minimumHeight, constraints.maxHeight);
      }

      //for the first run
      if (_currentHeight == null) {
        _currentHeight = widget.firstScrollTo == ScrollState.half
            ? _halfHeight
            : widget.firstScrollTo == ScrollState.full
                ? _fullHeight
                : widget.minimumHeight;
      } else if (_currentHeight < widget.minimumHeight) {
        _currentHeight = widget.minimumHeight;
      }

      _currentHeight = _currentHeight.clamp(_minimumHeight, _fullHeight);

      return Container(
          height: _currentHeight,
          child: GestureDetector(
              onVerticalDragEnd: (DragEndDetails details) {
                double targetHeight;

                if (_scrollController.position.pixels < 0.0)
                  _scrollController.position.animateTo(0.0,
                      duration: Duration(milliseconds: 200),
                      curve: Curves.ease);

                if (_currentHeight <= _halfHeight) {
                  if (widget.snapBelow &&
                      _scrollController.hasClients &&
                      _scrollController.position.pixels <= 0) {
                    if (_lastScrollDirection == ScrollDirection.down) {
                      targetHeight = _minimumHeight;
                    } else {
                      targetHeight = _halfHeight;
                    }
                  }
                } else {
                  if (widget.snapAbove &&
                      _scrollController.hasClients &&
                      _scrollController.position.pixels <= 0) {
                    if (_lastScrollDirection == ScrollDirection.down) {
                      targetHeight = _halfHeight;
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
                }

                _lastScrollDirection = ScrollDirection.none;

                if (_currentHeight >= _fullHeight &&
                    _currentState != ScrollState.full) {
                  _currentState = ScrollState.full;
                  if (widget.callback != null) widget.callback(_currentState);
                } else if (_currentState == ScrollState.full &&
                    _currentHeight < _halfHeight) {
                  _currentState = ScrollState.half;
                  if (widget.callback != null) widget.callback(_currentState);
                } else if (_currentState == ScrollState.minimum &&
                    _currentHeight >= _halfHeight) {
                  _currentState = ScrollState.half;
                  if (widget.callback != null) widget.callback(_currentState);
                } else if (_currentHeight <= widget.minimumHeight &&
                    _currentState != ScrollState.minimum) {
                  _currentState = ScrollState.minimum;
                  if (widget.callback != null) widget.callback(_currentState);
                }
                if (_currentHeight >= _fullHeight) {
                  _drag?.end(details);
                }
              },
              onVerticalDragDown: (DragDownDetails details) {
                _hold = _scrollController.position.hold(_disposeHold);
              },
              onVerticalDragCancel: () {
                _drag?.cancel();
                _hold?.cancel();
              },
              onVerticalDragUpdate: (DragUpdateDetails details) {
                if (details.primaryDelta > 0) {
                  // scroll downward
                  _lastScrollDirection = ScrollDirection.down;

                  if (_scrollController.offset <= 0.0) {
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

                  if (_currentHeight < _fullHeight) {
                    if (this.mounted) {
                      setState(() {
                        _currentHeight += details.primaryDelta * -1;
                      });
                    }
                  }
                }

                if (_currentHeight >= _fullHeight) {
                  DragUpdateDetails d = details;

                  if (_scrollController.offset + -d.primaryDelta < 0.0) {
                    Offset newGlobalPosition = Offset(
                        details.globalPosition.dx,
                        details.globalPosition.dy +
                            -(d.primaryDelta) +
                            _scrollController.offset);
                    Offset newDelta =
                        Offset(details.delta.dx, _scrollController.offset);

                    d = DragUpdateDetails(
                        delta: newDelta,
                        primaryDelta: _scrollController.offset,
                        globalPosition: newGlobalPosition,
                        sourceTimeStamp: details.sourceTimeStamp);
                  }

                  _drag?.update(d);
                }
              },
              onVerticalDragStart: (DragStartDetails details) {
                if (_scrollController.position.maxScrollExtent > 0.0)
                  _drag =
                      _scrollController.position.drag(details, _disposeDrag);
              },
              child: SingleChildScrollView(
                  controller: _scrollController,
                  physics: NeverScrollableScrollPhysics(),
                  child: Builder(builder: (BuildContext c) {
                    _headerContext = c;

                    return widget.child;
                  }))));
    });

    return child;
  }

  Drag _drag;
  ScrollHoldController _hold;

  void _disposeDrag() {
    _drag = null;
  }

  void _disposeHold() {
    _hold = null;
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
    _animateTo(_halfHeight);
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
            } else if (targetHeight == _halfHeight) {
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
