import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../viewmodels/admin_viewmodel.dart';
import '../../widgets/canteen_card.dart';

enum StatsRange { today, week, month }

class AdminStatsScreen extends StatefulWidget {
  const AdminStatsScreen({super.key});
  @override
  State<AdminStatsScreen> createState() => _AdminStatsScreenState();
}

class _AdminStatsScreenState extends State<AdminStatsScreen> {
  StatsRange range = StatsRange.week;
  late Future<AdminAnalytics> future;
  @override
  void initState() {
    super.initState();
    future = _load();
  }

  Future<AdminAnalytics> _load() {
    final now = DateTime.now();
    final to = DateTime(
      now.year,
      now.month,
      now.day,
    ).add(const Duration(days: 1));
    final from = switch (range) {
      StatsRange.today => DateTime(now.year, now.month, now.day),
      StatsRange.week => DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(const Duration(days: 6)),
      StatsRange.month => DateTime(now.year, now.month, 1),
    };
    return context.read<AdminViewModel>().loadAnalytics(from, to);
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<AdminAnalytics>(
    future: future,
    builder: (context, s) {
      if (s.hasError) {
        return Center(child: Text('Không tải được thống kê: ${s.error}'));
      }
      if (!s.hasData) return const Center(child: CircularProgressIndicator());
      final a = s.data!;
      return ListView(
        padding: const EdgeInsets.all(12),
        children: [
          SegmentedButton<StatsRange>(
            segments: const [
              ButtonSegment(value: StatsRange.today, label: Text('Hôm nay')),
              ButtonSegment(value: StatsRange.week, label: Text('Tuần này')),
              ButtonSegment(value: StatsRange.month, label: Text('Tháng này')),
            ],
            selected: {range},
            onSelectionChanged: (v) => setState(() {
              range = v.first;
              future = _load();
            }),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _Summary('Đơn hoàn thành', '${a.orders.length}')),
              const SizedBox(width: 8),
              Expanded(
                child: _Summary(
                  'Doanh thu',
                  NumberFormat.compactCurrency(
                    locale: 'vi',
                    symbol: '₫',
                  ).format(a.revenue),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _Summary(
                  'TB/ngày',
                  NumberFormat.compactCurrency(
                    locale: 'vi',
                    symbol: '₫',
                  ).format(a.averagePerDay),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _ChartCard(
            title: 'Doanh thu theo ngày',
            chart: _bar(
              a.revenueByDay.values.toList(),
              a.revenueByDay.keys
                  .map((date) => DateFormat('dd/MM').format(date))
                  .toList(),
            ),
          ),
          const SizedBox(height: 12),
          _ChartCard(
            title: 'Đơn theo giờ',
            chart: _bar(
              a.ordersByHour.values.map((v) => v.toDouble()).toList(),
              a.ordersByHour.keys.map((hour) => '${hour}h').toList(),
            ),
          ),
          const SizedBox(height: 12),
          CanteenCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Top 5 món ăn',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                if (a.topFoods.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: Text('Chưa có dữ liệu')),
                  ),
                ...a.topFoods.asMap().entries.map(
                  (e) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(child: Text('${e.key + 1}')),
                    title: Text(e.value.name),
                    subtitle: Text('${e.value.quantity} lượt'),
                    trailing: Text(
                      NumberFormat.compactCurrency(
                        locale: 'vi',
                        symbol: '₫',
                      ).format(e.value.revenue),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => _export(context, a),
            icon: const Icon(Icons.download),
            label: const Text('Xuất báo cáo CSV'),
          ),
          const SizedBox(height: 80),
        ],
      );
    },
  );
  Widget _bar(List<double> values, List<String> labels) {
    if (values.isEmpty) return const Center(child: Text('Chưa có dữ liệu'));
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= labels.length) {
                  return const SizedBox.shrink();
                }
                return SideTitleWidget(
                  meta: meta,
                  child: Text(
                    labels[index],
                    style: const TextStyle(fontSize: 10),
                  ),
                );
              },
            ),
          ),
        ),
        barGroups: values
            .asMap()
            .entries
            .map(
              (e) => BarChartGroupData(
                x: e.key,
                barRods: [
                  BarChartRodData(
                    toY: e.value,
                    color: AppColors.primary,
                    width: 16,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
            )
            .toList(),
      ),
    );
  }

  Future<void> _export(BuildContext context, AdminAnalytics data) async {
    try {
      final path = await context.read<AdminViewModel>().exportRevenueCsv(data);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Đã xuất báo cáo: $path')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Không thể xuất: $e')));
      }
    }
  }
}

class _Summary extends StatelessWidget {
  const _Summary(this.label, this.value);
  final String label, value;
  @override
  Widget build(BuildContext context) => CanteenCard(
    padding: const EdgeInsets.all(10),
    child: Column(
      children: [
        Text(
          value,
          maxLines: 1,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    ),
  );
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.title, required this.chart});
  final String title;
  final Widget chart;
  @override
  Widget build(BuildContext context) => CanteenCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        SizedBox(height: 190, child: chart),
      ],
    ),
  );
}
