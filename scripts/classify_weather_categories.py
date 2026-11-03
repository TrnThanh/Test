"""Script tự động phân loại và gán nhãn 10 thể loại món ăn Việt Nam vào bảng thời tiết (weather_categories).

Sử dụng ma trận Scoring Rule Engine đa trục (Nhiệt độ, Mưa, Khung giờ ăn, Mùa) kết hợp Memoization Cache
để xử lý toàn bộ 96,000 bản ghi quan trắc theo giờ một cách siêu tốc và an toàn (Idempotent).
"""

import sys
import os
import argparse
import time
from typing import Dict, List

# Đảm bảo import được module từ thư mục gốc
ROOT_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
if ROOT_DIR not in sys.path:
    sys.path.insert(0, ROOT_DIR)

if sys.stdout.encoding.lower() != "utf-8":
    sys.stdout.reconfigure(encoding="utf-8")

from sqlalchemy import select, func, text
from sqlalchemy.dialects.postgresql import insert as pg_insert
from server.app.db.session import SessionLocal
from server.app.models.weather import Weather
from server.app.models.category import Category
from server.app.models.weather_category import WeatherCategory
from server.app.services.category_service import CategoryService
from server.app.core.weather_food_rules import (
    classify_food_categories,
    get_weather_category_cache_key,
    CATEGORY_NAMES,
)


def run_classification(force: bool = False, batch_size: int = 5000) -> None:
    start_time = time.time()
    print("=" * 70)
    print("🚀 BẮT ĐẦU PHÂN LOẠI 10 THỂ LOẠI MÓN ĂN VÀO THỜI TIẾT (WEATHER_CATEGORIES)")
    print("=" * 70)

    with SessionLocal() as db:
        # 1. Đảm bảo 10 Master Categories đã được khởi tạo
        CategoryService.seed_default_categories(db)
        cats = db.scalars(select(Category).order_by(Category.id)).all()
        print(f"✅ Hệ thống đã sẵn sàng {len(cats)} Master Categories:")
        for c in cats:
            print(f"   [{c.id:2d}] {c.name} (order: {c.display_order})")

        # 2. Kiểm tra trạng thái hiện tại
        current_count = db.scalar(select(func.count(WeatherCategory.id))) or 0
        total_weather = db.scalar(select(func.count(Weather.id))) or 0
        print(f"\n📊 Tổng số bản ghi thời tiết: {total_weather:,}")
        print(f"📊 Số liên kết hiện tại trong weather_categories: {current_count:,}")

        if not force and current_count > 0:
            print("\n⚠️  Bảng weather_categories đã có dữ liệu. Thêm cờ '--force' để phân loại và ghi đè lại toàn bộ.")
            _print_category_stats(db)
            return

        if force:
            print("\n🔄 Đang dọn sạch liên kết cũ qua TRUNCATE...")
            db.execute(text("TRUNCATE TABLE weather_categories RESTART IDENTITY CASCADE;"))
            db.commit()

        # 3. Đọc toàn bộ bản ghi thời tiết
        print("\n⏳ Đang tải dữ liệu thời tiết và phân loại qua Rule Engine...")
        rows = db.execute(
            text("SELECT id, temperature, precipitation, condition, season, hour FROM weather ORDER BY id;")
        ).fetchall()

        if not rows:
            print("❌ Không tìm thấy bản ghi thời tiết nào trong bảng 'weather'!")
            return

        rule_cache: Dict[tuple, List[int]] = {}
        links_batch: List[dict] = []
        total_inserted = 0

        for r in rows:
            wid, temp, precip, cond, season, hour = r[0], r[1], r[2], r[3], r[4], r[5]
            ckey = get_weather_category_cache_key(temp, hour, precip, cond, season)
            if ckey not in rule_cache:
                rule_cache[ckey] = classify_food_categories(temp, hour, precip, cond, season)
            cat_ids = rule_cache[ckey]

            for cid in cat_ids:
                links_batch.append({"weather_id": wid, "category_id": cid})
                if len(links_batch) >= batch_size:
                    stmt = pg_insert(WeatherCategory).values(links_batch).on_conflict_do_nothing(
                        index_elements=["weather_id", "category_id"]
                    )
                    db.execute(stmt)
                    total_inserted += len(links_batch)
                    links_batch = []

        if links_batch:
            stmt = pg_insert(WeatherCategory).values(links_batch).on_conflict_do_nothing(
                index_elements=["weather_id", "category_id"]
            )
            db.execute(stmt)
            total_inserted += len(links_batch)

        db.commit()
        elapsed = time.time() - start_time
        print(f"\n🎉 Hoàn thành xuất sắc!")
        print(f"⏱️  Thời gian thực thi: {elapsed:.2f} giây")
        print(f"🔢 Tổng số liên kết đã nạp: {total_inserted:,}")
        print(f"⚡ Số tổ hợp thời tiết độc nhất đã cache: {len(rule_cache)}")

        # 4. Thống kê phân bổ
        _print_category_stats(db)


def _print_category_stats(db) -> None:
    print("\n📈 BẢNG THỐNG KÊ PHÂN BỔ 10 THỂ LOẠI MÓN ĂN THEO THỜI TIẾT:")
    print("-" * 65)
    print(f"{'ID':<4} | {'Tên Thể Loại':<32} | {'Số liên kết':<12} | {'Tỷ lệ':<8}")
    print("-" * 65)

    stats = db.execute(text("""
        SELECT c.id, c.name, COUNT(wc.id) as link_count
        FROM categories c
        LEFT JOIN weather_categories wc ON c.id = wc.category_id
        GROUP BY c.id, c.name
        ORDER BY c.id;
    """)).fetchall()

    total_links = sum(r[2] for r in stats) or 1
    for r in stats:
        pct = (r[2] / total_links) * 100
        print(f"{r[0]:<4} | {r[1]:<32} | {r[2]:<12,d} | {pct:6.2f}%")
    print("-" * 65)
    print(f"{'TỔNG':<4} | {'':<32} | {total_links:<12,d} | 100.00%")
    print("=" * 70)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Tự động phân loại 10 thể loại món ăn theo thời tiết")
    parser.add_argument("--force", action="store_true", help="Xóa sạch dữ liệu cũ và phân loại lại toàn bộ từ đầu")
    parser.add_argument("--batch-size", type=int, default=5000, help="Kích thước lô bulk insert (mặc định: 5000)")
    args = parser.parse_args()

    run_classification(force=args.force, batch_size=args.batch_size)
