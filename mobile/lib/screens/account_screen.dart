import 'package:flutter/material.dart';
import '../l10n/app_language.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../widgets/auth_form_modal.dart';
import '../widgets/onboarding_survey_dialog.dart';

class AccountScreen extends StatefulWidget {
  final ApiService api;
  final RoleLoginResponse? currentUser;
  final Function(RoleLoginResponse) onLoginSuccess;
  final VoidCallback onLogout;

  const AccountScreen({
    super.key,
    required this.api,
    required this.currentUser,
    required this.onLoginSuccess,
    required this.onLogout,
  });

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  UserProfile? _profile;
  bool _loadingProfile = false;

  @override
  void initState() {
    super.initState();
    _loadRoleData();
  }

  @override
  void didUpdateWidget(covariant AccountScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentUser?.id != oldWidget.currentUser?.id) {
      _loadRoleData();
    }
  }

  void _loadRoleData() {
    if (widget.currentUser == null) return;
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    if (widget.currentUser == null) return;
    setState(() => _loadingProfile = true);
    try {
      final p = await widget.api.getUserProfile(widget.currentUser!.id);
      if (mounted) setState(() => _profile = p);
    } catch (err) {
      debugPrint('Error loading user profile: $err');
    } finally {
      if (mounted) setState(() => _loadingProfile = false);
    }
  }

  String _formatBmiCategory(String? cat, double? bmi) {
    if (cat == 'underweight' || (bmi != null && bmi < 18.5)) return 'Hơi gầy';
    if (cat == 'normal' || (bmi != null && bmi < 23.0)) return 'Chuẩn dáng';
    if (cat == 'overweight' || (bmi != null && bmi < 25.0)) return 'Thừa cân';
    if (cat == 'obese' || (bmi != null && bmi >= 25.0)) return 'Thừa cân';
    return 'Chuẩn dáng';
  }

  String _formatDietaryLabel(String tag) {
    final key = tag.trim().toLowerCase();
    const map = {
      'clean_eating': 'Ăn sạch',
      'eat_clean': 'Ăn sạch',
      'eat clean': 'Ăn sạch',
      'healthy': 'Ăn lành mạnh',
      'eat_healthy': 'Ăn lành mạnh',
      'low_carb': 'Ít tinh bột',
      'low-carb': 'Ít tinh bột',
      'keto': 'Keto',
      'vegetarian': 'Ăn chay',
      'vegan': 'Thuần chay',
      'high_protein': 'Nhiều đạm',
      'nhiều protein': 'Nhiều đạm',
      'less_oil': 'Ít dầu mỡ',
      'ít dầu mỡ': 'Ít dầu mỡ',
      'low_fat': 'Ít chất béo',
      'light': 'Ăn thanh đạm',
      'ăn thanh đạm': 'Ăn thanh đạm',
      'gluten_free': 'Không gluten',
      'dairy_free': 'Không chứa sữa',
      'organic': 'Hữu cơ',
      'halal': 'Halal',
      'kosher': 'Kosher',
    };
    return map[key] ?? tag.replaceAll('_', ' ');
  }

  String _formatAllergyLabel(String alg) {
    final key = alg.trim().toLowerCase();
    const map = {
      'seafood': 'Hải sản',
      'peanut': 'Đậu phộng',
      'peanuts': 'Đậu phộng',
      'egg': 'Trứng',
      'eggs': 'Trứng',
      'milk': 'Sữa bò',
      'dairy': 'Chế phẩm sữa',
      'gluten': 'Gluten',
      'wheat': 'Lúa mì',
      'soy': 'Đậu nành',
      'soybean': 'Đậu nành',
    };
    return map[key] ?? alg.replaceAll('_', ' ');
  }

  void _openAuthSheet({bool isRegister = false, VoidCallback? onSuccess}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => AuthFormModal(
        api: widget.api,
        initialRegister: isRegister,
        onSuccess: (res) {
          widget.onLoginSuccess(res);
          _loadRoleData();
          onSuccess?.call();
        },
      ),
    );
  }

  void _showLocationInfo() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.location_on, color: kPrimaryGreen),
            SizedBox(width: 8),
            Text('Quyền vị trí GPS', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'PTC1 sử dụng toạ độ vị trí thời gian thực từ thiết bị để gợi ý quán ăn lân cận và hiển thị thời tiết chính xác nhất. Vị trí của bạn hoàn toàn được bảo mật và không lưu trữ trên máy chủ.',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: kPrimaryGreen),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đã hiểu'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyInfo() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.privacy_tip_outlined, color: kPrimaryGreen),
            SizedBox(width: 8),
            Text('Điều khoản & Quyền riêng tư', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'PTC1 cam kết tôn trọng quyền riêng tư của khách hàng. Bạn có thể tự do tìm kiếm quán ăn và tra cứu thực đơn mà không cần cung cấp bất kỳ thông tin cá nhân nào khi ở chế độ Khách.',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: kPrimaryGreen),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _showLanguageSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    const Icon(Icons.language_rounded, color: kPrimaryGreen),
                    const SizedBox(width: 8),
                    Text(
                      tr('lang_choose'),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppLanguage.instance.isVietnamese ? kLightGreen : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text('VI', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: kPrimaryGreen)),
                ),
                title: const Text('Tiếng Việt', style: TextStyle(fontWeight: FontWeight.w600)),
                trailing: AppLanguage.instance.isVietnamese
                    ? const Icon(Icons.check_circle, color: kPrimaryGreen)
                    : null,
                onTap: () {
                  AppLanguage.instance.setLocale(const Locale('vi'));
                  Navigator.pop(ctx);
                  setState(() {});
                },
              ),
              const Divider(height: 1, indent: 56),
              ListTile(
                leading: Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: !AppLanguage.instance.isVietnamese ? kLightGreen : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text('EN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: kPrimaryGreen)),
                ),
                title: const Text('English', style: TextStyle(fontWeight: FontWeight.w600)),
                trailing: !AppLanguage.instance.isVietnamese
                    ? const Icon(Icons.check_circle, color: kPrimaryGreen)
                    : null,
                onTap: () {
                  AppLanguage.instance.setLocale(const Locale('en'));
                  Navigator.pop(ctx);
                  setState(() {});
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBenefitRow({required IconData icon, required String title, required String desc}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: kLightGreen,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: kPrimaryGreen, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: kTextDark)),
              const SizedBox(height: 3),
              Text(desc, style: const TextStyle(fontSize: 12, color: kTextMuted, height: 1.35)),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // ----------------------------------------------------
    // TRẠNG THÁI 1: ĐÃ ĐĂNG NHẬP THỰC KHÁCH
    // ----------------------------------------------------
    if (widget.currentUser != null) {
      final user = widget.currentUser!;

      return Scaffold(
        backgroundColor: kScaffoldBg,
        appBar: AppBar(
          title: const Text('Tài Khoản Thực Khách', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          backgroundColor: Colors.white,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout, color: Color(0xFFDC2626)),
              tooltip: 'Đăng xuất',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    title: const Text('Xác nhận đăng xuất', style: TextStyle(fontWeight: FontWeight.bold)),
                    content: const Text('Bạn có chắc chắn muốn đăng xuất khỏi tài khoản không?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Huỷ', style: TextStyle(color: Colors.grey))),
                      FilledButton(
                        style: FilledButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
                        onPressed: () {
                          Navigator.pop(ctx);
                          widget.onLogout();
                        },
                        child: const Text('Đăng xuất'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          children: [
            // Thẻ hồ sơ thành viên
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: kBorderColor),
                boxShadow: [
                  BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 8, offset: const Offset(0, 3)),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: kPrimaryGreen,
                    child: Text(
                      (user.fullName?.isNotEmpty == true ? user.fullName![0] : user.email[0]).toUpperCase(),
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      user.fullName?.isNotEmpty == true ? user.fullName! : 'Thực khách',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: kTextDark),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Banner nhắc nhở khảo sát nếu chưa hoàn thành
            if (_profile != null && !_profile!.isOnboarded)
              Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: kSuperLightGreen,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: kPrimaryGreen.withAlpha(80)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.eco_outlined, color: kPrimaryGreen, size: 24),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Chưa thiết lập sở thích ẩm thực',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: kPrimaryGreen)),
                          SizedBox(height: 2),
                          Text('Khảo sát ngay để nhận gợi ý món ăn chuẩn vóc dáng & khẩu vị!',
                              style: TextStyle(fontSize: 12, color: Color(0xFF166534))),
                        ],
                      ),
                    ),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: kPrimaryGreen,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onPressed: () {
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (ctx) => OnboardingSurveyDialog(
                            api: widget.api,
                            userId: widget.currentUser!.id,
                            initialProfile: _profile,
                            onCompleted: _loadProfile,
                          ),
                        );
                      },
                      child: const Text('Khảo sát', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ),

            // Card Chi Tiết Hồ Sơ Sức Khỏe & Sở Thích
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: kBorderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.health_and_safety_outlined, color: kPrimaryGreen),
                          SizedBox(width: 8),
                          Text('Hồ Sơ Sức Khỏe & Sở Thích',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: kTextDark)),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_note, color: kPrimaryGreen),
                        tooltip: 'Chỉnh sửa sở thích & thể chất',
                        onPressed: () {
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (ctx) => OnboardingSurveyDialog(
                              api: widget.api,
                              userId: widget.currentUser!.id,
                              initialProfile: _profile,
                              onCompleted: _loadProfile,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const Divider(height: 16),
                  if (_loadingProfile)
                    const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
                  else if (_profile == null)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Column(
                          children: [
                            const Text('Chưa có thông tin hồ sơ sức khỏe & khẩu vị.', style: TextStyle(color: kTextMuted, fontSize: 13)),
                            const SizedBox(height: 10),
                            FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: kPrimaryGreen,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              ),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (ctx) => OnboardingSurveyDialog(
                                    api: widget.api,
                                    userId: widget.currentUser!.id,
                                    initialProfile: _profile,
                                    onCompleted: _loadProfile,
                                  ),
                                );
                              },
                              icon: const Icon(Icons.add_task_rounded, size: 16),
                              label: const Text('Thiết lập ngay', style: TextStyle(fontSize: 13)),
                            ),
                          ],
                        ),
                      ),
                    )
                  else ...[
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: kScaffoldBg,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: kBorderColor),
                            ),
                            child: Column(
                              children: [
                                const Text('Chiều cao', style: TextStyle(fontSize: 11, color: kTextMuted)),
                                const SizedBox(height: 2),
                                Text(
                                  _profile!.heightCm != null ? '${_profile!.heightCm!.toStringAsFixed(0)} cm' : '--',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: kScaffoldBg,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: kBorderColor),
                            ),
                            child: Column(
                              children: [
                                const Text('Cân nặng', style: TextStyle(fontSize: 11, color: kTextMuted)),
                                const SizedBox(height: 2),
                                Text(
                                  _profile!.weightKg != null ? '${_profile!.weightKg!.toStringAsFixed(1)} kg' : '--',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: kLightGreen,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: kPrimaryGreen.withAlpha(60)),
                            ),
                            child: Column(
                              children: [
                                const Text('BMI', style: TextStyle(fontSize: 11, color: kPrimaryGreen, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 2),
                                Text(
                                  _profile!.bmi != null ? _profile!.bmi!.toStringAsFixed(1) : '--',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: kPrimaryGreen),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Text('Thể trạng: ', style: TextStyle(fontSize: 12, color: kTextMuted)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: kLightGreen,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _formatBmiCategory(_profile!.bmiCategory, _profile!.bmi),
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: kPrimaryGreen),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text('• Mục tiêu: ', style: TextStyle(fontSize: 12, color: kTextMuted)),
                        Text(
                          _profile!.targetGoal == 'lose_weight'
                              ? 'Giảm cân'
                              : (_profile!.targetGoal == 'gain_muscle'
                                  ? 'Tăng cơ'
                                  : (_profile!.targetGoal == 'eat_healthy' ? 'Ăn healthy' : 'Duy trì vóc dáng')),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),

                    if (_profile!.dietaryPreferences.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Chế độ ăn: ', style: TextStyle(fontSize: 12, color: kTextMuted)),
                          Expanded(
                            child: Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: _profile!.dietaryPreferences.map((diet) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF0FDF4),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: const Color(0xFFBBF7D0)),
                                  ),
                                  child: Text(_formatDietaryLabel(diet), style: const TextStyle(fontSize: 11, color: Color(0xFF166534), fontWeight: FontWeight.w600)),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ],

                    if (_profile!.allergies.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Dị ứng: ', style: TextStyle(fontSize: 12, color: Color(0xFFDC2626), fontWeight: FontWeight.bold)),
                          Expanded(
                            child: Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: _profile!.allergies.map((alg) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEF2F2),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: const Color(0xFFFECACA)),
                                  ),
                                  child: Text(_formatAllergyLabel(alg), style: const TextStyle(fontSize: 11, color: Color(0xFFDC2626), fontWeight: FontWeight.bold)),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ],

                    if (_profile!.spicyTolerance != null || _profile!.budgetRange != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          if (_profile!.spicyTolerance != null) ...[
                            const Text('Độ cay: ', style: TextStyle(fontSize: 12, color: kTextMuted)),
                            Text(
                              _profile!.spicyTolerance == 'none'
                                  ? 'Không cay'
                                  : (_profile!.spicyTolerance == 'mild'
                                      ? 'Cay nhẹ'
                                      : (_profile!.spicyTolerance == 'medium' ? 'Cay vừa' : 'Ăn rất cay')),
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(width: 12),
                          ],
                          if (_profile!.budgetRange != null) ...[
                            const Text('Ngân sách: ', style: TextStyle(fontSize: 12, color: kTextMuted)),
                            Text(
                              _profile!.budgetRange == 'budget'
                                  ? 'Tiết kiệm (< 40k)'
                                  : (_profile!.budgetRange == 'moderate' ? 'Phổ thông (40k - 80k)' : 'Thoải mái (> 80k)'),
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Khối Cài đặt & Quyền riêng tư
            Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              clipBehavior: Clip.antiAlias,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: kBorderColor),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.location_on_outlined, color: kPrimaryGreen),
                      title: const Text('Quyền vị trí GPS', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                      onTap: _showLocationInfo,
                    ),
                    const Divider(height: 1, indent: 56),
                    ListTile(
                      leading: const Icon(Icons.language_rounded, color: kPrimaryGreen),
                      title: Text(tr('item_language'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(AppLanguage.instance.currentLanguageLabel, style: const TextStyle(fontSize: 13, color: kTextMuted)),
                          const SizedBox(width: 4),
                          const Icon(Icons.chevron_right, color: Colors.grey),
                        ],
                      ),
                      onTap: _showLanguageSheet,
                    ),
                    const Divider(height: 1, indent: 56),
                    ListTile(
                      leading: const Icon(Icons.privacy_tip_outlined, color: kPrimaryGreen),
                      title: Text(tr('item_privacy'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                      onTap: _showPrivacyInfo,
                    ),
                    const Divider(height: 1, indent: 56),
                    ListTile(
                      leading: const Icon(Icons.info_outline, color: kPrimaryGreen),
                      title: Text(tr('item_app_version'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      trailing: const Text('v1.0.0 (PTC1)', style: TextStyle(color: kTextMuted, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    // ----------------------------------------------------
    // TRẠNG THÁI 2: CHẾ ĐỘ KHÁCH (CHƯA ĐĂNG NHẬP)
    // ----------------------------------------------------
    return Scaffold(
      backgroundColor: kScaffoldBg,
      appBar: AppBar(
        title: Text(tr('account_title'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: kTextDark)),
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        children: [
          // 1. Khối Avatar mặc định + Lời chào Khách
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: kBorderColor),
              boxShadow: [
                BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: kLightGreen,
                    shape: BoxShape.circle,
                    border: Border.all(color: kPrimaryGreen.withAlpha(40), width: 2),
                  ),
                  child: const Icon(Icons.person_outline_rounded, size: 40, color: kPrimaryGreen),
                ),
                const SizedBox(height: 14),
                Text(
                  tr('greeting_guest'),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: kTextDark),
                ),
                const SizedBox(height: 4),
                Text(
                  tr('guest_experience'),
                  style: const TextStyle(fontSize: 13, color: kTextMuted),
                ),
                const SizedBox(height: 18),
                // 2. Hai nút: Đăng nhập & Tạo tài khoản miễn phí
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: kPrimaryGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => _openAuthSheet(isRegister: false),
                        child: Text(tr('btn_login'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: kPrimaryGreen,
                          side: const BorderSide(color: kPrimaryGreen, width: 1.5),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => _openAuthSheet(isRegister: true),
                        child: Text(tr('btn_register_free'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 3. Khối 3 Lợi ích thành viên
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: kBorderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.stars_rounded, color: kPrimaryGreen, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      tr('member_benefits'),
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: kTextDark),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildBenefitRow(
                  icon: Icons.favorite_border_rounded,
                  title: tr('benefit_1_title'),
                  desc: tr('benefit_1_desc'),
                ),
                const Divider(height: 22, color: Color(0xFFF1F5F9)),
                _buildBenefitRow(
                  icon: Icons.psychology_outlined,
                  title: tr('benefit_2_title'),
                  desc: tr('benefit_2_desc'),
                ),
                const Divider(height: 22, color: Color(0xFFF1F5F9)),
                _buildBenefitRow(
                  icon: Icons.storefront_outlined,
                  title: tr('benefit_3_title'),
                  desc: tr('benefit_3_desc'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 4. Khối Cài đặt, quyền riêng tư (dùng được không cần tài khoản)
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            clipBehavior: Clip.antiAlias,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: kBorderColor),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: kLightGreen, borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.location_on_outlined, color: kPrimaryGreen, size: 20),
                    ),
                    title: Text(tr('item_location_permission'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: Text(tr('item_location_permission_sub'), style: const TextStyle(fontSize: 12, color: kTextMuted)),
                    trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                    onTap: _showLocationInfo,
                  ),
                  const Divider(height: 1, indent: 60, color: Color(0xFFF1F5F9)),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: kLightGreen, borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.language_rounded, color: kPrimaryGreen, size: 20),
                    ),
                    title: Text(tr('item_language'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(AppLanguage.instance.currentLanguageLabel, style: const TextStyle(fontSize: 13, color: kTextMuted)),
                        const SizedBox(width: 4),
                        const Icon(Icons.chevron_right, color: Colors.grey),
                      ],
                    ),
                    onTap: _showLanguageSheet,
                  ),
                  const Divider(height: 1, indent: 60, color: Color(0xFFF1F5F9)),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: kLightGreen, borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.privacy_tip_outlined, color: kPrimaryGreen, size: 20),
                    ),
                    title: Text(tr('item_privacy'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                    onTap: _showPrivacyInfo,
                  ),
                  const Divider(height: 1, indent: 60, color: Color(0xFFF1F5F9)),
                  ListTile(
                    leading: const SizedBox(width: 20),
                    title: Text(tr('item_app_version'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    trailing: const Text('v1.0.0 (PTC1)', style: TextStyle(fontSize: 13, color: kTextMuted, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ==========================================
// FORM ĐĂNG NHẬP / ĐĂNG KÝ MODAL BOTTOM SHEET
// ==========================================
