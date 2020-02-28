import 'dart:math';
import 'dart:typed_data';
import 'package:quiver/iterables.dart';
import 'package:tflite/tflite.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image/image.dart' as img;
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:image_editor/image_editor.dart';
import 'package:multi_image_picker/multi_image_picker.dart';
import 'package:fluter_image_flip/image_detail_page.dart';
import 'package:fluter_image_flip/login_signup_page.dart';
import 'authentication.dart';

class HomePage extends StatefulWidget {
  HomePage({Key key, this.auth, this.userId, this.onSignedOut});

  final BaseAuth auth;
  final VoidCallback onSignedOut;
  final String userId;
  @override
  State<StatefulWidget> createState() => new _HomePageState();
}

class Data {
  List<double> imageAngles;
  Data({this.imageAngles});
}

class _HomePageState extends State<HomePage> {
  final data = Data(imageAngles: []);
  List<Asset> imageAssets = List<Asset>();
  List<List<int>> images = [];
  String _error = 'No Error Dectected';
  bool _isPaidUser = false;
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
    checkIsPremium();
  }

  Future checkIsPremium() async {
    await Firestore.instance
        .collection('premiumUsers')
        .document(this.widget.userId)
        .get()
        .then((DocumentSnapshot ds) {
      // use ds as a snapshot
      try {
        setState(() {
          _isPaidUser = ds.data['paid'];
        });
      } catch (e) {
        developer.log(e.toString(), name: 'my.app.home_page.checkIsPremium');
        _isPaidUser = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
        home: new Scaffold(
      appBar: new AppBar(
        title: const Text('Plugin example app'),
        actions: <Widget>[
          new FlatButton(
              child: new Text('Logout',
                  style: new TextStyle(fontSize: 17.0, color: Colors.white)),
              onPressed: signOut),
        ],
      ),
      body: Column(
        children: <Widget>[
          Center(child: Text('Error: $_error')),
          Expanded(
            child: buildGridView(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.image),
        onPressed: loadAssets,
        tooltip: "Upload images.",
      ),
      persistentFooterButtons: <Widget>[
        FlatButton(
          child:  Text("Flip Images"),
          onPressed: flipImages,
        ),
        FlatButton(
          child: Icon(Icons.save_alt), //Text("Save Images"),
          onPressed: rotateSaveImages,
        ),
        Visibility(
            visible: !_isPaidUser,
            child: new FlatButton(
                child: new Text('Go Premium',
                    style: new TextStyle(
                      fontSize: 17.0,
                      color: Colors.blueAccent,
                    )),
                onPressed: goPremium)),
      ],
    ));
  }

  Future rotatePressedImage(
      BuildContext context, Asset asset, int angleIndex) async {
    setState(() {
      data.imageAngles[angleIndex] = (data.imageAngles[angleIndex] + 90) % 360;
      developer.log(data.imageAngles[angleIndex].toString(),
          name: 'my.app.home_page');
    });
  }

  _secondPage(BuildContext context, Asset asset, int index) async {
    ByteData byteData = await asset.getByteData();
    final List<int> imageData = byteData.buffer.asUint8List();
    final dataFromSecondPage = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => ImageDetailPage(imageData, index, data: data)),
    ) as Data;
    setState(() {
      data.imageAngles = dataFromSecondPage.imageAngles;
    });
  }

  Widget buildGridView(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      mainAxisSpacing: 3,
      children: List.generate(imageAssets.length, (index) {
        Asset asset = imageAssets[index];
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
                  onLongPress: () {
                    _secondPage(context, asset, index);
                  },
                ));
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
        selectedAssets: imageAssets,
        cupertinoOptions: CupertinoOptions(takePhotoIcon: "chat"),
        materialOptions: MaterialOptions(
          actionBarColor: "#abcdef",
          actionBarTitle: "Example App",
          allViewTitle: "All Photos",
          useDetailsView: false,
          selectCircleStrokeColor: "#000000",
        ),
      );
    } on Exception catch (e) {
      error = e.toString();
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      imageAssets = resultList;
      data.imageAngles =
          new List<double>.generate(imageAssets.length, (int index) => 0);
      _error = error;
    });
  }

  Future<void> rotateSaveImages() async {
    List<int> imageListByteData;
    for (var image in enumerate(imageAssets)) {
      try {
        imageListByteData = images[image.index];
      } on RangeError {
        imageListByteData = await imgByteToList(image);
      }

      var angle = data.imageAngles[image.index];
      ImageEditorOption option = ImageEditorOption();
      option.addOption(RotateOption(angle.toInt()));
      option.outputFormat = OutputFormat.png(100);
      final result = await ImageEditor.editImage(
        image: imageListByteData,
        imageEditorOption: option,
      );
      await ImageGallerySaver.saveImage(result);
      showFloatingFlushbar(context, 'Images saved!');
    }
    setState(() {
      imageAssets = List<Asset>();
      data.imageAngles =
          new List<double>.generate(imageAssets.length, (int index) => 0);
    });
  }

  Future flipImages() async {
    for (var image in enumerate(imageAssets)) {
      List<int> imageData = await imgByteToList(image);
      images.add(imageData);
      img.Image reconstructedImage = img.decodeImage(imageData);
      img.Image imageThumbnail =
          img.copyResize(reconstructedImage, height: 224, width: 224);

      var recognitions = await Tflite.runModelOnBinary(
          binary: imageToByteListFloat32(
              imageThumbnail, 224, 127.5, 127.5), // required
          numResults: 1,
          threshold: 0.9, // use predictions with > 90 percent confidences
          asynch: true);
      developer.log("Predicted data is $recognitions",
          name: 'my.app.home_page');
      try {
        var predLabel = recognitions[0]['label'];
        var newAngle = _labelAngleMap[predLabel];
        data.imageAngles[image.index] += newAngle;
        developer.log(newAngle.toString(), name: 'my.app.home_page');
        setState(() {});
      } on RangeError {
        continue;
      }
    }
  }

  Future<List<int>> imgByteToList(IndexedValue<Asset> image) async {
    ByteData byteData = await image.value.getByteData();
    List<int> imageData = byteData.buffer.asUint8List();
    return imageData;
  }

  Uint8List imageToByteListFloat32(
      img.Image image, int inputSize, double mean, double std) {
    var convertedBytes = Float32List(1 * inputSize * inputSize * 3);
    var buffer = Float32List.view(convertedBytes.buffer);
    int pixelIndex = 0;
    for (var i = 0; i < inputSize; i++) {
      for (var j = 0; j < inputSize; j++) {
        var pixel = image.getPixel(j, i);
        buffer[pixelIndex++] = (img.getRed(pixel) - mean) / std;
        buffer[pixelIndex++] = (img.getGreen(pixel) - mean) / std;
        buffer[pixelIndex++] = (img.getBlue(pixel) - mean) / std;
      }
    }
    return convertedBytes.buffer.asUint8List();
  }

  Future loadModel() async {
    Tflite.close();
    try {
      String res;
      res = await Tflite.loadModel(
        model: "assets/imageflip.tflite",
        labels: "assets/imageflip.txt",
      );
      developer.log('Loaded model $res', name: 'my.app.home_page');
    } on PlatformException {
      developer.log('Failed to load model.', name: 'my.app.home_page');
    }
  }

  @override
  void dispose() async {
    await Tflite.close();
    super.dispose();
  }

  signOut() async {
    try {
      await widget.auth.signOut();
      widget.onSignedOut();
      showFloatingFlushbar(context, 'Successfully logged out!');
    } catch (e) {
      showSimpleErrorFlushbar(context, e.toString());
      print(e);
    }
  }

  goPremium() async {
    var userData = {'paid': true};
    await Firestore.instance
        .collection('premiumUsers')
        .document(this.widget.userId)
        .setData(userData);

    setState(() {
      _isPaidUser = true;
    });
  }
}
