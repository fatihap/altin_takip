import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/gold_provider.dart';
import '../providers/purchase_provider.dart';
import '../providers/asset_provider.dart';
import '../services/storage_service.dart';
import '../widgets/loading_widget.dart';
import '../widgets/error_widget.dart';
import '../widgets/total_asset_summary.dart';
import '../widgets/asset_card.dart';
import 'add_purchase_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final StorageService _storageService = StorageService();
  bool _isAuthenticated = false;
  bool _isCheckingAuth = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPasswordAndLoad();
    });
  }

  Future<void> _checkPasswordAndLoad() async {
    final isPasswordEnabled = await _storageService.isAssetPasswordEnabled();
    
    if (isPasswordEnabled && !_isAuthenticated) {
      setState(() {
        _isCheckingAuth = false;
      });
      await _showPasswordDialog();
    } else {
      setState(() {
        _isAuthenticated = true;
        _isCheckingAuth = false;
      });
      _loadData();
    }
  }

  Future<void> _showPasswordDialog() async {
    final passwordController = TextEditingController();
    
    if (!mounted) return;
    
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Varlık Görüntüleme',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: passwordController,
          obscureText: true,
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'Şifre',
            prefixIcon: const Icon(Icons.lock_rounded),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onSubmitted: (value) {
            if (value.isNotEmpty) {
              Navigator.pop(context, true);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (passwordController.text.isNotEmpty) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('Giriş Yap'),
          ),
        ],
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
        _checkPasswordAndLoad();
      }
    } else if (mounted) {
      _checkPasswordAndLoad();
    }
  }

  Future<void> _loadData() async {
    final goldProvider = context.read<GoldProvider>();
    final purchaseProvider = context.read<PurchaseProvider>();
    final assetProvider = context.read<AssetProvider>();

    // Altın fiyatlarını yükle
    await goldProvider.fetchGoldPrices();

    // Alış kayıtlarını yükle
    await purchaseProvider.loadPurchases();

    // Varlıkları hesapla
    assetProvider.calculateAssets(
      purchaseProvider.purchases,
      goldProvider.goldPrices,
    );
  }

  Future<void> _refreshData() async {
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingAuth) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!_isAuthenticated) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Varlıklarım'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_rounded,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'Varlıkları görüntülemek için şifre gerekli',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _checkPasswordAndLoad,
                icon: const Icon(Icons.lock_open_rounded),
                label: const Text('Şifre ile Giriş Yap'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Varlıklarım'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _refreshData,
            tooltip: 'Yenile',
          ),
        ],
      ),
      body: Consumer3<GoldProvider, PurchaseProvider, AssetProvider>(
        builder: (context, goldProvider, purchaseProvider, assetProvider, child) {
          // Altın fiyatları yükleniyor mu kontrol et
          if (goldProvider.isLoading && assetProvider.assets.isEmpty) {
            return const LoadingWidget(message: 'Veriler yükleniyor...');
          }

          // Altın fiyatları hatası var mı kontrol et
          if (goldProvider.error != null && assetProvider.assets.isEmpty) {
            return ErrorDisplayWidget(
              message: goldProvider.error!,
              onRetry: _refreshData,
            );
          }

          // Varlık yoksa
          if (assetProvider.assets.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refreshData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height - 200,
                  child: Center(
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
                          'Henüz varlık kaydı yok',
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
                        const SizedBox(height: 32),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AddPurchaseScreen(),
                              ),
                            ).then((_) => _refreshData());
                          },
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('İlk Alış Kaydını Ekle'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }

          // Varlıklar var, göster
          return RefreshIndicator(
            onRefresh: _refreshData,
            child: Column(
              children: [
                // Toplam varlık özeti
                TotalAssetSummary(
                  totalCurrentValue: assetProvider.totalCurrentValue,
                  totalPurchaseValue: assetProvider.totalPurchaseValue,
                  totalProfitLoss: assetProvider.totalProfitLoss,
                  totalProfitLossPercentage: assetProvider.totalProfitLossPercentage,
                ),
                // Varlık listesi
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 80),
                    itemCount: assetProvider.assets.length,
                    itemBuilder: (context, index) {
                      return AssetCard(
                        asset: assetProvider.assets[index],
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddPurchaseScreen()),
          ).then((_) => _refreshData());
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Altın Alış Ekle'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
