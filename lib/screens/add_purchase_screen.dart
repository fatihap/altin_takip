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

  @override
  void dispose() {
    _amountController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
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

  double? _calculatePricePerGram(String goldType, double satisPrice) {
    switch (goldType) {
      case 'Gram Altın':
      case 'Gram Has Altın':
        return satisPrice;
      case 'Çeyrek Altın':
        return satisPrice / 1.754;
      case 'Yarım Altın':
        return satisPrice / 3.508;
      case 'Tam Altın':
        return satisPrice / 7.016;
      case 'Cumhuriyet Altını':
        return satisPrice / 7.216;
      case 'Ata Altın':
        return satisPrice / 7.216;
      case 'Ons Altın':
        return satisPrice / 31.1035;
      case 'Gümüş':
        return satisPrice;
      default:
        return satisPrice / 7.0;
    }
  }

  double? _getCurrentPricePerGram() {
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
      // Eşleşme bulunamadı, ilk fiyatı kullan
      matchingPrice = goldProvider.goldPrices.first;
    }

    if (matchingPrice == null) return null;
    
    final satisPrice = PriceParser.parseTurkishPrice(matchingPrice.satis);
    if (satisPrice == null) return null;
    
    return _calculatePricePerGram(_selectedGoldType, satisPrice);
  }

  Future<void> _savePurchase() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Güncel fiyatı al
    final pricePerGram = _getCurrentPricePerGram();

    final purchase = GoldPurchase(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      goldType: _selectedGoldType,
      amount: double.parse(_amountController.text.replaceAll(',', '.')),
      purchaseDate: _selectedDate,
      location: _locationController.text.trim(),
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
              : 'Altın alış kaydı eklendi! (Fiyat bilgisi alınamadı)'),
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
                  }
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: 'Miktar (Gram)',
                  prefixIcon: const Icon(Icons.scale),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
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
              TextFormField(
                controller: _locationController,
                decoration: InputDecoration(
                  labelText: 'Kuyumcu / Yer',
                  prefixIcon: const Icon(Icons.location_on),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen yer bilgisini girin';
                  }
                  return null;
                },
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

