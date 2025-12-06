import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/asset_provider.dart';
import '../providers/purchase_provider.dart';
import '../providers/gold_provider.dart';
import '../models/gold_asset.dart';
import '../widgets/loading_widget.dart';
import '../widgets/standard_app_bar.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String _selectedPeriod = 'Haftalık';

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

  // Tarih aralığına göre varlıkları filtrele
  List<GoldAsset> _getFilteredAssets(List<GoldAsset> assets) {
    final now = DateTime.now();
    DateTime startDate;

    switch (_selectedPeriod) {
      case 'Haftalık':
        startDate = now.subtract(const Duration(days: 7));
        break;
      case 'Aylık':
        startDate = DateTime(now.year, now.month, 1);
        break;
      case 'Yıllık':
        startDate = DateTime(now.year, 1, 1);
        break;
      default:
        return assets;
    }

    return assets.where((asset) {
      return asset.purchase.purchaseDate.isAfter(startDate) ||
          asset.purchase.purchaseDate.isAtSameMomentAs(startDate);
    }).toList();
  }

  // Kar/zarar hesapla
  Map<String, double> _calculateProfitLoss(List<GoldAsset> assets) {
    double totalPurchase = 0;
    double totalCurrent = 0;

    for (final asset in assets) {
      final purchase = asset.totalPurchaseValue;
      final current = asset.totalCurrentValue;
      if (purchase != null) totalPurchase += purchase;
      if (current != null) totalCurrent += current;
    }

    final profitLoss = totalCurrent - totalPurchase;
    final profitLossPercent = totalPurchase > 0
        ? ((profitLoss / totalPurchase) * 100).toDouble()
        : 0.0;

    return {
      'purchase': totalPurchase,
      'current': totalCurrent,
      'profitLoss': profitLoss,
      'profitLossPercent': profitLossPercent,
    };
  }

  String _formatCurrency(double value) {
    final formatter = NumberFormat.currency(
      locale: 'tr_TR',
      symbol: '₺',
      decimalDigits: 2,
    );
    return formatter.format(value);
  }

  String _formatPercentage(double value) {
    final sign = value >= 0 ? '+' : '';
    return '$sign${value.toStringAsFixed(2)}%';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: const StandardAppBar(title: 'Raporlar'),
      body: Consumer3<GoldProvider, PurchaseProvider, AssetProvider>(
        builder:
            (context, goldProvider, purchaseProvider, assetProvider, child) {
              if (goldProvider.isLoading && assetProvider.assets.isEmpty) {
                return const LoadingWidget(message: 'Raporlar yükleniyor...');
              }

              final filteredAssets = _getFilteredAssets(assetProvider.assets);
              final stats = _calculateProfitLoss(filteredAssets);
              final isProfit = stats['profitLoss']! >= 0;

              return RefreshIndicator(
                onRefresh: _loadData,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Zaman dilimi seçici
                      Container(
                        margin: const EdgeInsets.all(20),
                        padding: const EdgeInsets.all(4),
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
                        child: Row(
                          children: ['Haftalık', 'Aylık', 'Yıllık'].map((
                            period,
                          ) {
                            final isSelected = _selectedPeriod == period;
                            return Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedPeriod = period;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFFD4AF37)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    period,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.grey[600],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),

                      // Özet kartı
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
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
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFFD4AF37,
                                    ).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.assessment_rounded,
                                    color: Color(0xFFD4AF37),
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '$_selectedPeriod Rapor',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1A1A1A),
                                        ),
                                      ),
                                      Text(
                                        DateFormat(
                                          'dd MMMM yyyy',
                                          'tr_TR',
                                        ).format(DateTime.now()),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            // Kar/Zarar
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: isProfit
                                    ? Colors.green[50]
                                    : Colors.red[50],
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        isProfit
                                            ? 'Toplam Kar'
                                            : 'Toplam Zarar',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[700],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Icon(
                                            isProfit
                                                ? Icons.trending_up_rounded
                                                : Icons.trending_down_rounded,
                                            color: isProfit
                                                ? Colors.green[700]
                                                : Colors.red[700],
                                            size: 24,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            _formatCurrency(
                                              stats['profitLoss']!,
                                            ),
                                            style: TextStyle(
                                              fontSize: 28,
                                              fontWeight: FontWeight.bold,
                                              color: isProfit
                                                  ? Colors.green[700]
                                                  : Colors.red[700],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _formatPercentage(
                                          stats['profitLossPercent']!,
                                        ),
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: isProfit
                                              ? Colors.green[700]
                                              : Colors.red[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            // Detaylar
                            Row(
                              children: [
                                Expanded(
                                  child: _buildStatCard(
                                    'Toplam Alış',
                                    _formatCurrency(stats['purchase']!),
                                    Icons.shopping_cart_rounded,
                                    Colors.blue,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildStatCard(
                                    'Güncel Değer',
                                    _formatCurrency(stats['current']!),
                                    Icons.account_balance_wallet_rounded,
                                    const Color(0xFFD4AF37),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // İşlem sayısı
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.receipt_long_rounded,
                                    color: Colors.grey[700],
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Toplam İşlem: ${filteredAssets.length}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[700],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              );
            },
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
