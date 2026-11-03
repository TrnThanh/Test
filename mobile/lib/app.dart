import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'l10n/app_language.dart';
import 'services/api_service.dart';
import 'shell/main_shell.dart';
import 'theme/app_colors.dart';

class Ptc1App extends StatelessWidget {
  final ApiService? apiService;

  const Ptc1App({
    super.key,
    this.apiService,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppLanguage.instance,
      builder: (context, _) {
        return MaterialApp(
          title: 'PTC1 Spatial Food',
          debugShowCheckedModeBanner: false,
          locale: AppLanguage.instance.locale,
          scrollBehavior: const MaterialScrollBehavior().copyWith(
            dragDevices: {
              PointerDeviceKind.mouse,
              PointerDeviceKind.touch,
              PointerDeviceKind.stylus,
              PointerDeviceKind.trackpad,
            },
          ),
          builder: (context, child) {
            final mq = MediaQuery.of(context);
            final insets = mq.viewInsets;
            if (insets.bottom < 0 || insets.top < 0 || insets.left < 0 || insets.right < 0) {
              final clampedInsets = EdgeInsets.only(
                left: insets.left < 0 ? 0.0 : insets.left,
                top: insets.top < 0 ? 0.0 : insets.top,
                right: insets.right < 0 ? 0.0 : insets.right,
                bottom: insets.bottom < 0 ? 0.0 : insets.bottom,
              );
              return MediaQuery(
                data: mq.copyWith(viewInsets: clampedInsets),
                child: child ?? const SizedBox.shrink(),
              );
            }
            return child ?? const SizedBox.shrink();
          },
          theme: ThemeData(
            useMaterial3: true,
            scaffoldBackgroundColor: kScaffoldBg,
            colorScheme: ColorScheme.fromSeed(
              seedColor: kPrimaryGreen,
              primary: kPrimaryGreen,
              surface: Colors.white,
            ),
            fontFamily: 'BeVietnamPro',
            appBarTheme: const AppBarTheme(
              centerTitle: false,
              elevation: 0,
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              foregroundColor: kTextDark,
              titleTextStyle: TextStyle(
                color: kTextDark,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
              iconTheme: IconThemeData(color: kTextDark),
            ),
            filledButtonTheme: FilledButtonThemeData(
              style: FilledButton.styleFrom(
                backgroundColor: kPrimaryGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                textStyle: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            outlinedButtonTheme: OutlinedButtonThemeData(
              style: OutlinedButton.styleFrom(
                foregroundColor: kPrimaryGreen,
                side: const BorderSide(color: kPrimaryGreen),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                textStyle: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: kBorderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: kBorderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: kPrimaryGreen, width: 1.8),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
          home: MainShell(
            apiService: apiService ?? ApiService(),
          ),
        );
      },
    );
  }
}
