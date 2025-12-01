import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/purchase_provider.dart';
import '../providers/gold_provider.dart';
import '../models/gold_purchase.dart';
import '../models/gold_price.dart';
import '../utils/price_parser.dart';

class AddPurchaseScreen extends StatefulWidget {
  const AddPurchaseScreen({super.key});

  @override
  State<AddPurchaseScreen> createState() => _AddPurchaseScreenState();
}

class _AddPurchaseScreenState extends State<AddPurchaseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _purchasePriceController = TextEditingController();
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();
  
  String _selectedGoldType = 'Gram Altın';
  DateTime _selectedDate = DateTime.now();

  final List<String> _goldTypes = [
    'Gram Altın',
    'Çeyrek Altın',
    'Yarım Altın',
    'Tam Altın',
    'Cumhuriyet Altını',
    'Ata Altın',
    'Ons Altın',
    'Gümüş',
  ];

  // Altın türüne göre birim
  String _getUnit(String goldType) {
    switch (goldType) {
      case 'Gram Altın':
      case 'Gram Has Altın':
      case 'Gümüş':
        return 'Gram';
      case 'Çeyrek Altın':
      case 'Yarım Altın':
      case 'Tam Altın':
      case 'Cumhuriyet Altını':
      case 'Ata Altın':
        return 'Adet';
      case 'Ons Altın':
        return 'Ons';
      default:
        return 'Gram';
    }
  }

  @override
  void initState() {
    super.initState();
    // Güncel fiyatı öneri olarak göster
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Altın fiyatlarını yükle
      final goldProvider = context.read<GoldProvider>();
      if (goldProvider.goldPrices.isEmpty) {
        await goldProvider.fetchGoldPrices();
      }
      _updateSuggestedPrice();
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _purchasePriceController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _updateSuggestedPrice({bool forceUpdate = false}) {
    final suggestedPrice = _getCurrentPriceFromAPI();
    if (suggestedPrice != null) {
      // Eğer alan boşsa veya zorla güncelleme isteniyorsa güncelle
      if (_purchasePriceController.text.isEmpty || forceUpdate) {
        setState(() {
          _purchasePriceController.text = PriceParser.formatTurkishPrice(suggestedPrice);
        });
      }
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('tr', 'TR'),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // API'den direkt fiyatı al (hesaplama yapma)
  double? _getCurrentPriceFromAPI() {
    final goldProvider = context.read<GoldProvider>();
    if (goldProvider.goldPrices.isEmpty) return null;

    GoldPrice? matchingPrice;
    
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
    };
    final searchTerms = typeMap[_selectedGoldType] ?? [_selectedGoldType];

    try {
      matchingPrice = goldProvider.goldPrices.firstWhere(
        (price) => searchTerms.any((term) => 
          price.name.toLowerCase().contains(term.toLowerCase()) ||
          term.toLowerCase().contains(price.name.toLowerCase())
        ),
      );
    } catch (e) {
      // Eşleşme bulunamadı
      return null;
    }

    if (matchingPrice == null) return null;
    
    // API'den gelen satış fiyatını direkt parse et (hesaplama yapma)
    final satisPrice = PriceParser.parseTurkishPrice(matchingPrice.satis);
    return satisPrice;
  }

  // Altın türüne göre fiyat birimi
  String _getPriceUnit() {
    switch (_selectedGoldType) {
      case 'Gram Altın':
      case 'Gram Has Altın':
      case 'Gümüş':
        return '₺/gram';
      case 'Çeyrek Altın':
      case 'Yarım Altın':
      case 'Tam Altın':
      case 'Cumhuriyet Altını':
      case 'Ata Altın':
        return '₺/adet';
      case 'Ons Altın':
        return '₺/ons';
      default:
        return '₺/gram';
    }
  }

  // Alış fiyatını gram başına çevir (hesaplamalar için)
  double? _convertToPricePerGram(double price) {
    switch (_selectedGoldType) {
      case 'Gram Altın':
      case 'Gram Has Altın':
      case 'Gümüş':
        return price; // Zaten gram başına
      case 'Çeyrek Altın':
        return price / 1.754; // Adet başına fiyatı gram başına çevir
      case 'Yarım Altın':
        return price / 3.508;
      case 'Tam Altın':
        return price / 7.016;
      case 'Cumhuriyet Altını':
      case 'Ata Altın':
        return price / 7.216;
      case 'Ons Altın':
        return price / 31.1035; // Ons başına fiyatı gram başına çevir
      default:
        return price / 7.0;
    }
  }

  Future<void> _savePurchase() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Kullanıcının girdiği alış fiyatını parse et
    double? purchasePrice;
    if (_purchasePriceController.text.isNotEmpty) {
      purchasePrice = PriceParser.parseTurkishPrice(_purchasePriceController.text);
      if (purchasePrice == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lütfen geçerli bir alış fiyatı girin'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    } else {
      // Eğer kullanıcı fiyat girmediyse, API'den güncel fiyatı kullan
      purchasePrice = _getCurrentPriceFromAPI();
    }

    // Fiyatı gram başına çevir (hesaplamalar için)
    double? pricePerGram;
    if (purchasePrice != null) {
      pricePerGram = _convertToPricePerGram(purchasePrice);
    }

    final purchase = GoldPurchase(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      goldType: _selectedGoldType,
      amount: double.parse(_amountController.text.replaceAll(',', '.')),
      purchaseDate: _selectedDate,
      location: _locationController.text.trim().isEmpty 
          ? null 
          : _locationController.text.trim(),
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      purchasePricePerGram: pricePerGram,
    );

    final purchaseProvider = context.read<PurchaseProvider>();
    await purchaseProvider.addPurchase(purchase);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(pricePerGram != null
              ? 'Altın alış kaydı eklendi! (Alış fiyatı: ${PriceParser.formatTurkishPrice(pricePerGram)} ₺/gram)'
              : 'Altın alış kaydı eklendi!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Altın Alış Ekle'),
        backgroundColor: Colors.amber[700],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                value: _selectedGoldType,
                decoration: InputDecoration(
                  labelText: 'Altın Türü',
                  prefixIcon: const Icon(Icons.account_balance_wallet),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: _goldTypes.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedGoldType = value;
                    });
                    // Altın türü değiştiğinde fiyatı zorla güncelle
                    _updateSuggestedPrice(forceUpdate: true);
                  }
                },
              ),
              const SizedBox(height: 16),
              Builder(
                builder: (context) {
                  final unit = _getUnit(_selectedGoldType);
                  return TextFormField(
                    controller: _amountController,
                    decoration: InputDecoration(
                      labelText: 'Miktar ($unit)',
                      prefixIcon: const Icon(Icons.scale),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      helperText: unit == 'Adet'
                          ? 'Örnek: 2 (2 adet)'
                          : unit == 'Ons'
                              ? 'Örnek: 1.5 (1.5 ons)'
                              : 'Örnek: 5.5 (5.5 gram)',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Lütfen miktarı girin';
                      }
                      if (double.tryParse(value.replaceAll(',', '.')) == null) {
                        return 'Geçerli bir sayı girin';
                      }
                      return null;
                    },
                  );
                },
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _selectDate,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Alış Tarihi',
                    prefixIcon: const Icon(Icons.calendar_today),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    DateFormat('dd MMMM yyyy', 'tr_TR').format(_selectedDate),
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Builder(
                builder: (context) {
                  final priceUnit = _getPriceUnit();
                  return TextFormField(
                    controller: _purchasePriceController,
                    decoration: InputDecoration(
                      labelText: 'Alış Fiyatı ($priceUnit)',
                      prefixIcon: const Icon(Icons.attach_money),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      helperText: 'Örnek: 5.774,89 (API\'den güncel fiyat otomatik doldurulur)',
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.refresh),
                        tooltip: 'Güncel fiyatı yükle',
                        onPressed: () {
                          final suggestedPrice = _getCurrentPriceFromAPI();
                          if (suggestedPrice != null) {
                            setState(() {
                              _purchasePriceController.text = PriceParser.formatTurkishPrice(suggestedPrice);
                            });
                          }
                        },
                      ),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Lütfen alış fiyatını girin';
                      }
                      final parsed = PriceParser.parseTurkishPrice(value);
                      if (parsed == null || parsed <= 0) {
                        return 'Geçerli bir fiyat girin';
                      }
                      return null;
                    },
                  );
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationController,
                decoration: InputDecoration(
                  labelText: 'Kuyumcu / Yer (Opsiyonel)',
                  prefixIcon: const Icon(Icons.location_on),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: InputDecoration(
                  labelText: 'Notlar (Opsiyonel)',
                  prefixIcon: const Icon(Icons.note),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _savePurchase,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Kaydet',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

