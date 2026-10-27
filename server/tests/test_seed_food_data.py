"""Kiểm thử tính toàn vẹn và hợp lệ của bộ dữ liệu ẩm thực Huyện Gia Lâm."""

import pytest
from fastapi.testclient import TestClient
from server.app.main import app
from server.app.db.session import SessionLocal
from server.app.models.restaurant import Restaurant
from server.app.models.category import Category
from server.app.models.dish import Dish
from server.app.services.initial_seed_service import is_in_gia_lam


client = TestClient(app)


def test_seeded_restaurants_inside_gia_lam():
    """Kiểm tra 100% quán ăn trong DB đều nằm trong ranh giới Huyện Gia Lâm."""
    db = SessionLocal()
    try:
        restaurants = db.query(Restaurant).filter(Restaurant.is_active == True).all()
        assert len(restaurants) >= 150, f"Kỳ vọng tối thiểu 150 quán ăn Gia Lâm, hiện có: {len(restaurants)}"
        
        for r in restaurants:
            assert is_in_gia_lam(r.latitude, r.longitude), (
                f"Quán '{r.name}' ({r.latitude}, {r.longitude}) nằm ngoài ranh giới Gia Lâm!"
            )
            assert r.address and "Gia Lâm" in r.address
            assert r.open_time is not None
            assert r.close_time is not None
            assert isinstance(r.service_licenses, list)
    finally:
        db.close()


def test_seeded_categories_exist():
    """Kiểm tra danh mục ẩm thực toàn cục đã được tạo đầy đủ."""
    db = SessionLocal()
    try:
        categories = db.query(Category).filter(Category.is_active == True).all()
        cat_names = [c.name for c in categories]
        
        expected_cats = ["Phở & Bún", "Cơm & Xôi", "Bánh mì", "Đồ ăn vặt", "Cà phê & Trà sữa", "Lẩu & Nướng"]
        for expected in expected_cats:
            assert expected in cat_names, f"Thiếu danh mục '{expected}'"
    finally:
        db.close()


def test_dishes_with_images_and_calories():
    """Kiểm tra toàn bộ món ăn đều có ảnh, calo, giá và bữa ăn hợp lệ."""
    db = SessionLocal()
    try:
        dishes = db.query(Dish).filter(Dish.is_available == True).all()
        assert len(dishes) >= 450, f"Kỳ vọng tối thiểu 450 món ăn, hiện có: {len(dishes)}"

        for d in dishes:
            assert d.price > 0, f"Món {d.name} có giá không hợp lệ: {d.price}"
            assert d.calories and d.calories > 0, f"Món {d.name} thiếu calo: {d.calories}"
            assert d.image_url and d.image_url.startswith("https://images.unsplash.com/"), (
                f"Món {d.name} có ảnh không hợp lệ: {d.image_url}"
            )
            assert d.meal_types and len(d.meal_types) > 0, f"Món {d.name} thiếu meal_types"
            assert isinstance(d.spicy_level, int) and 0 <= d.spicy_level <= 3
            assert isinstance(d.dietary_tags, list)
            assert isinstance(d.ingredients, list)
    finally:
        db.close()


def test_sponsored_restaurants_present():
    """Kiểm tra có các quán tài trợ nổi bật."""
    db = SessionLocal()
    try:
        sponsored = db.query(Restaurant).filter(Restaurant.is_sponsor == True).all()
        assert len(sponsored) >= 5, f"Kỳ vọng tối thiểu 5 quán tài trợ, hiện có: {len(sponsored)}"
        for s in sponsored:
            assert s.name
            assert s.is_active
    finally:
        db.close()
