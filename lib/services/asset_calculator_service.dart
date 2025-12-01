import '../models/gold_asset.dart';
import '../models/gold_purchase.dart';
import '../models/gold_price.dart';

class AssetCalculatorService {
  // Alış kayıtlarını güncel fiyatlarla eşleştir ve varlık listesi oluştur
  List<GoldAsset> calculateAssets(
    List<GoldPurchase> purchases,
    List<GoldPrice> currentPrices,
  ) {
    final List<GoldAsset> assets = [];

    for (final purchase in purchases) {
      // Alış kaydındaki altın türüne uygun güncel fiyatı bul
      final matchingPrice = _findMatchingPrice(purchase.goldType, currentPrices);
      
      assets.add(GoldAsset(
        purchase: purchase,
        currentPrice: matchingPrice,
      ));
    }

    return assets;
  }

  // Altın türüne göre eşleşen fiyatı bul
  GoldPrice? _findMatchingPrice(String goldType, List<GoldPrice> prices) {
    // Altın türü isimlerini eşleştir
    final typeMap = {
      'Gram Altın': ['gram-altin', 'Gram Altın'],
      'Gram Has Altın': ['gram-has-altin', 'Gram Has Altın'],
      'Çeyrek Altın': ['ceyrek-altin', 'Çeyrek Altın'],
      'Yarım Altın': ['yarim-altin', 'Yarım Altın'],
      'Tam Altın': ['tam-altin', 'Tam Altın'],
      'Cumhuriyet Altını': ['cumhuriyet-altini', 'Cumhuriyet Altını'],
      'Ata Altın': ['ata-altin', 'Ata Altın'],
      'Ons Altın': ['ons', 'Ons Altın'],
      'Gümüş': ['gumus', 'Gümüş'],
      '14 Ayar Altın': ['14-ayar-altin', '14 Ayar Altın'],
      '18 Ayar Altın': ['18-ayar-altin', '18 Ayar Altın'],
      '22 Ayar Bilezik': ['22-ayar-bilezik', '22 Ayar Bilezik'],
    };

    final searchTerms = typeMap[goldType] ?? [goldType];

    for (final price in prices) {
      for (final term in searchTerms) {
        if (price.name.toLowerCase().contains(term.toLowerCase()) ||
            term.toLowerCase().contains(price.name.toLowerCase())) {
          return price;
        }
      }
    }

    // Eğer tam eşleşme bulunamazsa, ilk altın fiyatını döndür
    if (prices.isNotEmpty) {
      return prices.first;
    }

    return null;
  }

  // Toplam varlık değeri
  double calculateTotalCurrentValue(List<GoldAsset> assets) {
    double total = 0;
    for (final asset in assets) {
      final value = asset.totalCurrentValue;
      if (value != null) {
        total += value;
      }
    }
    return total;
  }

  // Toplam alış değeri
  double calculateTotalPurchaseValue(List<GoldAsset> assets) {
    double total = 0;
    for (final asset in assets) {
      final value = asset.totalPurchaseValue;
      if (value != null) {
        total += value;
      }
    }
    return total;
  }

  // Toplam kar/zarar
  double calculateTotalProfitLoss(List<GoldAsset> assets) {
    double total = 0;
    for (final asset in assets) {
      final pl = asset.profitLoss;
      if (pl != null) {
        total += pl;
      }
    }
    return total;
  }
}

