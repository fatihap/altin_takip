import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/gold_asset.dart';

class AssetCard extends StatelessWidget {
  final GoldAsset asset;

  const AssetCard({
    super.key,
    required this.asset,
  });

  String _formatCurrency(double? value) {
    if (value == null) return 'Hesaplanamadı';
    final formatter = NumberFormat.currency(
      locale: 'tr_TR',
      symbol: '₺',
      decimalDigits: 2,
    );
    return formatter.format(value);
  }

  String _formatPercentage(double? value) {
    if (value == null) return '0%';
    return '${value >= 0 ? '+' : ''}${value.toStringAsFixed(2)}%';
  }

  @override
  Widget build(BuildContext context) {
    final isProfit = asset.isProfit;
    final profitLoss = asset.profitLoss;
    final profitLossPercent = asset.profitLossPercentage;
    final currentValue = asset.totalCurrentValue;
    final purchaseValue = asset.totalPurchaseValue;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Başlık - Altın türü ve miktar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD4AF37).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.account_balance_wallet_rounded,
                              color: Color(0xFFD4AF37),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              asset.purchase.goldType,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A1A1A),
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.only(left: 44),
                        child: Text(
                          '${asset.purchase.amount.toStringAsFixed(asset.purchase.unit == 'adet' ? 0 : 2)} ${asset.purchase.unit}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (asset.currentPrice != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isProfit
                            ? [
                                Colors.green[50]!,
                                Colors.green[100]!,
                              ]
                            : [
                                Colors.red[50]!,
                                Colors.red[100]!,
                              ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isProfit ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                          size: 18,
                          color: isProfit ? Colors.green[700] : Colors.red[700],
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _formatPercentage(profitLossPercent),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isProfit ? Colors.green[700] : Colors.red[700],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            // Değer bilgileri
            Row(
              children: [
                Expanded(
                  child: _buildValueColumn(
                    'Alış Değeri',
                    _formatCurrency(purchaseValue),
                    const Color(0xFF3B82F6),
                    Icons.shopping_cart_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildValueColumn(
                    'Güncel Değer',
                    _formatCurrency(currentValue),
                    const Color(0xFF10B981),
                    Icons.trending_up_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Kar/Zarar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isProfit
                      ? [
                          Colors.green[50]!,
                          Colors.green[100]!,
                        ]
                      : [
                          Colors.red[50]!,
                          Colors.red[100]!,
                        ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: (isProfit ? Colors.green : Colors.red)[700]!.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          isProfit ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                          size: 18,
                          color: isProfit ? Colors.green[700] : Colors.red[700],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        isProfit ? 'Kar' : 'Zarar',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isProfit ? Colors.green[700] : Colors.red[700],
                        ),
                      ),
                    ],
                  ),
                  Text(
                    _formatCurrency(profitLoss),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isProfit ? Colors.green[700] : Colors.red[700],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Tarih ve yer bilgisi
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.calendar_today_rounded, size: 14, color: Colors.grey[700]),
                ),
                const SizedBox(width: 8),
                Text(
                  DateFormat('dd MMMM yyyy', 'tr_TR').format(asset.purchase.purchaseDate),
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (asset.purchase.location != null && asset.purchase.location!.isNotEmpty) ...[
                  const SizedBox(width: 16),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.location_on_rounded, size: 14, color: Colors.grey[700]),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      asset.purchase.location!,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildValueColumn(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
