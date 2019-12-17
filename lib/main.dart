import 'dart:io';
import 'dart:math';
import 'package:quiver/iterables.dart';
import 'package:tflite/tflite.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/services.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:image_editor/image_editor.dart';
import 'package:multi_image_picker/multi_image_picker.dart';
import 'package:fluter_image_flip/advanced_page.dart';

void main() => runApp(new MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => new _MyAppState();
}

class Data {
  List<int> imageAngles;
  Data({this.imageAngles});
}

class _MyAppState extends State<MyApp> {
  final data = Data(imageAngles: []);
  List<Asset> images = List<Asset>();
  // List<int> imageAngles;
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
              child: buildGridView(context),
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

  Future rotatePressedImage(
      BuildContext context, Asset asset, int angleIndex) async {
    // String path = await asset.filePath;
    // developer.log(path, name: 'my.app.main');
    setState(() {
      data.imageAngles[angleIndex] = (data.imageAngles[angleIndex] + 90) % 360;
      developer.log(data.imageAngles[angleIndex].toString(), name: 'my.app.main');
    });
  }

  _secondPage(BuildContext context, Widget page) async {  
  final dataFromSecondPage = await Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => page),
  ) as Data;  // Here we have the data from the second screen  data.counter = dataFromSecondPage.counter;
  data.imageAngles = dataFromSecondPage.imageAngles;
}

  Widget buildGridView(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      mainAxisSpacing: 3,
      children: List.generate(images.length, (index) {
        Asset asset = images[index];
        return Builder(
            builder: (context) => GestureDetector(
                child: GridTile(
                    child: Transform.rotate(
                        angle: data.imageAngles[index] * pi / 180,
                        // TODO Use RotationTransition animation for eye candy
                        child: AssetThumb(
                          asset: asset,
                          width: 300,
                          height: 300,
                        ))),
                onTap: () {
                  rotatePressedImage(context, asset, index);
                },
                // onLongPress: _secondPage(context, AdvancedPage(data: data))));
                onLongPress: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => AdvancedPage(data:),
                    ))));
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
      data.imageAngles = new List<int>.generate(images.length, (int index) => 0);
      _error = error;
    });
  }

  Future<void> rotateSaveImages() async {
    for (var image in enumerate(images)) {
      String originalImagePath = await image.value.filePath;

      var angle = data.imageAngles[image.index];
      ImageEditorOption option = ImageEditorOption();
      option.addOption(RotateOption(angle));
      option.outputFormat = OutputFormat.png(100);
      // TODO: Use the loaded image getByteData method with edit Image from image_editor to optimize performance.
      final result = await ImageEditor.editFileImage(
        file: File(originalImagePath),
        imageEditorOption: option,
      );
      await ImageGallerySaver.saveImage(result);
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
      data.imageAngles[image.index] += newAngle;
      developer.log(newAngle.toString(), name: 'my.app.main');
      setState(() {});
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
