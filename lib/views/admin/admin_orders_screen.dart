import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/enums/order_status.dart';
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
  OrderStatus? filter;

  @override
  Widget build(BuildContext context) => StreamBuilder<List<OrderModel>>(
    stream: context.read<AdminViewModel>().ordersStream,
    builder: (context, s) {
      if (s.hasError) {
        return Center(child: Text('Không tải được đơn: ${s.error}'));
      }
      if (!s.hasData) return const Center(child: CircularProgressIndicator());
      final sourceOrders = s.data!;
      final selectedFilter = filter;
      final counts = AdminOrderListLogic.countByStatus(sourceOrders);
      final filteredOrders = AdminOrderListLogic.filterByStatus(
        sourceOrders,
        selectedFilter,
      );
      final filters = <MapEntry<OrderStatus?, String>>[
        const MapEntry(null, 'Tất cả'),
        ...OrderStatus.adminFilterStatuses.map(
          (status) => MapEntry(status, status.label),
        ),
      ];
      return Column(
        children: [
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              children: filters
                  .map(
                    (e) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        selected: filter == e.key,
                        onSelected: (_) => setState(() => filter = e.key),
                        label: Text(
                          e.key != null && (counts[e.key] ?? 0) > 0
                              ? '${e.value} (${counts[e.key]})'
                              : e.value,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          Expanded(
            child: filteredOrders.isEmpty
                ? Center(
                    child: Text(
                      selectedFilter == null
                          ? 'Chưa có đơn hàng'
                          : 'Không có đơn ${selectedFilter.label.toLowerCase()}',
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: filteredOrders.length,
                    itemBuilder: (context, i) {
                      final o = filteredOrders[i];
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
                                    '${DateFormat('dd/MM HH:mm').format(o.createdAt)} · Nhận ${DateFormat('dd/MM HH:mm').format(o.pickupAt)}',
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
