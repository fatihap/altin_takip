class PriceParser {
  // Türk formatındaki fiyatı parse et: "5.774,89" -> 5774.89
  static double? parseTurkishPrice(String priceStr) {
    if (priceStr.isEmpty) return null;
    
    // Dolar işareti varsa kaldır
    String cleaned = priceStr.replaceAll('\$', '').trim();
    
    // Binlik ayırıcıları (nokta) kaldır
    cleaned = cleaned.replaceAll('.', '');
    
    // Ondalık ayırıcıyı (virgül) noktaya çevir
    cleaned = cleaned.replaceAll(',', '.');
    
    return double.tryParse(cleaned);
  }

  // Fiyatı Türk formatına çevir: 5774.89 -> "5.774,89"
  static String formatTurkishPrice(double price) {
    final parts = price.toStringAsFixed(2).split('.');
    final integerPart = parts[0];
    final decimalPart = parts[1];
    
    // Binlik ayırıcıları ekle
    String formatted = '';
    int count = 0;
    for (int i = integerPart.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) {
        formatted = '.$formatted';
      }
      formatted = integerPart[i] + formatted;
      count++;
    }
    
    return '$formatted,$decimalPart';
  }
}

