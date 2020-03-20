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
    subscription.cancel();
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
      developer.log("Google IAP query products eesponse is empty $res",
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
    return purchases.firstWhere((purchase) => purchase.productID == pruductID ,orElse: () => null);
  }

  void verifyPurchase() {
    PurchaseDetails purchase = hasPurchased(iapPremiumProductId);

    if (purchase != null && purchase.status == PurchaseStatus.purchased) {
      paid = true;
    }
  }

  void buyProduct(ProductDetails prod) {
    final PurchaseParam purchaseParam = PurchaseParam(productDetails: prod);
    iap.buyNonConsumable(purchaseParam: purchaseParam);
    verifyPurchase();
  }

  //@ TODO remove or comment consume premium for production
  void consumePremium(ProductDetails prod) async {
    PurchaseDetails purchase = hasPurchased(prod.id);
    var res = await iap.consumePurchase(purchase);
    await getPastPurchases();
    developer.log("Consuming product result is $res",
        name: 'my.app.purchase_premium.consumePremium');
    paid = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
                  style: TextStyle(color: Colors.greenAccent, fontSize: 60)),
              FlatButton(
                child: Text('Buy Premium'),
                color: Colors.green,
                onPressed: () => buyProduct(prod),
              ),
            ],
            RaisedButton(
                child: Text("Back"),
                onPressed: () {
                  returnPaid(context); // data back to the first screen},
                }),
            RaisedButton(
                child: Text("Consume premium"),
                onPressed: () {
                  consumePremium(
                      products[0]);
                }),
          ],
        ),
      ),
    );
  }

  void returnPaid(BuildContext context) {
    Navigator.pop(context, paid);
  }
}
