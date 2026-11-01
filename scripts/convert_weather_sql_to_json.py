# -*- coding: utf-8 -*-
"""
Chuyển đổi dữ liệu 4000 mẫu thời tiết từ tệp SQL (scripts/weather_4000_mau_so_2000_2025.sql)
sang tệp JSON chuẩn hoá (scripts/weather_4000_mau_so_2000_2025.json) phục vụ tự động nạp (seed) vào PostgreSQL.
"""
import argparse
import json
import re
import sys
from pathlib import Path

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")


def convert_weather_sql_to_json(sql_filename: str = "weather_4000_mau_so_2000_2025.sql", json_filename: str = "weather_4000_mau_so_2000_2025.json", expected_count: int = 4000):
    script_dir = Path(__file__).resolve().parent
    sql_path = script_dir / sql_filename
    json_path = script_dir / json_filename

    if not sql_path.exists():
        raise FileNotFoundError(f"Không tìm thấy file SQL tại: {sql_path}")

    pattern = re.compile(
        r"VALUES\s*\(\s*(\d+),\s*'([^']*)',\s*'([^']*)',\s*'([^']*)',\s*([-\d.]+),\s*([-\d.]+),\s*([-\d.]+),\s*([-\d.]+),\s*'([^']*)',\s*'([^']*)',\s*'([^']*)',\s*(\d+),\s*(TRUE|FALSE),\s*'([^']*)'\s*\)\s*;",
        re.IGNORECASE
    )

    records = []
    seen_codes = set()
    seasons_count = {"spring": 0, "summer": 0, "autumn": 0, "winter": 0}

    with open(sql_path, "r", encoding="utf-8") as f:
        for line_num, line in enumerate(f, 1):
            line = line.strip()
            m = pattern.search(line)
            if m:
                code = m.group(2)
                min_temp = float(m.group(5))
                max_temp = float(m.group(6))
                min_humidity = int(round(float(m.group(7))))
                max_humidity = int(round(float(m.group(8))))
                season = m.group(11).lower()

                # Validate data integrity
                assert code not in seen_codes, f"Duplicate code tại dòng {line_num}: {code}"
                seen_codes.add(code)
                assert min_temp <= max_temp, f"Lỗi nhiệt độ min > max tại dòng {line_num}: {min_temp} > {max_temp}"
                assert 0 <= min_humidity <= 100, f"Độ ẩm min ngoài khoảng 0-100 tại dòng {line_num}: {min_humidity}"
                assert 0 <= max_humidity <= 100, f"Độ ẩm max ngoài khoảng 0-100 tại dòng {line_num}: {max_humidity}"
                assert min_humidity <= max_humidity, f"Độ ẩm min > max tại dòng {line_num}: {min_humidity} > {max_humidity}"
                if season in seasons_count:
                    seasons_count[season] += 1

                records.append({
                    "id": int(m.group(1)),
                    "code": code,
                    "name": m.group(3),
                    "description": m.group(4),
                    "min_temp": min_temp,
                    "max_temp": max_temp,
                    "min_humidity": min_humidity,
                    "max_humidity": max_humidity,
                    "condition": m.group(9),
                    "icon": m.group(10),
                    "season": season,
                    "sort_order": int(m.group(12)),
                    "is_active": (m.group(13).upper() == "TRUE"),
                    "created_at": m.group(14)
                })

    print(f"[*] Đã trích xuất thành công {len(records)} bản ghi thời tiết từ SQL ({sql_filename}).")
    for s, cnt in seasons_count.items():
        print(f"    - Mùa {s}: {cnt} mẫu")

    if expected_count:
        assert len(records) == expected_count, f"Dữ liệu không đủ {expected_count} bản ghi, chỉ có {len(records)} bản ghi!"

    with open(json_path, "w", encoding="utf-8") as f:
        json.dump(records, f, ensure_ascii=False, indent=2)

    print(f"[*] Đã lưu thành công file JSON tại: {json_path}")
    print(f"[*] Mẫu đầu tiên (#1): {records[0]['code']} - {records[0]['name']} (Độ ẩm: {records[0]['min_humidity']}% - {records[0]['max_humidity']}%)")
    print(f"[*] Mẫu cuối cùng (#{len(records)}): {records[-1]['code']} - {records[-1]['name']} (Độ ẩm: {records[-1]['min_humidity']}% - {records[-1]['max_humidity']}%)")
    return records


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Chuyển đổi SQL weather mẫu thành JSON")
    parser.add_argument("--sql", default="weather_4000_mau_so_2000_2025.sql", help="Tên file SQL nguồn")
    parser.add_argument("--json", default="weather_4000_mau_so_2000_2025.json", help="Tên file JSON đích")
    parser.add_argument("--expected", type=int, default=4000, help="Số lượng bản ghi kỳ vọng")
    args = parser.parse_args()

    convert_weather_sql_to_json(args.sql, args.json, args.expected)
