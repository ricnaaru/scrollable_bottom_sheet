import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:scrollable_bottom_sheet/scrollable_controller.dart';

typedef AnimationCallback = void Function(double value);
typedef StateCallback = void Function(ScrollState state);

enum ScrollDirection { none, up, down }
enum ScrollState { full, half, minimum }

class ScrollableBottomSheetByContent extends StatefulWidget {
  final Widget header;
  final Widget content;
  final ScrollableController controller;
  final StateCallback? callback;
  final bool snapAbove;
  final bool snapBelow;
  final bool autoPop;
  final ScrollState scrollTo;

  ScrollableBottomSheetByContent(
    this.header,
    this.content, {
    ScrollableController? controller,
    bool? snapAbove,
    bool? snapBelow,
    bool? autoPop,
    this.callback,
    ScrollState? scrollTo,
  })  : this.controller = controller ?? ScrollableController(),
        this.snapAbove = snapAbove ?? true,
        this.snapBelow = snapBelow ?? true,
        this.autoPop = autoPop ?? true,
        this.scrollTo = scrollTo ?? ScrollState.minimum;

  @override
  State<StatefulWidget> createState() => _ScrollableBottomSheetByContentState();
}

class _ScrollableBottomSheetByContentState
    extends State<ScrollableBottomSheetByContent> {
  late BuildContext _headerContext;
  late BuildContext _contentContext;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    WidgetsBinding.instance?.addPostFrameCallback((_) {
      final headerHeight = _headerContext.size?.height;
      final contentHeight = _contentContext.size?.height;

      if (headerHeight == null || contentHeight == null) return;

      widget.controller.setMinimumHeight(headerHeight);
      widget.controller.setHalfHeight(headerHeight + contentHeight);

      if (widget.scrollTo == ScrollState.minimum) {
        widget.controller.animateToMinimum(context);
      } else if (widget.scrollTo == ScrollState.half) {
        widget.controller.animateToHalf(context);
      } else if (widget.scrollTo == ScrollState.full) {
        widget.controller.animateToFull(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ScrollableBottomSheet(
      controller: widget.controller,
      snapAbove: widget.snapAbove,
      snapBelow: widget.snapBelow,
      autoPop: widget.autoPop,
      callback: widget.callback,
      child: Column(
        children: [
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
        ],
      ),
      halfHeight: 0.0,
    );
  }
}

class ScrollableBottomSheet extends StatefulWidget {
  /// We change from GlobalKey system to controller system
  /// Whenever parent wants to animate bottom sheet to certain position
  /// for example minimum / half / full, it is executed by this controller
  ///
  /// See [ScrollableInterface]
  final ScrollableController controller;

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
  final StateCallback? callback;

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

  ScrollableBottomSheet({
    ScrollableController? controller,
    required this.halfHeight,
    required this.child,
    bool? snapAbove,
    bool? snapBelow,
    bool? autoPop,
    double? minimumHeight,
    this.callback,
    ScrollState? scrollTo,
    bool? mayExceedChildHeight,
  })  : this.controller = controller ?? ScrollableController(),
        this.minimumHeight = minimumHeight ?? 0.0,
        this.snapAbove = snapAbove ?? true,
        this.snapBelow = snapBelow ?? true,
        this.autoPop = autoPop ?? true,
        this.firstScrollTo = scrollTo ?? ScrollState.half,
        this.mayExceedChildHeight = mayExceedChildHeight ?? false;

  @override
  State<StatefulWidget> createState() => _ScrollableBottomSheetState();
}

class _ScrollableBottomSheetState extends State<ScrollableBottomSheet>
    with TickerProviderStateMixin
    implements ScrollableInterface {
  double _currentHeight = -1.0;
  late double _minimumHeight;
  late double _halfHeight;
  late double _fullHeight;
  bool _requestToFull = false;
  double? _childHeight;
  ScrollController _scrollController = ScrollController();
  late ScrollState _currentState;
  late BuildContext _headerContext;
  AnimationController? _activeAnimController;

  ScrollDirection _lastScrollDirection = ScrollDirection.none;

  @override
  void initState() {
    super.initState();
    widget.controller.interface = this;

    _minimumHeight = widget.minimumHeight;
    _halfHeight = widget.halfHeight;

    WidgetsBinding.instance?.addPostFrameCallback((_) {
      _childHeight = _headerContext.size?.height;
      _currentState = widget.firstScrollTo;
      widget.callback?.call(_currentState);
    });
  }

  @override
  void dispose() {
    _activeAnimController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_requestToFull) {
      WidgetsBinding.instance?.addPostFrameCallback((_) {
        _animateTo(_fullHeight);
      });
      _requestToFull = false;
    }

    Widget child = LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        if (widget.mayExceedChildHeight) {
          _fullHeight = constraints.maxHeight;
        } else {
          _fullHeight = math.min(
            _childHeight ?? _minimumHeight,
            constraints.maxHeight,
          );
        }

        //for the first run
        if (_currentHeight == -1.0) {
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
              double? targetHeight;

              if (_scrollController.position.pixels < 0.0)
                _scrollController.position.animateTo(
                  0.0,
                  duration: Duration(milliseconds: 200),
                  curve: Curves.ease,
                );

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
                  if (targetHeight == 0.0 || targetHeight == _minimumHeight) {
                    if (widget.autoPop) Navigator.pop(context);
                  }
                });
              }

              _lastScrollDirection = ScrollDirection.none;

              if (_currentHeight >= _fullHeight &&
                  _currentState != ScrollState.full) {
                _currentState = ScrollState.full;
                widget.callback?.call(_currentState);
              } else if (_currentState == ScrollState.full &&
                  _currentHeight < _halfHeight) {
                _currentState = ScrollState.half;
                widget.callback?.call(_currentState);
              } else if (_currentState == ScrollState.minimum &&
                  _currentHeight >= _halfHeight) {
                _currentState = ScrollState.half;
                widget.callback?.call(_currentState);
              } else if (_currentHeight <= widget.minimumHeight &&
                  _currentState != ScrollState.minimum) {
                _currentState = ScrollState.minimum;
                widget.callback?.call(_currentState);
              }
              if (_currentHeight >= _fullHeight) {
                _drag?.end(details);
              } else {
                _drag?.cancel();
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
              final primaryDelta = details.primaryDelta;

              if (primaryDelta == null) return;

              if (primaryDelta > 0) {
                // scroll downward
                _lastScrollDirection = ScrollDirection.down;

                if (_scrollController.offset <= 0.0) {
                  if (_currentHeight > 0.0) {
                    if (this.mounted) {
                      setState(() {
                        _currentHeight += primaryDelta * -1;
                      });
                    }
                  }
                }
              } else if (primaryDelta < 0) {
                // scroll upward
                _lastScrollDirection = ScrollDirection.up;

                if (_currentHeight < _fullHeight) {
                  if (this.mounted) {
                    setState(() {
                      _currentHeight += primaryDelta * -1;
                    });
                  }
                }
              }

              if (_currentHeight >= _fullHeight) {
                DragUpdateDetails d = details;
                final primaryDelta = d.primaryDelta;

                if (primaryDelta == null) return;

                if (_scrollController.offset + -primaryDelta < 0.0) {
                  Offset newGlobalPosition = Offset(
                    details.globalPosition.dx,
                    details.globalPosition.dy +
                        -primaryDelta +
                        _scrollController.offset,
                  );
                  Offset newDelta = Offset(
                    details.delta.dx,
                    _scrollController.offset,
                  );

                  d = DragUpdateDetails(
                    delta: newDelta,
                    primaryDelta: _scrollController.offset,
                    globalPosition: newGlobalPosition,
                    sourceTimeStamp: details.sourceTimeStamp,
                  );
                }

                _drag?.update(d);
              }
            },
            onVerticalDragStart: (DragStartDetails details) {
              if (_scrollController.position.maxScrollExtent > 0.0) {
                _drag = _scrollController.position.drag(details, _disposeDrag);
              }
            },
            child: SingleChildScrollView(
              controller: _scrollController,
              physics: NeverScrollableScrollPhysics(),
              child: Builder(
                builder: (BuildContext c) {
                  _headerContext = c;
                  return widget.child;
                },
              ),
            ),
          ),
        );
      },
    );

    return child;
  }

  Drag? _drag;
  ScrollHoldController? _hold;

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
  @override
  void animateToMinimum(BuildContext context, {bool willPop = false}) {
    _animateTo(_minimumHeight, onComplete: () {
      if (willPop) Navigator.pop(context);
    });
  }

  /// animate current Bottom Sheet to 0.0
  /// you can call this method from Global Key
  ///
  /// See [example/main.dart] for example
  @override
  void animateToZero(BuildContext context, {bool willPop = false}) {
    _animateTo(0.0, onComplete: () {
      if (willPop) Navigator.pop(context);
    });
  }

  /// animate current Bottom Sheet to initialHeight
  /// you can call this method from Global Key
  ///
  /// See [example/main.dart] for example
  @override
  void animateToHalf(BuildContext context) {
    _animateTo(_halfHeight);
  }

  /// animate current Bottom Sheet to maximum height available
  /// you can call this method from Global Key
  ///
  /// See [example/main.dart] for example
  @override
  void animateToFull(BuildContext context) {
    setState(() {
      _requestToFull = true;
    });
  }

  _animateTo(double targetHeight, {VoidCallback? onComplete}) {
    if (!this.mounted) return;

    if (_scrollController.hasClients && _scrollController.position.pixels > 0) {
      _scrollController.animateTo(
        0.0,
        duration: Duration(milliseconds: 200),
        curve: Curves.ease,
      );
    }

    AnimationController animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _activeAnimController = animationController;

    var animation = CurvedAnimation(
      parent: animationController,
      curve: Interval(0.0, 1.0, curve: Curves.ease),
    );

    Animation<double> zeroScale = Tween<double>(
      begin: _currentHeight,
      end: targetHeight,
    ).animate(animation);

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

            onComplete?.call();
            animationController.dispose();
            _activeAnimController = null;

            widget.callback?.call(_currentState);
          }
        });
      }
    };

    zeroScale.addListener(listener);
  }

  @override
  void setHalfHeight(double newHalfHeight) {
    _halfHeight = newHalfHeight;
  }

  @override
  void setMinimumHeight(double newMinimumHeight) {
    _minimumHeight = newMinimumHeight;
  }
}
