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
import 'dart:typed_data';

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
  List _recognitions;


  @override
  void initState() {
    super.initState();
    loadModel().then((val) {
    });
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
              onPressed:
                  predictImage, //TODO Figure out how to pass the images for ML classification
            ),
            Expanded(
              child: buildGridView(),
            ),
            RaisedButton(
              child: Text("Save Images"),
              onPressed:
                  rotateSaveImages,
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
      File('$newImagePath')..writeAsBytes(imageLib.encodeJpg(rotatedImage));
      developer.log(newImagePath);
    }
  }
    Uint8List imageToByteListFloat32(
      imageLib.Image image, int inputSize, double mean, double std) {
    var convertedBytes = Float32List(1 * inputSize * inputSize * 3);
    var buffer = Float32List.view(convertedBytes.buffer);
    int pixelIndex = 0;
    for (var i = 0; i < inputSize; i++) {
      for (var j = 0; j < inputSize; j++) {
        var pixel = image.getPixel(j, i);
        buffer[pixelIndex++] = (imageLib.getRed(pixel) - mean) / std;
        buffer[pixelIndex++] = (imageLib.getGreen(pixel) - mean) / std;
        buffer[pixelIndex++] = (imageLib.getBlue(pixel) - mean) / std;
      }
    }
    return convertedBytes.buffer.asUint8List();
  }

  // Future predictImage() async {
  //       String imgPath = await images[0].filePath;
  //   var imageBytes = (await rootBundle.load(imgPath)).buffer;
  //   imageLib.Image oriImage = imageLib.decodeJpg(imageBytes.asUint8List());
  //   imageLib.Image resizedImage = imageLib.copyResize(oriImage, width: 224, height: 224);
  //   var recognitions = await Tflite.runModelOnBinary(
  //     binary: imageToByteListFloat32(resizedImage, 224, 127.5, 127.5),
  //     numResults: 6,
  //     threshold: 0.05,
  //   );
  //   setState(() {
  //     _recognitions = recognitions;
  //   });
  //       developer.log(_recognitions.toString(), name: 'my.app.main');

  // }
  Future recognizeImage() async {
    String imgPath = await images[0].filePath;
    var recognitions = await Tflite.runModelOnImage(
      path: imgPath,
      numResults: 6,
      threshold: 0.05,
      imageMean: 127.5,
      imageStd: 127.5,
    );
    setState(() {
      _recognitions = recognitions;
    });
    developer.log(_recognitions.toString(), name: 'my.app.main');
  }
  
  Future predictImage() async {
      await recognizeImage();
    // await recognizeImageBinary(image);
  }

  Future loadModel() async {
    Tflite.close();
    try {
      String res;
          res = await Tflite.loadModel(
            model: "assets/mobilenet_v1_1.0_224.tflite",
            labels: "assets/mobilenet_v1_1.0_224.txt",
          );
      print('Loaded model $res');
    } on PlatformException {
      print('Failed to load model.');
    }
  }
}
