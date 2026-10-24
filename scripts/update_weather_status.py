# -*- coding: utf-8 -*-
import io

file_path = r'mobile/lib/main.dart'

with io.open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

old_func = """  String _getWeatherShortStatus(CurrentWeather? weather) {
    if (weather == null) return 'Trời mát mẻ';
    final desc = weather.description.trim();
    if (desc.isNotEmpty) {
      return desc[0].toUpperCase() + desc.substring(1);
    }
    final temp = weather.temperature;
    if (temp < 20) return 'Trời se lạnh';
    if (temp < 26) return 'Trời mát mẻ';
    if (temp < 32) return 'Trời nắng nhẹ';
    return 'Trời oi nóng';
  }"""

new_func = """  String _getWeatherShortStatus(CurrentWeather? weather) {
    if (weather == null) return 'Trời mát mẻ';
    final cond = weather.condition.toLowerCase();
    final desc = weather.description.toLowerCase();
    final temp = weather.temperature;

    if (cond.contains('rain') || desc.contains('mưa')) {
      return 'Trời có mưa';
    } else if (temp < 22) {
      return 'Trời se lạnh';
    } else if (temp < 28 || cond.contains('cloud') || desc.contains('mây')) {
      return 'Trời mát mẻ';
    } else if (temp < 33) {
      return 'Trời nắng nhẹ';
    } else {
      return 'Trời oi nóng';
    }
  }"""

assert old_func in content, "old_func not found"
content = content.replace(old_func, new_func, 1)

with io.open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print("SUCCESS: Updated _getWeatherShortStatus to natural concise weather wording!")
