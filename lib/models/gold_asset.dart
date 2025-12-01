import 'gold_purchase.dart';
import 'gold_price.dart';
import '../utils/price_parser.dart';

class GoldAsset {
  final GoldPurchase purchase;
  final GoldPrice? currentPrice;
  
  GoldAsset({
    required this.purchase,
    this.currentPrice,
  });

  // Alış fiyatı (gram başına)
  double? get purchasePricePerGram {
    // Eğer alış fiyatı kaydedilmişse onu kullan
    if (purchase.purchasePricePerGram != null) {
      return purchase.purchasePricePerGram;
    }
    
    // Eğer kaydedilmemişse, güncel fiyatı kullan (geriye dönük uyumluluk)
    return currentPricePerGram;
  }

  // Güncel değer (gram başına)
  double? get currentPricePerGram {
    if (currentPrice == null) return null;
    
    // Satış fiyatını parse et (Türk formatı: "5.774,89")
    final satisPrice = PriceParser.parseTurkishPrice(currentPrice!.satis);
    if (satisPrice == null) return null;
    
    return _calculatePricePerGram(satisPrice);
  }

  // Toplam alış değeri
  double? get totalPurchaseValue {
    final pricePerGram = purchasePricePerGram;
    if (pricePerGram == null) return null;
    return pricePerGram * purchase.amount;
  }

  // Toplam güncel değer
  double? get totalCurrentValue {
    final pricePerGram = currentPricePerGram;
    if (pricePerGram == null) return null;
    return pricePerGram * purchase.amount;
  }

  // Kar/Zarar miktarı
  double? get profitLoss {
    final purchase = totalPurchaseValue;
    final current = totalCurrentValue;
    if (purchase == null || current == null) return null;
    return current - purchase;
  }

  // Kar/Zarar yüzdesi
  double? get profitLossPercentage {
    final purchase = totalPurchaseValue;
    final profitLoss = this.profitLoss;
    if (purchase == null || profitLoss == null || purchase == 0) return null;
    return (profitLoss / purchase) * 100;
  }

  bool get isProfit {
    final pl = profitLoss;
    return pl != null && pl > 0;
  }

  // Altın türüne göre gram başına fiyat hesaplama
  double _calculatePricePerGram(double satisPrice) {
    switch (purchase.goldType) {
      case 'Gram Altın':
      case 'Gram Has Altın':
        return satisPrice;
      case 'Çeyrek Altın':
        return satisPrice / 1.754; // Çeyrek altın ~1.754 gram
      case 'Yarım Altın':
        return satisPrice / 3.508; // Yarım altın ~3.508 gram
      case 'Tam Altın':
        return satisPrice / 7.016; // Tam altın ~7.016 gram
      case 'Cumhuriyet Altını':
        return satisPrice / 7.216; // Cumhuriyet altını ~7.216 gram
      case 'Ata Altın':
        return satisPrice / 7.216; // Ata altın ~7.216 gram
      case 'Ons Altın':
        return satisPrice / 31.1035; // 1 ons = 31.1035 gram
      case 'Gümüş':
        return satisPrice; // Gümüş için gram başına
      default:
        // Diğer altın türleri için ortalama bir değer
        return satisPrice / 7.0; // Varsayılan olarak tam altın ağırlığı
    }
  }
}

