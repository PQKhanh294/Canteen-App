import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/enums/discount_type.dart';
import '../../models/promo_model.dart';
import '../../viewmodels/admin_viewmodel.dart';
import '../../widgets/canteen_card.dart';

class AdminPromoScreen extends StatelessWidget {
  const AdminPromoScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final body = StreamBuilder<List<PromoModel>>(
      stream: context.read<AdminViewModel>().promosStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text('Không tải được mã giảm giá: ${snapshot.error}'),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final promos = snapshot.data!;
        return Scaffold(
          backgroundColor: AppColors.background,
          body: promos.isEmpty
              ? const Center(child: Text('Chưa có mã giảm giá'))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: promos.length,
                  itemBuilder: (context, index) {
                    final promo = promos[index];
                    final expired = promo.expiresAt.isBefore(DateTime.now());
                    final valueText =
                        promo.discountType == DiscountType.percentage
                        ? '${promo.discountValue.toStringAsFixed(0)}%'
                        : NumberFormat.currency(
                            locale: 'vi',
                            symbol: '₫',
                          ).format(promo.discountValue);
                    return CanteenCard(
                      margin: const EdgeInsets.only(bottom: 8),
                      onTap: () => _showForm(context, promo: promo),
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          promo.code,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '$valueText · Đã dùng ${promo.usedCount}'
                          '${promo.usageLimit == null ? '' : '/${promo.usageLimit}'}'
                          ' · HSD ${DateFormat('dd/MM/yyyy').format(promo.expiresAt)}'
                          '${expired ? ' · Hết hạn' : ''}',
                        ),
                        trailing: Switch(
                          value: promo.isActive && !expired,
                          onChanged: expired
                              ? null
                              : (value) => context
                                    .read<AdminViewModel>()
                                    .togglePromo(promo, value),
                        ),
                      ),
                    );
                  },
                ),
          floatingActionButton: FloatingActionButton(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            onPressed: () => _showForm(context),
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

  Future<void> _showForm(BuildContext context, {PromoModel? promo}) async {
    final codeController = TextEditingController(text: promo?.code ?? '');
    final descriptionController = TextEditingController(
      text: promo?.description ?? '',
    );
    final valueController = TextEditingController(
      text: promo == null ? '' : promo.discountValue.toStringAsFixed(0),
    );
    final minimumController = TextEditingController(
      text: promo?.minimumOrderAmount?.toStringAsFixed(0) ?? '',
    );
    final maximumController = TextEditingController(
      text: promo?.maximumDiscount?.toStringAsFixed(0) ?? '',
    );
    final usageLimitController = TextEditingController(
      text: promo?.usageLimit?.toString() ?? '',
    );
    var type = promo?.discountType ?? DiscountType.percentage;
    var startAt = promo?.startAt ?? DateTime.now();
    var expiresAt =
        promo?.expiresAt ?? DateTime.now().add(const Duration(days: 30));
    var isActive = promo?.isActive ?? true;
    String? validationError;

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(promo == null ? 'Thêm mã giảm giá' : 'Sửa mã giảm giá'),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: codeController,
                    enabled: promo == null,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(labelText: 'Mã'),
                  ),
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(labelText: 'Mô tả'),
                  ),
                  DropdownButtonFormField<DiscountType>(
                    initialValue: type,
                    decoration: const InputDecoration(labelText: 'Loại giảm'),
                    items: const [
                      DropdownMenuItem(
                        value: DiscountType.percentage,
                        child: Text('Phần trăm'),
                      ),
                      DropdownMenuItem(
                        value: DiscountType.fixed,
                        child: Text('Số tiền cố định'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) setDialogState(() => type = value);
                    },
                  ),
                  TextField(
                    controller: valueController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Giá trị giảm',
                    ),
                  ),
                  TextField(
                    controller: minimumController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Giá trị đơn tối thiểu (không bắt buộc)',
                    ),
                  ),
                  TextField(
                    controller: maximumController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Mức giảm tối đa (không bắt buộc)',
                    ),
                  ),
                  TextField(
                    controller: usageLimitController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText:
                          'Giới hạn lượt dùng (để trống = không giới hạn)',
                    ),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'Bắt đầu: ${DateFormat('dd/MM/yyyy').format(startAt)}',
                    ),
                    trailing: const Icon(Icons.calendar_month),
                    onTap: () async {
                      final selected = await showDatePicker(
                        context: dialogContext,
                        firstDate: DateTime.now().subtract(
                          const Duration(days: 365),
                        ),
                        lastDate: DateTime.now().add(const Duration(days: 730)),
                        initialDate: startAt,
                      );
                      if (selected != null) {
                        setDialogState(() => startAt = selected);
                      }
                    },
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'Hết hạn: ${DateFormat('dd/MM/yyyy').format(expiresAt)}',
                    ),
                    trailing: const Icon(Icons.event_busy),
                    onTap: () async {
                      final selected = await showDatePicker(
                        context: dialogContext,
                        firstDate: startAt,
                        lastDate: DateTime.now().add(const Duration(days: 730)),
                        initialDate: expiresAt.isBefore(startAt)
                            ? startAt
                            : expiresAt,
                      );
                      if (selected != null) {
                        setDialogState(
                          () => expiresAt = DateTime(
                            selected.year,
                            selected.month,
                            selected.day,
                            23,
                            59,
                            59,
                          ),
                        );
                      }
                    },
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Đang hoạt động'),
                    value: isActive,
                    onChanged: (value) =>
                        setDialogState(() => isActive = value),
                  ),
                  if (validationError != null)
                    Text(
                      validationError!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () {
                final code = codeController.text.trim();
                final value = double.tryParse(valueController.text.trim());
                final minimum = minimumController.text.trim().isEmpty
                    ? null
                    : double.tryParse(minimumController.text.trim());
                final maximum = maximumController.text.trim().isEmpty
                    ? null
                    : double.tryParse(maximumController.text.trim());
                final usageLimit = usageLimitController.text.trim().isEmpty
                    ? null
                    : int.tryParse(usageLimitController.text.trim());
                String? error;
                if (code.isEmpty) {
                  error = 'Vui lòng nhập mã giảm giá.';
                } else if (value == null || value <= 0) {
                  error = 'Giá trị giảm phải lớn hơn 0.';
                } else if (type == DiscountType.percentage && value > 100) {
                  error = 'Phần trăm giảm không được vượt quá 100.';
                } else if (minimumController.text.trim().isNotEmpty &&
                    minimum == null) {
                  error = 'Giá trị đơn tối thiểu không hợp lệ.';
                } else if (minimum != null && minimum < 0) {
                  error = 'Giá trị đơn tối thiểu không được âm.';
                } else if (maximumController.text.trim().isNotEmpty &&
                    maximum == null) {
                  error = 'Mức giảm tối đa không hợp lệ.';
                } else if (maximum != null && maximum <= 0) {
                  error = 'Mức giảm tối đa phải lớn hơn 0.';
                } else if (!expiresAt.isAfter(startAt)) {
                  error = 'Ngày hết hạn phải sau ngày bắt đầu.';
                } else if (usageLimitController.text.trim().isNotEmpty &&
                    usageLimit == null) {
                  error = 'Giới hạn lượt dùng không hợp lệ.';
                } else if (usageLimit != null && usageLimit <= 0) {
                  error = 'Giới hạn lượt dùng phải lớn hơn 0.';
                }

                if (error != null) {
                  setDialogState(() => validationError = error);
                  return;
                }
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );

    try {
      if (shouldSave == true && context.mounted) {
        await context.read<AdminViewModel>().savePromo(
          id: promo?.id,
          code: codeController.text,
          description: descriptionController.text,
          discountType: type,
          discountValue: double.parse(valueController.text.trim()),
          minimumOrderAmount: double.tryParse(minimumController.text.trim()),
          maximumDiscount: double.tryParse(maximumController.text.trim()),
          startAt: startAt,
          expiresAt: expiresAt,
          usageLimit: int.tryParse(usageLimitController.text.trim()),
          usedCount: promo?.usedCount ?? 0,
          isActive: isActive,
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể lưu mã giảm giá: $error')),
        );
      }
    } finally {
      codeController.dispose();
      descriptionController.dispose();
      valueController.dispose();
      minimumController.dispose();
      maximumController.dispose();
      usageLimitController.dispose();
    }
  }
}
