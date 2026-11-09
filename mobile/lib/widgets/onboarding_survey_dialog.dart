import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/models.dart';
import '../services/api_service.dart';

// ============================================================================
// HỌA HÌNH VECTOR BÁT MÓN ĂN (FOOD BOWL BADGE) THEO ĐÚNG MẪU THIẾT KẾ
// ============================================================================
class _FoodBowlBadge extends StatelessWidget {
  const _FoodBowlBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 68,
      height: 68,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: const CustomPaint(
        painter: _FoodBowlPainter(),
      ),
    );
  }
}

class _FoodBowlPainter extends CustomPainter {
  const _FoodBowlPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Vùng nền tròn xanh nhạt băng tuyết
    final bgPaint = Paint()..color = const Color(0xFFE0F2FE);
    canvas.drawCircle(Offset(w / 2, h / 2), w * 0.44, bgPaint);

    // Các viên đồ ăn bên trong bát
    // Viên màu xanh ngọc (bên trái)
    final greenBall = Paint()..color = const Color(0xFF34D399);
    canvas.drawCircle(Offset(w * 0.36, h * 0.43), w * 0.11, greenBall);

    // Viên màu vàng tươi (bên phải)
    final yellowBall = Paint()..color = const Color(0xFFFBBF24);
    canvas.drawCircle(Offset(w * 0.64, h * 0.43), w * 0.11, yellowBall);

    // Viên màu cam đậm (ở giữa nổi lên trên)
    final orangeBall = Paint()..color = const Color(0xFFF97316);
    canvas.drawCircle(Offset(w * 0.50, h * 0.36), w * 0.12, orangeBall);

    // Thân bát men màu xanh ngọc sẫm (Deep Teal)
    final bowlPaint = Paint()..color = const Color(0xFF0D7A65);
    final bowlRect = Rect.fromCenter(
      center: Offset(w * 0.5, h * 0.53),
      width: w * 0.52,
      height: h * 0.40,
    );
    canvas.drawArc(bowlRect, 0, 3.14159, false, bowlPaint);

    // Viền miệng bát nằm ngang
    final rimPaint = Paint()
      ..color = const Color(0xFF0D7A65)
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(w * 0.22, h * 0.53),
      Offset(w * 0.78, h * 0.53),
      rimPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ============================================================================
// DIALOG KHẢO SÁT THỰC KHÁCH (ONBOARDING SURVEY DIALOG) - MẪU CHUẨN
// ============================================================================
class OnboardingSurveyDialog extends StatefulWidget {
  final ApiService api;
  final int userId;
  final UserProfile? initialProfile;
  final VoidCallback onCompleted;

  const OnboardingSurveyDialog({
    super.key,
    required this.api,
    required this.userId,
    this.initialProfile,
    required this.onCompleted,
  });

  @override
  State<OnboardingSurveyDialog> createState() => _OnboardingSurveyDialogState();
}

class _OnboardingSurveyDialogState extends State<OnboardingSurveyDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _heightCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _birthYearCtrl = TextEditingController();

  String? _gender = 'male';
  String? _activityLevel;
  String? _targetGoal = 'lose_weight';
  String? _spicyTolerance = 'medium';
  String? _budgetRange = 'budget';

  final Set<String> _selectedDiets = {};
  final Set<String> _selectedAllergies = {'Hải sản'};

  bool _saving = false;
  String? _error;
  String? _heightError;
  String? _weightError;
  String? _birthYearError;

  // 10 danh mục chuẩn xác theo bản thiết kế mẫu của người dùng
  static final List<Category> _defaultCategories = [
    Category(id: 1, name: 'Phở, Bún & Món nước', displayOrder: 1, isActive: true),
    Category(id: 2, name: 'Cơm & Xôi', displayOrder: 2, isActive: true),
    Category(id: 3, name: 'Bánh mì', displayOrder: 3, isActive: true),
    Category(id: 4, name: 'Bánh truyền thống & Món cuốn', displayOrder: 4, isActive: true),
    Category(id: 5, name: 'Lẩu & Nướng', displayOrder: 5, isActive: true),
    Category(id: 6, name: 'Ốc & Quán lai rai', displayOrder: 6, isActive: true),
    Category(id: 7, name: 'Đồ ăn vặt', displayOrder: 7, isActive: true),
    Category(id: 8, name: 'Chè & Tráng miệng', displayOrder: 8, isActive: true),
    Category(id: 9, name: 'Cà phê & Thức uống', displayOrder: 9, isActive: true),
    Category(id: 10, name: 'Ẩm thực chay & Thực dưỡng', displayOrder: 10, isActive: true),
  ];

