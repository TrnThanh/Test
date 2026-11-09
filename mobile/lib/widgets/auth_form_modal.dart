import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../l10n/app_language.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../utils/helpers.dart';

// ==========================================
// FORM ĐĂNG NHẬP / ĐĂNG KÝ CHUẨN MOCKUP NUTRIFOOD PTC1
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
  bool _rememberLogin = true;
  bool _agreeTerms = true;

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

  bool _isEmailValid(String email) {
    return RegExp(r'^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+$').hasMatch(email);
  }

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    final pwd = _passwordCtrl.text;

    if (email.isEmpty || pwd.isEmpty) {
      setState(() {
        _emailError = email.isEmpty ? tr('err_email_empty') : null;
        _passwordError = pwd.isEmpty ? tr('err_pwd_empty') : null;
        _generalError = 'Vui lòng nhập đầy đủ Email và Mật khẩu';
      });
      return;
    }

    if (!_isEmailValid(email)) {
      setState(() {
        _emailError = tr('err_email_invalid');
        _generalError = 'Địa chỉ email không đúng định dạng';
      });
      return;
    }

    if (pwd.length < 6) {
      setState(() {
        _passwordError = tr('err_pwd_min');
        _generalError = 'Mật khẩu phải có tối thiểu 6 ký tự';
      });
      return;
    }

    if (_isRegister) {
      final confirmPwd = _confirmPasswordCtrl.text;
      if (confirmPwd.isEmpty) {
        setState(() {
          _confirmPasswordError = tr('err_confirm_pwd_empty');
          _generalError = 'Vui lòng xác nhận lại mật khẩu';
        });
        return;
      } else if (confirmPwd != pwd) {
        setState(() {
          _confirmPasswordError = tr('err_confirm_pwd_mismatch');
          _generalError = 'Mật khẩu xác nhận không trùng khớp';
        });
        return;
      }

      final phone = _phoneCtrl.text.trim();
      if (phone.isNotEmpty) {
        final phoneRegex = RegExp(r'^(0|\+84)(3|5|7|8|9)[0-9]{8}$');
        if (!phoneRegex.hasMatch(phone)) {
          setState(() {
            _phoneError = tr('err_phone_invalid');
            _generalError = 'Số điện thoại không hợp lệ (gồm 10 số, đầu 03, 05, 07, 08, 09)';
          });
          return;
        }
      }
    }

    setState(() {
      _emailError = null;
      _passwordError = null;
      _confirmPasswordError = null;
      _phoneError = null;
      _generalError = null;
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
        final errStr = e.toString().toLowerCase();
        if (errStr.contains('401') ||
            errStr.contains('incorrect') ||
            errStr.contains('sai email') ||
            errStr.contains('tài khoản hoặc mật khẩu không chính xác') ||
            errStr.contains('unauthorized')) {
          setState(() {
            _generalError = tr('err_login_credentials');
          });
        } else {
          setState(() {
            _generalError = formatErrorMessage(e);
          });
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  void _showForgotPassword() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.lock_reset_rounded, color: Color(0xFF16A34A)),
            const SizedBox(width: 8),
            Text(tr('forgot_pwd_title'), style: GoogleFonts.nunito(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Text(
          tr('forgot_pwd_desc'),
          style: GoogleFonts.nunito(fontSize: 13, height: 1.4),
        ),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF16A34A)),
            onPressed: () => Navigator.pop(ctx),
            child: Text(tr('close')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAF8),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 12,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Thanh kéo drag handle gọn gàng
              Center(
                child: Container(
                  width: 44,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              Center(
                child: Text(
                  !_isRegister ? tr('modal_login_title') : tr('modal_register_title'),
                  style: GoogleFonts.nunito(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1E293B),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // 4. Tab Switcher bo tròn: [Đăng nhập] | [Đăng ký]
              Container(
                height: 44,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          if (_isRegister) {
                            setState(() {
                              _isRegister = false;
                              _generalError = null;
                            });
                          }
                        },
                        borderRadius: BorderRadius.circular(18),
                        child: Container(
                          decoration: BoxDecoration(
                            color: !_isRegister ? const Color(0xFF064E3B) : Colors.transparent,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (!_isRegister) ...[
                                const Icon(Icons.login_rounded, size: 16, color: Colors.white),
                                const SizedBox(width: 6),
                              ],
                              Text(
                                'Đăng nhập',
                                style: GoogleFonts.nunito(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: !_isRegister ? Colors.white : const Color(0xFF475569),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          if (!_isRegister) {
                            setState(() {
                              _isRegister = true;
                              _generalError = null;
                            });
                          }
                        },
                        borderRadius: BorderRadius.circular(18),
                        child: Container(
                          decoration: BoxDecoration(
                            color: _isRegister ? const Color(0xFF064E3B) : Colors.transparent,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (_isRegister) ...[
                                const Icon(Icons.person_add_alt_1_rounded, size: 16, color: Colors.white),
                                const SizedBox(width: 6),
                              ],
                              Text(
                                'Đăng ký',
                                style: GoogleFonts.nunito(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: _isRegister ? Colors.white : const Color(0xFF475569),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Thông báo lỗi nếu có
              if (_generalError != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(
                    '⚠️ $_generalError',
                    style: GoogleFonts.nunito(color: Colors.red.shade800, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
              const SizedBox(height: 14),

              // 5. White Form Card chứa các trường nhập liệu
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10, offset: const Offset(0, 3)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // A. Trường: Họ và tên (chỉ khi đăng ký)
                    if (_isRegister) ...[
                      Row(
                        children: [
                          const Icon(Icons.assignment_ind_outlined, size: 15, color: Color(0xFF16A34A)),
                          const SizedBox(width: 6),
                          Text(
                            tr('label_fullname'),
                            style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF334155)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Container(
                        height: 46,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.person_outline_rounded, size: 19, color: Color(0xFF64748B)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: _nameCtrl,
                                style: GoogleFonts.nunito(fontSize: 13.5, color: const Color(0xFF1E293B)),
                                decoration: InputDecoration(
                                  hintText: 'Nguyễn Hoàng Minh',
                                  hintStyle: GoogleFonts.nunito(color: const Color(0xFF94A3B8), fontSize: 13.5),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // B. Trường: Email
                    Row(
                      children: [
                        const Text('@', style: TextStyle(color: Color(0xFF16A34A), fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(width: 6),
                        Text(
                          tr('label_email'),
                          style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF334155)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 46,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _emailError != null ? Colors.red : const Color(0xFFCBD5E1)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.mail_outline_rounded, size: 19, color: Color(0xFF64748B)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _emailCtrl,
                              keyboardType: TextInputType.emailAddress,
                              onChanged: (val) {
                                if (_emailError != null) setState(() => _emailError = null);
                              },
                              style: GoogleFonts.nunito(fontSize: 13.5, color: const Color(0xFF1E293B)),
                              decoration: InputDecoration(
                                hintText: 'hoangminh.ptc1@gmail.com',
                                hintStyle: GoogleFonts.nunito(color: const Color(0xFF94A3B8), fontSize: 13.5),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                          if (_isEmailValid(_emailCtrl.text.trim()))
                            const Icon(Icons.check_circle_rounded, size: 18, color: Color(0xFF16A34A)),
                        ],
                      ),
                    ),
                    if (_emailError != null) ...[
                      const SizedBox(height: 4),
                      Text(_emailError!, style: GoogleFonts.nunito(color: Colors.red, fontSize: 11)),
                    ] else if (_isRegister && _isEmailValid(_emailCtrl.text.trim())) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.check_circle_outline_rounded, size: 13, color: Color(0xFF16A34A)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Email hợp lệ, dùng để nhận lịch gợi ý vi chất bữa ăn',
                              style: GoogleFonts.nunito(fontSize: 11.5, color: const Color(0xFF16A34A), fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 12),

                    // C. Trường: Số điện thoại (chỉ khi đăng ký)
                    if (_isRegister) ...[
                      Row(
                        children: [
                          const Icon(Icons.phone_outlined, size: 15, color: Color(0xFF16A34A)),
                          const SizedBox(width: 6),
                          Text(
                            'Số điện thoại',
                            style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF334155)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Container(
                        height: 46,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _phoneError != null ? Colors.red : const Color(0xFFCBD5E1)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.phone_android_rounded, size: 19, color: Color(0xFF64748B)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: _phoneCtrl,
                                keyboardType: TextInputType.phone,
                                onChanged: (val) {
                                  if (_phoneError != null) setState(() => _phoneError = null);
                                },
                                style: GoogleFonts.nunito(fontSize: 13.5, color: const Color(0xFF1E293B)),
                                decoration: InputDecoration(
                                  hintText: '0984 215 678',
                                  hintStyle: GoogleFonts.nunito(color: const Color(0xFF94A3B8), fontSize: 13.5),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_phoneError != null) ...[
                        const SizedBox(height: 4),
                        Text(_phoneError!, style: GoogleFonts.nunito(color: Colors.red, fontSize: 11)),
                      ],
                      const SizedBox(height: 12),
                    ],

                    // D. Trường: Mật khẩu
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.vpn_key_outlined, size: 15, color: Color(0xFF16A34A)),
                            const SizedBox(width: 6),
                            Text(
                              tr('label_password'),
                              style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF334155)),
                            ),
                          ],
                        ),
                        if (!_isRegister)
                          InkWell(
                            onTap: _showForgotPassword,
                            child: Text(
                              'Quên mật khẩu?',
                              style: GoogleFonts.nunito(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF0D9488),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 46,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _passwordError != null ? Colors.red : const Color(0xFFCBD5E1)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.lock_outline_rounded, size: 19, color: Color(0xFF64748B)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _passwordCtrl,
                              obscureText: _obscurePassword,
                              onChanged: (val) {
                                if (_passwordError != null) setState(() => _passwordError = null);
                                setState(() {});
                              },
                              style: GoogleFonts.nunito(fontSize: 13.5, color: const Color(0xFF1E293B)),
                              decoration: InputDecoration(
                                hintText: '•••••••••••••••••',
                                hintStyle: GoogleFonts.nunito(color: const Color(0xFF94A3B8), fontSize: 13.5),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                              size: 19,
                              color: const Color(0xFF64748B),
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ],
                      ),
                    ),
                    if (_passwordError != null) ...[
                      const SizedBox(height: 4),
                      Text(_passwordError!, style: GoogleFonts.nunito(color: Colors.red, fontSize: 11)),
                    ],

                    // Thanh đo độ an toàn sinh học (chỉ khi đăng ký)
                    if (_isRegister) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: List.generate(4, (i) {
                          final strong = _passwordCtrl.text.length >= (i + 1) * 2;
                          return Expanded(
                            child: Container(
                              height: 4,
                              margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
                              decoration: BoxDecoration(
                                color: strong ? const Color(0xFF16A34A) : const Color(0xFFCBD5E1),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Text('Độ an toàn sinh học: ', style: GoogleFonts.nunito(fontSize: 11.5, color: const Color(0xFF64748B))),
                          const Icon(Icons.shield_rounded, size: 12, color: Color(0xFF16A34A)),
                          const SizedBox(width: 3),
                          Text(
                            _passwordCtrl.text.length >= 8 ? 'Mật khẩu rất mạnh' : (_passwordCtrl.text.length >= 6 ? 'Mật khẩu tốt' : 'Mật khẩu ngắn'),
                            style: GoogleFonts.nunito(fontSize: 11.5, color: const Color(0xFF166534), fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // E. Trường: Xác nhận mật khẩu
                      Row(
                        children: [
                          const Icon(Icons.history_rounded, size: 15, color: Color(0xFF16A34A)),
                          const SizedBox(width: 6),
                          Text(
                            'Xác nhận mật khẩu',
                            style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF334155)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Container(
                        height: 46,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _confirmPasswordError != null ? Colors.red : const Color(0xFFCBD5E1)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.shield_outlined, size: 19, color: Color(0xFF64748B)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: _confirmPasswordCtrl,
                                obscureText: _obscureConfirmPassword,
                                onChanged: (val) {
                                  if (_confirmPasswordError != null) setState(() => _confirmPasswordError = null);
                                  setState(() {});
                                },
                                style: GoogleFonts.nunito(fontSize: 13.5, color: const Color(0xFF1E293B)),
                                decoration: InputDecoration(
                                  hintText: '•••••••••••••••••',
                                  hintStyle: GoogleFonts.nunito(color: const Color(0xFF94A3B8), fontSize: 13.5),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ),
                            if (_confirmPasswordCtrl.text.isNotEmpty && _confirmPasswordCtrl.text == _passwordCtrl.text)
                              const Icon(Icons.check_circle_rounded, size: 18, color: Color(0xFF16A34A)),
                          ],
                        ),
                      ),
                      if (_confirmPasswordError != null) ...[
                        const SizedBox(height: 4),
                        Text(_confirmPasswordError!, style: GoogleFonts.nunito(color: Colors.red, fontSize: 11)),
                      ] else if (_confirmPasswordCtrl.text.isNotEmpty && _confirmPasswordCtrl.text == _passwordCtrl.text) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.check, size: 13, color: Color(0xFF16A34A)),
                            const SizedBox(width: 4),
                            Text('Khớp mật khẩu bảo vệ', style: GoogleFonts.nunito(fontSize: 11.5, color: const Color(0xFF16A34A), fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ],
                    ],
                    const SizedBox(height: 12),

                    // F. Tùy chọn Ghi nhớ / Điều khoản
                    if (!_isRegister)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          InkWell(
                            onTap: () => setState(() => _rememberLogin = !_rememberLogin),
                            borderRadius: BorderRadius.circular(6),
                            child: Row(
                              children: [
                                Container(
                                  width: 18,
                                  height: 18,
                                  decoration: BoxDecoration(
                                    color: _rememberLogin ? const Color(0xFF064E3B) : Colors.white,
                                    borderRadius: BorderRadius.circular(5),
                                    border: Border.all(color: _rememberLogin ? const Color(0xFF064E3B) : const Color(0xFFCBD5E1)),
                                  ),
                                  child: _rememberLogin
                                      ? const Icon(Icons.check, size: 13, color: Colors.white)
                                      : null,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Ghi nhớ đăng nhập',
                                  style: GoogleFonts.nunito(fontSize: 12.5, fontWeight: FontWeight.w600, color: const Color(0xFF334155)),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              const Icon(Icons.lock_outline_rounded, size: 14, color: Color(0xFF0D9488)),
                              const SizedBox(width: 4),
                              Text(
                                'Phiên an toàn 30 ngày',
                                style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF0D9488)),
                              ),
                            ],
                          ),
                        ],
                      )
                    else
                      InkWell(
                        onTap: () => setState(() => _agreeTerms = !_agreeTerms),
                        borderRadius: BorderRadius.circular(6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 18,
                              height: 18,
                              margin: const EdgeInsets.only(top: 2),
                              decoration: BoxDecoration(
                                color: _agreeTerms ? const Color(0xFF064E3B) : Colors.white,
                                borderRadius: BorderRadius.circular(5),
                                border: Border.all(color: _agreeTerms ? const Color(0xFF064E3B) : const Color(0xFFCBD5E1)),
                              ),
                              child: _agreeTerms
                                  ? const Icon(Icons.check, size: 13, color: Colors.white)
                                  : null,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Tôi đồng ý với Quy chế hoạt động & Chính sách bảo mật an toàn dinh dưỡng của NutriFood PTC1.',
                                style: GoogleFonts.nunito(fontSize: 12, color: const Color(0xFF334155), height: 1.3, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),

                    // G. NÚT SUBMIT CHÍNH: [Đăng nhập ->] hoặc [Đăng ký tài khoản ->]
                    SizedBox(
                      height: 48,
                      width: double.infinity,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF064E3B),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        ),
                        onPressed: _loading ? null : _submit,
                        child: _loading
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _isRegister ? tr('btn_submit_register') : tr('btn_submit_login'),
                                    style: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.arrow_forward_rounded, size: 18, color: Colors.white),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // 6. KHỐI KHÁM PHÁ VỚI TƯ CÁCH KHÁCH
              InkWell(
                onTap: () => Navigator.pop(context),
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDFA),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFF99F6E4), style: BorderStyle.solid),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Color(0xFFDCFCE7),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.explore_outlined, color: Color(0xFF0F766E), size: 18),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'Tiếp tục khám phá với tư cách Khách',
                              style: GoogleFonts.nunito(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF0F766E),
                              ),
                            ),
                            Text(
                              '(Không cần đăng ký)',
                              style: GoogleFonts.nunito(
                                fontSize: 11.5,
                                color: const Color(0xFF0F766E),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded, color: Color(0xFF0F766E), size: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // 7. Dòng chú thích phiên bản dưới cùng
              Text(
                'Phiên bản PTC1 • Chuẩn hóa chỉ số BMI & khí hậu địa phương',
                style: GoogleFonts.nunito(
                  fontSize: 11,
                  color: const Color(0xFF94A3B8),
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
