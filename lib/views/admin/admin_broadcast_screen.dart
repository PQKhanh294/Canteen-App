import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../viewmodels/admin_viewmodel.dart';
import '../../widgets/canteen_button.dart';
import '../../widgets/canteen_card.dart';
import '../../widgets/canteen_text_field.dart';

class AdminBroadcastScreen extends StatefulWidget {
  const AdminBroadcastScreen({super.key});
  @override
  State<AdminBroadcastScreen> createState() => _AdminBroadcastScreenState();
}

class _AdminBroadcastScreenState extends State<AdminBroadcastScreen> {
  final formKey = GlobalKey<FormState>();
  final titleController = TextEditingController();
  final bodyController = TextEditingController();

  @override
  void dispose() {
    titleController.dispose();
    bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thông báo hàng loạt')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Form(
            key: formKey,
            child: CanteenCard(
              child: Column(
                children: [
                  CanteenTextField(
                    controller: titleController,
                    labelText: 'Tiêu đề',
                    prefixIcon: Icons.title,
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Vui lòng nhập tiêu đề'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  CanteenTextField(
                    controller: bodyController,
                    labelText: 'Nội dung',
                    maxLines: 4,
                    validator: (value) =>
                        value == null || value.trim().length < 5
                        ? 'Nội dung tối thiểu 5 ký tự'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  CanteenButton(
                    text: 'Gửi đến tất cả sinh viên',
                    isLoading: context.watch<AdminViewModel>().isLoading,
                    onPressed: _send,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Lịch sử đã gửi',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          StreamBuilder<List<AdminBroadcast>>(
            stream: context.read<AdminViewModel>().broadcastsStream,
            builder: (context, snapshot) {
              if (!snapshot.hasData)
                return const Center(child: CircularProgressIndicator());
              if (snapshot.data!.isEmpty)
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('Chưa gửi thông báo nào'),
                  ),
                );
              return Column(
                children: snapshot.data!
                    .map(
                      (broadcast) => CanteenCard(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const CircleAvatar(
                            child: Icon(Icons.campaign),
                          ),
                          title: Text(broadcast.title),
                          subtitle: Text(
                            '${broadcast.body}\n${DateFormat('dd/MM/yyyy HH:mm').format(broadcast.sentAt)}',
                          ),
                          isThreeLine: true,
                          trailing: Text(
                            '${broadcast.recipientCount}\nngười',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _send() async {
    if (!formKey.currentState!.validate()) return;
    final accepted =
        await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Xác nhận gửi'),
            content: const Text('Thông báo sẽ được gửi đến tất cả sinh viên.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Hủy'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Gửi'),
              ),
            ],
          ),
        ) ??
        false;
    if (!accepted || !mounted) return;
    try {
      await context.read<AdminViewModel>().sendBroadcast(
        titleController.text,
        bodyController.text,
      );
      titleController.clear();
      bodyController.clear();
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xếp hàng gửi thông báo')),
        );
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$error')));
    }
  }
}
