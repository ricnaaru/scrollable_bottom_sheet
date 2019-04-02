```
import 'package:flutter/material.dart';
import 'package:scrollable_bottom_sheet/scrollable_bottom_sheet.dart';
import 'package:scrollable_bottom_sheet/scrollable_controller.dart';
import 'package:scrollable_bottom_sheet_example/another_scrollable.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: BottomSheetDemo());
  }
}

class BottomSheetDemo extends StatefulWidget {
  @override
  _BottomSheetDemoState createState() => _BottomSheetDemoState();
}

class _BottomSheetDemoState extends State<BottomSheetDemo> with TickerProviderStateMixin {
  bool _bottomSheetActive = false;
  String _currentState = "initial";
  String _currentDirection = "up";
  final controller = ScrollableController();

  void _showMessage(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: const Text('You tapped the floating action button.'),
          actions: <Widget>[
            FlatButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('OK'))
          ],
        );
      },
    );
  }

  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('Persistent bottom sheet'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showMessage(context);
        },
        backgroundColor: Colors.redAccent,
        child: const Icon(
          Icons.add,
          semanticLabel: 'Add',
        ),
      ),
      body: Builder(
        builder: (BuildContext context) {
          return Column(children: [
            Expanded(
                child: Center(
                    child: RaisedButton(
                        onPressed: _bottomSheetActive
                            ? null
                            : () {
                                setState(() {
                                  //disable button
                                  _bottomSheetActive = true;
                                });
                                _showBottomSheet(context);
                              },
                        child: const Text('Show bottom sheet')))),
            Expanded(
                child: Center(
                    child: RaisedButton(
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => AnotherScrollable()));
                        },
                        child: const Text('Show bottom sheet')))),
          ]);
        },
      ),
    );
  }

  Widget _bottomSheetBuilder(BuildContext context) {
    final ThemeData themeData = Theme.of(context);

    return Stack(children: [
      ScrollableBottomSheet(
        controller: controller,
        halfHeight: 250.0,
        minimumHeight: 50.0,
        autoPop: false,
        scrollTo: ScrollState.minimum,
        snapAbove: false,
        snapBelow: false,
        callback: (state) {
          if (state == ScrollState.minimum) {
            _currentState = "minimum";
            _currentDirection = "up";
          } else if (state == ScrollState.half) {
            if (_currentState == "minimum") {
              _currentDirection = "up";
            } else {
              _currentDirection = "down";
            }
            _currentState = "half";
          } else {
            _currentState = "full";
            _currentDirection = "down";
          }
        },
        child: Container(
            color: Colors.greenAccent,
            margin: EdgeInsets.only(bottom: 50.0),
            child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(children: [
                  InkWell(
                    child: Container(color: Colors.red, height: 57.0),
                    onTap: () {
                      controller.animateToZero(context, willPop: true);
                    },
                  ),
                  Text('This is a Material persistent bottom sheet. Drag downwards to dismiss it.',
                      textAlign: TextAlign.center, style: TextStyle(color: themeData.accentColor, fontSize: 24.0)),
                  Column(
                      children: List.generate(100, (index) {
                    return Text("Text $index");
                  }))
                ]))),
      ),
      Positioned(
          bottom: 0.0,
          left: 0.0,
          right: 0.0,
          height: 50.0,
          child: Material(
            elevation: 15.0,
            child: IconButton(
                icon: Icon(Icons.location_on),
                onPressed: () {
                  if (_currentState == "half") {
                    if (_currentDirection == "up") {
                      controller.animateToFull(context);
                    } else {
                      controller.animateToMinimum(context);
                    }
                  } else {
                    controller.animateToHalf(context);
                  }
                }),
          ))
    ]);
  }

  _showBottomSheet(BuildContext context) {
    showBottomSheet<void>(context: context, builder: _bottomSheetBuilder).closed.whenComplete(() {
      if (mounted) {
        setState(() {
          // re-enable the button
          _bottomSheetActive = false;
        });
      }
    });
  }
}

```