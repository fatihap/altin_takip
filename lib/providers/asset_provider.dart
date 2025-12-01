import 'package:flutter/foundation.dart';
import '../models/gold_asset.dart';
import '../models/gold_purchase.dart';
import '../models/gold_price.dart';
import '../services/asset_calculator_service.dart';
import 'purchase_provider.dart';
import 'gold_provider.dart';

class AssetProvider with ChangeNotifier {
  final AssetCalculatorService _calculator = AssetCalculatorService();
  
  List<GoldAsset> _assets = [];
  bool _isLoading = false;

  List<GoldAsset> get assets => _assets;
  bool get isLoading => _isLoading;

  // Toplam güncel değer
  double get totalCurrentValue => _calculator.calculateTotalCurrentValue(_assets);
  
  // Toplam alış değeri
  double get totalPurchaseValue => _calculator.calculateTotalPurchaseValue(_assets);
  
  // Toplam kar/zarar
  double get totalProfitLoss => _calculator.calculateTotalProfitLoss(_assets);
  
  // Toplam kar/zarar yüzdesi
  double get totalProfitLossPercentage {
    if (totalPurchaseValue == 0) return 0;
    return (totalProfitLoss / totalPurchaseValue) * 100;
  }

  // Varlıkları hesapla
  void calculateAssets(List<GoldPurchase> purchases, List<GoldPrice> currentPrices) {
    _isLoading = true;
    notifyListeners();

    _assets = _calculator.calculateAssets(purchases, currentPrices);
    
    // Varlıkları tarihe göre sırala (en yeni önce)
    _assets.sort((a, b) => b.purchase.purchaseDate.compareTo(a.purchase.purchaseDate));

    _isLoading = false;
    notifyListeners();
  }

  void clearAssets() {
    _assets = [];
    notifyListeners();
  }
}

