import 'package:flutter/material.dart';
import 'package:fluter_image_flip/authentication.dart';
import 'package:fluter_image_flip/root_page.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

void main() {
  InAppPurchaseConnection.enablePendingPurchases();
  runApp(new MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
        title: 'Auto Image Flip',
        debugShowCheckedModeBanner: false,
        theme: new ThemeData(
          primarySwatch: Colors.purple,
        ),
        home: new RootPage(auth: new Auth()));
  }
}
