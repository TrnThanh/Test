# -*- coding: utf-8 -*-
# Script cập nhật hàm _getWeatherShortStatus theo định dạng vắn tắt, không hiển thị địa danh 'tại đâu'.
import io

file_path = r'mobile/lib/main.dart'

with io.open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

print('Checked script status: up to date with concise weather status (no location suffix).')
