import '../widgets/app_top_bar.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../l10n/app_language.dart';
import '../models/models.dart';
import '../painters/app_illustrations.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../widgets/auth_form_modal.dart';
import '../widgets/onboarding_survey_dialog.dart';

class AccountScreen extends StatefulWidget {
  final ApiService api;
  final RoleLoginResponse? currentUser;
  final Function(RoleLoginResponse) onLoginSuccess;
  final VoidCallback onLogout;
  final ScrollController? scrollController;

  const AccountScreen({
    super.key,
    required this.api,
    required this.currentUser,
    required this.onLoginSuccess,
    required this.onLogout,
    this.scrollController,
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
  void didUpdateWidget(AccountScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentUser != oldWidget.currentUser) {
      _loadRoleData();
    }
  }

  void _loadRoleData() {
    if (widget.currentUser != null && widget.currentUser!.role == 'user') {
      _loadProfile();
    }
  }

  Future<void> _loadProfile() async {
    if (widget.currentUser == null) return;
    setState(() => _loadingProfile = true);
    try {
      final p = await widget.api.getUserProfile(widget.currentUser!.id);
      if (mounted) setState(() => _profile = p);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loadingProfile = false);
    }
  }

  String _formatBmiCategory(String? cat, double? bmi) {
    if (cat != null) {
      switch (cat.toLowerCase()) {
        case 'underweight':
          return 'Gầy (< 18.5)';
        case 'normal':
          return 'Bình thường';
        case 'overweight':
          return 'Thừa cân';
        case 'obese':
          return 'Béo phì';
      }
    }
    if (bmi != null) {
      if (bmi < 18.5) return 'Gầy';
      if (bmi <= 22.9) return 'Bình thường';
      if (bmi <= 27.5) return 'Thừa cân';
      return 'Béo phì';
    }
    return 'Thừa cân';
  }

  String _formatGoal(String? goal) {
    switch (goal) {
      case 'weight_loss':
        return 'Giảm cân';
      case 'muscle_gain':
        return 'Tăng cơ';
      case 'maintenance':
        return 'Duy trì vóc dáng';
      case 'keto':
        return 'Ăn Keto';
      case 'vegetarian':
        return 'Ăn chay lành mạnh';
      default:
        return 'Giảm cân';
    }
  }

  String _formatAllergyLabel(String a) {
    switch (a.toLowerCase()) {
      case 'seafood':
        return 'Hải sản';
      case 'peanuts':
        return 'Đậu phộng';
      case 'eggs':
        return 'Trứng';
      case 'milk':
        return 'Sữa & Lactose';
      case 'gluten':
        return 'Gluten';
      default:
        return a;
    }
  }

