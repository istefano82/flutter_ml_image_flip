import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:multi_image_picker/multi_image_picker.dart';

import 'package:photo_view/photo_view.dart';

import 'main.dart';

class AdvancedPage extends StatelessWidget {
  final Data data;
  final String imgPath;
  AdvancedPage(this.imgPath, {this.data});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                  //TODO: Figure out how to convert multi image picker image bytestream to AssetImage
                  imageProvider: AssetImage(this.imgPath),
                  // Contained = the smallest possible size to fit one dimension of the screen
                  //TODO DIsable zooming
                  minScale: PhotoViewComputedScale.contained * 0.8,
                  // Covered = the smallest possible size to fit the whole screen
                  maxScale: PhotoViewComputedScale.covered * 2,
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
