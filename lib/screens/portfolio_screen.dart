import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/asset_provider.dart';
import '../providers/purchase_provider.dart';
import '../providers/gold_provider.dart';
import '../services/storage_service.dart';
import '../widgets/asset_card.dart';
import '../widgets/loading_widget.dart';
import 'add_purchase_screen.dart';

class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({super.key});

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> {
  final StorageService _storageService = StorageService();
  bool _isAuthenticated = false;
  bool _isCheckingAuth = true;

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
    // Eğer iptal edildiyse veya dialog kapatıldıysa, sadece geri dön
    // Kullanıcı tekrar portföyü açmak isterse tekrar şifre isteyecek
  }

  Future<void> _loadData() async {
    final goldProvider = context.read<GoldProvider>();
    final purchaseProvider = context.read<PurchaseProvider>();
    final assetProvider = context.read<AssetProvider>();

    if (goldProvider.goldPrices.isEmpty) {
      await goldProvider.fetchGoldPrices();
    }
    if (purchaseProvider.purchases.isEmpty) {
      await purchaseProvider.loadPurchases();
    }

    assetProvider.calculateAssets(
      purchaseProvider.purchases,
      goldProvider.goldPrices,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingAuth) {
      return const Scaffold(
        backgroundColor: Colors.grey,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!_isAuthenticated) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text('Portföy'),
          backgroundColor: Colors.grey[50],
          elevation: 0,
        ),
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
      appBar: AppBar(
        title: const Text(
          'Portföy',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: Colors.grey[50],
        elevation: 0,
      ),
      body: Consumer3<GoldProvider, PurchaseProvider, AssetProvider>(
        builder:
            (context, goldProvider, purchaseProvider, assetProvider, child) {
              if (goldProvider.isLoading && assetProvider.assets.isEmpty) {
                return const LoadingWidget(message: 'Portföy yükleniyor...');
              }

              if (assetProvider.assets.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.account_balance_wallet_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Henüz portföy kaydı yok',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: _loadData,
                child: ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: assetProvider.assets.length,
                  itemBuilder: (context, index) {
                    return AssetCard(asset: assetProvider.assets[index]);
                  },
                ),
              );
            },
      ),
    );
  }
}
