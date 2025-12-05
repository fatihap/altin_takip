import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/purchase_provider.dart';
import '../providers/gold_provider.dart';
import '../models/gold_purchase.dart';
import '../models/gold_price.dart';
import '../utils/price_parser.dart';

class EditPurchaseScreen extends StatefulWidget {
  final GoldPurchase purchase;

  const EditPurchaseScreen({super.key, required this.purchase});

  @override
  State<EditPurchaseScreen> createState() => _EditPurchaseScreenState();
}

class _EditPurchaseScreenState extends State<EditPurchaseScreen> {
  late final GlobalKey<FormState> _formKey;
  late final TextEditingController _amountController;
  late final TextEditingController _purchasePriceController;
  late final TextEditingController _locationController;
  late final TextEditingController _notesController;

  late String _selectedGoldType;
  late DateTime _selectedDate;

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
  void initState() {
    super.initState();
    _formKey = GlobalKey<FormState>();
    _selectedGoldType = widget.purchase.goldType;
    _selectedDate = widget.purchase.purchaseDate;

    _amountController = TextEditingController(
      text: widget.purchase.amount.toStringAsFixed(
        widget.purchase.unit == 'adet' ? 0 : 2,
      ),
    );
    _purchasePriceController = TextEditingController(
      text: widget.purchase.purchasePricePerGram != null
          ? PriceParser.formatTurkishPrice(
              widget.purchase.purchasePricePerGram!,
            )
          : '',
    );
    _locationController = TextEditingController(
      text: widget.purchase.location ?? '',
    );
    _notesController = TextEditingController(text: widget.purchase.notes ?? '');
  }

  @override
  void dispose() {
    _amountController.dispose();
    _purchasePriceController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

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
        (price) => searchTerms.any(
          (term) =>
              price.name.toLowerCase().contains(term.toLowerCase()) ||
              term.toLowerCase().contains(price.name.toLowerCase()),
        ),
      );
    } catch (e) {
      return null;
    }

    if (matchingPrice == null) return null;
    final satisPrice = PriceParser.parseTurkishPrice(matchingPrice.satis);
    return satisPrice;
  }

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

  double? _convertToPricePerGram(double price) {
    switch (_selectedGoldType) {
      case 'Gram Altın':
      case 'Gram Has Altın':
      case 'Gümüş':
        return price;
      case 'Çeyrek Altın':
        return price / 1.754;
      case 'Yarım Altın':
        return price / 3.508;
      case 'Tam Altın':
        return price / 7.016;
      case 'Cumhuriyet Altını':
      case 'Ata Altın':
        return price / 7.216;
      case 'Ons Altın':
        return price / 31.1035;
      default:
        return price / 7.0;
    }
  }

  Future<void> _updatePurchase() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    double? purchasePrice;
    if (_purchasePriceController.text.isNotEmpty) {
      purchasePrice = PriceParser.parseTurkishPrice(
        _purchasePriceController.text,
      );
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
      purchasePrice = _getCurrentPriceFromAPI();
    }

    double? pricePerGram;
    if (purchasePrice != null) {
      pricePerGram = _convertToPricePerGram(purchasePrice);
    }

    final updatedPurchase = GoldPurchase(
      id: widget.purchase.id,
      goldType: _selectedGoldType,
      amount: double.parse(_amountController.text.replaceAll(',', '.')),
      purchaseDate: _selectedDate,
      location: _locationController.text.trim().isEmpty
          ? null
          : _locationController.text.trim(),
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      purchasePricePerGram: pricePerGram,
    );

    final purchaseProvider = context.read<PurchaseProvider>();
    await purchaseProvider.updatePurchase(updatedPurchase);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Alış kaydı güncellendi!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Alış Kaydını Düzenle')),
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
                  return DropdownMenuItem(value: type, child: Text(type));
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
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
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
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.refresh),
                        tooltip: 'Güncel fiyatı yükle',
                        onPressed: () {
                          final suggestedPrice = _getCurrentPriceFromAPI();
                          if (suggestedPrice != null) {
                            setState(() {
                              _purchasePriceController.text =
                                  PriceParser.formatTurkishPrice(
                                    suggestedPrice,
                                  );
                            });
                          }
                        },
                      ),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
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
              ElevatedButton.icon(
                onPressed: _updatePurchase,
                icon: const Icon(Icons.check_rounded),
                label: const Text('Güncelle'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
