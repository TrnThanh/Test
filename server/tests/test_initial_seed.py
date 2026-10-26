"""
Kiểm thử tự động cho InitialSeedService:
1. Tự động nạp đủ 204 quán ăn Gia Lâm và danh sách thực đơn phong phú.
2. BẢO VỆ TUYỆT ĐỐI dữ liệu bảng users: không drop, không truncate, không xóa bất kỳ user nào.
3. Tính Idempotent: chạy lại nhiều lần không sinh duplicate và thoát nhanh.
"""

from sqlalchemy.orm import Session
from sqlalchemy import func

from server.app.models.user import User
from server.app.models.restaurant import Restaurant
from server.app.models.dish import Dish
from server.app.models.category import Category
from server.app.models.seed_meta import SeedMeta
from server.app.services.initial_seed_service import (
    InitialSeedService,
    INITIAL_SEED_KEY,
    DEFAULT_CATEGORIES,
)


def test_seed_initial_data_populates_restaurants_and_dishes(db_session: Session):
    """Kiểm thử nạp dữ liệu ban đầu khi DB chưa có quán ăn."""
    # Xoá marker và restaurants trong session test nếu có
    db_session.query(SeedMeta).filter(SeedMeta.key == INITIAL_SEED_KEY).delete()
    db_session.query(Dish).delete()
    db_session.query(Restaurant).delete()
    db_session.commit()

    # Gọi auto-seed
    result = InitialSeedService.seed_initial_data_if_needed(db_session, force=True)
    assert result is True

    # Kiểm tra số lượng quán ăn và món ăn
    rest_count = db_session.query(func.count(Restaurant.id)).scalar()
    dish_count = db_session.query(func.count(Dish.id)).scalar()

    assert rest_count == 204, f"Kỳ vọng 204 quán ăn nhưng nhận được {rest_count}"
    assert dish_count >= 600, f"Kỳ vọng ít nhất 600 món ăn nhưng nhận được {dish_count}"

    # Kiểm tra danh mục
    for cat_name in DEFAULT_CATEGORIES:
        cat = db_session.query(Category).filter(func.lower(Category.name) == cat_name.lower()).first()
        assert cat is not None, f"Danh mục '{cat_name}' phải tồn tại"

    # Kiểm tra marker
    marker = db_session.query(SeedMeta).filter(SeedMeta.key == INITIAL_SEED_KEY).first()
    assert marker is not None
    assert marker.version == 1


def test_user_data_strictly_preserved_during_seed(db_session: Session):
    """
    RÀNG BUỘC CỐT LÕI: Kiểm thử dữ liệu bảng users KHÔNG BAO GIỜ bị xoá hay thay đổi
    khi seeder chạy khởi tạo dữ liệu ẩm thực ban đầu.
    """
    # 1. Tạo 2 user mẫu đặc biệt
    user_email_1 = "important_customer_preserve@example.com"
    user_email_2 = "vip_merchant_preserve@example.com"

    # Dọn sạch nếu có từ trước
    db_session.query(User).filter(User.email.in_([user_email_1, user_email_2])).delete()
    db_session.commit()

    user1 = User(
        email=user_email_1,
        hashed_password="hashed_secure_password_123",
        full_name="Nguyễn Văn Bảo Tồn",
        height_cm=175.5,
        weight_kg=68.0,
        is_onboarded=True,
        dietary_preferences=["Ăn kiêng ít calo", "Đặc sản Hà Nội"],
        spicy_tolerance="Ít cay",
    )
    user2 = User(
        email=user_email_2,
        hashed_password="hashed_secure_password_456",
        full_name="Trần Thị Khách Quen",
        height_cm=160.0,
        weight_kg=50.0,
        is_onboarded=False,
    )
    db_session.add(user1)
    db_session.add(user2)
    db_session.commit()

    total_users_before = db_session.query(func.count(User.id)).scalar()
    assert total_users_before >= 2

    # 2. Chạy InitialSeedService
    InitialSeedService.seed_initial_data_if_needed(db_session, force=True)

    # 3. Xác minh số lượng users không hề giảm và 2 user mẫu vẫn còn nguyên vẹn 100%
    total_users_after = db_session.query(func.count(User.id)).scalar()
    assert total_users_after == total_users_before, "Số lượng users không được phép thay đổi!"

    check_user1 = db_session.query(User).filter(User.email == user_email_1).first()
    assert check_user1 is not None, "User 1 không được phép bị xoá!"
    assert check_user1.full_name == "Nguyễn Văn Bảo Tồn"
    assert check_user1.height_cm == 175.5
    assert check_user1.weight_kg == 68.0
    assert check_user1.is_onboarded is True
    assert "Ăn kiêng ít calo" in check_user1.dietary_preferences

    check_user2 = db_session.query(User).filter(User.email == user_email_2).first()
    assert check_user2 is not None, "User 2 không được phép bị xoá!"
    assert check_user2.full_name == "Trần Thị Khách Quen"


def test_idempotent_behavior_skips_when_already_seeded(db_session: Session):
    """Kiểm thử tính Idempotent: chạy lần 2 khi đã có marker thì bỏ qua ngay và trả về False."""
    # Đảm bảo marker tồn tại
    existing_marker = db_session.query(SeedMeta).filter(SeedMeta.key == INITIAL_SEED_KEY).first()
    if not existing_marker:
        db_session.add(SeedMeta(key=INITIAL_SEED_KEY, version=1))
        db_session.commit()

    count_rests_before = db_session.query(func.count(Restaurant.id)).scalar()

    # Chạy lần 2 với force=False
    res = InitialSeedService.seed_initial_data_if_needed(db_session, force=False)
    assert res is False, "Khi đã có marker, seeder phải trả về False và không nạp lại"

    count_rests_after = db_session.query(func.count(Restaurant.id)).scalar()
    assert count_rests_after == count_rests_before, "Số lượng quán không được thay đổi"
