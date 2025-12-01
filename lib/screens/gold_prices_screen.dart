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
                    margin: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4AF37).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.update_rounded,
                          size: 16,
                          color: Colors.grey[700],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Son Güncelleme: ${provider.updateDate}',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 20),
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

