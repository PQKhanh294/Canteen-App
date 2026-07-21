import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/order_model.dart';
import '../../viewmodels/admin_viewmodel.dart';
import '../../widgets/canteen_card.dart';
import '../../widgets/status_badge.dart';

class AdminCustomerScreen extends StatefulWidget {
  const AdminCustomerScreen({super.key});
  @override
  State<AdminCustomerScreen> createState() => _AdminCustomerScreenState();
}

class _AdminCustomerScreenState extends State<AdminCustomerScreen> {
  String query = '';
  late Future<List<CustomerSummary>> customersFuture;

  @override
  void initState() {
    super.initState();
    customersFuture = context.read<AdminViewModel>().loadCustomers();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<CustomerSummary>>(
    future: customersFuture,
    builder: (context, s) {
      if (s.hasError) {
        return Center(child: Text('Không tải được khách hàng: ${s.error}'));
      }
      if (!s.hasData) return const Center(child: CircularProgressIndicator());
      final list = s.data!
          .where(
            (c) => ('${c.user.displayName} ${c.user.email}')
                .toLowerCase()
                .contains(query.toLowerCase()),
          )
          .toList();
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: SearchBar(
              hintText: 'Tìm theo tên hoặc email',
              leading: const Icon(Icons.search),
              onChanged: (v) => setState(() => query = v),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: list.length,
              itemBuilder: (context, i) {
                final c = list[i];
                return CanteenCard(
                  margin: const EdgeInsets.only(bottom: 8),
                  onTap: () => _history(context, c),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundImage: c.user.avatarUrl.isEmpty
                            ? null
                            : CachedNetworkImageProvider(c.user.avatarUrl),
                        child: c.user.avatarUrl.isEmpty
                            ? Text(
                                c.user.displayName.isEmpty
                                    ? '?'
                                    : c.user.displayName[0],
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              c.user.displayName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(c.user.email),
                            Text(
                              '${c.orderCount} đơn · ${NumberFormat.currency(locale: 'vi', symbol: '₫').format(c.totalSpent)}',
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      );
    },
  );
  void _history(BuildContext context, CustomerSummary customer) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (c) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: .8,
        builder: (c, controller) => FutureBuilder<List<OrderModel>>(
          future: context.read<AdminViewModel>().loadCustomerOrders(
            customer.user.uid,
          ),
          builder: (c, s) => Column(
            children: [
              ListTile(
                title: Text(
                  customer.user.displayName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text('Lịch sử đơn hàng'),
              ),
              Expanded(
                child: s.hasError
                    ? Center(child: Text('Không tải được lịch sử: ${s.error}'))
                    : !s.hasData
                    ? const Center(child: CircularProgressIndicator())
                    : ListView(
                        controller: controller,
                        children: s.data!
                            .map(
                              (o) => ListTile(
                                title: Text(
                                  NumberFormat.currency(
                                    locale: 'vi',
                                    symbol: '₫',
                                  ).format(o.totalPrice),
                                ),
                                subtitle: Text(
                                  DateFormat(
                                    'dd/MM/yyyy HH:mm',
                                  ).format(o.createdAt),
                                ),
                                trailing: StatusBadge(status: o.status),
                              ),
                            )
                            .toList(),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
