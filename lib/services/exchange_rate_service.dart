import 'dart:convert';
import 'package:http/http.dart' as http;

class ExchangeRateService {
  static const String baseUrl = 'https://finans.truncgil.com/today.json';

  Future<Map<String, double>> fetchExchangeRates() async {
    try {
      final response = await http.get(Uri.parse(baseUrl));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        
        double? usdRate;
        double? eurRate;

        // USD ve EUR kurlarını direkt key olarak bul
        if (data.containsKey('USD') && data['USD'] is Map<String, dynamic>) {
          final usdData = data['USD'] as Map<String, dynamic>;
          final satis = usdData['Satış'] ?? '';
          usdRate = _parsePrice(satis);
        }
        
        if (data.containsKey('EUR') && data['EUR'] is Map<String, dynamic>) {
          final eurData = data['EUR'] as Map<String, dynamic>;
          final satis = eurData['Satış'] ?? '';
          eurRate = _parsePrice(satis);
        }

        return {
          'USD': usdRate ?? 0.0,
          'EUR': eurRate ?? 0.0,
        };
      } else {
        throw Exception('API\'den veri alınamadı: ${response.statusCode}');
      }
    } catch (e) {
      // Hata durumunda varsayılan değerler döndür
      return {
        'USD': 0.0,
        'EUR': 0.0,
      };
    }
  }

  double? _parsePrice(dynamic price) {
    if (price == null) return null;
    
    final priceStr = price.toString().replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(priceStr);
  }
}

