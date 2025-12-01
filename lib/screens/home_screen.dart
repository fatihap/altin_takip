import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/gold_provider.dart';
import '../providers/purchase_provider.dart';
import '../providers/asset_provider.dart';
import '../widgets/loading_widget.dart';
import '../widgets/error_widget.dart';
import '../widgets/total_asset_summary.dart';
import '../widgets/asset_card.dart';
import 'add_purchase_screen.dart';
import 'gold_prices_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
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
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Varlıklarım',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.amber[700],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
            tooltip: 'Yenile',
          ),
          IconButton(
            icon: const Icon(Icons.trending_up),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const GoldPricesScreen()),
              );
            },
            tooltip: 'Altın Fiyatları',
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
                        Icon(
                          Icons.account_balance_wallet_outlined,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Henüz varlık kaydı yok',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Altın alış kaydı ekleyerek başlayın',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AddPurchaseScreen(),
                              ),
                            ).then((_) => _refreshData());
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('İlk Alış Kaydını Ekle'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber[700],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
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
        backgroundColor: Colors.amber[700],
        icon: const Icon(Icons.add),
        label: const Text('Altın Alış Ekle'),
      ),
    );
  }
}