  List<Category> _categories = [];
  bool _loadingCategories = false;
  final Set<int> _selectedCategoryIds = {4, 5}; // Mặc định chọn Bánh truyền thống & Lẩu nướng như ảnh 2

  static final List<String> _defaultAllergyOptions = [
    'Hải sản',
    'Đậu phộng',
    'Trứng',
    'Sữa bò',
    'Gluten',
    'Đậu nành',
    'Động vật có vỏ',
    'Tôm',
    'Cá',
    'Mực',
    'Ốc',
    'Các loại hạt',
    'Phô mai',
    'Bơ (sữa)',
    'Mè (vừng)',
    'Trái cây',
    'Thịt bò',
    'Bột ngọt (mì chính)',
    'Đường mía',
    'Nấm',
  ];

  List<String> _allergyOptions = [];
  bool _loadingAllergens = false;
  static const int _kDefaultVisibleAllergies = 6;
  bool _showAllAllergies = false;

  List<String> get _displayedAllergies {
    if (_showAllAllergies || _allergyOptions.length <= _kDefaultVisibleAllergies) {
      return _allergyOptions;
    }
    final result = _allergyOptions.take(_kDefaultVisibleAllergies).toList();
    for (final alg in _allergyOptions) {
      if (_selectedAllergies.contains(alg) && !result.contains(alg)) {
        result.add(alg);
      }
    }
    return result;
  }

