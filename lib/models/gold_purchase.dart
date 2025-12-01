class GoldPurchase {
  final String id;
  final String goldType;
  final double amount; // Miktar (gram veya adet olabilir)
  final DateTime purchaseDate;
  final String? location; // Artık opsiyonel
  final String? notes;
  final double? purchasePricePerGram; // Alış fiyatı (gram başına)

  GoldPurchase({
    required this.id,
    required this.goldType,
    required this.amount,
    required this.purchaseDate,
    this.location,
    this.notes,
    this.purchasePricePerGram,
  });

  // Altın türüne göre birim (gram/adet)
  String get unit {
    switch (goldType) {
      case 'Gram Altın':
      case 'Gram Has Altın':
      case 'Gümüş':
        return 'gram';
      case 'Çeyrek Altın':
      case 'Yarım Altın':
      case 'Tam Altın':
      case 'Cumhuriyet Altını':
      case 'Ata Altın':
        return 'adet';
      case 'Ons Altın':
        return 'ons';
      default:
        return 'gram';
    }
  }

  // Miktarı grama çevir
  double get amountInGrams {
    switch (goldType) {
      case 'Gram Altın':
      case 'Gram Has Altın':
      case 'Gümüş':
        return amount;
      case 'Çeyrek Altın':
        return amount * 1.754; // 1 çeyrek = 1.754 gram
      case 'Yarım Altın':
        return amount * 3.508; // 1 yarım = 3.508 gram
      case 'Tam Altın':
        return amount * 7.016; // 1 tam = 7.016 gram
      case 'Cumhuriyet Altını':
        return amount * 7.216; // 1 cumhuriyet = 7.216 gram
      case 'Ata Altın':
        return amount * 7.216; // 1 ata = 7.216 gram
      case 'Ons Altın':
        return amount * 31.1035; // 1 ons = 31.1035 gram
      default:
        return amount;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'goldType': goldType,
      'amount': amount,
      'purchaseDate': purchaseDate.toIso8601String(),
      'location': location,
      'notes': notes,
      'purchasePricePerGram': purchasePricePerGram,
    };
  }

  factory GoldPurchase.fromJson(Map<String, dynamic> json) {
    return GoldPurchase(
      id: json['id'] ?? '',
      goldType: json['goldType'] ?? '',
      amount: (json['amount'] as num).toDouble(),
      purchaseDate: DateTime.parse(json['purchaseDate']),
      location: json['location'],
      notes: json['notes'],
      purchasePricePerGram: json['purchasePricePerGram'] != null
          ? (json['purchasePricePerGram'] as num).toDouble()
          : null,
    );
  }
}

