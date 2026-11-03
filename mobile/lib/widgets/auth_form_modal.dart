import 'package:flutter/material.dart';
import '../l10n/app_language.dart';
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
  final _phoneCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  bool _loading = false;
  String? _generalError;
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;
  String? _phoneError;

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _isRegister = widget.initialRegister;
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    final pwd = _passwordCtrl.text;

    String? emailErr;
    String? pwdErr;
    String? confirmPwdErr;
    String? phoneErr;

    if (email.isEmpty) {
      emailErr = tr('err_email_empty');
    } else {
      final emailRegex = RegExp(r'^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+$');
      if (!emailRegex.hasMatch(email)) {
        emailErr = tr('err_email_invalid');
      }
    }

    if (pwd.isEmpty) {
      pwdErr = tr('err_pwd_empty');
    } else if (pwd.length < 6) {
      pwdErr = tr('err_pwd_min');
    }

    if (_isRegister) {
      final confirmPwd = _confirmPasswordCtrl.text;
      if (confirmPwd.isEmpty) {
        confirmPwdErr = tr('err_confirm_pwd_empty');
      } else if (confirmPwd != pwd) {
        confirmPwdErr = tr('err_confirm_pwd_mismatch');
      }

      final phone = _phoneCtrl.text.trim();
      if (phone.isNotEmpty) {
        final phoneRegex = RegExp(r'^(0|\+84)(3|5|7|8|9)[0-9]{8}$');
        if (!phoneRegex.hasMatch(phone)) {
          phoneErr = tr('err_phone_invalid');
        }
      }
    }

    setState(() {
      _emailError = emailErr;
      _passwordError = pwdErr;
      _confirmPasswordError = confirmPwdErr;
      _phoneError = phoneErr;
      _generalError = null;
    });

    if (emailErr != null || pwdErr != null || confirmPwdErr != null || phoneErr != null) {
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      RoleLoginResponse res;
      if (!_isRegister) {
        res = await widget.api.loginUser(email, pwd);
      } else {
        final confirmPwd = _confirmPasswordCtrl.text;
        final name = _nameCtrl.text.trim();
        final phone = _phoneCtrl.text.trim();
        res = await widget.api.registerUser(email, pwd, name, phone, confirmPwd);
      }
      if (mounted) {
        Navigator.pop(context);
        widget.onSuccess(res);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _generalError = formatErrorMessage(e);
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
    return SingleChildScrollView(
      child: Padding(
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
                  _isRegister ? tr('modal_register_title') : tr('modal_login_title'),
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
              segments: [
                ButtonSegment(value: false, label: Text(tr('tab_btn_login'), style: const TextStyle(fontWeight: FontWeight.bold))),
                ButtonSegment(value: true, label: Text(tr('tab_btn_register'), style: const TextStyle(fontWeight: FontWeight.bold))),
              ],
              selected: {_isRegister},
              onSelectionChanged: (set) {
                setState(() {
                  _isRegister = set.first;
                  _generalError = null;
                  _emailError = null;
                  _passwordError = null;
                  _confirmPasswordError = null;
                  _phoneError = null;
                });
              },
            ),

            if (_generalError != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('⚠️ $_generalError', style: TextStyle(color: Colors.red.shade800, fontSize: 13)),
              ),
            ],

            const SizedBox(height: 14),

            TextField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              onChanged: (val) {
                if (_emailError != null) setState(() => _emailError = null);
              },
              decoration: InputDecoration(
                labelText: tr('label_email'),
                errorText: _emailError,
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _passwordCtrl,
              obscureText: _obscurePassword,
              onChanged: (val) {
                if (_passwordError != null) setState(() => _passwordError = null);
              },
              decoration: InputDecoration(
                labelText: tr('label_password'),
                errorText: _passwordError,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey,
                  ),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
            ),

            if (_isRegister) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _confirmPasswordCtrl,
                obscureText: _obscureConfirmPassword,
                onChanged: (val) {
                  if (_confirmPasswordError != null) setState(() => _confirmPasswordError = null);
                },
                decoration: InputDecoration(
                  labelText: tr('label_confirm_password'),
                  errorText: _confirmPasswordError,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey,
                    ),
                    onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _nameCtrl,
                decoration: InputDecoration(labelText: tr('label_fullname')),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                onChanged: (val) {
                  if (_phoneError != null) setState(() => _phoneError = null);
                },
                decoration: InputDecoration(
                  labelText: tr('label_phone'),
                  hintText: '0987...',
                  errorText: _phoneError,
                ),
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
                    : Text(_isRegister ? tr('btn_submit_register') : tr('btn_submit_login'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
