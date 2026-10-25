"""Kiểm thử tính toàn vẹn và hợp lệ của bộ dữ liệu ẩm thực Huyện Gia Lâm."""

import pytest
from fastapi.testclient import TestClient
from server.app.main import app
from server.app.db.session import SessionLocal
from server.app.models.restaurant import Restaurant
from server.app.models.category import Category
from server.app.models.dish import Dish
from scripts.seed_gialam_food_data import is_in_gia_lam


client = TestClient(app)


def test_seeded_restaurants_inside_gia_lam():
    """Kiểm tra 100% quán ăn trong DB đều nằm trong ranh giới Huyện Gia Lâm."""
    db = SessionLocal()
    try:
        restaurants = db.query(Restaurant).filter(Restaurant.is_active == True).all()
        assert len(restaurants) >= 8, f"Kỳ vọng tối thiểu 8 quán ăn Gia Lâm, hiện có: {len(restaurants)}"
        
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
        assert len(dishes) >= 24, f"Kỳ vọng tối thiểu 24 món ăn, hiện có: {len(dishes)}"

        for d in dishes:
            assert d.price > 0, f"Món {d.name} có giá không hợp lệ: {d.price}"
            assert d.calories and d.calories > 0, f"Món {d.name} thiếu calo: {d.calories}"
            assert d.image_url and d.image_url.startswith("https://images.unsplash.com/"), (
                f"Món {d.name} có ảnh không hợp lệ: {d.image_url}"
            )
            assert 0 <= d.spicy_level <= 3, f"Món {d.name} có độ cay ngoài khoảng 0-3: {d.spicy_level}"
            assert len(d.meal_types) > 0, f"Món {d.name} thiếu thông tin meal_types"
            assert d.category_id is not None, f"Món {d.name} chưa gắn category_id"
    finally:
        db.close()


def test_api_restaurants_and_dishes():
    """Kiểm tra API /restaurants và /restaurants/{id}/dishes trả về dữ liệu chuẩn."""
    resp = client.get("/api/v1/restaurants")
    assert resp.status_code == 200
    rests = resp.json()
    assert len(rests) >= 8
    
    first_rest = rests[0]
    rest_id = first_rest["id"]
    
    resp_dishes = client.get(f"/api/v1/restaurants/{rest_id}/dishes")
    assert resp_dishes.status_code == 200
    dishes = resp_dishes.json()
    assert len(dishes) >= 3
    
    first_dish = dishes[0]
    assert first_dish["name"]
    assert first_dish["price"] > 0
    assert first_dish["image_url"].startswith("http")
    assert first_dish["calories"] > 0
