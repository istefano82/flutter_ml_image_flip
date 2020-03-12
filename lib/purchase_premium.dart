import 'dart:async';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

final String testID = 'premium';

class MarketScreen extends StatefulWidget {
  @override
  _MarketScreenState createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> {
  InAppPurchaseConnection iap = InAppPurchaseConnection.instance;
  bool available = true;

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
      print(products);

      verifyPurchase();

      subscription = iap.purchaseUpdatedStream.listen((data) => setState(() {
            print('NEW PURCHASE');
            purchases.addAll(data);
            verifyPurchase();
          }));
    }
  }

  Future<void> getProducts() async {
    Set<String> ids = Set.from([testID]);
    ProductDetailsResponse response = await iap.queryProductDetails(ids);
    if (response.notFoundIDs.isNotEmpty) {
      var res = response.notFoundIDs;
      print("Response is empty $res");
    // Handle the error.
}
    // const Set<String> _kIds = {'premium', ''};
    // final ProductDetailsResponse response =
    //     await InAppPurchaseConnection.instance.queryProductDetails(_kIds);
    // if (!response.notFoundIDs.isEmpty) {
    //   var res = response.notFoundIDs
    //   print('Following products not found $res');
    //   // Handle the error.
    // }
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
    return purchases.firstWhere((purchase) => purchase.productID == testID,
        orElse: () => null);
  }

  void verifyPurchase() {
    PurchaseDetails purchase = hasPurchased(testID);

    if (purchase != null && purchase.status == PurchaseStatus.purchased) {
      credits = 10;
    }
  }

  void buyProduct(ProductDetails prod) {
    final PurchaseParam purchaseParam = PurchaseParam(productDetails: prod);
    iap.buyConsumable(purchaseParam: purchaseParam, autoConsume: false);
  }

  void spendCredits(PurchaseDetails purchase) async {
    setState(() {
      credits--;
    });

    if (credits == 0) {
      var res = await iap.consumePurchase(purchase);
      await getPastPurchases();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(available ? 'Yes' : 'No'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            for (var prod in products)
              if (hasPurchased(prod.id) != null) ...[
                Text('$credits', style: TextStyle(fontSize: 60)),
                FlatButton(
                  child: Text('Consume'),
                  color: Colors.green,
                  onPressed: () => spendCredits(hasPurchased(prod.id)),
                ),
              ] else ...[
                Text(prod.title, style: Theme.of(context).textTheme.headline),
                Text(prod.description),
                Text(prod.price,
                    style: TextStyle(color: Colors.greenAccent, fontSize: 60)),
                FlatButton(
                  child: Text('Buy it'),
                  color: Colors.green,
                  onPressed: () => buyProduct(prod),
                ),
              ],
            RaisedButton(
                child: Text("Back"),
                onPressed: () {
                  returnPaid(context); // data back to the first screen},
                }),
          ],
        ),
      ),
    );
  }

  void returnPaid(BuildContext context) {
    // TODO - link the paid boolean to actual payment function
    bool paid = false;
    Navigator.pop(context, paid);
  }
  // Private methods go here

}
