import 'package:flutter/material.dart';
import 'app.dart';

// Tái xuất (re-export) toàn bộ module để đảm bảo tương thích ngược 100%
export 'app.dart';
export 'l10n/app_language.dart';
export 'l10n/app_strings.dart';
export 'painters/golden_moon.dart';
export 'painters/leaves_painter.dart';
export 'painters/spark_painter.dart';
export 'painters/weather_painters.dart';
export 'screens/account_screen.dart';
export 'screens/explore_screen.dart';
export 'screens/favourites_screen.dart';
export 'screens/map_screen.dart';
export 'shell/main_shell.dart';
export 'theme/app_colors.dart';
export 'utils/helpers.dart';
export 'widgets/auth_form_modal.dart';
export 'widgets/onboarding_survey_dialog.dart';
export 'widgets/restaurant_menu_widget.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const Ptc1App());
}
