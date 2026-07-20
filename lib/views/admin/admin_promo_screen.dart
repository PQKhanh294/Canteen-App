import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/admin_viewmodel.dart';
import '../../widgets/canteen_card.dart';

class AdminPromoScreen extends StatelessWidget {
  const AdminPromoScreen({super.key, this.embedded = false});
  final bool embedded;
  @override
  Widget build(BuildContext context) {
    final body = StreamBuilder<List<AdminPromo>>(
      stream: context.read<AdminViewModel>().promosStream,
      builder: (context, s) {
        if (!s.hasData) return const Center(child: CircularProgressIndicator());
        return Scaffold(
          body: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: s.data!.length,
            itemBuilder: (context, i) {
              final p = s.data![i],
                  expired = p.expiresAt.isBefore(DateTime.now());
              return CanteenCard(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    p.code,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${p.type == 'percentage' ? '${p.value.toStringAsFixed(0)}%' : NumberFormat.currency(locale: 'vi', symbol: '₫').format(p.value)} · HSD ${DateFormat('dd/MM/yyyy').format(p.expiresAt)}${expired ? ' · Hết hạn' : ''}',
                  ),
                  trailing: Switch(
                    value: p.active && !expired,
                    onChanged: expired
                        ? null
                        : (v) =>
                              context.read<AdminViewModel>().togglePromo(p, v),
                  ),
                ),
              );
            },
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _form(context),
            child: const Icon(Icons.add),
          ),
        );
      },
    );
    return embedded
        ? body
        : Scaffold(
            appBar: AppBar(title: const Text('Mã giảm giá')),
            body: body,
          );
  }

  Future<void> _form(BuildContext context) async {
    final code = TextEditingController(), value = TextEditingController();
    String type = 'percentage';
    DateTime expiry = DateTime.now().add(const Duration(days: 30));
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, set) => AlertDialog(
          title: const Text('Thêm mã giảm giá'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: code,
                decoration: const InputDecoration(labelText: 'Mã'),
              ),
              DropdownButtonFormField(
                initialValue: type,
                items: const [
                  DropdownMenuItem(
                    value: 'percentage',
                    child: Text('Phần trăm'),
                  ),
                  DropdownMenuItem(
                    value: 'fixed',
                    child: Text('Số tiền cố định'),
                  ),
                ],
                onChanged: (v) => set(() => type = v!),
              ),
              TextField(
                controller: value,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Giá trị'),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'Hết hạn: ${DateFormat('dd/MM/yyyy').format(expiry)}',
                ),
                trailing: const Icon(Icons.calendar_month),
                onTap: () async {
                  final d = await showDatePicker(
                    context: c,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 730)),
                    initialDate: expiry,
                  );
                  if (d != null) set(() => expiry = d);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
    if (ok == true &&
        code.text.trim().isNotEmpty &&
        (double.tryParse(value.text) ?? 0) > 0 &&
        context.mounted)
      await context.read<AdminViewModel>().savePromo(
        code: code.text,
        type: type,
        value: double.parse(value.text),
        expiresAt: expiry,
      );
    code.dispose();
    value.dispose();
  }
}
