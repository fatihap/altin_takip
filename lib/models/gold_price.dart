class GoldPrice {
  final String name;
  final String alis;
  final String satis;
  final String degisim;
  final String tur;

  GoldPrice({
    required this.name,
    required this.alis,
    required this.satis,
    required this.degisim,
    required this.tur,
  });

  factory GoldPrice.fromJson(String key, Map<String, dynamic> json) {
    return GoldPrice(
      name: _formatName(key),
      alis: json['Alış'] ?? '',
      satis: json['Satış'] ?? '',
      degisim: json['Değişim'] ?? '',
      tur: json['Tür'] ?? '',
    );
  }

  static String _formatName(String key) {
    // Altın isimlerini daha okunabilir hale getir
    final nameMap = {
      'ons': 'Ons Altın',
      'gram-altin': 'Gram Altın',
      'gram-has-altin': 'Gram Has Altın',
      'ceyrek-altin': 'Çeyrek Altın',
      'yarim-altin': 'Yarım Altın',
      'tam-altin': 'Tam Altın',
      'cumhuriyet-altini': 'Cumhuriyet Altını',
      'ata-altin': 'Ata Altın',
      '14-ayar-altin': '14 Ayar Altın',
      '18-ayar-altin': '18 Ayar Altın',
      '22-ayar-bilezik': '22 Ayar Bilezik',
      'ikibucuk-altin': 'İkibuçuk Altın',
      'besli-altin': 'Beşli Altın',
      'gremse-altin': 'Gremse Altın',
      'resat-altin': 'Reşat Altın',
      'hamit-altin': 'Hamit Altın',
      'gumus': 'Gümüş',
      'gram-platin': 'Gram Platin',
      'gram-paladyum': 'Gram Paladyum',
    };

    return nameMap[key] ?? key;
  }

  bool get isPositiveChange {
    if (degisim.isEmpty) return false;
    return !degisim.contains('-');
  }
}

