# -*- coding: utf-8 -*-
"""
Script chuẩn hóa trường name trong bảng weather và dataset JSON:
- Loại bỏ chuỗi khung giờ bị nhồi vào name: (HH:00 - Mẫu NNNN Mùa X)
- Khôi phục tên gốc chuẩn sạch từ 4,000 pattern: 'Trời quang / Nắng đẹp - Mẫu 0001 (Mùa Xuân)'
- Bổ sung trường hour_display dạng 12-hour AM/PM ('7:00 AM') vào dataset JSON
"""
import json
import logging
import sys
import time
from pathlib import Path

# Đảm bảo UTF-8 cho Windows console
if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")

root_dir = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(root_dir))

from sqlalchemy import text
from server.app.core.time_utils import format_hour_12h
from server.app.db.session import engine

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")
logger = logging.getLogger("clean_weather_names")


def clean_weather_dataset_and_database() -> None:
    logger.info("🚀 BẮT ĐẦU CHUẨN HOÁ TÊN THỜI TIẾT VÀ BỔ SUNG HOUR_DISPLAY")
    t0 = time.time()

    # 1. Đọc ánh xạ mã pattern -> tên chuẩn sạch từ weather_4000_mau_so_2000_2025.json
    source_4000_path = root_dir / "scripts" / "weather_4000_mau_so_2000_2025.json"
    if not source_4000_path.exists():
        source_4000_path = root_dir / "weather_4000_mau_so_2000_2025.json"

    logger.info("1. Đọc 4,000 mẫu gốc từ %s...", source_4000_path.name)
    with open(source_4000_path, "r", encoding="utf-8") as f:
        data_4000 = json.load(f)

    pattern_names = {item["code"]: item["name"] for item in data_4000}
    logger.info("   Đã nạp %s tên mẫu chuẩn sạch.", len(pattern_names))

    # 2. Cập nhật bảng weather trong cơ sở dữ liệu PostgreSQL qua Temporary Table JOIN Update
    logger.info("2. Cập nhật chuẩn hoá bảng weather trong PostgreSQL...")
    with engine.begin() as conn:
        conn.execute(
            text("""
            CREATE TEMP TABLE temp_clean_patterns (
                pattern_code VARCHAR(50) PRIMARY KEY,
                clean_name VARCHAR(255) NOT NULL
            ) ON COMMIT DROP;
            """)
        )

        # Nạp theo batch vào temp table
        batch_tuples = [{"code": code, "name": name} for code, name in pattern_names.items()]
        conn.execute(
            text("INSERT INTO temp_clean_patterns (pattern_code, clean_name) VALUES (:code, :name);"),
            batch_tuples,
        )

        # Chạy UPDATE nối bảng
        res = conn.execute(
            text("""
            UPDATE weather w
            SET name = tp.clean_name
            FROM temp_clean_patterns tp
            WHERE w.pattern_code = tp.pattern_code;
            """)
        )
        logger.info("   Đã cập nhật thành công %s bản ghi trong bảng weather PostgreSQL.", res.rowcount)

        # Kiểm tra xác nhận không còn bản ghi nào chứa chuỗi giờ
        dirty_count = conn.execute(
            text("SELECT COUNT(*) FROM weather WHERE name LIKE :pattern;"),
            {"pattern": "%:00 - %"}
        ).scalar()
        logger.info("   Số bản ghi còn sót chuỗi (HH:00 trong name: %s", dirty_count)
        assert dirty_count == 0, f"Lỗi: Còn {dirty_count} bản ghi chưa được làm sạch tên!"

    # 3. Chuẩn hóa dataset JSON weather_4000_mau_so_flat_hourly.json
    target_files = [
        root_dir / "scripts" / "weather_4000_mau_so_flat_hourly.json",
        root_dir / "weather_4000_mau_so_flat_hourly.json",
    ]

    for p in target_files:
        if p.exists():
            logger.info("3. Cập nhật tệp JSON: %s...", p.name)
            with open(p, "r", encoding="utf-8") as f:
                records = json.load(f)

            for r in records:
                p_code = r.get("pattern_code")
                if p_code in pattern_names:
                    r["name"] = pattern_names[p_code]
                h = r.get("hour")
                if h is not None:
                    r["hour_display"] = format_hour_12h(int(h))

            with open(p, "w", encoding="utf-8") as f:
                json.dump(records, f, ensure_ascii=False, indent=2)
            logger.info("   Đã lưu %s bản ghi sạch vào %s.", len(records), p.name)

    logger.info("✅ HOÀN TẤT CHUẨN HOÁ TRONG %.2fs!", time.time() - t0)


if __name__ == "__main__":
    clean_weather_dataset_and_database()
