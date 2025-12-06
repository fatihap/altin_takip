import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/asset_provider.dart';
import '../providers/purchase_provider.dart';
import '../providers/gold_provider.dart';
import '../providers/exchange_rate_provider.dart';
import '../services/storage_service.dart';
import '../widgets/enhanced_asset_card.dart';
import '../widgets/standard_app_bar.dart';
import '../widgets/loading_widget.dart';
import '../models/gold_asset.dart';
import 'add_purchase_screen.dart';
import 'edit_purchase_screen.dart';

class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({super.key});

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> {
  final StorageService _storageService = StorageService();
  bool _isAuthenticated = false;
  bool _isCheckingAuth = true;

  // Filtre ve arama
  String _searchQuery = '';
  String _selectedFilter = 'Tümü'; // Tümü, Kar, Zarar
  String _selectedSort =
      'Tarih (Yeni)'; // Tarih (Yeni), Tarih (Eski), Değer (Yüksek), Değer (Düşük)
  String? _selectedGoldType;
  bool _showFilters = false;

  final List<String> _filterOptions = ['Tümü', 'Kar', 'Zarar'];
  final List<String> _sortOptions = [
    'Tarih (Yeni)',
    'Tarih (Eski)',
    'Değer (Yüksek)',
    'Değer (Düşük)',
    'Kar/Zarar (Yüksek)',
    'Kar/Zarar (Düşük)',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeScreen();
    });
  }

  Future<void> _initializeScreen() async {
    final isPasswordEnabled = await _storageService.isAssetPasswordEnabled();

    if (isPasswordEnabled) {
      setState(() {
        _isAuthenticated = false;
        _isCheckingAuth = false;
      });
    } else {
      setState(() {
        _isAuthenticated = true;
        _isCheckingAuth = false;
      });
      _loadData();
    }
  }

  Future<void> _checkPasswordAndLoad() async {
    final isPasswordEnabled = await _storageService.isAssetPasswordEnabled();

    if (!isPasswordEnabled) {
      setState(() {
        _isAuthenticated = true;
      });
      _loadData();
      return;
    }

    await _showPasswordDialog();
  }

  Future<void> _showPasswordDialog() async {
    final passwordController = TextEditingController();
    bool obscurePassword = true;

    if (!mounted) return;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFD4AF37).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.lock_rounded,
                  color: Color(0xFFD4AF37),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Portföy Görüntüleme',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              const Text(
                'Portföyünüzü görüntülemek için şifrenizi girin',
                style: TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: passwordController,
                obscureText: obscurePassword,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Şifre',
                  hintText: 'Şifrenizi girin',
                  prefixIcon: const Icon(Icons.lock_rounded),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscurePassword
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                      color: Colors.grey[600],
                    ),
                    onPressed: () {
                      setState(() {
                        obscurePassword = !obscurePassword;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                onSubmitted: (value) {
                  if (value.isNotEmpty) {
                    Navigator.of(dialogContext).pop(true);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () {
                if (passwordController.text.isNotEmpty) {
                  Navigator.of(dialogContext).pop(true);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4AF37),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Giriş Yap'),
            ),
          ],
        ),
      ),
    );

    if (result == true && passwordController.text.isNotEmpty) {
      final isCorrect = await _storageService.checkAssetPassword(
        passwordController.text,
      );

      if (isCorrect && mounted) {
        setState(() {
          _isAuthenticated = true;
        });
        _loadData();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Şifre yanlış'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadData() async {
    final goldProvider = context.read<GoldProvider>();
    final purchaseProvider = context.read<PurchaseProvider>();
    final assetProvider = context.read<AssetProvider>();
    final exchangeRateProvider = context.read<ExchangeRateProvider>();

    if (goldProvider.goldPrices.isEmpty) {
      await goldProvider.fetchGoldPrices();
    }
    if (purchaseProvider.purchases.isEmpty) {
      await purchaseProvider.loadPurchases();
    }
    if (exchangeRateProvider.usdRate == 0.0 ||
        exchangeRateProvider.eurRate == 0.0) {
      await exchangeRateProvider.fetchExchangeRates();
    }

    assetProvider.calculateAssets(
      purchaseProvider.purchases,
      goldProvider.goldPrices,
    );
  }

  // Filtrelenmiş ve sıralanmış varlıkları al
  List<GoldAsset> _getFilteredAndSortedAssets(List<GoldAsset> assets) {
    List<GoldAsset> filtered = assets;

    // Arama filtresi
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((asset) {
        return asset.purchase.goldType.toLowerCase().contains(
          _searchQuery.toLowerCase(),
        );
      }).toList();
    }

    // Kar/Zarar filtresi
    if (_selectedFilter == 'Kar') {
      filtered = filtered.where((asset) => asset.isProfit).toList();
    } else if (_selectedFilter == 'Zarar') {
      filtered = filtered.where((asset) => !asset.isProfit).toList();
    }

    // Altın türü filtresi
    if (_selectedGoldType != null && _selectedGoldType!.isNotEmpty) {
      filtered = filtered.where((asset) {
        return asset.purchase.goldType == _selectedGoldType;
      }).toList();
    }

    // Sıralama
    switch (_selectedSort) {
      case 'Tarih (Yeni)':
        filtered.sort(
          (a, b) => b.purchase.purchaseDate.compareTo(a.purchase.purchaseDate),
        );
        break;
      case 'Tarih (Eski)':
        filtered.sort(
          (a, b) => a.purchase.purchaseDate.compareTo(b.purchase.purchaseDate),
        );
        break;
      case 'Değer (Yüksek)':
        filtered.sort((a, b) {
          final aVal = a.totalCurrentValue ?? 0;
          final bVal = b.totalCurrentValue ?? 0;
          return bVal.compareTo(aVal);
        });
        break;
      case 'Değer (Düşük)':
        filtered.sort((a, b) {
          final aVal = a.totalCurrentValue ?? 0;
          final bVal = b.totalCurrentValue ?? 0;
          return aVal.compareTo(bVal);
        });
        break;
      case 'Kar/Zarar (Yüksek)':
        filtered.sort((a, b) {
          final aVal = a.profitLoss ?? 0;
          final bVal = b.profitLoss ?? 0;
          return bVal.compareTo(aVal);
        });
        break;
      case 'Kar/Zarar (Düşük)':
        filtered.sort((a, b) {
          final aVal = a.profitLoss ?? 0;
          final bVal = b.profitLoss ?? 0;
          return aVal.compareTo(bVal);
        });
        break;
    }

    return filtered;
  }

  // Benzersiz altın türlerini al
  List<String> _getUniqueGoldTypes(List<GoldAsset> assets) {
    final types = assets.map((a) => a.purchase.goldType).toSet().toList();
    types.sort();
    return types;
  }

  String _formatCurrency(double value) {
    final formatter = NumberFormat.currency(
      locale: 'tr_TR',
      symbol: '₺',
      decimalDigits: 2,
    );
    return formatter.format(value);
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingAuth) {
      return const Scaffold(
        backgroundColor: Colors.blueGrey,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!_isAuthenticated) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: const StandardAppBar(title: 'Portföy'),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFD4AF37).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_rounded,
                  size: 64,
                  color: Color(0xFFD4AF37),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Portföyü görüntülemek için şifre gerekli',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Portföyünüzü görmek için şifrenizi girin',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _checkPasswordAndLoad,
                icon: const Icon(Icons.lock_open_rounded),
                label: const Text('Şifre ile Giriş Yap'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD4AF37),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Consumer3<GoldProvider, PurchaseProvider, AssetProvider>(
        builder:
            (context, goldProvider, purchaseProvider, assetProvider, child) {
              if (goldProvider.isLoading && assetProvider.assets.isEmpty) {
                return const Scaffold(
                  body: LoadingWidget(message: 'Portföy yükleniyor...'),
                );
              }

              if (assetProvider.assets.isEmpty) {
                return Scaffold(
                  backgroundColor: Colors.grey[50],
                  appBar: const StandardAppBar(title: 'Portföy'),
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD4AF37).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.account_balance_wallet_outlined,
                            size: 64,
                            color: Color(0xFFD4AF37),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Henüz portföy kaydı yok',
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Altın alış kaydı ekleyerek başlayın',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final filteredAssets = _getFilteredAndSortedAssets(
                assetProvider.assets,
              );
              final uniqueTypes = _getUniqueGoldTypes(assetProvider.assets);

              // Toplam değerleri hesapla
              double totalValue = 0;
              double totalProfit = 0;
              for (final asset in filteredAssets) {
                if (asset.totalCurrentValue != null) {
                  totalValue += asset.totalCurrentValue!;
                }
                if (asset.profitLoss != null) {
                  totalProfit += asset.profitLoss!;
                }
              }

              return CustomScrollView(
                slivers: [
                  // AppBar
                  SliverAppBar(
                    expandedHeight: 0,
                    floating: true,
                    pinned: false,
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    flexibleSpace: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFFD4AF37),
                            const Color(0xFFC9A227),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFD4AF37).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                    title: const Text(
                      'Portföy',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 22,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                    iconTheme: const IconThemeData(
                      color: Colors.white,
                      size: 24,
                    ),
                    actions: [
                      IconButton(
                        icon: Icon(
                          _showFilters
                              ? Icons.filter_alt
                              : Icons.filter_alt_outlined,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          setState(() {
                            _showFilters = !_showFilters;
                          });
                        },
                        tooltip: 'Filtreler',
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh_rounded),
                        color: Colors.white,
                        onPressed: _loadData,
                        tooltip: 'Yenile',
                      ),
                    ],
                  ),

                  // Özet kartı
                  SliverToBoxAdapter(
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFFD4AF37).withOpacity(0.2),
                            const Color(0xFFD4AF37).withOpacity(0.1),
                            Colors.white,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFD4AF37).withOpacity(0.15),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Başlık
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.white.withOpacity(0.9),
                                        Colors.white.withOpacity(0.7),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.account_balance_wallet_rounded,
                                    color: Color(0xFFD4AF37),
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Toplam Portföy',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey[700],
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        _formatCurrency(totalValue),
                                        style: const TextStyle(
                                          fontSize: 28,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1A1A1A),
                                          letterSpacing: -0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            // Kar/Zarar kartı
                            if (totalProfit != 0)
                              Container(
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: totalProfit > 0
                                        ? [
                                            Colors.green[400]!,
                                            Colors.green[500]!,
                                          ]
                                        : [Colors.red[400]!, Colors.red[500]!],
                                  ),
                                  borderRadius: BorderRadius.circular(18),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          (totalProfit > 0
                                                  ? Colors.green
                                                  : Colors.red)
                                              .withOpacity(0.3),
                                      blurRadius: 12,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(
                                              0.25,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Icon(
                                            totalProfit > 0
                                                ? Icons.trending_up_rounded
                                                : Icons.trending_down_rounded,
                                            color: Colors.white,
                                            size: 24,
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              totalProfit > 0
                                                  ? 'Toplam Kar'
                                                  : 'Toplam Zarar',
                                              style: const TextStyle(
                                                fontSize: 13,
                                                color: Colors.white70,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              _formatCurrency(totalProfit),
                                              style: const TextStyle(
                                                fontSize: 22,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                                letterSpacing: -0.5,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    Icon(
                                      totalProfit > 0
                                          ? Icons.arrow_upward_rounded
                                          : Icons.arrow_downward_rounded,
                                      color: Colors.white.withOpacity(0.9),
                                      size: 28,
                                    ),
                                  ],
                                ),
                              )
                            else
                              Container(
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[400],
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.remove_rounded,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    const Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Kar/Zarar Yok',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.black54,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            'Portföy değeri değişmedi',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            const SizedBox(height: 20),
                            // Döviz Kurları
                            Consumer<ExchangeRateProvider>(
                              builder: (context, exchangeProvider, child) {
                                final usdRate = exchangeProvider.usdRate;
                                final eurRate = exchangeProvider.eurRate;

                                if (usdRate == 0.0 && eurRate == 0.0) {
                                  return const SizedBox.shrink();
                                }

                                return Row(
                                  children: [
                                    Expanded(
                                      child: _buildExchangeRateCard(
                                        'USD',
                                        usdRate,
                                        totalValue,
                                        Icons.attach_money_rounded,
                                        Colors.green,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildExchangeRateCard(
                                        'EUR',
                                        eurRate,
                                        totalValue,
                                        Icons.euro_rounded,
                                        Colors.blue,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Arama ve filtreler
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        // Arama kutusu
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 20),
                          child: TextField(
                            onChanged: (value) {
                              setState(() {
                                _searchQuery = value;
                              });
                            },
                            decoration: InputDecoration(
                              hintText: 'Altın türü ara...',
                              prefixIcon: const Icon(Icons.search_rounded),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear_rounded),
                                      onPressed: () {
                                        setState(() {
                                          _searchQuery = '';
                                        });
                                      },
                                    )
                                  : null,
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),

                        // Filtreler (açılır/kapanır)
                        if (_showFilters) ...[
                          const SizedBox(height: 12),
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 20),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.tune_rounded,
                                      color: Color(0xFFD4AF37),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Filtreler',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                // Kar/Zarar filtresi
                                _buildFilterSection(
                                  'Durum',
                                  _filterOptions,
                                  _selectedFilter,
                                  (value) {
                                    setState(() {
                                      _selectedFilter = value;
                                    });
                                  },
                                ),
                                const SizedBox(height: 16),
                                // Altın türü filtresi
                                _buildGoldTypeFilter(uniqueTypes),
                                const SizedBox(height: 16),
                                // Sıralama
                                _buildFilterSection(
                                  'Sıralama',
                                  _sortOptions,
                                  _selectedSort,
                                  (value) {
                                    setState(() {
                                      _selectedSort = value;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),

                  // Varlık listesi
                  if (filteredAssets.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off_rounded,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Sonuç bulunamadı',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Filtreleri değiştirerek tekrar deneyin',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          return EnhancedAssetCard(
                            asset: filteredAssets[index],
                          );
                        }, childCount: filteredAssets.length),
                      ),
                    ),

                  const SliverToBoxAdapter(child: SizedBox(height: 20)),
                ],
              );
            },
      ),
    );
  }

  Widget _buildExchangeRateCard(
    String currency,
    double rate,
    double totalValue,
    IconData icon,
    Color color,
  ) {
    if (rate == 0.0) {
      return const SizedBox.shrink();
    }

    final convertedValue = totalValue / rate;
    final formatter = NumberFormat.currency(
      locale: 'tr_TR',
      symbol: currency == 'USD' ? '\$' : '€',
      decimalDigits: 2,
    );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withOpacity(0.15), color.withOpacity(0.08)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 8),
              Text(
                currency,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            formatter.format(convertedValue),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Kur: ${_formatCurrency(rate)}',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection(
    String title,
    List<String> options,
    String selected,
    Function(String) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final isSelected = selected == option;
            return GestureDetector(
              onTap: () => onChanged(option),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFFD4AF37)
                      : Colors.grey[100],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFFD4AF37)
                        : Colors.grey[300]!,
                    width: 1,
                  ),
                ),
                child: Text(
                  option,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : Colors.grey[700],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildGoldTypeFilter(List<String> types) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Altın Türü',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
            ),
            if (_selectedGoldType != null)
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedGoldType = null;
                  });
                },
                child: const Text('Temizle', style: TextStyle(fontSize: 12)),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            GestureDetector(
              onTap: () {
                setState(() {
                  _selectedGoldType = null;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: _selectedGoldType == null
                      ? const Color(0xFFD4AF37)
                      : Colors.grey[100],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _selectedGoldType == null
                        ? const Color(0xFFD4AF37)
                        : Colors.grey[300]!,
                    width: 1,
                  ),
                ),
                child: Text(
                  'Tümü',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _selectedGoldType == null
                        ? Colors.white
                        : Colors.grey[700],
                  ),
                ),
              ),
            ),
            ...types.map((type) {
              final isSelected = _selectedGoldType == type;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedGoldType = isSelected ? null : type;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFD4AF37)
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFFD4AF37)
                          : Colors.grey[300]!,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    type,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : Colors.grey[700],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ],
    );
  }
}
