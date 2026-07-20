import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../models/order_model.dart';
import '../../viewmodels/admin_viewmodel.dart';
import '../../widgets/canteen_card.dart';
import '../../widgets/status_badge.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});
  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  String filter = 'all';
  static const filters = {
    'all': 'Tất cả',
    AppConstants.statusPending: 'Chờ xác nhận',
    AppConstants.statusPreparing: 'Đang làm',
    AppConstants.statusReady: 'Sẵn sàng',
    AppConstants.statusCompleted: 'Hoàn thành',
  };
  @override
  Widget build(BuildContext context) => StreamBuilder<List<OrderModel>>(
    stream: context.read<AdminViewModel>().ordersStream,
    builder: (context, s) {
      if (s.hasError)
        return Center(child: Text('Không tải được đơn: ${s.error}'));
      if (!s.hasData) return const Center(child: CircularProgressIndicator());
      final pending = s.data!
          .where((o) => o.status == AppConstants.statusPending)
          .length;
      final list = filter == 'all'
          ? s.data!
          : s.data!.where((o) => o.status == filter).toList();
      return Column(
        children: [
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              children: filters.entries
                  .map(
                    (e) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        selected: filter == e.key,
                        onSelected: (_) => setState(() => filter = e.key),
                        label: Text(
                          e.key == AppConstants.statusPending
                              ? '${e.value} ($pending)'
                              : e.value,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          Expanded(
            child: list.isEmpty
                ? const Center(child: Text('Chưa có đơn hàng'))
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: list.length,
                    itemBuilder: (context, i) {
                      final o = list[i];
                      return CanteenCard(
                        margin: const EdgeInsets.only(bottom: 10),
                        onTap: () => Navigator.pushNamed(
                          context,
                          '/admin/order-detail',
                          arguments: o,
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              child: Text(
                                o.userName.isEmpty
                                    ? '?'
                                    : o.userName[0].toUpperCase(),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    o.userName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '${DateFormat('dd/MM HH:mm').format(o.createdAt)} · ${o.pickupTime}',
                                  ),
                                  Text(
                                    NumberFormat.currency(
                                      locale: 'vi',
                                      symbol: '₫',
                                    ).format(o.totalPrice),
                                  ),
                                ],
                              ),
                            ),
                            StatusBadge(status: o.status),
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
}
