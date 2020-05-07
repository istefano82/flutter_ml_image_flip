import 'dart:async';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'dart:developer' as developer;

final String iapPremiumProductId = 'premium';

class MarketScreen extends StatefulWidget {
  @override
  _MarketScreenState createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> {
  InAppPurchaseConnection iap = InAppPurchaseConnection.instance;
  bool available = false;
  bool paid = false;

  List<ProductDetails> products = [];
  List<PurchaseDetails> purchases = [];
  StreamSubscription subscription;

  int credits = 0;

  @override
  void initState() {
    initialize();
    super.initState();
  }

  @override
  void dispose() {
    try {
      subscription.cancel();
    } on NoSuchMethodError {
      developer.log('IAP StreamSubscription not available.',
          name: 'my.app.purchase_premium.dispose');
    }
    super.dispose();
  }

  void initialize() async {
    available = await iap.isAvailable();

    if (available) {
      await getProducts();
      await getPastPurchases();

      verifyPurchase();

      subscription = iap.purchaseUpdatedStream.listen((data) => setState(() {
            purchases.addAll(data);
            verifyPurchase();
          }));
    }
  }

  Future<void> getProducts() async {
    Set<String> ids = Set.from([iapPremiumProductId]);
    ProductDetailsResponse response = await iap.queryProductDetails(ids);
    if (response.notFoundIDs.isNotEmpty) {
      var res = response.notFoundIDs;
      developer.log("Google IAP query products response is empty $res",
          name: 'my.app.purchase_premium.getProducts');
    }
    setState(() {
      products = response.productDetails;
    });
  }

  Future<void> getPastPurchases() async {
    QueryPurchaseDetailsResponse response = await iap.queryPastPurchases();
    setState(() {
      purchases = response.pastPurchases;
    });
  }

  PurchaseDetails hasPurchased(String pruductID) {
    return purchases.firstWhere((purchase) => purchase.productID == pruductID,
        orElse: () => null);
  }

  void verifyPurchase() {
    PurchaseDetails purchase = hasPurchased(iapPremiumProductId);

    if (purchase != null && purchase.pendingCompletePurchase) {
      iap.completePurchase(purchase);
    }

    if (purchase != null && purchase.status == PurchaseStatus.purchased) {
      paid = true;
    }
  }

  void buyProduct(ProductDetails prod) {
    final PurchaseParam purchaseParam = PurchaseParam(productDetails: prod);
    iap.buyNonConsumable(purchaseParam: purchaseParam);
    verifyPurchase();
  }

  // void consumePremium(ProductDetails prod) async {
  //   PurchaseDetails purchase = hasPurchased(prod.id);
  //   var res = await iap.consumePurchase(purchase);
  //   await getPastPurchases();
  //   developer.log("Consuming product result is $res",
  //       name: 'my.app.purchase_premium.consumePremium');
  //   paid = false;
  // }

  @override
  Widget build(BuildContext context) {
    return new WillPopScope(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.purple,
          automaticallyImplyLeading: false,
          title: Text(
              available ? 'Purchase Premium' : 'Premium service Not Available'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              for (var prod in products) ...[
                Text(prod.title, style: Theme.of(context).textTheme.headline),
                Text(prod.description),
                Text(prod.price,
                    style: TextStyle(color: Colors.purpleAccent, fontSize: 60)),
                FlatButton(
                  child: Text('Buy Premium'),
                  color: Colors.purple,
                  onPressed: () => buyProduct(prod),
                ),
              ],
              new RaisedButton(
                  elevation: 5.0,
                  shape: new RoundedRectangleBorder(
                      borderRadius: new BorderRadius.circular(30.0)),
                  color: Colors.purple,
                  child: new Text('Back',
                      style:
                          new TextStyle(fontSize: 20.0, color: Colors.white)),
                  onPressed: () {
                    returnPaid(context); // data back to the first screen},
                  }),

              // RaisedButton(
              //     child: Text("Consume premium"),
              //     onPressed: () {
              //       consumePremium(products[0]);
              //     }),
            ],
          ),
        ),
      ),
      onWillPop: () {
        returnPaid(context);
        return null;
      },
    );
  }

  void returnPaid(BuildContext context) {
    Navigator.pop(context, paid);
  }
}
