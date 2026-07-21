import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../viewmodels/admin_viewmodel.dart';
import '../../widgets/canteen_card.dart';
import '../../widgets/canteen_text_field.dart';
import 'admin_promo_screen.dart';

class AdminCategoryScreen extends StatelessWidget {
  const AdminCategoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Danh mục & ưu đãi'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Danh mục'),
              Tab(text: 'Mã giảm giá'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [_CategoryBody(), AdminPromoScreen(embedded: true)],
        ),
      ),
    );
  }
}

class _CategoryBody extends StatelessWidget {
  const _CategoryBody();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AdminCategory>>(
      stream: context.read<AdminViewModel>().categoriesStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text('Không tải được danh mục: ${snapshot.error}'),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        return Scaffold(
          body: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final category = snapshot.data![index];
              return CanteenCard(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    child: Text(category.icon.isEmpty ? '🍴' : category.icon),
                  ),
                  title: Text(category.name),
                  trailing: Wrap(
                    children: [
                      IconButton(
                        onPressed: () => _edit(context, category),
                        icon: const Icon(Icons.edit_outlined),
                      ),
                      IconButton(
                        onPressed: () => _delete(context, category),
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _edit(context, null),
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  Future<void> _edit(BuildContext context, AdminCategory? category) async {
    final name = TextEditingController(text: category?.name);
    final icon = TextEditingController(text: category?.icon ?? '🍴');
    final accepted =
        await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(category == null ? 'Thêm danh mục' : 'Sửa danh mục'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CanteenTextField(
                  controller: name,
                  labelText: 'Tên danh mục',
                  prefixIcon: Icons.category_outlined,
                ),
                const SizedBox(height: 12),
                CanteenTextField(
                  controller: icon,
                  labelText: 'Icon/emoji',
                  prefixIcon: Icons.emoji_emotions_outlined,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Hủy'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Lưu'),
              ),
            ],
          ),
        ) ??
        false;
    if (accepted && name.text.trim().isNotEmpty && context.mounted) {
      try {
        await context.read<AdminViewModel>().saveCategory(
          id: category?.id,
          name: name.text,
          icon: icon.text,
        );
      } catch (error) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('$error')));
        }
      }
    }
    name.dispose();
    icon.dispose();
  }

  Future<void> _delete(BuildContext context, AdminCategory category) async {
    final accepted =
        await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Xóa danh mục?'),
            content: Text('Bạn chắc chắn muốn xóa “${category.name}”?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Hủy'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Xóa'),
              ),
            ],
          ),
        ) ??
        false;
    if (!accepted || !context.mounted) return;
    try {
      await context.read<AdminViewModel>().deleteCategory(category);
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$error')));
      }
    }
  }
}
