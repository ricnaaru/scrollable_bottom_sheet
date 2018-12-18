```
import 'package:flutter/material.dart';
import 'package:scrollable_bottom_sheet/scrollable_bottom_sheet.dart';

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

class _BottomSheetDemoState extends State<BottomSheetDemo> {
  bool _bottomSheetActive = false;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            final ThemeData themeData = Theme.of(context);
            return Center(
                child: RaisedButton(
                    onPressed: _bottomSheetActive
                        ? null
                        : () {
                            setState(() {
                              //disable button
                              _bottomSheetActive = true;
                            });
                            showBottomSheet<void>(
                                context: context,
                                builder: (BuildContext context) {
                                  final key = new GlobalKey<
                                      ScrollableBottomSheetState>();
                                  return ScrollableBottomSheet(
                                    key: key,
                                    initialHeight: 250.0,
                                    child: Container(
                                        color: Colors.greenAccent,
                                        child: Padding(
                                            padding: const EdgeInsets.all(32.0),
                                            child: Column(children: [
                                              InkWell(
                                                child: Container(
                                                    color: Colors.red,
                                                    height: 57.0),
                                                onTap: () {
                                                  key.currentState
                                                      .animateToZero(context,
                                                          willPop: true,
                                                          callback: () {
                                                    print("im finished!");
                                                  });
                                                },
                                              ),
                                              Text(
                                                  'This is a Material persistent bottom sheet. Drag downwards to dismiss it.',
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                      color:
                                                          themeData.accentColor,
                                                      fontSize: 24.0)),
                                              Column(
                                                  children: List.generate(100,
                                                      (index) {
                                                return Text("Text $index");
                                              }))
                                            ]))),
                                  );
                                }).closed.whenComplete(() {
                              if (mounted) {
                                setState(() {
                                  // re-enable the button
                                  _bottomSheetActive = false;
                                });
                              }
                            });
                          },
                    child: const Text('Show bottom sheet')));
          },
        ));
  }
}
```