from typing import List, Optional
from fastapi import HTTPException, status
from sqlalchemy import select, func
from sqlalchemy.orm import Session
from server.app.models.category import Category
from server.app.models.dish import Dish
from server.app.schemas.category import CategoryCreate, CategoryUpdate, CategoryResponse


# Lớp dịch vụ quản lý danh mục món ăn toàn cục và phân nhóm thực đơn
class CategoryService:
    # Tạo mới một danh mục phân loại món ăn toàn hệ thống
    @staticmethod
    def create_category(
        db: Session, data: CategoryCreate, restaurant_id: Optional[int] = None
    ) -> CategoryResponse:
        """Tạo danh mục mới toàn cục (Master Category). Tham số restaurant_id giữ lại để tương thích ngược."""
        # 1. Kiểm tra trùng tên danh mục toàn hệ thống (không phân biệt hoa/thường)
        existing = db.execute(
            select(Category).where(
                func.lower(Category.name) == data.name.lower(),
            )
        ).scalar_one_or_none()
        if existing:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Danh mục '{data.name}' đã tồn tại trong hệ thống",
            )

        # 2. Tạo thực thể danh mục mới
        category = Category(
            name=data.name,
            description=data.description,
            display_order=data.display_order,
            is_active=data.is_active,
        )
        db.add(category)
        db.commit()
        db.refresh(category)

        # 3. Đóng gói kết quả trả về kèm số lượng món ăn ban đầu là 0
        res = CategoryResponse.model_validate(category)
        res.dish_count = 0
        return res

    # Lấy danh sách toàn bộ các danh mục kèm số lượng món ăn tương ứng
    @staticmethod
    def get_categories(
        db: Session, restaurant_id: Optional[int] = None, is_active_only: bool = False
    ) -> List[CategoryResponse]:
        """Lấy danh sách các nhóm danh mục (toàn cục hoặc theo quán ăn)."""
        # 1. Khởi tạo câu truy vấn danh mục
        query = select(Category)
        # 2. Lọc các danh mục mà quán này đang có món ăn phục vụ nếu truyền restaurant_id
        if restaurant_id is not None:
            query = query.join(Dish, Dish.category_id == Category.id).where(Dish.restaurant_id == restaurant_id).distinct()
        # 3. Lọc theo trạng thái hoạt động nếu yêu cầu
        if is_active_only:
            query = query.where(Category.is_active == True)  # noqa: E712
        query = query.order_by(Category.display_order.asc(), Category.id.asc())
        categories = db.execute(query).scalars().all()

        # 4. Đếm số lượng món ăn thuộc từng danh mục
        results: List[CategoryResponse] = []
        for cat in categories:
            dish_count_query = select(func.count(Dish.id)).where(Dish.category_id == cat.id)
            if restaurant_id is not None:
                dish_count_query = dish_count_query.where(Dish.restaurant_id == restaurant_id)
            dish_count = db.execute(dish_count_query).scalar() or 0

            cat_res = CategoryResponse.model_validate(cat)
            cat_res.dish_count = dish_count
            results.append(cat_res)
        return results

    # Lấy thông tin chi tiết một danh mục món ăn theo ID kèm số lượng món ăn
    @staticmethod
    def get_category_by_id(db: Session, category_id: int) -> CategoryResponse:
        """Lấy thông tin chi tiết một danh mục theo ID."""
        # 1. Tìm danh mục trong CSDL
        cat = db.get(Category, category_id)
        if not cat:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Không tìm thấy danh mục món ăn",
            )
        # 2. Đếm số món ăn đang thuộc danh mục này
        dish_count = db.execute(
            select(func.count(Dish.id)).where(Dish.category_id == cat.id)
        ).scalar() or 0
        # 3. Đóng gói phản hồi
        res = CategoryResponse.model_validate(cat)
        res.dish_count = dish_count
        return res

    # Chỉnh sửa thông tin danh mục món ăn (tên, mô tả, thứ tự sắp xếp)
    @staticmethod
    def update_category(
        db: Session, category_id: int, data: CategoryUpdate
    ) -> CategoryResponse:
        """Cập nhật thông tin danh mục món ăn."""
        # 1. Tìm danh mục cần sửa
        cat = db.get(Category, category_id)
        if not cat:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Không tìm thấy danh mục món ăn",
            )

        # 2. Kiểm tra nếu đổi tên thì tên mới không được trùng với danh mục khác
        update_dict = data.model_dump(exclude_unset=True)
        if "name" in update_dict and update_dict["name"] is not None:
            new_name = update_dict["name"]
            existing = db.execute(
                select(Category).where(
                    Category.id != cat.id,
                    func.lower(Category.name) == new_name.lower(),
                )
            ).scalar_one_or_none()
            if existing:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"Danh mục '{new_name}' đã tồn tại trong hệ thống",
                )

        # 3. Gán các trường mới và commit
        for key, value in update_dict.items():
            setattr(cat, key, value)

        db.commit()
        db.refresh(cat)

        # 4. Đếm số lượng món ăn và trả về
        dish_count = db.execute(
            select(func.count(Dish.id)).where(Dish.category_id == cat.id)
        ).scalar() or 0
        res = CategoryResponse.model_validate(cat)
        res.dish_count = dish_count
        return res

    # Xoá hoàn toàn danh mục món ăn khỏi cơ sở dữ liệu
    @staticmethod
    def delete_category(db: Session, category_id: int) -> None:
        """Xoá một danh mục món ăn."""
        # 1. Tìm danh mục theo ID
        cat = db.get(Category, category_id)
        if not cat:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Không tìm thấy danh mục món ăn",
            )

        # 2. Xoá bản ghi danh mục
        db.delete(cat)
        db.commit()

    # Tự động nạp hoặc cập nhật 10 thể loại món ăn Việt Nam chuẩn hóa
    @staticmethod
    def seed_default_categories(db: Session) -> None:
        """Khởi tạo hoặc cập nhật 10 thể loại món ăn Việt Nam chuẩn hóa toàn cục."""
        categories_data = [
            (
                "Phở, Bún & Món nước",
                "Các món nước thanh ngọt, sợi bún phở mềm mịn, nước dùng hầm xương đậm đà chuẩn vị truyền thống.",
                1,
                ["phở & bún"],
            ),
            (
                "Cơm & Xôi",
                "Cơm niêu giòn đáy, cơm sườn nướng mật ong và xôi nếp dẻo thơm chắc dạ trọn vẹn từng bữa ăn.",
                2,
                [],
            ),
            (
                "Bánh mì",
                "Bánh mì nướng giòn rụm, đầy đặn nhân pate thịt nguội, xúc xích và rau thơm tươi ngon.",
                3,
                [],
            ),
            (
                "Bánh truyền thống & Món cuốn",
                "Bún chả, bún đậu mắm tôm, gỏi cuốn tôm thịt, bánh cuốn nóng và các món bánh dân dã truyền thống.",
                4,
                [],
            ),
            (
                "Lẩu & Nướng",
                "Nồi lẩu bốc khói nghi ngút và thịt nướng xèo xèo thơm phức lý tưởng cho những buổi hội ngộ sum vầy.",
                5,
                [],
            ),
            (
                "Ốc & Quán lai rai",
                "Ốc hương xào bơ tỏi, ngao hấp sả, chân gà sả tắc và các món nhậu lai rai đậm đà chuẩn vị.",
                6,
                [],
            ),
            (
                "Đồ ăn vặt",
                "Nem chua rán giòn rụm, bánh tráng nướng, khoai tây lắc phô mai thơm ngon cho bữa xế vui vẻ.",
                7,
                [],
            ),
            (
                "Chè & Tráng miệng",
                "Chè bưởi, tàu hũ trân châu, caramen béo ngậy và các món tráng miệng ngọt ngào thanh mát.",
                8,
                [],
            ),
            (
                "Cà phê & Thức uống giải khát",
                "Cà phê đậm đà, trà hoa quả thanh mát giải nhiệt và thức uống giải khát sảng khoái.",
                9,
                ["cà phê & trà sữa"],
            ),
            (
                "Ẩm thực Chay & Thực dưỡng",
                "Món chay thanh tịnh, lẩu nấm dưỡng sinh thanh lọc cơ thể từ rau củ quả tự nhiên.",
                10,
                ["món chay"],
            ),
        ]

        for name, desc, order, legacy_aliases in categories_data:
            cat = None
            # Tìm danh mục theo tên hiện tại
            cat = db.execute(select(Category).where(func.lower(Category.name) == name.lower())).scalar_one_or_none()
            if not cat and legacy_aliases:
                for alias in legacy_aliases:
                    cat = db.execute(select(Category).where(func.lower(Category.name) == alias.lower())).scalar_one_or_none()
                    if cat:
                        break

            if cat:
                cat.name = name
                cat.description = desc
                cat.display_order = order
                cat.is_active = True
            else:
                new_cat = Category(
                    name=name,
                    description=desc,
                    display_order=order,
                    is_active=True,
                )
                db.add(new_cat)

        db.commit()
