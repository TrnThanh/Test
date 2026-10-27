import logging
from sqlalchemy import text
from server.app.core.config import settings
from server.app.db.base import Base
from server.app.db.session import engine, SessionLocal
from server.app.services.admin_service import AdminService
from server.app.services.user_service import UserService
from server.app.services.meal_type_service import MealTypeService
from server.app.services.weather_service import WeatherService
# Import models để Base.metadata nhận diện các bảng trước khi create_all
import server.app.models  # noqa: F401

logger = logging.getLogger(__name__)


def apply_schema_patches(conn) -> None:
    """Thực thi các câu lệnh DDL vá schema cơ sở dữ liệu và tương thích ngược."""
    conn.execute(text("CREATE EXTENSION IF NOT EXISTS postgis;"))
    conn.execute(text("ALTER TABLE IF EXISTS restaurants DROP COLUMN IF EXISTS seller_id CASCADE;"))
    conn.execute(text("DROP TABLE IF EXISTS sellers CASCADE;"))
    conn.execute(text("DROP TABLE IF EXISTS user_profiles CASCADE;"))
    conn.execute(text("ALTER TABLE restaurants ADD COLUMN IF NOT EXISTS open_time TIME;"))
    conn.execute(text("ALTER TABLE restaurants ADD COLUMN IF NOT EXISTS close_time TIME;"))
    conn.execute(text("ALTER TABLE IF EXISTS users ADD COLUMN IF NOT EXISTS height_cm DOUBLE PRECISION DEFAULT NULL;"))
    conn.execute(text("ALTER TABLE IF EXISTS users ADD COLUMN IF NOT EXISTS weight_kg DOUBLE PRECISION DEFAULT NULL;"))
    conn.execute(text("ALTER TABLE IF EXISTS users ADD COLUMN IF NOT EXISTS gender VARCHAR(20) DEFAULT NULL;"))
    conn.execute(text("ALTER TABLE IF EXISTS users ADD COLUMN IF NOT EXISTS birth_year INTEGER DEFAULT NULL;"))
    conn.execute(text("ALTER TABLE IF EXISTS users ADD COLUMN IF NOT EXISTS activity_level VARCHAR(30) DEFAULT NULL;"))
    conn.execute(text("ALTER TABLE IF EXISTS users ADD COLUMN IF NOT EXISTS target_goal VARCHAR(50) DEFAULT NULL;"))
    conn.execute(text("ALTER TABLE IF EXISTS users ADD COLUMN IF NOT EXISTS favorite_category_ids INTEGER[] NOT NULL DEFAULT '{}';"))
    conn.execute(text("ALTER TABLE IF EXISTS users ADD COLUMN IF NOT EXISTS dietary_preferences TEXT[] NOT NULL DEFAULT '{}';"))
    conn.execute(text("ALTER TABLE IF EXISTS users ADD COLUMN IF NOT EXISTS spicy_tolerance VARCHAR(20) DEFAULT NULL;"))
    conn.execute(text("ALTER TABLE IF EXISTS users ADD COLUMN IF NOT EXISTS allergies TEXT[] NOT NULL DEFAULT '{}';"))
    conn.execute(text("ALTER TABLE IF EXISTS users ADD COLUMN IF NOT EXISTS budget_range VARCHAR(20) DEFAULT NULL;"))
    conn.execute(text("ALTER TABLE IF EXISTS users ADD COLUMN IF NOT EXISTS is_onboarded BOOLEAN NOT NULL DEFAULT FALSE;"))
    conn.execute(text("ALTER TABLE IF EXISTS users ADD COLUMN IF NOT EXISTS onboarded_at TIMESTAMPTZ DEFAULT NULL;"))
    conn.execute(text("ALTER TABLE IF EXISTS users ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW();"))

    # --- TASK-053: Bổ sung trường service_licenses (Restaurant), season (Weather), và calories (Dish) ---
    conn.execute(text("ALTER TABLE IF EXISTS restaurants ADD COLUMN IF NOT EXISTS service_licenses TEXT[] NOT NULL DEFAULT '{}';"))
    conn.execute(text("CREATE INDEX IF NOT EXISTS ix_restaurants_service_licenses_gin ON restaurants USING gin (service_licenses);"))
    conn.execute(text("ALTER TABLE IF EXISTS weather ADD COLUMN IF NOT EXISTS season VARCHAR(50) DEFAULT NULL;"))
    conn.execute(text("CREATE INDEX IF NOT EXISTS ix_weather_season ON weather (season);"))
    conn.execute(text("ALTER TABLE IF EXISTS dishes ADD COLUMN IF NOT EXISTS calories INTEGER DEFAULT NULL;"))
    conn.execute(text("""
        DO $$
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'ck_dishes_calories_non_negative') THEN
                ALTER TABLE dishes ADD CONSTRAINT ck_dishes_calories_non_negative CHECK (calories IS NULL OR calories >= 0);
            END IF;
        END $$;
    """))

    # --- TASK-038: Cải tổ Schema: Categories toàn cục, Dish đa dạng phân loại & Restaurant tài trợ ---
    conn.execute(text("ALTER TABLE IF EXISTS restaurants ADD COLUMN IF NOT EXISTS is_sponsor BOOLEAN NOT NULL DEFAULT FALSE;"))
    conn.execute(text("ALTER TABLE IF EXISTS dishes ADD COLUMN IF NOT EXISTS spicy_level SMALLINT NOT NULL DEFAULT 0;"))
    conn.execute(text("ALTER TABLE IF EXISTS dishes ADD COLUMN IF NOT EXISTS dietary_tags TEXT[] NOT NULL DEFAULT '{}';"))
    conn.execute(text("ALTER TABLE IF EXISTS dishes ADD COLUMN IF NOT EXISTS meal_types TEXT[] NOT NULL DEFAULT '{}';"))
    conn.execute(text("ALTER TABLE IF EXISTS dishes ADD COLUMN IF NOT EXISTS allergens TEXT[] NOT NULL DEFAULT '{}';"))

    conn.execute(text("""
        DO $$
        BEGIN
            IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='dishes' AND column_name='meal_type') THEN
                UPDATE dishes SET meal_types = ARRAY[meal_type] WHERE (meal_types IS NULL OR cardinality(meal_types) = 0) AND meal_type IS NOT NULL;
            END IF;
        END $$;
    """))

    conn.execute(text("""
        DO $$
        DECLARE
            rec RECORD;
        BEGIN
            IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='categories' AND column_name='restaurant_id') THEN
                FOR rec IN 
                    SELECT lower(name) AS l_name, min(id) AS keep_id, array_agg(id) AS all_ids 
                    FROM categories 
                    GROUP BY lower(name) 
                    HAVING count(*) > 1
                LOOP
                    UPDATE dishes SET category_id = rec.keep_id WHERE category_id = ANY(rec.all_ids) AND category_id != rec.keep_id;
                    UPDATE weather_categories SET category_id = rec.keep_id WHERE category_id = ANY(rec.all_ids) AND category_id != rec.keep_id;
                    DELETE FROM categories WHERE id = ANY(rec.all_ids) AND id != rec.keep_id;
                END LOOP;
            END IF;
        END $$;
    """))

    conn.execute(text("""
        DO $$
        BEGIN
            IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='categories' AND column_name='restaurant_id') THEN
                ALTER TABLE categories DROP CONSTRAINT IF EXISTS uq_restaurant_category_name;
                ALTER TABLE categories DROP COLUMN IF EXISTS restaurant_id CASCADE;
            END IF;
        END $$;
    """))

    conn.execute(text("""
        DO $$
        BEGIN
            IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='dishes' AND column_name='meal_type') THEN
                ALTER TABLE dishes DROP CONSTRAINT IF EXISTS ck_dishes_meal_type;
                ALTER TABLE dishes DROP COLUMN IF EXISTS meal_type CASCADE;
            END IF;
            IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='dishes' AND column_name='meal_type_id') THEN
                ALTER TABLE dishes DROP COLUMN IF EXISTS meal_type_id CASCADE;
            END IF;
        END $$;
    """))

    conn.execute(text("CREATE UNIQUE INDEX IF NOT EXISTS uq_categories_name_lower ON categories (lower(name));"))


def init_database() -> None:
    """Tự động cập nhật schema PostgreSQL, tạo bảng và seed dữ liệu mặc định."""
    with engine.begin() as conn:
        apply_schema_patches(conn)

    Base.metadata.create_all(bind=engine)

    # Tự động seed tài khoản Admin, MealTypes và Weathers mặc định
    with SessionLocal() as db:
        AdminService.seed_default_admin(db)
        UserService.seed_default_user(db)
        MealTypeService.seed_default_meal_types(db)
        WeatherService.seed_default_weathers(db)
        if getattr(settings, "AUTO_SEED_INITIAL_DATA", True):
            from server.app.services.initial_seed_service import InitialSeedService
            InitialSeedService.seed_initial_data_if_needed(db)
