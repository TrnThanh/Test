import uuid
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from server.app.db.session import get_db
from server.app.schemas.user import UserRegister, UserLogin, UserResponse
from server.app.schemas.common import RoleLoginResponse
from server.app.services.user_service import UserService

router = APIRouter()


# Đăng ký tài khoản người dùng mới (Thực khách)
@router.post(
    "/register",
    response_model=UserResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Đăng ký tài khoản User",
    description="Nhận thông tin đăng ký người dùng thông thường và lưu vào bảng users.",
)
def register_user(
    user_in: UserRegister,
    db: Session = Depends(get_db),
) -> UserResponse:
    """Đăng ký tài khoản mới cho thực khách và lưu trữ vào CSDL."""
    # 1. Kiểm tra xem email đã được đăng ký trước đó hay chưa
    existing_user = UserService.get_user_by_email(db, user_in.email)
    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email already registered for user",
        )
    # 2. Tạo tài khoản người dùng mới
    user = UserService.create_user(db=db, user_in=user_in)
    session_id = uuid.uuid4().hex
    user_dict = {
        "id": user.id,
        "email": user.email,
        "full_name": user.full_name,
        "phone": user.phone,
        "is_active": user.is_active,
        "created_at": user.created_at.isoformat(),
    }
    return UserResponse(
        id=user.id,
        email=user.email,
        full_name=user.full_name,
        phone=user.phone,
        is_active=user.is_active,
        created_at=user.created_at,
        session_id=session_id,
        role="user",
        message="User registered successfully",
        data=user_dict,
    )


# Đăng nhập tài khoản người dùng thông thường
@router.post(
    "/login",
    response_model=RoleLoginResponse,
    status_code=status.HTTP_200_OK,
    summary="Đăng nhập tài khoản User",
    description="Kiểm tra email và mật khẩu trong bảng users.",
)
def login_user(
    user_in: UserLogin,
    db: Session = Depends(get_db),
) -> RoleLoginResponse:
    """Xác thực thông tin đăng nhập của thực khách và trả về phiên làm việc."""
    # 1. Xác thực email và mật khẩu người dùng
    user = UserService.authenticate_user(db=db, email=user_in.email, password=user_in.password)
    # 2. Xử lý trường hợp sai thông tin đăng nhập
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password",
        )
    # 3. Đóng gói dữ liệu hồ sơ người dùng
    user_dict = {
        "id": user.id,
        "email": user.email,
        "full_name": user.full_name,
        "phone": user.phone,
        "is_active": user.is_active,
        "created_at": user.created_at.isoformat(),
    }
    # 4. Trả về thông tin đăng nhập thành công
    return RoleLoginResponse(
        message="User login successful",
        role="user",
        session_id=uuid.uuid4().hex,
        data=user_dict,
    )