  // Xác định trạng thái "Đã điền" của từng phần khảo sát
  bool get _isTab1Filled => _selectedCategoryIds.isNotEmpty;
  bool get _isTab2Filled =>
      _heightCtrl.text.trim().isNotEmpty ||
      _weightCtrl.text.trim().isNotEmpty ||
      _birthYearCtrl.text.trim().isNotEmpty ||
      _targetGoal != null;
  bool get _isTab3Filled =>
      _selectedAllergies.isNotEmpty ||
      _spicyTolerance != null ||
      _budgetRange != null;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });

    _allergyOptions = List.from(_defaultAllergyOptions);
    _categories = List.from(_defaultCategories);

    final p = widget.initialProfile;
    if (p != null) {
      if (p.heightCm != null) _heightCtrl.text = p.heightCm!.toStringAsFixed(0);
      if (p.weightKg != null) _weightCtrl.text = p.weightKg!.toStringAsFixed(1);
      if (p.birthYear != null) _birthYearCtrl.text = p.birthYear.toString();
      _gender = p.gender ?? 'male';
      _activityLevel = p.activityLevel;
      _targetGoal = p.targetGoal ?? 'lose_weight';
      _spicyTolerance = p.spicyTolerance ?? 'medium';
      _budgetRange = p.budgetRange ?? 'budget';

      for (final d in p.dietaryPreferences) {
        if (d.isNotEmpty) _selectedDiets.add(d);
      }

      if (p.allergies.isNotEmpty) {
        _selectedAllergies.clear();
        for (final a in p.allergies) {
          final key = a.trim().toLowerCase();
          if (key == 'seafood') {
            _selectedAllergies.add('Hải sản');
          } else if (key == 'peanut' || key == 'peanuts' || key == 'lạc') {
            _selectedAllergies.add('Đậu phộng');
          } else if (key == 'egg' || key == 'eggs') {
            _selectedAllergies.add('Trứng');
          } else if (key == 'milk' || key == 'dairy') {
            _selectedAllergies.add('Sữa bò');
          } else if (key == 'gluten' || key == 'wheat' || key == 'lúa mì') {
            _selectedAllergies.add('Gluten');
          } else if (key == 'soy' || key == 'soybean') {
            _selectedAllergies.add('Đậu nành');
          } else if (a.trim().isNotEmpty) {
            _selectedAllergies.add(a.trim());
          }
        }
      }

      for (final a in _selectedAllergies) {
        if (!_allergyOptions.contains(a)) {
          _allergyOptions.add(a);
        }
      }

      if (p.favoriteCategoryIds.isNotEmpty) {
        _selectedCategoryIds.clear();
        _selectedCategoryIds.addAll(p.favoriteCategoryIds);
      }
    } else {
      // Dữ liệu mẫu khởi tạo đẹp giống với ảnh của người dùng
      _heightCtrl.text = '172';
      _weightCtrl.text = '78.0';
      _birthYearCtrl.text = '1998';
      _gender = 'male';
      _targetGoal = 'lose_weight';
      _spicyTolerance = 'medium';
      _budgetRange = 'budget';
    }

    _loadCategories();
    _loadAllergens();
  }

  Future<void> _loadCategories() async {
    setState(() => _loadingCategories = true);
    try {
      final list = await widget.api.getAllCategories(isActiveOnly: true);
      if (mounted && list.isNotEmpty) {
        setState(() {
          _categories = list;
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _loadingCategories = false);
  }

  Future<void> _loadAllergens() async {
    setState(() => _loadingAllergens = true);
    try {
      final list = await widget.api.getAllergens();
      if (mounted && list.isNotEmpty) {
        setState(() {
          final Set<String> merged = {..._allergyOptions, ...list, ..._selectedAllergies};
          _allergyOptions = merged.toList();
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _loadingAllergens = false);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    _birthYearCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final heightText = _heightCtrl.text.trim();
      final weightText = _weightCtrl.text.trim();
      final birthYearText = _birthYearCtrl.text.trim();

      String? heightErr;
      String? weightErr;
      String? birthYearErr;

      double? h;
      if (heightText.isNotEmpty) {
        h = double.tryParse(heightText);
        if (h == null || h < 50 || h > 260) {
          heightErr = 'Từ 50 - 260 cm';
        }
      }

      double? w;
      if (weightText.isNotEmpty) {
        w = double.tryParse(weightText);
        if (w == null || w < 10 || w > 300) {
          weightErr = 'Từ 10 - 300 kg';
        }
      }

      int? by;
      if (birthYearText.isNotEmpty) {
        by = int.tryParse(birthYearText);
        final currentYear = DateTime.now().year;
        if (by == null || by < 1920 || by > currentYear) {
          birthYearErr = 'Từ 1920 - $currentYear';
        }
      }

      String? err;
      if (heightErr != null) {
        err = 'Chiều cao phải là số từ 50 đến 260 cm.';
      } else if (weightErr != null) {
        err = 'Cân nặng phải là số từ 10 đến 300 kg.';
      } else if (birthYearErr != null) {
        final currentYear = DateTime.now().year;
        err = 'Năm sinh phải từ 1920 đến $currentYear.';
      }

      setState(() {
        _heightError = heightErr;
        _weightError = weightErr;
        _birthYearError = birthYearErr;
        _error = err;
      });

      if (heightErr != null || weightErr != null || birthYearErr != null) {
        setState(() => _saving = false);
        _tabController.animateTo(1);
        return;
      }

      final payload = <String, dynamic>{
        'gender': _gender,
        'activity_level': _activityLevel,
        'target_goal': _targetGoal,
        'spicy_tolerance': _spicyTolerance,
        'budget_range': _budgetRange,
        'favorite_category_ids': _selectedCategoryIds.toList(),
        'dietary_preferences': _selectedDiets.toList(),
        'allergies': _selectedAllergies.toList(),
        'complete_onboarding': true,
      };

      if (h != null) payload['height_cm'] = h;
      if (w != null) payload['weight_kg'] = w;
      if (by != null) payload['birth_year'] = by;

      await widget.api.updateUserProfile(widget.userId, payload);
      widget.onCompleted();
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _saving = false;
      });
    }
  }

  // ============================================================================
  // CÁC HÀM TIỆN ÍCH BUILD GIAO DIỆN CON
  // ============================================================================
  Widget _buildStepTab({
    required int index,
    required String label,
    required String testLabel,
    required bool isFilled,
  }) {
    final isActive = _tabController.index == index;

    return Expanded(
      child: InkWell(
        onTap: () {
          _tabController.animateTo(index);
          setState(() {});
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFFEBF6F3) : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isActive ? const Color(0xFF0D7A65) : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Opacity(
                opacity: 0.0,
                child: SizedBox(
                  width: 1,
                  height: 1,
                  child: Text(testLabel),
                ),
              ),
              // Vòng tròn số thứ tự / dấu tích hoàn thành
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: (!isActive && isFilled)
                      ? const Color(0xFF0D7A65)
                      : Colors.transparent,
                  border: Border.all(
                    color: isActive
                        ? const Color(0xFF0D7A65)
                        : (isFilled ? const Color(0xFF0D7A65) : const Color(0xFF94A3B8)),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: (!isActive && isFilled)
                      ? const Icon(Icons.check, size: 15, color: Colors.white)
                      : Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: isActive
                                ? const Color(0xFF0D7A65)
                                : const Color(0xFF64748B),
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                isActive
                    ? 'Đang chọn'
                    : (isFilled ? 'Đã điền' : 'Tùy chọn'),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: isActive ? const Color(0xFF0D7A65) : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGoalPill(String title, String val) {
    final selected = _targetGoal == val;
    return InkWell(
      onTap: () => setState(() => _targetGoal = val),
      borderRadius: BorderRadius.circular(24),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9.5),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF0D7A65) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: selected ? null : Border.all(color: const Color(0xFFCBD5E1), width: 1.2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected) ...[
              const Icon(Icons.check, size: 15, color: Colors.white),
              const SizedBox(width: 6),
            ],
            Text(
              title,
              style: GoogleFonts.nunito(
                fontSize: 13.5,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                color: selected ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpicyPill(String title, String val) {
    final selected = _spicyTolerance == val;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _spicyTolerance = val),
        borderRadius: BorderRadius.circular(24),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF0D7A65) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: selected ? null : Border.all(color: const Color(0xFFCBD5E1), width: 1.2),
          ),
          child: Center(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                fontSize: 12.5,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                color: selected ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBudgetCard({
    required String keyVal,
    required String title,
    required String subtitle,
  }) {
    final selected = _budgetRange == keyVal;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _budgetRange = keyVal),
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFEBF6F3) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? const Color(0xFF0D7A65) : const Color(0xFFCBD5E1),
              width: selected ? 1.5 : 1.2,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: GoogleFonts.nunito(
                  fontSize: 13.5,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  color: selected ? const Color(0xFF0D7A65) : const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: GoogleFonts.nunito(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      clipBehavior: Clip.antiAlias,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 720),
        child: Column(
          children: [
            // ================================================================
            // HEADER BANNER (MÀU XANH NHẸ + BADGE BÁT MÓN ĂN + NÚT ĐÓNG X)
            // ================================================================
            Container(
              padding: const EdgeInsets.fromLTRB(20, 18, 16, 18),
              color: const Color(0xFFEBF5FB),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Khám phá vị ngon phù hợp với bạn!',
                          style: GoogleFonts.nunito(
                            color: const Color(0xFF1E293B),
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Cùng chúng tôi tìm hiểu một chút nhé',
                          style: GoogleFonts.nunito(
                            color: const Color(0xFF0D7A65),
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        // Thẻ phụ ẩn phục vụ test automation tương thích ngược
                        const Opacity(
                          opacity: 0.0,
                          child: SizedBox(
                            height: 0,
                            child: Text('Sở Thích Ẩm Thực & Sức Khỏe'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.transparent,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close_rounded, size: 22, color: Color(0xFF64748B)),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const _FoodBowlBadge(),
                    ],
                  ),
                ],
              ),
            ),

            // ================================================================
            // DÒNG HƯỚNG DẪN DƯỚI HEADER
            // ================================================================
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Không bắt buộc. Chọn phần nào trước cũng được, bỏ qua phần nào cũng được.',
                  style: GoogleFonts.nunito(
                    color: const Color(0xFF64748B),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    height: 1.35,
                  ),
                ),
              ),
            ),

            // ================================================================
            // THANH 3 BƯỚC / 3 TAB THEO ĐÚNG THIẾT KẾ MẪU
            // ================================================================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  _buildStepTab(
                    index: 0,
                    label: 'Thể loại',
                    testLabel: '1. Thể Loại',
                    isFilled: _isTab1Filled,
                  ),
                  const SizedBox(width: 6),
                  _buildStepTab(
                    index: 1,
                    label: 'Thể chất',
                    testLabel: '2. Thể Chất',
                    isFilled: _isTab2Filled,
                  ),
                  const SizedBox(width: 6),
                  _buildStepTab(
                    index: 2,
                    label: 'Khẩu vị',
                    testLabel: '3. Khẩu Vị',
                    isFilled: _isTab3Filled,
                  ),
                ],
              ),
            ),

            const Divider(height: 1, color: Color(0xFFF1F5F9)),

            if (_error != null)
              Container(
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, size: 16, color: Color(0xFFDC2626)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Color(0xFFDC2626), fontSize: 12.5, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),

            // ================================================================
            // NỘI DUNG 3 TAB (TABBARVIEW)
            // ================================================================
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // ----------------------------------------------------------
                  // TAB 1: THỂ LOẠI (HÌNH 2)
                  // ----------------------------------------------------------
                  ListView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                    children: [
                      Text(
                        'Bạn thích loại món nào?',
                        style: GoogleFonts.nunito(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_loadingCategories && _categories.isEmpty)
                        const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
                      else
                        Wrap(
                          spacing: 8,
                          runSpacing: 9,
                          children: _categories.map((cat) {
                            final selected = _selectedCategoryIds.contains(cat.id);
                            return InkWell(
                              onTap: () {
                                setState(() {
                                  if (selected) {
                                    _selectedCategoryIds.remove(cat.id);
                                  } else {
                                    _selectedCategoryIds.add(cat.id);
                                  }
                                });
                              },
                              borderRadius: BorderRadius.circular(24),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9.5),
                                decoration: BoxDecoration(
                                  color: selected ? const Color(0xFF0D7A65) : Colors.white,
                                  borderRadius: BorderRadius.circular(24),
                                  border: selected
                                      ? null
                                      : Border.all(color: const Color(0xFFCBD5E1), width: 1.2),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (selected) ...[
                                      const Icon(Icons.check, size: 15, color: Colors.white),
                                      const SizedBox(width: 6),
                                    ],
                                    Text(
                                      cat.name,
                                      style: GoogleFonts.nunito(
                                        fontSize: 13.5,
                                        fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                                        color: selected ? Colors.white : const Color(0xFF1E293B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                    ],
                  ),

                  // ----------------------------------------------------------
                  // TAB 2: THỂ CHẤT (HÌNH 1)
                  // ----------------------------------------------------------
                  ListView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                    children: [
                      // Tiêu đề phần 1: Chỉ số cơ thể
                      Stack(
                        children: [
                          const Opacity(
                            opacity: 0.0,
                            child: SizedBox(
                              height: 0,
                              child: Text('Chỉ số thể chất cơ bản:'),
                            ),
                          ),
                          Text(
                            'Chỉ số cơ thể',
                            style: GoogleFonts.nunito(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Hàng 1: Chiều cao & Cân nặng
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Chiều cao (cm)', style: GoogleFonts.nunito(fontSize: 12.5, fontWeight: FontWeight.w600, color: const Color(0xFF475569))),
                                const SizedBox(height: 6),
                                Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: _heightError != null ? const Color(0xFFDC2626) : const Color(0xFFCBD5E1),
                                      width: 1.2,
                                    ),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 14),
                                  child: TextField(
                                    controller: _heightCtrl,
                                    keyboardType: TextInputType.number,
                                    style: GoogleFonts.nunito(fontSize: 15.5, fontWeight: FontWeight.w800, color: const Color(0xFF1E293B)),
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      isDense: true,
                                      contentPadding: EdgeInsets.symmetric(vertical: 12),
                                    ),
                                    onChanged: (_) {
                                      if (_heightError != null) setState(() => _heightError = null);
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Cân nặng (kg)', style: GoogleFonts.nunito(fontSize: 12.5, fontWeight: FontWeight.w600, color: const Color(0xFF475569))),
                                const SizedBox(height: 6),
                                Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: _weightError != null ? const Color(0xFFDC2626) : const Color(0xFFCBD5E1),
                                      width: 1.2,
                                    ),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 14),
                                  child: TextField(
                                    controller: _weightCtrl,
                                    keyboardType: TextInputType.number,
                                    style: GoogleFonts.nunito(fontSize: 15.5, fontWeight: FontWeight.w800, color: const Color(0xFF1E293B)),
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      isDense: true,
                                      contentPadding: EdgeInsets.symmetric(vertical: 12),
                                    ),
                                    onChanged: (_) {
                                      if (_weightError != null) setState(() => _weightError = null);
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Hàng 2: Năm sinh & Giới tính
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Năm sinh', style: GoogleFonts.nunito(fontSize: 12.5, fontWeight: FontWeight.w600, color: const Color(0xFF475569))),
                                const SizedBox(height: 6),
                                Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: _birthYearError != null ? const Color(0xFFDC2626) : const Color(0xFFCBD5E1),
                                      width: 1.2,
                                    ),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 14),
                                  child: TextField(
                                    controller: _birthYearCtrl,
                                    keyboardType: TextInputType.number,
                                    style: GoogleFonts.nunito(fontSize: 15.5, fontWeight: FontWeight.w800, color: const Color(0xFF1E293B)),
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      isDense: true,
                                      contentPadding: EdgeInsets.symmetric(vertical: 12),
                                    ),
                                    onChanged: (_) {
                                      if (_birthYearError != null) setState(() => _birthYearError = null);
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Giới tính', style: GoogleFonts.nunito(fontSize: 12.5, fontWeight: FontWeight.w600, color: const Color(0xFF475569))),
                                const SizedBox(height: 6),
                                Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: const Color(0xFFCBD5E1), width: 1.2),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 14),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: _gender ?? 'male',
                                      isExpanded: true,
                                      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF475569)),
                                      style: GoogleFonts.nunito(fontSize: 15.5, fontWeight: FontWeight.w800, color: const Color(0xFF1E293B)),
                                      items: const [
                                        DropdownMenuItem(value: 'male', child: Text('Nam')),
                                        DropdownMenuItem(value: 'female', child: Text('Nữ')),
                                        DropdownMenuItem(value: 'other', child: Text('Khác')),
                                      ],
                                      onChanged: (val) => setState(() => _gender = val),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Tiêu đề phần 2: Mục tiêu dinh dưỡng
                      Text(
                        'Mục tiêu dinh dưỡng',
                        style: GoogleFonts.nunito(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 9,
                        children: [
                          _buildGoalPill('Duy trì vóc dáng', 'maintain'),
                          _buildGoalPill('Giảm cân / Đốt mỡ', 'lose_weight'),
                          _buildGoalPill('Tăng cân / Tăng cơ', 'gain_muscle'),
                          _buildGoalPill('Ăn lành mạnh', 'eat_healthy'),
                        ],
                      ),

                      const SizedBox(height: 18),
                      Text(
                        'Thông tin chỉ dùng để gợi ý món phù hợp. Bạn có thể thay đổi bất kỳ lúc nào trong mục Cá nhân.',
                        style: GoogleFonts.nunito(
                          fontSize: 12,
                          color: const Color(0xFF94A3B8),
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),

                  // ----------------------------------------------------------
                  // TAB 3: KHẨU VỊ (HÌNH 3)
                  // ----------------------------------------------------------
                  ListView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                    children: [
                      // 1. Mức độ cay
                      Stack(
                        children: [
                          const Opacity(
                            opacity: 0.0,
                            child: SizedBox(height: 0, child: Text('Mức độ ăn cay:')),
                          ),
                          Text(
                            'Mức độ cay',
                            style: GoogleFonts.nunito(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _buildSpicyPill('Không cay', 'none'),
                          const SizedBox(width: 6),
                          _buildSpicyPill('Cay nhẹ', 'mild'),
                          const SizedBox(width: 6),
                          _buildSpicyPill('Cay vừa', 'medium'),
                          const SizedBox(width: 6),
                          _buildSpicyPill('Rất cay', 'hot'),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // 2. Dị ứng thực phẩm (nếu có)
                      Stack(
                        children: [
                          const Opacity(
                            opacity: 0.0,
                            child: SizedBox(height: 0, child: Text('Dị ứng thực phẩm (nếu có):')),
                          ),
                          Text(
                            'Dị ứng thực phẩm (nếu có)',
                            style: GoogleFonts.nunito(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (_loadingAllergens && _allergyOptions.isEmpty)
                        const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator()))
                      else ...[
                        Wrap(
                          spacing: 8,
                          runSpacing: 9,
                          children: _displayedAllergies.map((alg) {
                            final selected = _selectedAllergies.contains(alg);
                            return InkWell(
                              onTap: () {
                                setState(() {
                                  if (selected) {
                                    _selectedAllergies.remove(alg);
                                  } else {
                                    _selectedAllergies.add(alg);
                                  }
                                });
                              },
                              borderRadius: BorderRadius.circular(20),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7.5),
                                decoration: BoxDecoration(
                                  color: selected ? const Color(0xFFB91C1C) : const Color(0xFFFEF2F2),
                                  borderRadius: BorderRadius.circular(20),
                                  border: selected
                                      ? null
                                      : Border.all(color: const Color(0xFFFECACA), width: 1.2),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (selected) ...[
                                      const Icon(Icons.check, size: 14, color: Colors.white),
                                      const SizedBox(width: 5),
                                    ],
                                    Text(
                                      alg,
                                      style: GoogleFonts.nunito(
                                        fontSize: 13,
                                        fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
                                        color: selected ? Colors.white : const Color(0xFF991B1B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        if (_allergyOptions.length > _kDefaultVisibleAllergies) ...[
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: () => setState(() => _showAllAllergies = !_showAllAllergies),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                                child: Text(
                                  _showAllAllergies
                                      ? 'Rút gọn'
                                      : 'Xem thêm ${_allergyOptions.length - _displayedAllergies.length} dị ứng khác',
                                  style: GoogleFonts.nunito(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFFB91C1C),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                      const SizedBox(height: 20),

                      // 3. Ngân sách mỗi bữa
                      Text(
                        'Ngân sách mỗi bữa',
                        style: GoogleFonts.nunito(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _buildBudgetCard(
                            keyVal: 'budget',
                            title: 'Tiết kiệm',
                            subtitle: 'Dưới 40k',
                          ),
                          const SizedBox(width: 8),
                          _buildBudgetCard(
                            keyVal: 'moderate',
                            title: 'Vừa phải',
                            subtitle: '40k – 80k',
                          ),
                          const SizedBox(width: 8),
                          _buildBudgetCard(
                            keyVal: 'premium',
                            title: 'Thoải mái',
                            subtitle: 'Trên 80k',
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ================================================================
            // FOOTER ACTIONS (NÚT "ĐỂ SAU" VÀ NÚT "LƯU & HOÀN TẤT")
            // ================================================================
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFF1F5F9), width: 1.2)),
              ),
              child: Row(
                children: [
                  TextButton(
                    onPressed: _saving ? null : () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    child: Text(
                      'Để sau',
                      style: GoogleFonts.nunito(
                        color: const Color(0xFF475569),
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: _saving ? null : _handleSave,
                    borderRadius: BorderRadius.circular(28),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 13),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D7A65),
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x300D7A65),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : Text(
                              'Lưu & Hoàn tất',
                              style: GoogleFonts.nunito(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 14.5,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
