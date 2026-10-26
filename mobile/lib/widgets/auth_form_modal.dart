import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../utils/helpers.dart';

// ==========================================
// FORM ĐĂNG NHẬP / ĐĂNG KÝ MODAL BOTTOM SHEET
// ==========================================
class AuthFormModal extends StatefulWidget {
  final ApiService api;
  final bool initialRegister;
  final Function(RoleLoginResponse) onSuccess;

  const AuthFormModal({
    super.key,
    required this.api,
    this.initialRegister = false,
    required this.onSuccess,
  });

  @override
  State<AuthFormModal> createState() => _AuthFormModalState();
}

class _AuthFormModalState extends State<AuthFormModal> {
  late bool _isRegister;
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();

  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _isRegister = widget.initialRegister;
  }

  void _fillSampleAccount() {
    setState(() {
      _emailCtrl.text = 'user@example.com';
      _passwordCtrl.text = '123456';
      if (_isRegister) {
        _nameCtrl.text = 'Nguyễn Văn Thực Khách';
      }
    });
  }

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    final pwd = _passwordCtrl.text;
    if (email.isEmpty || pwd.isEmpty) {
      setState(() => _error = 'Vui lòng nhập đầy đủ Email và Mật khẩu');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      RoleLoginResponse res;
      if (!_isRegister) {
        res = await widget.api.loginUser(email, pwd);
      } else {
        final name = _nameCtrl.text.trim();
        res = await widget.api.registerUser(email, pwd, name);
      }
      if (mounted) {
        Navigator.pop(context);
        widget.onSuccess(res);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = formatErrorMessage(e);
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _isRegister ? 'Tạo Tài Khoản Khách Hàng' : 'Đăng Nhập Khách Hàng',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: kTextDark),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.grey),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 8),

          SegmentedButton<bool>(
            style: SegmentedButton.styleFrom(
              selectedBackgroundColor: kPrimaryGreen,
              selectedForegroundColor: Colors.white,
              backgroundColor: Colors.white,
              foregroundColor: kTextDark,
              side: const BorderSide(color: kBorderColor),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            segments: const [
              ButtonSegment(value: false, label: Text('Đăng nhập', style: TextStyle(fontWeight: FontWeight.bold))),
              ButtonSegment(value: true, label: Text('Đăng ký', style: TextStyle(fontWeight: FontWeight.bold))),
            ],
            selected: {_isRegister},
            onSelectionChanged: (set) {
              setState(() {
                _isRegister = set.first;
                _error = null;
              });
            },
          ),

          if (_error != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('⚠️ $_error', style: TextStyle(color: Colors.red.shade800, fontSize: 13)),
            ),
          ],

          const SizedBox(height: 14),

          // Nút điền nhanh tài khoản mẫu
          InkWell(
            onTap: _fillSampleAccount,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: kSuperLightGreen,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: kPrimaryGreen.withAlpha(80)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.flash_on_rounded, size: 16, color: kPrimaryGreen),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Bấm để điền nhanh tài khoản mẫu (user@example.com / 123456)',
                      style: TextStyle(fontSize: 11, color: kPrimaryGreen, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 14),

          TextField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Email *'),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _passwordCtrl,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Mật khẩu *'),
          ),

          if (_isRegister) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Họ và tên'),
            ),
          ],

          const SizedBox(height: 20),

          SizedBox(
            height: 48,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: kPrimaryGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(_isRegister ? 'Đăng ký ngay' : 'Đăng nhập', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
