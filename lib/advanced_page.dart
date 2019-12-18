import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'main.dart';

class AdvancedPage extends StatelessWidget {
  final Data data;
  AdvancedPage({this.data});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Constructor — second page'),
      ),
      body: Container(
        padding: EdgeInsets.all(12.0),
        alignment: Alignment.center,
        child: Column(
          children: <Widget>[
            Container(
              height: 54.0,
              padding: EdgeInsets.all(12.0),
              child: Text('Data passed to this page:',
               style: TextStyle(fontWeight: FontWeight.w700))),
            Text('Text: ${data.imageAngles}'),
            RaisedButton(
              child: Text("Back"),
                onPressed: () {
                   _modifyAngles(context); // data back to the first screen},
                }),
          ],
        ),
      ),
    );
  }
  void _modifyAngles(BuildContext context) {
    data.imageAngles = [180];
    Navigator.pop(context, data);
  }
}
