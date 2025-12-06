import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/gold_provider.dart';
import '../providers/purchase_provider.dart';
import '../providers/asset_provider.dart';
import '../services/storage_service.dart';
import '../widgets/loading_widget.dart';
import '../widgets/error_widget.dart';
import '../widgets/simple_total_asset_card.dart';
import '../widgets/asset_chart_widget.dart';
import '../widgets/compact_asset_card.dart';
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
    bool obscurePassword = true;

    if (!mounted) return;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
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
                  'Varlık Görüntüleme',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              const Text(
                'Varlıklarınızı görüntülemek için şifrenizi girin',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
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
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
    // Dialog iptal edildiyse veya kapatıldıysa, sadece geri dön
    // Kullanıcı tekrar ana sayfayı açmak isterse tekrar şifre isteyecek
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
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!_isAuthenticated) {
      return Scaffold(
        appBar: AppBar(title: const Text('Varlıklarım')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_rounded, size: 64, color: Colors.grey[400]),
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
      backgroundColor: Colors.grey[50],
      body: Consumer3<GoldProvider, PurchaseProvider, AssetProvider>(
        builder:
            (context, goldProvider, purchaseProvider, assetProvider, child) {
          // Altın fiyatları yükleniyor mu kontrol et
          if (goldProvider.isLoading && assetProvider.assets.isEmpty) {
            return const Scaffold(
              body: LoadingWidget(message: 'Veriler yükleniyor...'),
            );
          }

          // Altın fiyatları hatası var mı kontrol et
          if (goldProvider.error != null && assetProvider.assets.isEmpty) {
            return Scaffold(
              body: ErrorDisplayWidget(
                message: goldProvider.error!,
                onRetry: _refreshData,
              ),
            );
          }

          // Varlık yoksa
          if (assetProvider.assets.isEmpty) {
            return Scaffold(
              body: RefreshIndicator(
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
                                  builder: (context) =>
                                      const AddPurchaseScreen(),
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
              ),
            );
          }

          // Grafik için örnek veri (gerçek uygulamada geçmiş verilerden gelecek)
          final chartData = List.generate(
            7,
            (index) => assetProvider.totalCurrentValue * (0.95 + (index * 0.01)),
          );

          // Varlıklar var, göster
          return RefreshIndicator(
            onRefresh: _refreshData,
            child: CustomScrollView(
              slivers: [
                // Custom AppBar
                SliverAppBar(
                  expandedHeight: 0,
                  floating: true,
                  pinned: false,
                  backgroundColor: Colors.grey[50],
                  elevation: 0,
                  leading: Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const CircleAvatar(
                      backgroundColor: Colors.blue,
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                  ),
                  title: const Text(
                    'Ana Sayfa',
                    style: TextStyle(
                      color: Color(0xFF1A1A1A),
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  actions: [
                    Container(
                      margin: const EdgeInsets.only(right: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.notifications_outlined),
                        color: const Color(0xFF1A1A1A),
                        onPressed: () {},
                      ),
                    ),
                  ],
                ),
                // Toplam Varlık Kartı
                SliverToBoxAdapter(
                  child: SimpleTotalAssetCard(
                    totalCurrentValue: assetProvider.totalCurrentValue,
                    totalProfitLoss: assetProvider.totalProfitLoss,
                  ),
                ),
                // Grafik
                SliverToBoxAdapter(
                  child: AssetChartWidget(
                    dataPoints: chartData,
                    selectedPeriod: 'Gün',
                  ),
                ),
                // Varlık Kartları Grid
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.85,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index >= assetProvider.assets.length) {
                          return const SizedBox.shrink();
                        }
                        return CompactAssetCard(
                          asset: assetProvider.assets[index],
                        );
                      },
                      childCount: assetProvider.assets.length > 4
                          ? 4
                          : assetProvider.assets.length,
                    ),
                  ),
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: 20),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
