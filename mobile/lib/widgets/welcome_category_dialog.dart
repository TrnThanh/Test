import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class WelcomeCategoryDialog extends StatefulWidget {
  final String? selectedCategory;
  final Function(String) onCategorySelected;

  const WelcomeCategoryDialog({
    super.key,
    this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  State<WelcomeCategoryDialog> createState() => _WelcomeCategoryDialogState();
}

class _WelcomeCategoryDialogState extends State<WelcomeCategoryDialog> {
  String? _chosen;

  final List<Map<String, dynamic>> _categories = const [
    {'name': 'Phở & Bún', 'icon': Icons.ramen_dining, 'desc': 'Phở bò, bún bò huế, bún chả'},
    {'name': 'Cơm & Xôi', 'icon': Icons.rice_bowl, 'desc': 'Cơm tấm, cơm gà, xôi xéo'},
    {'name': 'Bánh mì', 'icon': Icons.bakery_dining, 'desc': 'Bánh mì pate, chả, trứng giòn'},
    {'name': 'Đồ ăn vặt', 'icon': Icons.fastfood, 'desc': 'Trà sữa, bánh tráng, xiên que'},
    {'name': 'Cà phê & Trà sữa', 'icon': Icons.local_cafe, 'desc': 'Cà phê muối, trà sen, trà đào'},
    {'name': 'Lẩu & Nướng', 'icon': Icons.outdoor_grill, 'desc': 'Lẩu thái, nướng BBQ, bò tơ'},
  ];

  @override
  void initState() {
    super.initState();
    _chosen = widget.selectedCategory ?? 'Phở & Bún';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 580),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.restaurant, size: 26, color: kPrimaryGreen),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Hôm Nay Bạn Muốn Ăn Gì?',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      SizedBox(height: 2),
                      Text('Chọn thể loại để PTC1 chuẩn bị món ngon cho bạn',
                          style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            const Text('Chọn 1 thể loại món bạn muốn ăn nhất:',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.separated(
                itemCount: _categories.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (ctx, i) {
                  final item = _categories[i];
                  final name = item['name']!;
                  final isSelected = _chosen == name;
                  return InkWell(
                    onTap: () => setState(() => _chosen = name),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? kPrimaryGreen : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? kPrimaryGreen : kBorderColor,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            item['icon'] as IconData,
                            color: isSelected ? Colors.white : Colors.black87,
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: isSelected ? Colors.white : Colors.black,
                                  ),
                                ),
                                Text(
                                  item['desc']!,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isSelected ? Colors.white70 : Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            const Icon(Icons.check_circle, color: Colors.white, size: 20),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                TextButton(
                  onPressed: () {
                    widget.onCategorySelected('Tất cả');
                    Navigator.of(context).pop();
                  },
                  child: const Text('Xem tất cả món', style: TextStyle(color: Colors.grey)),
                ),
                const Spacer(),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    if (_chosen != null) {
                      widget.onCategorySelected(_chosen!);
                    }
                    Navigator.of(context).pop();
                  },
                  child: const Text('Khám Phá', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}