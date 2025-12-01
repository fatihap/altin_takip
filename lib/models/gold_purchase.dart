class GoldPurchase {
  final String id;
  final String goldType;
  final double amount;
  final DateTime purchaseDate;
  final String location;
  final String? notes;
  final double? purchasePricePerGram; // Alış fiyatı (gram başına)

  GoldPurchase({
    required this.id,
    required this.goldType,
    required this.amount,
    required this.purchaseDate,
    required this.location,
    this.notes,
    this.purchasePricePerGram,
  });

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
      location: json['location'] ?? '',
      notes: json['notes'],
      purchasePricePerGram: json['purchasePricePerGram'] != null
          ? (json['purchasePricePerGram'] as num).toDouble()
          : null,
    );
  }
}

