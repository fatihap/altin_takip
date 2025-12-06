import 'package:flutter/foundation.dart';
import '../services/exchange_rate_service.dart';

class ExchangeRateProvider with ChangeNotifier {
  final ExchangeRateService _service = ExchangeRateService();
  
  double _usdRate = 0.0;
  double _eurRate = 0.0;
  bool _isLoading = false;
  String? _error;

  double get usdRate => _usdRate;
  double get eurRate => _eurRate;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchExchangeRates() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final rates = await _service.fetchExchangeRates();
      _usdRate = rates['USD'] ?? 0.0;
      _eurRate = rates['EUR'] ?? 0.0;
      _error = null;
    } catch (e) {
      _error = e.toString();
      _usdRate = 0.0;
      _eurRate = 0.0;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