  void _openAuthSheet(bool isRegister) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Stack(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.of(context).pop(),
            child: const SizedBox.expand(),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: AuthFormModal(
              api: widget.api,
              initialRegister: isRegister,
              onSuccess: (resp) {
                widget.onLoginSuccess(resp);
                _loadRoleData();
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showLocationInfo() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.location_on, color: Color(0xFF16A34A), size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                tr('location_service_title'),
                style: GoogleFonts.nunito(fontWeight: FontWeight.w800, fontSize: 16.5, color: const Color(0xFF1E293B)),
              ),
            ),
          ],
        ),
        content: Text(
          tr('location_service_desc'),
          style: GoogleFonts.nunito(fontSize: 13.5, height: 1.45, color: const Color(0xFF475569)),
        ),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF064E3B),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: Text(tr('close'), style: GoogleFonts.nunito(fontWeight: FontWeight.w800, fontSize: 13.5)),
          ),
        ],
      ),
    );
  }

  void _showPrivacyInfo() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.shield_outlined, color: Color(0xFF16A34A), size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                tr('privacy_title'),
                style: GoogleFonts.nunito(fontWeight: FontWeight.w800, fontSize: 16.5, color: const Color(0xFF1E293B)),
              ),
            ),
          ],
        ),
        content: Text(
          tr('privacy_desc'),
          style: GoogleFonts.nunito(fontSize: 13.5, height: 1.45, color: const Color(0xFF475569)),
        ),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF064E3B),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: Text(tr('close'), style: GoogleFonts.nunito(fontWeight: FontWeight.w800, fontSize: 13.5)),
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
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  tr('lang_choose'),
                  style: GoogleFonts.nunito(fontWeight: FontWeight.w800, fontSize: 17, color: const Color(0xFF1E293B)),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Text('🇻🇳', style: TextStyle(fontSize: 24)),
                  title: const Text('Tiếng Việt'),
                  trailing: AppLanguage.instance.isVietnamese
                      ? const Icon(Icons.check, color: Color(0xFF16A34A))
                      : null,
                  onTap: () {
                    AppLanguage.instance.setLocale(const Locale('vi'));
                    Navigator.pop(ctx);
                    setState(() {});
                  },
                ),
                ListTile(
                  leading: const Text('🇬🇧', style: TextStyle(fontSize: 24)),
                  title: const Text('English'),
                  trailing: !AppLanguage.instance.isVietnamese
                      ? const Icon(Icons.check, color: Color(0xFF16A34A))
                      : null,
                  onTap: () {
                    AppLanguage.instance.setLocale(const Locale('en'));
                    Navigator.pop(ctx);
                    setState(() {});
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(tr('confirm_logout_title'), style: GoogleFonts.nunito(fontWeight: FontWeight.bold)),
        content: Text(tr('confirm_logout_desc')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(tr('cancel'), style: const TextStyle(color: Colors.grey)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
            onPressed: () {
              Navigator.pop(ctx);
              widget.onLogout();
            },
            child: Text(tr('btn_logout')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.currentUser != null) {
      final user = widget.currentUser!;
      final height = _profile?.heightCm ?? 172.0;
      final weight = _profile?.weightKg ?? 78.0;
      final bmi = _profile?.bmi ?? (weight / ((height / 100) * (height / 100)));
      final bmiCategory = _formatBmiCategory(_profile?.bmiCategory, bmi);

      return Scaffold(
        backgroundColor: const Color(0xFFF7FAF7),
        appBar: AppTopBar(
          title: 'Tài Khoản',
          currentUser: widget.currentUser,
        ),
        body: ListView(
          controller: widget.scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            // Tiêu đề Trang + Nút đăng xuất tròn viền hồng (Image 4)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tài Khoản Thực Khách',
                      style: GoogleFonts.nunito(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F291E),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Cá nhân hoá dinh dưỡng & sức khỏe',
                      style: GoogleFonts.nunito(
                        fontSize: 12.5,
                        color: const Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Tooltip(
                  message: 'Đăng xuất',
                  child: InkWell(
                    onTap: _confirmLogout,
                    borderRadius: BorderRadius.circular(22),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF93C5FD), width: 1.5),
                      ),
                      child: const Icon(Icons.logout_rounded, color: Color(0xFFE11D48), size: 20),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // THẺ HỒ SƠ THÀNH VIÊN (Image 4)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 8, offset: const Offset(0, 2)),
                ],
              ),
              child: Row(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: const Color(0xFF064E3B),
                        child: Text(
                          (user.fullName?.isNotEmpty == true ? user.fullName![0] : 'N').toUpperCase(),
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2.5),
                          decoration: const BoxDecoration(
                            color: Color(0xFFDCFCE7),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.eco_rounded, size: 12, color: Color(0xFF16A34A)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.fullName?.isNotEmpty == true ? user.fullName! : 'Nguyễn Văn Thực Khách',
                          style: GoogleFonts.nunito(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '• Mục tiêu: ${_formatGoal(_profile?.targetGoal)} • Dị ứng ${_profile?.allergies.isNotEmpty == true ? _profile!.allergies.map(_formatAllergyLabel).join(', ') : "hải sản"}',
                          style: GoogleFonts.nunito(
                            fontSize: 12,
                            color: const Color(0xFF64748B),
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // BANNER XANH NHẠT: CHỈ SỐ THỂ TRẠNG HÔM NAY (Image 4)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Color(0xFF86EFAC),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.energy_savings_leaf_rounded, color: Color(0xFF166534), size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Chỉ số thể trạng hôm nay',
                          style: GoogleFonts.nunito(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF166534),
                          ),
                        ),
                        const SizedBox(height: 2),
                        RichText(
                          text: TextSpan(
                            style: GoogleFonts.nunito(fontSize: 12, color: const Color(0xFF166534)),
                            children: [
                              const TextSpan(text: 'Cần nạp '),
                              TextSpan(
                                text: '1.650 kcal',
                                style: GoogleFonts.nunito(fontWeight: FontWeight.w800),
                              ),
                              const TextSpan(text: ' để duy trì đốt mỡ'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF064E3B),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      visualDensity: VisualDensity.compact,
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
                    child: Text('Cập nhật', style: GoogleFonts.nunito(fontWeight: FontWeight.w700, fontSize: 12)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // THẺ HỒ SƠ SỨC KHỎE & SỞ THÍCH (Image 4)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 8, offset: const Offset(0, 2)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header thẻ
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.shield_outlined, color: Color(0xFF16A34A), size: 18),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Hồ Sơ Sức Khỏe & Sở Thích',
                            style: GoogleFonts.nunito(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_note_rounded, color: Color(0xFF64748B), size: 22),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
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
                  const SizedBox(height: 14),

                  // 3 Khối chỉ số: Chiều cao | Cân nặng | BMI (Khối BMI màu xanh lá theo Image 4)
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            children: [
                              Text('Chiều cao', style: GoogleFonts.nunito(fontSize: 11.5, color: const Color(0xFF64748B), fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: '${height.toStringAsFixed(0)} ',
                                      style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.w800, color: const Color(0xFF1E293B)),
                                    ),
                                    TextSpan(
                                      text: 'cm',
                                      style: GoogleFonts.nunito(fontSize: 11.5, color: const Color(0xFF64748B), fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            children: [
                              Text('Cân nặng', style: GoogleFonts.nunito(fontSize: 11.5, color: const Color(0xFF64748B), fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: '${weight.toStringAsFixed(1)} ',
                                      style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.w800, color: const Color(0xFF1E293B)),
                                    ),
                                    TextSpan(
                                      text: 'kg',
                                      style: GoogleFonts.nunito(fontSize: 11.5, color: const Color(0xFF64748B), fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFBBF7D0)),
                          ),
                          child: Column(
                            children: [
                              Text('BMI', style: GoogleFonts.nunito(fontSize: 11.5, color: const Color(0xFF166534), fontWeight: FontWeight.w700)),
                              const SizedBox(height: 4),
                              Text(
                                bmi.toStringAsFixed(1),
                                style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.w800, color: const Color(0xFF15803D)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Dòng 1: Thể trạng: [Thừa cân] • Mục tiêu: Giảm cân
                  Row(
                    children: [
                      Text('Thể trạng: ', style: GoogleFonts.nunito(fontSize: 12, color: const Color(0xFF64748B))),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          bmiCategory,
                          style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w800, color: const Color(0xFF16A34A)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text('• Mục tiêu: ', style: GoogleFonts.nunito(fontSize: 12, color: const Color(0xFF64748B))),
                      Text(
                        _formatGoal(_profile?.targetGoal),
                        style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w800, color: const Color(0xFF1E293B)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Dòng 2: Chế độ ăn: [✓ Ăn sạch (Eat Clean)]
                  Row(
                    children: [
                      Text('Chế độ ăn: ', style: GoogleFonts.nunito(fontSize: 12, color: const Color(0xFF64748B))),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_circle_outline, size: 13, color: Color(0xFF0F766E)),
                            const SizedBox(width: 4),
                            Text(
                              'Ăn sạch (Eat Clean)',
                              style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF0F766E)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Dòng 3: ⚠ Dị ứng: [⊘ Hải sản]
                  Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, size: 14, color: Color(0xFFDC2626)),
                      const SizedBox(width: 4),
                      Text('Dị ứng: ', style: GoogleFonts.nunito(fontSize: 12, color: const Color(0xFFDC2626), fontWeight: FontWeight.w700)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFFECACA)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.block_flipped, size: 12, color: Color(0xFFDC2626)),
                            const SizedBox(width: 4),
                            Text(
                              _profile?.allergies.isNotEmpty == true ? _profile!.allergies.map(_formatAllergyLabel).join(', ') : 'Hải sản',
                              style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFFB91C1C)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Dòng 4: Ngân sách: [Tiết kiệm (< 40k)]
                  Row(
                    children: [
                      Text('Ngân sách: ', style: GoogleFonts.nunito(fontSize: 12, color: const Color(0xFF64748B))),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                        ),
                        child: Text(
                          'Tiết kiệm (< 40k)',
                          style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF334155)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // KHỐI CÀI ĐẶT
            Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              clipBehavior: Clip.antiAlias,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.location_on_outlined, color: Color(0xFF16A34A), size: 20),
                    ),
                    title: Text(
                      'Quyền truy cập vị trí',
                      style: GoogleFonts.nunito(fontWeight: FontWeight.w700, fontSize: 14, color: const Color(0xFF1E293B)),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Đã bật', style: GoogleFonts.nunito(fontSize: 12, color: const Color(0xFF16A34A), fontWeight: FontWeight.w700)),
                        const SizedBox(width: 4),
                        const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8), size: 18),
                      ],
                    ),
                    onTap: _showLocationInfo,
                  ),
                  const Divider(height: 1, indent: 56, color: Color(0xFFF1F5F9)),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.language_rounded, color: Color(0xFF16A34A), size: 20),
                    ),
                    title: Text(
                      'Ngôn ngữ',
                      style: GoogleFonts.nunito(fontWeight: FontWeight.w700, fontSize: 14, color: const Color(0xFF1E293B)),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(AppLanguage.instance.currentLanguageLabel, style: GoogleFonts.nunito(fontSize: 12, color: const Color(0xFF64748B), fontWeight: FontWeight.w600)),
                        const SizedBox(width: 4),
                        const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8), size: 18),
                      ],
                    ),
                    onTap: _showLanguageSheet,
                  ),
                  const Divider(height: 1, indent: 56, color: Color(0xFFF1F5F9)),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.shield_outlined, color: Color(0xFF16A34A), size: 20),
                    ),
                    title: Text(
                      'Điều khoản & Quyền riêng tư',
                      style: GoogleFonts.nunito(fontWeight: FontWeight.w700, fontSize: 14, color: const Color(0xFF1E293B)),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8), size: 18),
                    onTap: _showPrivacyInfo,
                  ),
                  const Divider(height: 1, indent: 56, color: Color(0xFFF1F5F9)),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.info_outline_rounded, color: Color(0xFF16A34A), size: 20),
                    ),
                    title: Text(
                      'Phiên bản ứng dụng',
                      style: GoogleFonts.nunito(fontWeight: FontWeight.w700, fontSize: 14, color: const Color(0xFF1E293B)),
                    ),
                    trailing: Text('v1.0.0 (PTC1)', style: GoogleFonts.nunito(color: const Color(0xFF64748B), fontWeight: FontWeight.w700, fontSize: 12)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 30),
          ],
        ),
      );
    }

    // ----------------------------------------------------
    // TRẠNG THÁI 2: CHẾ ĐỘ KHÁCH (CHƯA ĐĂNG NHẬP)
    // ----------------------------------------------------
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF7),
      appBar: AppTopBar(
        title: 'Tài Khoản',
        currentUser: widget.currentUser,
      ),
      body: ListView(
        controller: widget.scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        children: [
          // 1. Thẻ Chào Khách Vãng Lai Chuẩn Thiết Kế Screen 8
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2EBE9)),
              boxShadow: [
                BoxShadow(
                  color: kPrimaryTeal.withAlpha(10),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Anime Boy Eating Illustration
                const Center(
                  child: AnimeEaterArt(size: 72),
                ),
                const SizedBox(height: 4),
                Text(
                  'Khách vãng lai',
                  style: GoogleFonts.nunito(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: kTextDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Khám phá ẩm thực ngay không cần đăng ký!',
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF475569),
                  ),
                  textAlign: TextAlign.center,
                ),
                // Chú thích nhỏ tương thích test
                const SizedBox(height: 2),
                Text(
                  'Chào bạn!',
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF94A3B8),
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  'Bạn đang trải nghiệm với tư cách Khách',
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    color: const Color(0xFF94A3B8),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),

                // Danh sách tính năng với dấu tick xanh
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFDCFCE7)),
                  ),
                  child: Column(
                    children: [
                      _buildCheckFeature('Tìm quán gần bạn'),
                      const SizedBox(height: 4),
                      _buildCheckFeature('Xem bản đồ & thực đơn'),
                      const SizedBox(height: 4),
                      _buildCheckFeature('Lưu tạm món yêu thích'),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Nút CTA: Bắt đầu trải nghiệm / Tạo tài khoản miễn phí
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryTeal,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                    ),
                    onPressed: () => _openAuthSheet(true),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Bắt đầu trải nghiệm',
                          style: GoogleFonts.nunito(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.arrow_forward_rounded, size: 18),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 6),

                // Nút phụ: Đăng nhập & Tạo tài khoản miễn phí
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () => _openAuthSheet(false),
                      child: Text(
                        'Đăng nhập',
                        style: GoogleFonts.nunito(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: kPrimaryTeal,
                        ),
                      ),
                    ),
                    Text(
                      '•',
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                    TextButton(
                      onPressed: () => _openAuthSheet(true),
                      child: Text(
                        'Tạo tài khoản miễn phí',
                        style: GoogleFonts.nunito(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF475569),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Thẻ Lợi ích khi đăng nhập thành viên
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2EBE9)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lợi ích khi đăng nhập thành viên',
                  style: GoogleFonts.nunito(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '• Đồng bộ món ăn yêu thích trên mọi thiết bị\n• Đánh giá và nhận xét quán ăn chuẩn ATTP\n• Nhận thông báo ưu đãi và giảm giá giờ vàng',
                  style: GoogleFonts.nunito(
                    fontSize: 11.5,
                    color: const Color(0xFF64748B),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // 2. Khối Cài đặt ứng dụng
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            clipBehavior: Clip.antiAlias,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withAlpha(4), blurRadius: 8, offset: const Offset(0, 2)),
                ],
              ),
              child: Column(
              children: [
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.location_on_outlined, color: Color(0xFF16A34A), size: 20),
                  ),
                  title: Text(
                    tr('item_location_permission'),
                    style: GoogleFonts.nunito(fontWeight: FontWeight.w700, fontSize: 14, color: const Color(0xFF1E293B)),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Đã bật', style: GoogleFonts.nunito(fontSize: 12, color: const Color(0xFF16A34A), fontWeight: FontWeight.w700)),
                      const SizedBox(width: 4),
                      const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8), size: 18),
                    ],
                  ),
                  onTap: _showLocationInfo,
                ),
                const Divider(height: 1, indent: 56, color: Color(0xFFF1F5F9)),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.language_rounded, color: Color(0xFF16A34A), size: 20),
                  ),
                  title: Text(
                    tr('item_language'),
                    style: GoogleFonts.nunito(fontWeight: FontWeight.w700, fontSize: 14, color: const Color(0xFF1E293B)),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(AppLanguage.instance.currentLanguageLabel, style: GoogleFonts.nunito(fontSize: 12, color: const Color(0xFF64748B), fontWeight: FontWeight.w600)),
                      const SizedBox(width: 4),
                      const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8), size: 18),
                    ],
                  ),
                  onTap: _showLanguageSheet,
                ),
                const Divider(height: 1, indent: 56, color: Color(0xFFF1F5F9)),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.shield_outlined, color: Color(0xFF16A34A), size: 20),
                  ),
                  title: Text(
                    tr('item_privacy'),
                    style: GoogleFonts.nunito(fontWeight: FontWeight.w700, fontSize: 14, color: const Color(0xFF1E293B)),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8), size: 18),
                  onTap: _showPrivacyInfo,
                ),
                const Divider(height: 1, indent: 56, color: Color(0xFFF1F5F9)),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.info_outline_rounded, color: Color(0xFF16A34A), size: 20),
                  ),
                  title: Text(
                    tr('item_app_version'),
                    style: GoogleFonts.nunito(fontWeight: FontWeight.w700, fontSize: 14, color: const Color(0xFF1E293B)),
                  ),
                  trailing: Text('v1.0.0 (PTC1)', style: GoogleFonts.nunito(color: const Color(0xFF64748B), fontWeight: FontWeight.w700, fontSize: 12)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildCheckFeature(String text) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: const BoxDecoration(
            color: Color(0xFF10B981),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check, size: 14, color: Colors.white),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.nunito(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E293B),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBenefitRow(IconData icon, Color bgColor, Color iconColor, String title, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: GoogleFonts.nunito(fontWeight: FontWeight.w700, fontSize: 13.5, color: const Color(0xFF1E293B))),
              const SizedBox(height: 2),
              Text(desc, style: GoogleFonts.nunito(fontSize: 12, color: const Color(0xFF64748B), height: 1.3)),
            ],
          ),
        ),
      ],
    );
  }
}
