from typing import Generator
import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker, Session

from server.app.main import app
from server.app.core.config import settings
from server.app.db.base import Base
from server.app.db.session import get_db
from server.app.services.admin_service import AdminService
from server.app.services.meal_type_service import MealTypeService
from server.app.services.weather_service import WeatherService
from server.app.services.category_service import CategoryService

test_engine = create_engine(
    settings.TEST_DATABASE_URL,
    pool_pre_ping=True,
)

TestingSessionLocal = sessionmaker(
    bind=test_engine,
    autocommit=False,
    autoflush=False,
    expire_on_commit=False,
)


@pytest.fixture(scope="session", autouse=True)
def setup_test_db():
    """Khởi tạo toàn bộ bảng trên PostgreSQL test database và seed admin, meal_types, weathers mặc định."""
    settings.AUTO_SEED_INITIAL_DATA = False
    with test_engine.begin() as conn:
        conn.execute(text("CREATE EXTENSION IF NOT EXISTS postgis;"))
    Base.metadata.drop_all(bind=test_engine)
    Base.metadata.create_all(bind=test_engine)
    with TestingSessionLocal() as session:
        AdminService.seed_default_admin(session)
        MealTypeService.seed_default_meal_types(session)
        WeatherService.seed_4000_weather_patterns(session)
        CategoryService.seed_default_categories(session)
    yield
    Base.metadata.drop_all(bind=test_engine)
    test_engine.dispose()


@pytest.fixture(scope="function")
def db_session() -> Generator[Session, None, None]:
    """Cung cấp session với Savepoint Transaction để tự động rollback sạch sẽ sau mỗi test case."""
    connection = test_engine.connect()
    transaction = connection.begin()
    session = TestingSessionLocal(bind=connection, join_transaction_mode="create_savepoint")
    try:
        yield session
    finally:
        session.close()
        transaction.rollback()
        connection.close()


@pytest.fixture(scope="function")
def client(db_session: Session) -> Generator[TestClient, None, None]:
    """Cung cấp TestClient với get_db dependency được override bằng PostgreSQL test session."""
    def override_get_db() -> Generator[Session, None, None]:
        yield db_session

    app.dependency_overrides[get_db] = override_get_db
    with TestClient(app) as test_client:
        yield test_client
    app.dependency_overrides.clear()
