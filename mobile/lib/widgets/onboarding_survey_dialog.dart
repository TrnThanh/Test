import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';

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

class _OnboardingSurveyDialogState extends State<OnboardingSurveyDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _heightCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _birthYearCtrl = TextEditingController();

  String? _gender;
  String? _activityLevel;
  String? _targetGoal;
  String? _spicyTolerance;
  String? _budgetRange;

  final Set<String> _selectedDiets = {};
  final Set<String> _selectedAllergies = {};

  bool _saving = false;
  String? _error;
  String? _heightError;
  String? _weightError;
  String? _birthYearError;

  static final List<Category> _defaultCategories = [
    Category(id: 1, name: 'Phở & Bún', displayOrder: 1, isActive: true),
    Category(id: 2, name: 'Cơm & Xôi', displayOrder: 2, isActive: true),
    Category(id: 3, name: 'Bánh mì', displayOrder: 3, isActive: true),
    Category(id: 4, name: 'Đồ ăn vặt', displayOrder: 4, isActive: true),
    Category(id: 5, name: 'Cà phê & Trà sữa', displayOrder: 5, isActive: true),
    Category(id: 6, name: 'Lẩu & Nướng', displayOrder: 6, isActive: true),
  ];

  List<Category> _categories = [];
  bool _loadingCategories = false;
  final Set<int> _selectedCategoryIds = {};

  final List<String> _dietOptions = [
    'Ăn sạch',
    'Ăn thanh đạm',
    'Ít dầu mỡ',
    'Low-carb',
    'Keto',
    'Ăn chay',
    'Nhiều đạm',
  ];

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _allergyOptions = List.from(_defaultAllergyOptions);

    final p = widget.initialProfile;
    if (p != null) {
      if (p.heightCm != null) _heightCtrl.text = p.heightCm!.toStringAsFixed(0);
      if (p.weightKg != null) _weightCtrl.text = p.weightKg!.toStringAsFixed(1);
      if (p.birthYear != null) _birthYearCtrl.text = p.birthYear.toString();
      _gender = p.gender;
      _activityLevel = p.activityLevel;
      _targetGoal = p.targetGoal ?? 'maintain';
      _spicyTolerance = p.spicyTolerance ?? 'mild';
      _budgetRange = p.budgetRange ?? 'moderate';
      for (final d in p.dietaryPreferences) {
        if (d == 'clean_eating' || d == 'eat_clean' || d == 'Eat clean') {
          _selectedDiets.add('Ăn sạch');
        } else if (d == 'high_protein' || d == 'Nhiều protein') {
          _selectedDiets.add('Nhiều đạm');
        } else {
          _selectedDiets.add(d);
        }
      }
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
        } else if (key == 'hoa quả' || key == 'trái cây' || key == 'fruit' || key == 'fruits') {
          _selectedAllergies.add('Trái cây');
        } else if (key == 'vừng' || key == 'mè' || key == 'mè (vừng)' || key == 'sesame') {
          _selectedAllergies.add('Mè (vừng)');
        } else if (a.trim().isNotEmpty) {
          _selectedAllergies.add(a.trim());
        }
      }
      for (final a in _selectedAllergies) {
        if (!_allergyOptions.contains(a)) {
          _allergyOptions.add(a);
        }
      }
      _selectedCategoryIds.addAll(p.favoriteCategoryIds);
    } else {
      _targetGoal = 'maintain';
      _spicyTolerance = 'mild';
      _budgetRange = 'moderate';
      _gender = 'male';
    }
    _categories = _defaultCategories;
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

      setState(() {
        _heightError = heightErr;
        _weightError = weightErr;
        _birthYearError = birthYearErr;
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

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 680),
        child: Column(
          children: [
            // Header Dialog
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.restaurant_menu, color: Colors.white, size: 24),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Sở Thích Ẩm Thực & Sức Khỏe',
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        Text('Giúp PTC1 gợi ý món ăn chuẩn gu & thể trạng của bạn',
                            style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Tab bar 3 bước
            TabBar(
              controller: _tabController,
              labelColor: Colors.black,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.black,
              tabs: const [
                Tab(icon: Icon(Icons.fastfood_outlined, size: 20), text: '1. Thể Loại'),
                Tab(icon: Icon(Icons.fitness_center_outlined, size: 20), text: '2. Thể Chất'),
                Tab(icon: Icon(Icons.tune, size: 20), text: '3. Khẩu Vị'),
              ],
            ),

            if (_error != null)
              Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(8),
                color: Colors.red[50],
                child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 12)),
              ),

            // Nội dung các tab
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // TAB 1: Thể loại món & Chế độ ăn
                  ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      const Text('Bạn thích những thể loại món ăn nào?',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 8),
                      if (_loadingCategories && _categories.isEmpty)
                        const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator()))
                      else
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _categories.map((cat) {
                            final selected = _selectedCategoryIds.contains(cat.id);
                            return FilterChip(
                              label: Text(cat.name),
                              selected: selected,
                              selectedColor: kPrimaryGreen,
                              labelStyle: TextStyle(
                                color: selected ? Colors.white : kTextDark,
                                fontSize: 13,
                                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                              ),
                              backgroundColor: Colors.grey[100],
                              onSelected: (val) {
                                setState(() {
                                  if (val) {
                                    _selectedCategoryIds.add(cat.id);
                                  } else {
                                    _selectedCategoryIds.remove(cat.id);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                      const SizedBox(height: 20),
                      const Text('Chế độ ăn uống quan tâm:',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _dietOptions.map((diet) {
                          final selected = _selectedDiets.contains(diet);
                          return FilterChip(
                            label: Text(diet),
                            selected: selected,
                            selectedColor: Colors.purple[700],
                            labelStyle: TextStyle(
                              color: selected ? Colors.white : Colors.purple[900],
                              fontSize: 13,
                              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                            ),
                            backgroundColor: Colors.purple[50],
                            onSelected: (val) {
                              setState(() {
                                if (val) {
                                  _selectedDiets.add(diet);
                                } else {
                                  _selectedDiets.remove(diet);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),

                  // TAB 2: Thể chất & Mục tiêu sức khỏe
                  ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      const Text('Chỉ số thể chất cơ bản:',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _heightCtrl,
                              keyboardType: TextInputType.number,
                              onChanged: (val) {
                                if (_heightError != null) setState(() => _heightError = null);
                              },
                              decoration: InputDecoration(
                                labelText: 'Chiều cao (cm)',
                                hintText: '170',
                                border: const OutlineInputBorder(),
                                suffixText: 'cm',
                                errorText: _heightError,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _weightCtrl,
                              keyboardType: TextInputType.number,
                              onChanged: (val) {
                                if (_weightError != null) setState(() => _weightError = null);
                              },
                              decoration: InputDecoration(
                                labelText: 'Cân nặng (kg)',
                                hintText: '65',
                                border: const OutlineInputBorder(),
                                suffixText: 'kg',
                                errorText: _weightError,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _birthYearCtrl,
                              keyboardType: TextInputType.number,
                              onChanged: (val) {
                                if (_birthYearError != null) setState(() => _birthYearError = null);
                              },
                              decoration: InputDecoration(
                                labelText: 'Năm sinh',
                                hintText: '2000',
                                border: const OutlineInputBorder(),
                                errorText: _birthYearError,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _gender ?? 'male',
                              decoration: const InputDecoration(
                                labelText: 'Giới tính',
                                border: OutlineInputBorder(),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'male', child: Text('Nam')),
                                DropdownMenuItem(value: 'female', child: Text('Nữ')),
                                DropdownMenuItem(value: 'other', child: Text('Khác')),
                              ],
                              onChanged: (val) => setState(() => _gender = val),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Text('Mục tiêu dinh dưỡng hiện tại:',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          ChoiceChip(
                            label: const Text('Duy trì vóc dáng'),
                            selected: _targetGoal == 'maintain',
                            onSelected: (_) => setState(() => _targetGoal = 'maintain'),
                          ),
                          ChoiceChip(
                            label: const Text('Giảm cân / Đốt mỡ'),
                            selected: _targetGoal == 'lose_weight',
                            onSelected: (_) => setState(() => _targetGoal = 'lose_weight'),
                          ),
                          ChoiceChip(
                            label: const Text('Tăng cân / Tăng cơ'),
                            selected: _targetGoal == 'gain_muscle',
                            onSelected: (_) => setState(() => _targetGoal = 'gain_muscle'),
                          ),
                          ChoiceChip(
                            label: const Text('Ăn uống lành mạnh'),
                            selected: _targetGoal == 'eat_healthy',
                            onSelected: (_) => setState(() => _targetGoal = 'eat_healthy'),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // TAB 3: Khẩu vị & Dị ứng & Ngân sách
                  ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      const Text('Mức độ ăn cay:',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          ChoiceChip(
                            label: const Text('Không ăn cay'),
                            selected: _spicyTolerance == 'none',
                            onSelected: (_) => setState(() => _spicyTolerance = 'none'),
                          ),
                          ChoiceChip(
                            label: const Text('Cay nhẹ'),
                            selected: _spicyTolerance == 'mild',
                            onSelected: (_) => setState(() => _spicyTolerance = 'mild'),
                          ),
                          ChoiceChip(
                            label: const Text('Cay vừa'),
                            selected: _spicyTolerance == 'medium',
                            onSelected: (_) => setState(() => _spicyTolerance = 'medium'),
                          ),
                          ChoiceChip(
                            label: const Text('Rất cay'),
                            selected: _spicyTolerance == 'hot',
                            onSelected: (_) => setState(() => _spicyTolerance = 'hot'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      const Text('Dị ứng thực phẩm (nếu có):',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 8),
                      if (_loadingAllergens && _allergyOptions.isEmpty)
                        const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator()))
                      else ...[
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _displayedAllergies.map((alg) {
                            final selected = _selectedAllergies.contains(alg);
                            return FilterChip(
                              label: Text(alg),
                              selected: selected,
                              selectedColor: Colors.red[700],
                              labelStyle: TextStyle(
                                color: selected ? Colors.white : Colors.red[900],
                                fontSize: 13,
                              ),
                              backgroundColor: Colors.red[50],
                              onSelected: (val) {
                                setState(() {
                                  if (val) {
                                    _selectedAllergies.add(alg);
                                  } else {
                                    _selectedAllergies.remove(alg);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                        if (_allergyOptions.length > _kDefaultVisibleAllergies) ...[
                          const SizedBox(height: 6),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: () => setState(() => _showAllAllergies = !_showAllAllergies),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _showAllAllergies
                                          ? 'Rút gọn'
                                          : 'Xem thêm (${_allergyOptions.length - _displayedAllergies.length} dị ứng khác)',
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFFDC2626),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      _showAllAllergies
                                          ? Icons.keyboard_arrow_up_rounded
                                          : Icons.keyboard_arrow_down_rounded,
                                      size: 18,
                                      color: const Color(0xFFDC2626),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                      const SizedBox(height: 18),
                      const Text('Ngân sách ăn uống:',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          ChoiceChip(
                            label: const Text('Tiết kiệm (< 40k)'),
                            selected: _budgetRange == 'budget',
                            onSelected: (_) => setState(() => _budgetRange = 'budget'),
                          ),
                          ChoiceChip(
                            label: const Text('Vừa phải (40k - 80k)'),
                            selected: _budgetRange == 'moderate',
                            onSelected: (_) => setState(() => _budgetRange = 'moderate'),
                          ),
                          ChoiceChip(
                            label: const Text('Thoải mái (> 80k)'),
                            selected: _budgetRange == 'premium',
                            onSelected: (_) => setState(() => _budgetRange = 'premium'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Footer Actions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                border: Border(top: BorderSide(color: Colors.grey[200]!)),
              ),
              child: Row(
                children: [
                  TextButton(
                    onPressed: _saving ? null : () => Navigator.of(context).pop(),
                    child: const Text('Để sau', style: TextStyle(color: Colors.grey)),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    onPressed: _saving ? null : _handleSave,
                    child: _saving
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Lưu & Hoàn tất'),
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


// ============================================================================
// WELCOME CATEGORY DIALOG (MỚI VÀO PHẢI CHỌN THỂ LOẠI MÓN ĂN)
// ============================================================================
