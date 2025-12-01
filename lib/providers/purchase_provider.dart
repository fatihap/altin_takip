import 'package:flutter/foundation.dart';
import '../models/gold_purchase.dart';
import '../services/storage_service.dart';

class PurchaseProvider with ChangeNotifier {
  final StorageService _storageService = StorageService();
  
  List<GoldPurchase> _purchases = [];
  bool _isLoading = false;

  List<GoldPurchase> get purchases => _purchases;
  bool get isLoading => _isLoading;

  Future<void> loadPurchases() async {
    _isLoading = true;
    notifyListeners();

    _purchases = await _storageService.getPurchases();
    _purchases.sort((a, b) => b.purchaseDate.compareTo(a.purchaseDate));

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addPurchase(GoldPurchase purchase) async {
    await _storageService.savePurchase(purchase);
    await loadPurchases();
  }

  Future<void> deletePurchase(String id) async {
    await _storageService.deletePurchase(id);
    await loadPurchases();
  }
}

