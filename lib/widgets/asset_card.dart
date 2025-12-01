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

    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Başlık - Altın türü ve miktar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        asset.purchase.goldType,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${asset.purchase.amount.toStringAsFixed(asset.purchase.unit == 'adet' ? 0 : 2)} ${asset.purchase.unit}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                if (asset.currentPrice != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isProfit ? Colors.green[50] : Colors.red[50],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isProfit ? Icons.trending_up : Icons.trending_down,
                          size: 16,
                          color: isProfit ? Colors.green[700] : Colors.red[700],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatPercentage(profitLossPercent),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isProfit ? Colors.green[700] : Colors.red[700],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            // Değer bilgileri
            Row(
              children: [
                Expanded(
                  child: _buildValueColumn(
                    'Alış Değeri',
                    _formatCurrency(purchaseValue),
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildValueColumn(
                    'Güncel Değer',
                    _formatCurrency(currentValue),
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Kar/Zarar
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isProfit ? Colors.green[50] : Colors.red[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isProfit ? 'Kar' : 'Zarar',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isProfit ? Colors.green[700] : Colors.red[700],
                    ),
                  ),
                  Text(
                    _formatCurrency(profitLoss),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isProfit ? Colors.green[700] : Colors.red[700],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Tarih ve yer bilgisi
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  DateFormat('dd MMMM yyyy', 'tr_TR').format(asset.purchase.purchaseDate),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                if (asset.purchase.location != null && asset.purchase.location!.isNotEmpty) ...[
                  const SizedBox(width: 16),
                  Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      asset.purchase.location!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
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

  Widget _buildValueColumn(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
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
        ),
      ],
    );
  }
}

