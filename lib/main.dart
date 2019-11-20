import 'dart:io';
import 'dart:math';
import 'package:path/path.dart' as p;
import 'package:quiver/iterables.dart';
import 'package:image/image.dart' as imageLib;
import 'package:tflite/tflite.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/services.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';

import 'package:multi_image_picker/multi_image_picker.dart';

void main() => runApp(new MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => new _MyAppState();
}

class _MyAppState extends State<MyApp> {
  List<Asset> images = List<Asset>();
  List<int> imageAngles;
  String _error = 'No Error Dectected';
  Map _labelAngleMap = {
    'left': 90,
    'right': 270,
    'upright': 0,
    'upsidedown': 180
  };

  @override
  void initState() {
    super.initState();
    loadModel().then((val) {});
  }

  Future goToDetailsPage(
      BuildContext context, Asset asset, int angleIndex) async {
    // String path = await asset.filePath;
    // developer.log(path, name: 'my.app.main');
    setState(() {
      imageAngles[angleIndex] = (imageAngles[angleIndex] + 90) % 360;
      developer.log(imageAngles[angleIndex].toString(), name: 'my.app.main');
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
                  angle: imageAngles[index] * pi / 180,
                  // @TODO Use RotationTransition animation for eye candy
                  child: AssetThumb(
                    asset: asset,
                    width: 300,
                    height: 300,
                  ))),
          onTap: () {
            goToDetailsPage(context, asset, index);
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
        maxImages: 15,
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
      imageAngles = new List<int>.generate(images.length, (int index) => 0);
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
            RaisedButton(
              child: Text("Flip Images"),
              onPressed: flipImages,
            ),
            Expanded(
              child: buildGridView(),
            ),
            RaisedButton(
              child: Text("Save Images"),
              onPressed: rotateSaveImages,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> rotateSaveImages() async {
    for (var image in enumerate(images)) {
      String originalImagePath = await image.value.filePath;
      String newImagePath = p.join(p.dirname(originalImagePath),
          'flipped_' + p.basename(originalImagePath));
      var angle = imageAngles[image.index];
      imageLib.Image originalImage =
          imageLib.decodeImage(File(originalImagePath).readAsBytesSync());
      imageLib.Image rotatedImage = imageLib.copyRotate(originalImage, angle);
      //TODO Figure out why on the emulator newly saved images are shown only after emulator restart.
      // File('$newImagePath').writeAsBytesSync(imageLib.encodePng(rotatedImage));
      var x = imageLib.encodePng(rotatedImage);
      await ImageGallerySaver.saveImage(x);
      developer.log(newImagePath);
    }
  }

  Future flipImages() async {
    for (var image in enumerate(images)) {
      String imgPath = await image.value.filePath;
      var recognitions = await Tflite.runModelOnImage(
        path: imgPath,
        numResults: 1,
        threshold: 0.05,
        imageMean: 127.5,
        imageStd: 127.5,
      );
      developer.log(recognitions[0]['label'].toString(), name: 'my.app.main');
      var predLabel = recognitions[0]['label'];
      // TODO: Make sure images are only rotated if confidence is above 90% for example
      var newAngle = _labelAngleMap[predLabel];
      imageAngles[image.index] += newAngle;
      developer.log(newAngle.toString(), name: 'my.app.main');
      setState(() {
      });
    }
    await Tflite.close();
  }


  Future loadModel() async {
    Tflite.close();
    try {
      String res;
      res = await Tflite.loadModel(
        model: "assets/imageflip.tflite",
        labels: "assets/imageflip.txt",
      );
      print('Loaded model $res');
    } on PlatformException {
      print('Failed to load model.');
    }
  }
}
