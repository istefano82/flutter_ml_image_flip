import 'dart:math';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'package:photo_view/photo_view.dart';

import 'home_page.dart';

class ImageDetailPage extends StatefulWidget {
  final Data data;
  final List<int> imageData;
  final int imgAngleIndex;
  ImageDetailPage(this.imageData, this.imgAngleIndex, {this.data});
  @override
  _ImageDetailPageState createState() =>
      _ImageDetailPageState(this.imageData, this.imgAngleIndex, data: data);
}

class _ImageDetailPageState extends State<ImageDetailPage> {
  PhotoViewController controller;
  double rotateCopy;
  double originalAngleRdians;
  final Data data;
  final int imgAngleIndex;
  final List<int> imageData;

  _ImageDetailPageState(this.imageData, this.imgAngleIndex, {this.data});

  @override
  void initState() {
    super.initState();
    originalAngleRdians = data.imageAngles[this.imgAngleIndex];
    developer.log("original angle from main dart is $originalAngleRdians",
        name: 'my.app._ImageDetailPageState');
    controller = PhotoViewController()..outputStateStream.listen(listener);
    controller.rotation = originalAngleRdians * pi / 180;
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void listener(PhotoViewControllerValue value) {
    setState(() {
      rotateCopy = value.rotation * 180 / pi;
    });
  }

  @override
  Widget build(BuildContext context) {
    return new WillPopScope(child: Scaffold(
      appBar: AppBar(
        title: Text('Clipped Photo View'),
        automaticallyImplyLeading: false,
      ),
      body: Container(
        padding: EdgeInsets.all(12.0),
        alignment: Alignment.center,
        child: Column(
          children: <Widget>[
            AspectRatio(
              aspectRatio: 16 / 9,
              // Puts a "mask" on the child, so that it will keep its original, unzoomed size
              // even while it's being zoomed in
              child: ClipRect(
                child: PhotoView(
                  imageProvider:  new MemoryImage(imageData),
                  // Contained = the smallest possible size to fit one dimension of the screen
                  controller: controller,
                  minScale: PhotoViewComputedScale.contained * 1.0,
                  maxScale: PhotoViewComputedScale.contained * 1.0,
                  enableRotation: true,

                  loadingChild: Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
              ),
            ),
            RaisedButton(
                child: Text("Back"),
                onPressed: () {
                  _updateImageAngles(
                      context); // data back to the first screen},
                }),
            Text("Rotation applied: $rotateCopy"),
          ],
        ),
      ),
    ), 
    onWillPop: () {
      _updateImageAngles(context);
    },
    );
  }

  Future<void> _updateImageAngles(BuildContext context) {
    developer.log(
        "Applying new imageAngle to imageAngle array with value: $rotateCopy",
        name: 'my.app._ImageDetailPageState');
    data.imageAngles[this.imgAngleIndex] = rotateCopy;
    Navigator.pop(context, data);
  }
}
