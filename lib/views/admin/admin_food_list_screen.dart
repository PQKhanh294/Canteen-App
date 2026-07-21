import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/food_model.dart';
import '../../viewmodels/admin_viewmodel.dart';
import '../../widgets/canteen_card.dart';

class AdminFoodListScreen extends StatelessWidget {
  const AdminFoodListScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    body: StreamBuilder<List<FoodModel>>(
      stream: context.read<AdminViewModel>().foodsStream,
      builder: (context, s) {
        if (s.hasError) return Center(child: Text('${s.error}'));
        if (!s.hasData) return const Center(child: CircularProgressIndicator());
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
          itemCount: s.data!.length,
          itemBuilder: (context, i) {
            final f = s.data![i];
            return CanteenCard(
              margin: const EdgeInsets.only(bottom: 10),
              onTap: () => Navigator.pushNamed(
                context,
                '/admin/food-form',
                arguments: f,
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: f.imageUrl.isEmpty
                        ? const SizedBox(
                            width: 64,
                            height: 64,
                            child: ColoredBox(
                              color: Colors.black12,
                              child: Icon(Icons.restaurant),
                            ),
                          )
                        : CachedNetworkImage(
                            imageUrl: f.imageUrl,
                            width: 64,
                            height: 64,
                            fit: BoxFit.cover,
                            errorWidget: (_, _, _) =>
                                const Icon(Icons.broken_image),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          f.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(f.category),
                        Text(
                          NumberFormat.currency(
                            locale: 'vi',
                            symbol: '₫',
                          ).format(f.price),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      Switch(
                        value: f.available,
                        onChanged: (v) =>
                            context.read<AdminViewModel>().toggleFood(f, v),
                      ),
                      IconButton(
                        tooltip: 'Xóa',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _delete(context, f),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    ),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: () => Navigator.pushNamed(context, '/admin/food-form'),
      icon: const Icon(Icons.add),
      label: const Text('Thêm món'),
    ),
  );
  Future<void> _delete(BuildContext context, FoodModel food) async {
    final yes =
        await showDialog<bool>(
          context: context,
          builder: (c) => AlertDialog(
            title: const Text('Xóa món ăn?'),
            content: Text('Bạn chắc chắn muốn xóa “${food.name}”?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(c, false),
                child: const Text('Hủy'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(c, true),
                child: const Text('Xóa'),
              ),
            ],
          ),
        ) ??
        false;
    if (yes && context.mounted) {
      await context.read<AdminViewModel>().deleteFood(food);
    }
  }
}
