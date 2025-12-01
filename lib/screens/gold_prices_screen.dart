import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/gold_provider.dart';
import '../widgets/gold_price_card.dart';
import '../widgets/loading_widget.dart';
import '../widgets/error_widget.dart';

class GoldPricesScreen extends StatefulWidget {
  const GoldPricesScreen({super.key});

  @override
  State<GoldPricesScreen> createState() => _GoldPricesScreenState();
}

class _GoldPricesScreenState extends State<GoldPricesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GoldProvider>().fetchGoldPrices();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Altın Fiyatları'),
        backgroundColor: Colors.amber[700],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Consumer<GoldProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const LoadingWidget(message: 'Altın fiyatları yükleniyor...');
          }

          if (provider.error != null) {
            return ErrorDisplayWidget(
              message: provider.error!,
              onRetry: () {
                provider.fetchGoldPrices();
              },
            );
          }

          if (provider.goldPrices.isEmpty) {
            return const Center(
              child: Text('Altın fiyatı bulunamadı'),
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.fetchGoldPrices(),
            child: Column(
              children: [
                if (provider.updateDate != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    color: Colors.amber[50],
                    child: Text(
                      'Son Güncelleme: ${provider.updateDate}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 12,
                      ),
                    ),
                  ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: provider.goldPrices.length,
                    itemBuilder: (context, index) {
                      return GoldPriceCard(
                        goldPrice: provider.goldPrices[index],
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

