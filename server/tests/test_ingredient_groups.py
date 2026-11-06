import pytest
from fastapi.testclient import TestClient
from sqlalchemy.orm import Session
from sqlalchemy import select

from server.app.models.ingredient import Ingredient
from server.app.models.ingredient_group import IngredientGroup


def test_ingredient_groups_crud_flow(client: TestClient, db_session: Session):
    """Kiểm tra toàn diện flow Thêm, Xem, Sửa, Lọc và Xóa nhóm nguyên liệu."""
    # 1. Tạo nhóm nguyên liệu mới
    create_payload = {
        "name": "Gia vị thảo mộc Test",
        "description": "Các loại gia vị, thảo mộc khô và tươi",
        "display_order": 99,
        "is_active": True,
    }
    res = client.post("/api/v1/ingredient-groups", json=create_payload)
    assert res.status_code == 201, res.text
    group_data = res.json()
    group_id = group_data["id"]
    assert group_data["name"] == "Gia vị thảo mộc Test"
    assert group_data["ingredient_count"] == 0

    # 2. Tạo trùng tên (không phân biệt hoa thường và khoảng trắng thừa) -> 400 Bad Request
    dup_res = client.post(
        "/api/v1/ingredient-groups",
        json={"name": "  gia vị thảo mộc test  "},
    )
    assert dup_res.status_code == 400
    assert "đã tồn tại" in dup_res.json()["detail"]

    # 3. Lấy danh sách nhóm
    list_res = client.get("/api/v1/ingredient-groups")
    assert list_res.status_code == 200
    groups = list_res.json()
    assert any(g["id"] == group_id for g in groups)

    # 4. Xem chi tiết nhóm
    detail_res = client.get(f"/api/v1/ingredient-groups/{group_id}")
    assert detail_res.status_code == 200
    detail = detail_res.json()
    assert detail["name"] == "Gia vị thảo mộc Test"
    assert detail["display_order"] == 99

    # 5. Cập nhật nhóm
    update_res = client.put(
        f"/api/v1/ingredient-groups/{group_id}",
        json={
            "name": "Thảo mộc tự nhiên Test",
            "description": "Thảo mộc rừng nguyên sinh",
            "display_order": 50,
            "is_active": False,
        },
    )
    assert update_res.status_code == 200
    updated = update_res.json()
    assert updated["name"] == "Thảo mộc tự nhiên Test"
    assert updated["display_order"] == 50
    assert updated["is_active"] is False

    # 6. Gán nguyên liệu vào nhóm và lọc theo group_id
    ing_res = client.post(
        "/api/v1/ingredients",
        json={
            "name": "Lá xạ hương Thyme Test",
            "group_id": group_id,
            "is_active": True,
        },
    )
    assert ing_res.status_code == 201
    ing = ing_res.json()
    assert ing["group_id"] == group_id
    assert ing["group_name"] == "Thảo mộc tự nhiên Test"

    # Lọc nguyên liệu theo group_id
    filter_res = client.get(f"/api/v1/ingredients?group_id={group_id}")
    assert filter_res.status_code == 200
    filtered_items = filter_res.json()["items"]
    assert len(filtered_items) >= 1
    assert any(item["id"] == ing["id"] for item in filtered_items)

    # Kiểm tra group count lúc này = 1
    group_check = client.get(f"/api/v1/ingredient-groups/{group_id}").json()
    assert group_check["ingredient_count"] == 1

    # 7. Xóa an toàn khi có nguyên liệu trực thuộc -> Bị chặn 400
    del_fail = client.delete(f"/api/v1/ingredient-groups/{group_id}")
    assert del_fail.status_code == 400
    assert "đang có 1 nguyên liệu thuộc nhóm này" in del_fail.json()["detail"]

    # 8. Xóa với force=true -> Thành công, nguyên liệu được giữ lại nhưng group_id về None
    del_ok = client.delete(f"/api/v1/ingredient-groups/{group_id}?force=true")
    assert del_ok.status_code == 200

    # Kiểm tra lại nhóm đã bị xóa (404)
    assert client.get(f"/api/v1/ingredient-groups/{group_id}").status_code == 404

    # Kiểm tra nguyên liệu vẫn còn và group_id đã về null
    ing_check = client.get(f"/api/v1/ingredients/{ing['id']}").json()
    assert ing_check["group_id"] is None
    assert ing_check["group_name"] is None
