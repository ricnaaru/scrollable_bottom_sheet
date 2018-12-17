import 'package:flutter/material.dart';

enum ScrollDirection { none, up, down }

class ScrollableBottomSheet extends StatefulWidget {
  final double initialHeight;
  final Widget child;
  final bool snapAbove;

  ScrollableBottomSheet(
      {@required this.initialHeight, @required this.child, bool snapAbove})
      : this.snapAbove = snapAbove ?? false;

  @override
  State<StatefulWidget> createState() => _ScrollableBottomSheetState();
}
https://github.com/ricnaaru/scrollable_bottom_sheet.git
class _ScrollableBottomSheetState extends State<ScrollableBottomSheet>
    with TickerProviderStateMixin {
  double _currentHeight;
  ScrollController scrollController = ScrollController();
  Animation<double> scale;

  ScrollDirection lastScrollDirection = ScrollDirection.none;

  @override
  void initState() {
    super.initState();
    _currentHeight = widget.initialHeight;
  }

  @override
  Widget build(BuildContext context) {
    scrollController = ScrollController();

    Widget child = LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
      double _maxHeight = constraints.maxHeight;
      if (_currentHeight < 0) _currentHeight = 0;

      return Container(
          height: _currentHeight,
          child: GestureDetector(
              onVerticalDragEnd: (DragEndDetails details) {
                double targetHeight;
                if (_currentHeight <= widget.initialHeight) {
                  if (lastScrollDirection == ScrollDirection.down) {
                    targetHeight = 0.0;
                  } else {
                    targetHeight = widget.initialHeight;
                  }
                } else {
                  if (widget.snapAbove && scrollController.hasClients &&
                      scrollController.position.pixels <= 0) {
                    if (lastScrollDirection == ScrollDirection.down) {
                      targetHeight = widget.initialHeight;
                    } else {
                      targetHeight = _maxHeight;
                    }
                  }
                }
                if (targetHeight != null) {
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

                  scale =
                      Tween<double>(begin: _currentHeight, end: targetHeight)
                          .animate(animation);

                  animationController.forward();

                  scale.addListener(() {
                    setState(() {
                      _currentHeight = scale.value;
                      if (scale.value == 0.0) Navigator.pop(context);
                    });
                  });
                }

                lastScrollDirection = ScrollDirection.none;
              },
              onVerticalDragUpdate: (DragUpdateDetails details) {
                if (details.primaryDelta > 0) {
                  // downward
                  lastScrollDirection = ScrollDirection.down;
                  if (scrollController.offset > 0.0) {
                    scrollController.jumpTo(
                        scrollController.offset + details.primaryDelta * -1);
                  } else {
                    if (_currentHeight > 0.0) {
                      setState(() {
                        _currentHeight += details.primaryDelta * -1;
                      });
                    }
                  }
                } else if (details.primaryDelta < 0) {
                  lastScrollDirection = ScrollDirection.up;

                  // upward
                  if (_currentHeight <= _maxHeight) {
                    setState(() {
                      _currentHeight += details.primaryDelta * -1;
                    });
                  } else {
                    scrollController.jumpTo(
                        scrollController.offset + details.primaryDelta * -1);
                  }
                }
              },
              child: SingleChildScrollView(
                  controller: scrollController,
                  physics: NeverScrollableScrollPhysics(),
                  child: widget.child)));
    });

    return child;
  }
}
