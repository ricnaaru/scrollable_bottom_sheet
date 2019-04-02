import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:scrollable_bottom_sheet/scrollable_bottom_sheet.dart';
import 'package:scrollable_bottom_sheet/scrollable_controller.dart';

class AnotherScrollable extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _AnotherScrollableState();
}

class _AnotherScrollableState extends State<AnotherScrollable> with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  final ScrollableController controller = ScrollableController();

  @override
  void initState() {
    super.initState();
    /*
    Uncomment this if you want to put bottom sheet into Route Stack,
    so that when you press back button, this bottom sheet will be closed

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scaffoldKey.currentState.showBottomSheet<void>(_bottomSheetBuilder);
    });
    */
  }

  List<Order> orders = [];
  List<String> randomFruits = [
    "Apple",
    "Apricot",
    "Blackberry",
    "Cherry",
    "Dragonfruit",
    "Grape",
    "Honeydew",
    "Jujube",
    "Kumquat",
    "Lime",
    "Papaya",
    "Passon Fruit",
    "Peach",
    "Pineapple",
    "Plum",
    "Raspberry",
    "Tomato"
  ];

  @override
  Widget build(BuildContext context) {
    math.Random random = math.Random();

    orders = List.generate(random.nextInt(100), (index) {
      return Order(randomFruits[random.nextInt(randomFruits.length - 1)], random.nextInt(100));
    });

    return Scaffold(
      bottomSheet: _bottomSheetBuilder(context),
      //if you use this bottomSheet, bottom Sheet will not put into Route Stack,
      // so when you press back button, it will pop this page
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text("Scrollable by content"),
      ),
      body: Stack(
        children: <Widget>[
          Center(child: CircularProgressIndicator()),
          Container(
            constraints: BoxConstraints.expand(),
            // Add box decoration
            decoration: BoxDecoration(
              // Box decoration takes a gradient
              gradient: LinearGradient(
                // Where the linear gradient begins and ends
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                // Add one stop for each color. Stops should increase from 0 to 1
                stops: [0.1, 0.5, 0.7, 0.9],
                colors: [
                  Color((math.Random().nextDouble() * 0xFFFFFF).toInt() << 0).withOpacity(1.0),
                  Color((math.Random().nextDouble() * 0xFFFFFF).toInt() << 0).withOpacity(1.0),
                  Color((math.Random().nextDouble() * 0xFFFFFF).toInt() << 0).withOpacity(1.0),
                  Color((math.Random().nextDouble() * 0xFFFFFF).toInt() << 0).withOpacity(1.0)
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomSheetBuilder(BuildContext context) {
    return ScrollableBottomSheetByContent(
      _buildHeader(context),
      _buildContent(),
      autoPop: false,
      scrollTo: ScrollState.minimum,
      controller: controller,
    );
  }

  _buildHeader(BuildContext context) {
    return Container(
        width: double.infinity,
        padding: EdgeInsets.all(16.0),
        color: Theme.of(context).primaryColor,
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(child: Icon(Icons.shopping_cart, color: Colors.white), margin: EdgeInsets.all(8.0)),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text("You've got order", style: Theme.of(context).primaryTextTheme.title),
            Text("Swipe up for details", style: Theme.of(context).primaryTextTheme.body1)
          ])
        ]));
  }

  _buildContent() {
    int counter = 0;

    return Column(
        children: orders.map((order) {
      List<Widget> children = [];

      children.add(ListTile(title: Text(order.name), subtitle: Text("Qty: ${order.qty} pcs")));

      if (counter < orders.length) {
        children.add(Container(color: Colors.black38, height: 0.5));
      }
      return Column(children: children);
    }).toList());
  }
}

class Order {
  final String name;
  final int qty;

  Order(this.name, this.qty);
}
