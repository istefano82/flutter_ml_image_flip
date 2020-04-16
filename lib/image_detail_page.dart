import 'dart:math';
import 'dart:developer' as developer;

import 'package:flushbar/flushbar_helper.dart';
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
    return new WillPopScope(
      child: Scaffold(
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
                    imageProvider: new MemoryImage(imageData),
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
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          child: Icon(Icons.help),
          onPressed: showHelp,
          tooltip: "Show Help",
          heroTag: 'showHelp',
        ),
      ),
      onWillPop: () {
        _updateImageAngles(context);
        return null;
      },
    );
  }

  void _updateImageAngles(BuildContext context) {
    developer.log(
        "Applying new imageAngle to imageAngle array with value: $rotateCopy",
        name: 'my.app._ImageDetailPageState');
    data.imageAngles[this.imgAngleIndex] = rotateCopy;
    Navigator.pop(context, data);
    return null;
  }

  void showHelp() {
    String msg =
        '1: Use rotation gesture for precise image degree correction\n\n' +
            '2: When finished click "Back" button to back.\n\n';
    FlushbarHelper.createInformation(
        title: 'Help!', message: msg, duration: null)
      ..show(context);
  }
}
