import 'dart:math';

import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:developer' as developer;

import 'package:multi_image_picker/multi_image_picker.dart';

void main() => runApp(new MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => new _MyAppState();
}

class _MyAppState extends State<MyApp> {
  List<Asset> images = List<Asset>();
  Map<Asset, int> imagesAnglesMap = Map();
  String _error = 'No Error Dectected';
  int degrees = 0;

  @override
  void initState() {
    super.initState();
  }

  Future goToDetailsPage(BuildContext context, Asset asset) async {
    // String path = await asset.filePath;
    // developer.log(path, name: 'my.app.main');
    setState(() {
      degrees = (degrees + 90) % 360;
      developer.log(degrees.toString(), name: 'my.app.main');
    });
  }

  Widget buildGridView() {
    return GridView.count(
      crossAxisCount: 3,
      mainAxisSpacing: 3,
      children: List.generate(images.length, (index) {
        Asset asset = images[index];
        return GestureDetector(
          child: GridTile(
              child: Transform.rotate(
                  angle: degrees * pi / 180,
                  // @TODO Use RotationTransition animation for eye candy
                  child: AssetThumb(
                    asset: asset,
                    width: 300,
                    height: 300,
                  ))),
          onTap: () {
            goToDetailsPage(context, asset);
          },
        );
      }),
    );
  }

  Future<void> loadAssets() async {
    List<Asset> resultList = List<Asset>();
    String error = 'No Error Dectected';

    try {
      resultList = await MultiImagePicker.pickImages(
        maxImages: 300,
        enableCamera: true,
        selectedAssets: images,
        cupertinoOptions: CupertinoOptions(takePhotoIcon: "chat"),
        materialOptions: MaterialOptions(
          actionBarColor: "#abcdef",
          actionBarTitle: "Example App",
          allViewTitle: "All Photos",
          useDetailsView: false,
          selectCircleStrokeColor: "#000000",
        ),
      );

      for (var r in resultList) {
        var t = await r.filePath;
        print(t);
      }
    } on Exception catch (e) {
      error = e.toString();
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      images = resultList;
      var angles = new List<int>.generate(images.length, (int index) => 0);
      imagesAnglesMap = new Map.fromIterables(images, angles);
      developer.log(imagesAnglesMap.toString());
      _error = error;
    });
  }

  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      home: new Scaffold(
        appBar: new AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Column(
          children: <Widget>[
            Center(child: Text('Error: $_error')),
            RaisedButton(
              child: Text("Pick images"),
              onPressed: loadAssets,
            ),
            Expanded(
              child: buildGridView(),
            )
          ],
        ),
      ),
    );
  }
}
