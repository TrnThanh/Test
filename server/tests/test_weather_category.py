import pytest
from fastapi.testclient import TestClient
from sqlalchemy.orm import Session
from sqlalchemy import select

from server.app.models.restaurant import Restaurant
from server.app.models.category import Category
from server.app.models.weather import Weather
from server.app.models.weather_category import WeatherCategory


@pytest.fixture
def sample_data(db_session: Session):
    """Fixture tạo dữ liệu mẫu: 1 Restaurant, 2 Categories, 2 Weathers."""
    restaurant = Restaurant(
        name="Quán Nướng & Lẩu WC",
        address="123 Phố Nướng, Hà Nội",
        latitude=21.0285,
        longitude=105.8542,
    )
    db_session.add(restaurant)
    db_session.flush()

    cat1 = Category(
        name="Món Lẩu Nóng",
        description="Các món lẩu nghi ngút khói thích hợp ngày lạnh",
        display_order=1,
    )
    cat2 = Category(
        name="Đồ Uống Mát Lạnh",
        description="Trà sữa, nước ngọt, kem cho ngày nắng nóng",
        display_order=2,
    )
    db_session.add_all([cat1, cat2])
    db_session.flush()

    # Query hoặc tạo weather mẫu
    weather_cold = db_session.execute(
        select(Weather).where(Weather.code == "cold")
    ).scalar_one_or_none()
    if not weather_cold:
        weather_cold = Weather(
            code="cold",
            name="Trời rét buốt",
            temperature=10.0,
            humidity=80.0,
            condition="Cold",
        )
        db_session.add(weather_cold)
        db_session.flush()

    weather_hot = db_session.execute(
        select(Weather).where(Weather.code == "hot")
    ).scalar_one_or_none()
    if not weather_hot:
        weather_hot = Weather(
            code="hot",
            name="Nắng gắt",
            temperature=35.0,
            humidity=60.0,
            condition="Hot",
        )
        db_session.add(weather_hot)
        db_session.flush()

    db_session.commit()
    return {
        "restaurant": restaurant,
        "cat1": cat1,
        "cat2": cat2,
        "weather_cold": weather_cold,
        "weather_hot": weather_hot,
    }


def test_link_weather_category_success(client: TestClient, sample_data):
    """Kiểm tra liên kết category vào weather thành công."""
    weather_id = sample_data["weather_cold"].id
    cat_id = sample_data["cat1"].id

    response = client.post(
        f"/api/v1/weather-categories/weathers/{weather_id}/categories/{cat_id}"
    )
    assert response.status_code == 201
    data = response.json()
    assert data["weather_id"] == weather_id
    assert data["category_id"] == cat_id
    assert "created_at" in data
    assert data["id"] > 0


def test_link_weather_category_idempotent(client: TestClient, sample_data):
    """Kiểm tra tính lũy thừa (Idempotent): gọi liên kết nhiều lần không bị duplicate/lỗi."""
    weather_id = sample_data["weather_cold"].id
    cat_id = sample_data["cat1"].id

    res1 = client.post(
        f"/api/v1/weather-categories/weathers/{weather_id}/categories/{cat_id}"
    )
    assert res1.status_code == 201
    id1 = res1.json()["id"]

    res2 = client.post(
        f"/api/v1/weather-categories/weathers/{weather_id}/categories/{cat_id}"
    )
    assert res2.status_code == 201
    id2 = res2.json()["id"]

    assert id1 == id2


def test_unlink_weather_category_success(client: TestClient, sample_data):
    """Kiểm tra hủy liên kết giữa weather và category."""
    weather_id = sample_data["weather_cold"].id
    cat_id = sample_data["cat1"].id

    # Tạo link
    client.post(f"/api/v1/weather-categories/weathers/{weather_id}/categories/{cat_id}")

    # Xóa link
    del_res = client.delete(
        f"/api/v1/weather-categories/weathers/{weather_id}/categories/{cat_id}"
    )
    assert del_res.status_code == 200
    assert "thành công" in del_res.json()["message"]

    # Tra cứu lại danh sách categories của weather
    get_res = client.get(
        f"/api/v1/weather-categories/weathers/{weather_id}/categories"
    )
    assert get_res.status_code == 200
    categories = get_res.json()
    assert not any(c["id"] == cat_id for c in categories)


