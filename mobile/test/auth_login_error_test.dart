import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/models/models.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/utils/helpers.dart';
import 'package:mobile/widgets/auth_form_modal.dart';

class MockFailedLoginApiService extends ApiService {
  @override
  Future<RoleLoginResponse> loginUser(String email, String password) async {
    // Giả lập lỗi 401 khi người dùng nhập sai email/mật khẩu
    throw Exception('Lỗi máy chủ (401)');
  }
}

class MockIncorrectCredentialsApiService extends ApiService {
  @override
  Future<RoleLoginResponse> loginUser(String email, String password) async {
    throw Exception('Incorrect email or password');
  }
}

void main() {
  test('formatErrorMessage chuyển đổi lỗi 401 sang thông báo thân thiện', () {
    expect(
      formatErrorMessage(Exception('Lỗi máy chủ (401)')),
      'Tài khoản hoặc mật khẩu không chính xác. Vui lòng kiểm tra lại!',
    );
    expect(
      formatErrorMessage(Exception('Incorrect email or password')),
      'Tài khoản hoặc mật khẩu không chính xác. Vui lòng kiểm tra lại!',
    );
  });

  testWidgets('AuthFormModal hiển thị thông báo thân thiện khi nhập sai tài khoản/mật khẩu', (WidgetTester tester) async {
    final mockApi = MockFailedLoginApiService();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AuthFormModal(
            api: mockApi,
            onSuccess: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final textFields = find.byType(TextField);
    await tester.enterText(textFields.at(0), 'user@example.com');
    await tester.enterText(textFields.at(1), 'wrong_password');

    await tester.tap(find.widgetWithText(FilledButton, 'Đăng nhập'));
    await tester.pumpAndSettle();

    // Không còn hiển thị lỗi kỹ thuật 401
    expect(find.textContaining('401'), findsNothing);
    expect(find.textContaining('Lỗi máy chủ'), findsNothing);

    // Hiển thị thông báo thân thiện
    expect(
      find.text('⚠️ Tài khoản hoặc mật khẩu không chính xác. Vui lòng kiểm tra lại!'),
      findsOneWidget,
    );
  });

  testWidgets('AuthFormModal hiển thị thông báo thân thiện khi backend trả về Incorrect email or password', (WidgetTester tester) async {
    final mockApi = MockIncorrectCredentialsApiService();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AuthFormModal(
            api: mockApi,
            onSuccess: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final textFields = find.byType(TextField);
    await tester.enterText(textFields.at(0), 'user@example.com');
    await tester.enterText(textFields.at(1), 'wrong_password');

    await tester.tap(find.widgetWithText(FilledButton, 'Đăng nhập'));
    await tester.pumpAndSettle();

    // Không hiển thị lỗi tiếng Anh hoặc mã lỗi
    expect(find.textContaining('Incorrect email or password'), findsNothing);

    // Hiển thị thông báo tiếng Việt thân thiện
    expect(
      find.text('⚠️ Tài khoản hoặc mật khẩu không chính xác. Vui lòng kiểm tra lại!'),
      findsOneWidget,
    );
  });
}
