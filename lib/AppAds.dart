import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'package:firebase_admob/firebase_admob.dart';

import 'package:ads/ads.dart';

class AppAds {
  static Ads _ads;
  static final String _appId = Platform.isAndroid
      ? 'ca-app-pub-5263866612878215~5952960563'
      // TODO Use real APp store app ID
      : 'ca-app-pub-3940256099942544~1458002511';

  static final String _bannerUnitId = Platform.isAndroid
      ? 'ca-app-pub-5263866612878215/4594666924'
      // TODO Use real Appstore  store banner ID

      : 'ca-app-pub-3940256099942544/2934735716';

  static final String _screenUnitId = Platform.isAndroid
      ? 'ca-app-pub-5263866612878215/5010487944'
      // TODO Use real Appstore  store screenunit ID

      : 'ca-app-pub-3940256099942544/4411468910';

  /// Assign a listener.
  static MobileAdListener _eventListener = (MobileAdEvent event) {
    if (event == MobileAdEvent.clicked) {
      print("_eventListener: The opened ad is clicked on.");
    }
  };

  static void showBanner(
          {String adUnitId,
          AdSize size,
          List<String> keywords,
          String contentUrl,
          bool childDirected,
          List<String> testDevices,
          bool testing,
          MobileAdListener listener,
          State state,
          double anchorOffset,
          AnchorType anchorType}) =>
      _ads?.showBannerAd(
          adUnitId: adUnitId,
          size: size,
          keywords: keywords,
          contentUrl: contentUrl,
          childDirected: childDirected,
          testDevices: testDevices,
          testing: testing,
          listener: listener,
          state: state,
          anchorOffset: anchorOffset,
          anchorType: anchorType);

  static void hideBanner() => _ads?.closeBannerAd();

  static void showFullScreenAd(
          {String adUnitId,
          List<String> keywords,
          String contentUrl,
          bool childDirected,
          List<String> testDevices,
          bool testing,
          MobileAdListener listener,
          State state,
          double anchorOffset,
          AnchorType anchorType}) =>
      _ads?.showFullScreenAd(
          adUnitId: adUnitId,
          keywords: keywords,
          contentUrl: contentUrl,
          childDirected: childDirected,
          testDevices: testDevices,
          testing: testing,
          listener: listener,
          state: state,
          anchorOffset: anchorOffset,
          anchorType: anchorType);

  static void hideFullScreenAd() => _ads?.closeFullScreenAd();

  /// Call this static function in your State object's initState() function.
  static void init() => _ads ??= Ads(
        _appId,
        bannerUnitId: _bannerUnitId,
        screenUnitId: _screenUnitId,
        keywords: <String>['ibm', 'computers'],
        contentUrl: 'http://www.ibm.com',
        childDirected: false,
        testDevices: [],
        testing: false,
        listener: _eventListener,
      );

  /// Remember to call this in the State object's dispose() function.
  static void dispose() => _ads?.dispose();
}