def test_get_categories_by_weather(client: TestClient, sample_data):
    """Kiểm tra tra cứu danh sách Category theo Weather."""
    weather_id = sample_data["weather_cold"].id
    cat1_id = sample_data["cat1"].id
    cat2_id = sample_data["cat2"].id

    client.post(f"/api/v1/weather-categories/weathers/{weather_id}/categories/{cat1_id}")
    client.post(f"/api/v1/weather-categories/weathers/{weather_id}/categories/{cat2_id}")

    res = client.get(f"/api/v1/weather-categories/weathers/{weather_id}/categories")
    assert res.status_code == 200
    cats = res.json()
    cat_ids = [c["id"] for c in cats]
    assert cat1_id in cat_ids
    assert cat2_id in cat_ids


def test_get_weathers_by_category(client: TestClient, sample_data):
    """Kiểm tra tra cứu danh sách Weather áp dụng cho một Category."""
    cat1_id = sample_data["cat1"].id
    w_cold_id = sample_data["weather_cold"].id
    w_hot_id = sample_data["weather_hot"].id

    client.post(f"/api/v1/weather-categories/weathers/{w_cold_id}/categories/{cat1_id}")
    client.post(f"/api/v1/weather-categories/weathers/{w_hot_id}/categories/{cat1_id}")

    res = client.get(f"/api/v1/weather-categories/categories/{cat1_id}/weathers")
    assert res.status_code == 200
    weathers = res.json()
    weather_ids = [w["id"] for w in weathers]
    assert w_cold_id in weather_ids
    assert w_hot_id in weather_ids


def test_link_nonexistent_returns_404(client: TestClient, sample_data):
    """Kiểm tra gán liên kết khi weather hoặc category không tồn tại sẽ trả về 404."""
    cat_id = sample_data["cat1"].id
    res_w = client.post(
        f"/api/v1/weather-categories/weathers/999999/categories/{cat_id}"
    )
    assert res_w.status_code == 404

    w_id = sample_data["weather_cold"].id
    res_c = client.post(
        f"/api/v1/weather-categories/weathers/{w_id}/categories/999999"
    )
    assert res_c.status_code == 404


def test_create_weather_category_via_body_and_list(client: TestClient, sample_data):
    """Kiểm tra tạo liên kết qua body và lọc danh sách liên kết."""
    w_id = sample_data["weather_hot"].id
    cat_id = sample_data["cat2"].id

    res = client.post(
        "/api/v1/weather-categories",
        json={"weather_id": w_id, "category_id": cat_id},
    )
    assert res.status_code == 201
    link_id = res.json()["id"]

    # Danh sách có lọc
    list_res = client.get(f"/api/v1/weather-categories?weather_id={w_id}")
    assert list_res.status_code == 200
    links = list_res.json()
    assert any(l["id"] == link_id for l in links)


def test_cascade_delete_weather_removes_link(db_session: Session, sample_data):
    """Kiểm tra xóa Weather thì WeatherCategory liên quan tự động xóa theo (Cascade Delete)."""
    weather = sample_data["weather_cold"]
    cat = sample_data["cat1"]

    wc = WeatherCategory(weather_id=weather.id, category_id=cat.id)
    db_session.add(wc)
    db_session.commit()
    wc_id = wc.id

    # Xóa weather
    db_session.delete(weather)
    db_session.commit()
    db_session.expire_all()

    # Link phải bị xóa ở DB
    assert db_session.query(WeatherCategory).filter_by(id=wc_id).first() is None
    # Category gốc không bị xóa
    assert db_session.get(Category, cat.id) is not None


def test_cascade_delete_category_removes_link(db_session: Session, sample_data):
    """Kiểm tra xóa Category thì WeatherCategory liên quan tự động xóa theo (Cascade Delete)."""
    weather = sample_data["weather_hot"]
    cat = sample_data["cat2"]

    wc = WeatherCategory(weather_id=weather.id, category_id=cat.id)
    db_session.add(wc)
    db_session.commit()
    wc_id = wc.id

    # Xóa category
    db_session.delete(cat)
    db_session.commit()
    db_session.expire_all()

    # Link phải bị xóa ở DB
    assert db_session.query(WeatherCategory).filter_by(id=wc_id).first() is None
    # Weather gốc không bị xóa
    assert db_session.get(Weather, weather.id) is not None
