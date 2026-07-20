import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../models/food_model.dart';
import '../../viewmodels/admin_viewmodel.dart';
import '../../widgets/canteen_button.dart';
import '../../widgets/canteen_text_field.dart';

class AdminFoodFormScreen extends StatefulWidget {
  const AdminFoodFormScreen({super.key, this.food});
  final FoodModel? food;
  @override
  State<AdminFoodFormScreen> createState() => _AdminFoodFormScreenState();
}

class _AdminFoodFormScreenState extends State<AdminFoodFormScreen> {
  final key = GlobalKey<FormState>();
  late final TextEditingController name, description, price;
  late String category;
  bool available = true, featured = false;
  File? image;
  @override
  void initState() {
    super.initState();
    final f = widget.food;
    name = TextEditingController(text: f?.name);
    description = TextEditingController(text: f?.description);
    price = TextEditingController(text: f?.price.toStringAsFixed(0));
    category = AppConstants.foodCategories.contains(f?.category)
        ? f!.category
        : AppConstants.foodCategories.first;
    available = f?.available ?? true;
    if (f != null)
      context.read<AdminViewModel>().isFoodFeatured(f.id).then((v) {
        if (mounted) setState(() => featured = v);
      });
  }

  @override
  void dispose() {
    name.dispose();
    description.dispose();
    price.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.food == null ? 'Thêm món mới' : 'Sửa món ăn'),
    ),
    body: Form(
      key: key,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              height: 190,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(16),
              ),
              child: image != null
                  ? Image.file(image!, fit: BoxFit.cover)
                  : widget.food?.imageUrl.isNotEmpty == true
                  ? CachedNetworkImage(
                      imageUrl: widget.food!.imageUrl,
                      fit: BoxFit.cover,
                    )
                  : const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_a_photo_outlined, size: 44),
                        Text('Chọn hoặc chụp ảnh'),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 16),
          CanteenTextField(
            controller: name,
            labelText: 'Tên món',
            prefixIcon: Icons.restaurant,
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Vui lòng nhập tên' : null,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: category,
            decoration: const InputDecoration(labelText: 'Danh mục'),
            items: AppConstants.foodCategories
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: (v) => setState(() => category = v!),
          ),
          const SizedBox(height: 12),
          CanteenTextField(
            controller: price,
            labelText: 'Giá',
            keyboardType: TextInputType.number,
            prefixIcon: Icons.payments,
            validator: (v) => (double.tryParse(v ?? '') ?? 0) <= 0
                ? 'Giá phải lớn hơn 0'
                : null,
          ),
          const SizedBox(height: 12),
          CanteenTextField(
            controller: description,
            labelText: 'Mô tả',
            maxLines: 4,
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Vui lòng nhập mô tả' : null,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Còn hàng'),
            value: available,
            onChanged: (v) => setState(() => available = v),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Món hôm nay (nổi bật)'),
            value: featured,
            onChanged: (v) => setState(() => featured = v),
          ),
          const SizedBox(height: 12),
          CanteenButton(
            text: 'Lưu món ăn',
            isLoading: context.watch<AdminViewModel>().isLoading,
            onPressed: _save,
          ),
        ],
      ),
    ),
  );
  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (c) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Thư viện'),
              onTap: () => Navigator.pop(c, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Máy ảnh'),
              onTap: () => Navigator.pop(c, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    final file = await ImagePicker().pickImage(
      source: source,
      imageQuality: 82,
      maxWidth: 1600,
    );
    if (file != null) setState(() => image = File(file.path));
  }

  Future<void> _save() async {
    if (!key.currentState!.validate()) return;
    try {
      await context.read<AdminViewModel>().saveFood(
        id: widget.food?.id,
        name: name.text.trim(),
        description: description.text.trim(),
        price: double.parse(price.text),
        category: category,
        available: available,
        isFeatured: featured,
        image: image,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
    }
  }
}
