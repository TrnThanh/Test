# -*- coding: utf-8 -*-
"""
Chuyển đổi dữ liệu 400 mẫu thời tiết từ tệp SQL (scripts/weather_400_mau_so_2000_2025.sql)
sang tệp JSON chuẩn hoá (scripts/weather_400_mau_so_2000_2025.json) phục vụ tự động nạp (seed) vào PostgreSQL.
"""
import json
import re
import sys
from pathlib import Path

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")

def convert_weather_sql_to_json():
    sql_path = Path(__file__).resolve().parent / "weather_400_mau_so_2000_2025.sql"
    json_path = Path(__file__).resolve().parent / "weather_400_mau_so_2000_2025.json"

    pattern = re.compile(
        r"VALUES\s*\(\s*(\d+),\s*'([^']*)',\s*'([^']*)',\s*'([^']*)',\s*([-\d.]+),\s*([-\d.]+),\s*'([^']*)',\s*'([^']*)',\s*'([^']*)',\s*(\d+),\s*(TRUE|FALSE),\s*'([^']*)'\s*\)\s*;",
        re.IGNORECASE
    )

    records = []
    with open(sql_path, "r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            m = pattern.search(line)
            if m:
                records.append({
                    "id": int(m.group(1)),
                    "code": m.group(2),
                    "name": m.group(3),
                    "description": m.group(4),
                    "min_temp": float(m.group(5)),
                    "max_temp": float(m.group(6)),
                    "condition": m.group(7),
                    "icon": m.group(8),
                    "season": m.group(9),
                    "sort_order": int(m.group(10)),
                    "is_active": (m.group(11).upper() == "TRUE"),
                    "created_at": m.group(12)
                })

    print(f"[*] Đã trích xuất thành công {len(records)} bản ghi thời tiết từ SQL.")
    assert len(records) == 400, f"Dữ liệu không đủ 400 bản ghi, chỉ có {len(records)} bản ghi!"

    with open(json_path, "w", encoding="utf-8") as f:
        json.dump(records, f, ensure_ascii=False, indent=2)

    print(f"[*] Đã lưu thành công file JSON tại: {json_path}")
    print(f"[*] Mẫu đầu tiên (#1): {records[0]['code']} - {records[0]['name']}")
    print(f"[*] Mẫu cuối cùng (#400): {records[-1]['code']} - {records[-1]['name']}")

if __name__ == "__main__":
    convert_weather_sql_to_json()
