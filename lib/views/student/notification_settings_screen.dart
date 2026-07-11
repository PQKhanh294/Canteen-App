import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/canteen_card.dart';

// ============================================================
// VIEW: views/student/notification_settings_screen.dart
// Owner: Member 1 — Khánh
// ============================================================

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _orderStatusNotif = true;
  bool _readyToPickupNotif = true;
  bool _promoNotif = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _orderStatusNotif = prefs.getBool('notif_order_status') ?? true;
      _readyToPickupNotif = prefs.getBool('notif_ready_pickup') ?? true;
      _promoNotif = prefs.getBool('notif_promo') ?? false;
      _isLoading = false;
    });
  }

  Future<void> _saveSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cài Đặt Thông Báo'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Nhận thông báo qua thiết bị',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Cấu hình loại tin nhắn đẩy mà bạn mong muốn nhận từ nhà bếp căn tin',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              
              CanteenCard(
                child: Column(
                  children: [
                    // Switch 1: Trạng thái đơn hàng
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Trạng thái đơn hàng',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      subtitle: const Text(
                        'Nhận thông báo khi đơn được xác nhận hoặc đang chuẩn bị.',
                        style: TextStyle(fontSize: 12),
                      ),
                      activeColor: AppColors.primary,
                      value: _orderStatusNotif,
                      onChanged: (bool value) {
                        setState(() {
                          _orderStatusNotif = value;
                        });
                        _saveSetting('notif_order_status', value);
                      },
                    ),
                    const Divider(height: 32),
                    
                    // Switch 2: Sẵn sàng nhận đồ ăn
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Món ăn đã sẵn sàng',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      subtitle: const Text(
                        'Báo cho bạn ngay lập tức khi món ăn nấu xong và có thể lấy.',
                        style: TextStyle(fontSize: 12),
                      ),
                      activeColor: AppColors.primary,
                      value: _readyToPickupNotif,
                      onChanged: (bool value) {
                        setState(() {
                          _readyToPickupNotif = value;
                        });
                        _saveSetting('notif_ready_pickup', value);
                      },
                    ),
                    const Divider(height: 32),
                    
                    // Switch 3: Tin khuyến mãi
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Tin tức & Khuyến mãi',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      subtitle: const Text(
                        'Nhận mã giảm giá độc quyền từ các quầy bán tại căn tin.',
                        style: TextStyle(fontSize: 12),
                      ),
                      activeColor: AppColors.primary,
                      value: _promoNotif,
                      onChanged: (bool value) {
                        setState(() {
                          _promoNotif = value;
                        });
                        _saveSetting('notif_promo', value);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
