import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/gold_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/gold_price_card.dart';
import '../widgets/loading_widget.dart';
import '../widgets/error_widget.dart';
import 'purchase_list_screen.dart';
import 'add_purchase_screen.dart';
import 'login_screen.dart';

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
      context.read<GoldProvider>().fetchGoldPrices();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Altın Takip',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.amber[700],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<GoldProvider>().fetchGoldPrices();
            },
            tooltip: 'Yenile',
          ),
          IconButton(
            icon: const Icon(Icons.list),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PurchaseListScreen()),
              );
            },
            tooltip: 'Alış Kayıtları',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) async {
              if (value == 'logout') {
                await context.read<AuthProvider>().logout();
                if (mounted) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                  );
                }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Çıkış Yap'),
                  ],
                ),
              ),
            ],
          ),
        ],
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddPurchaseScreen()),
          );
        },
        backgroundColor: Colors.amber[700],
        icon: const Icon(Icons.add),
        label: const Text('Altın Alış Ekle'),
      ),
    );
  }
}

