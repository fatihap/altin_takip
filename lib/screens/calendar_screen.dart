import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../providers/purchase_provider.dart';
import '../models/gold_purchase.dart';
import '../widgets/standard_app_bar.dart';
import 'add_purchase_screen.dart';

// isSameDay fonksiyonu için
bool isSameDay(DateTime? a, DateTime? b) {
  if (a == null || b == null) return false;
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _focusedDay;
  late DateTime _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PurchaseProvider>().loadPurchases();
    });
  }

  // Altın alınan günleri al
  Set<DateTime> _getPurchaseDates(List<GoldPurchase> purchases) {
    return purchases.map((purchase) {
      return DateTime(
        purchase.purchaseDate.year,
        purchase.purchaseDate.month,
        purchase.purchaseDate.day,
      );
    }).toSet();
  }

  // Seçilen günün alışlarını al
  List<GoldPurchase> _getPurchasesForDay(DateTime day, List<GoldPurchase> purchases) {
    return purchases.where((purchase) {
      final purchaseDate = purchase.purchaseDate;
      return purchaseDate.year == day.year &&
          purchaseDate.month == day.month &&
          purchaseDate.day == day.day;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const StandardAppBar(title: 'Alış Takvimi'),
      body: Consumer<PurchaseProvider>(
        builder: (context, purchaseProvider, child) {
          final purchases = purchaseProvider.purchases;
          final purchaseDates = _getPurchaseDates(purchases);
          final selectedDayPurchases = _getPurchasesForDay(_selectedDay, purchases);

          return Column(
            children: [
              // Takvim
              TableCalendar<GoldPurchase>(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) {
                  return isSameDay(_selectedDay, day);
                },
                calendarFormat: _calendarFormat,
                onFormatChanged: (format) {
                  setState(() {
                    _calendarFormat = format;
                  });
                },
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                  
                  // Seçilen güne tıklanınca AddPurchaseScreen'e yönlendir
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddPurchaseScreen(
                        initialDate: selectedDay,
                      ),
                    ),
                  ).then((_) {
                    // Geri dönünce alışları yeniden yükle
                    context.read<PurchaseProvider>().loadPurchases();
                  });
                },
                onPageChanged: (focusedDay) {
                  _focusedDay = focusedDay;
                },
                eventLoader: (day) {
                  return _getPurchasesForDay(day, purchases);
                },
                calendarStyle: CalendarStyle(
                  todayDecoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                  markerDecoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                  // Altın alınan günleri yeşil göster
                  outsideDaysVisible: false,
                ),
                // Altın alınan günleri özel stil ile göster
                calendarBuilders: CalendarBuilders(
                  defaultBuilder: (context, date, _) {
                    final dateOnly = DateTime(date.year, date.month, date.day);
                    final hasPurchase = purchaseDates.contains(dateOnly);
                    
                    if (hasPurchase) {
                      return Container(
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.3),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.green,
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '${date.day}',
                            style: const TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    }
                    return null;
                  },
                  todayBuilder: (context, date, _) {
                    final dateOnly = DateTime(date.year, date.month, date.day);
                    final hasPurchase = purchaseDates.contains(dateOnly);
                    
                    if (hasPurchase) {
                      return Container(
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.5),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.green,
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '${date.day}',
                            style: const TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    }
                    return null;
                  },
                  selectedBuilder: (context, date, _) {
                    final dateOnly = DateTime(date.year, date.month, date.day);
                    final hasPurchase = purchaseDates.contains(dateOnly);
                    
                    if (hasPurchase) {
                      return Container(
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.green.shade700,
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '${date.day}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    }
                    return null;
                  },
                ),
                headerStyle: HeaderStyle(
                  formatButtonVisible: true,
                  titleCentered: true,
                  formatButtonShowsNext: false,
                  formatButtonDecoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  formatButtonTextStyle: const TextStyle(
                    color: Colors.white,
                  ),
                ),
                locale: 'tr_TR',
              ),
              const Divider(),
              // Seçilen günün alışları
              Expanded(
                child: selectedDayPurchases.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.calendar_today_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              DateFormat('d MMMM yyyy', 'tr_TR').format(_selectedDay),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Bu günde altın alışı yok',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.shopping_cart,
                                  color: Colors.green[700],
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  DateFormat('d MMMM yyyy', 'tr_TR').format(_selectedDay),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${selectedDayPurchases.length} alış',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.green[700],
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: selectedDayPurchases.length,
                              itemBuilder: (context, index) {
                                final purchase = selectedDayPurchases[index];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  elevation: 2,
                                  child: ListTile(
                                    leading: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.monetization_on,
                                        color: Colors.green[700],
                                      ),
                                    ),
                                    title: Text(
                                      purchase.goldType,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 4),
                                        Text(
                                          'Miktar: ${purchase.amount.toStringAsFixed(2)} ${purchase.unit}',
                                        ),
                                        if (purchase.purchasePricePerGram != null)
                                          Text(
                                            'Alış Fiyatı: ${purchase.purchasePricePerGram!.toStringAsFixed(2)} ₺/gram',
                                          ),
                                        if (purchase.location != null)
                                          Text(
                                            'Konum: ${purchase.location}',
                                          ),
                                        if (purchase.notes != null)
                                          Text(
                                            'Not: ${purchase.notes}',
                                            style: TextStyle(
                                              fontStyle: FontStyle.italic,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                      ],
                                    ),
                                    isThreeLine: true,
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

