import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/gold_price.dart';

class GoldApiService {
  static const String baseUrl = 'https://finans.truncgil.com/today.json';

  Future<Map<String, dynamic>> fetchGoldPrices() async {
    try {
      final response = await http.get(Uri.parse(baseUrl));

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('API\'den veri alınamadı: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Bağlantı hatası: $e');
    }
  }

  List<GoldPrice> parseGoldPrices(Map<String, dynamic> data) {
    final List<MapEntry<String, GoldPrice>> goldPriceEntries = [];

    // Sadece altın türlerini filtrele ve key ile birlikte sakla
    data.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        final tur = value['Tür'] ?? '';
        if (tur == 'Altın') {
          final goldPrice = GoldPrice.fromJson(key, value);
          goldPriceEntries.add(MapEntry(key, goldPrice));
        }
      }
    });

    // Öncelikli altınları önce göster
    final priorityOrder = [
      'gram-altin',
      'ceyrek-altin',
      'yarim-altin',
      'tam-altin',
      'cumhuriyet-altini',
      'ata-altin',
      'ons',
      'gram-has-altin',
      '14-ayar-altin',
      '18-ayar-altin',
      '22-ayar-bilezik',
      'ikibucuk-altin',
      'besli-altin',
      'gremse-altin',
      'resat-altin',
      'hamit-altin',
      'gumus',
      'gram-platin',
      'gram-paladyum',
    ];

    goldPriceEntries.sort((a, b) {
      final aIndex = priorityOrder.indexOf(a.key);
      final bIndex = priorityOrder.indexOf(b.key);
      
      if (aIndex == -1 && bIndex == -1) return 0;
      if (aIndex == -1) return 1;
      if (bIndex == -1) return -1;
      
      return aIndex.compareTo(bIndex);
    });

    return goldPriceEntries.map((entry) => entry.value).toList();
  }

  String? getUpdateDate(Map<String, dynamic> data) {
    return data['Update_Date'] as String?;
  }
}

