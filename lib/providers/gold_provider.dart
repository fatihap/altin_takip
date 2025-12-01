import 'package:flutter/foundation.dart';
import '../models/gold_price.dart';
import '../services/gold_api_service.dart';

class GoldProvider with ChangeNotifier {
  final GoldApiService _apiService = GoldApiService();
  
  List<GoldPrice> _goldPrices = [];
  bool _isLoading = false;
  String? _error;
  String? _updateDate;

  List<GoldPrice> get goldPrices => _goldPrices;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get updateDate => _updateDate;

  Future<void> fetchGoldPrices() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _apiService.fetchGoldPrices();
      _updateDate = _apiService.getUpdateDate(data);
      _goldPrices = _apiService.parseGoldPrices(data);
      _error = null;
    } catch (e) {
      _error = e.toString();
      _goldPrices = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

