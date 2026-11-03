import logging
from sqlalchemy import text
from server.app.core.config import settings
from server.app.db.base import Base
from server.app.db.session import engine, SessionLocal
from server.app.services.admin_service import AdminService
from server.app.services.user_service import UserService
from server.app.services.meal_type_service import MealTypeService
from server.app.services.weather_service import WeatherService
from server.app.services.category_service import CategoryService
# Import models để Base.metadata nhận diện các bảng trước khi create_all
import server.app.models  # noqa: F401

logger = logging.getLogger(__name__)


def apply_schema_patches(conn) -> None:
    """Thực thi các câu lệnh DDL vá schema cơ sở dữ liệu và tương thích ngược."""
    conn.execute(text("CREATE EXTENSION IF NOT EXISTS postgis;"))
    conn.execute(text("ALTER TABLE IF EXISTS admins DROP COLUMN IF EXISTS role_level CASCADE;"))
    conn.execute(text("ALTER TABLE IF EXISTS users DROP COLUMN IF EXISTS is_active CASCADE;"))
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
    conn.execute(text("ALTER TABLE IF EXISTS users ADD COLUMN IF NOT EXISTS phone VARCHAR(50) DEFAULT NULL;"))
    conn.execute(text("ALTER TABLE IF EXISTS restaurants ADD COLUMN IF NOT EXISTS service_licenses TEXT[] NOT NULL DEFAULT '{}';"))
    conn.execute(text("CREATE INDEX IF NOT EXISTS ix_restaurants_service_licenses_gin ON restaurants USING gin (service_licenses);"))
    conn.execute(text("ALTER TABLE IF EXISTS weather ADD COLUMN IF NOT EXISTS season VARCHAR(50) DEFAULT NULL;"))
    conn.execute(text("CREATE INDEX IF NOT EXISTS ix_weather_season ON weather (season);"))

    # TASK-121 & TASK-141: Chuẩn hóa cột humidity (Float), temperature (Float), hourly (JSONB) và mở rộng 96,000 bản ghi phẳng (bỏ date, chỉ lấy hour)
    conn.execute(text("ALTER TABLE IF EXISTS weather ADD COLUMN IF NOT EXISTS temperature DOUBLE PRECISION DEFAULT NULL;"))
    conn.execute(text("ALTER TABLE IF EXISTS weather ADD COLUMN IF NOT EXISTS humidity DOUBLE PRECISION DEFAULT NULL;"))
    conn.execute(text("ALTER TABLE IF EXISTS weather DROP COLUMN IF EXISTS hourly CASCADE;"))
    conn.execute(text("ALTER TABLE IF EXISTS weather ALTER COLUMN code TYPE VARCHAR(60);"))
    conn.execute(text("ALTER TABLE IF EXISTS weather ADD COLUMN IF NOT EXISTS pattern_code VARCHAR(50);"))
    conn.execute(text("ALTER TABLE IF EXISTS weather ADD COLUMN IF NOT EXISTS hour INTEGER DEFAULT NULL;"))
    conn.execute(text("ALTER TABLE IF EXISTS weather ADD COLUMN IF NOT EXISTS precipitation DOUBLE PRECISION DEFAULT 0.0;"))
    conn.execute(text("ALTER TABLE IF EXISTS weather ADD COLUMN IF NOT EXISTS weather_code INTEGER DEFAULT 0;"))
    conn.execute(text("ALTER TABLE IF EXISTS weather DROP COLUMN IF EXISTS date CASCADE;"))
    conn.execute(text("""
        DO $$
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'ck_weather_hour_valid') THEN
                ALTER TABLE weather ADD CONSTRAINT ck_weather_hour_valid CHECK (hour IS NULL OR (hour >= 0 AND hour <= 23));
            END IF;
        END $$;
    """))
    conn.execute(text("CREATE INDEX IF NOT EXISTS ix_weather_pattern_code ON weather (pattern_code);"))
    conn.execute(text("CREATE INDEX IF NOT EXISTS ix_weather_hour ON weather (hour);"))
    conn.execute(text("CREATE INDEX IF NOT EXISTS ix_weather_pattern_hour ON weather (pattern_code, hour);"))
    conn.execute(text("CREATE INDEX IF NOT EXISTS ix_weather_season_temp ON weather (season, temperature);"))

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
    conn.execute(text("ALTER TABLE IF EXISTS restaurants ADD COLUMN IF NOT EXISTS rating DOUBLE PRECISION DEFAULT NULL;"))
    conn.execute(text("ALTER TABLE IF EXISTS restaurants ADD COLUMN IF NOT EXISTS admin_rating DOUBLE PRECISION DEFAULT NULL;"))
    conn.execute(text("""
        DO $$
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'ck_restaurant_admin_rating') THEN
                ALTER TABLE restaurants ADD CONSTRAINT ck_restaurant_admin_rating CHECK (admin_rating IS NULL OR (admin_rating >= 0.0 AND admin_rating <= 5.0));
            END IF;
        END $$;
    """))
    conn.execute(text("""
        DO $$
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'ck_restaurant_rating') THEN
                ALTER TABLE restaurants ADD CONSTRAINT ck_restaurant_rating CHECK (rating IS NULL OR (rating >= 0.0 AND rating <= 5.0));
            END IF;
        END $$;
    """))
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
            UPDATE dishes SET meal_types = ARRAY['all_day'] WHERE (meal_types IS NULL OR cardinality(meal_types) = 0);
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

    conn.execute(text("""
        DO $$
        BEGIN
            IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name='users') THEN
                IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='users' AND column_name='phone') THEN
                    ALTER TABLE users ADD COLUMN phone VARCHAR(50);
                END IF;
            END IF;
        END $$;
    """))

    conn.execute(text("CREATE UNIQUE INDEX IF NOT EXISTS uq_categories_name_lower ON categories (lower(name));"))

    conn.execute(text("""
        DO $$
        BEGIN
            IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name='weather') THEN
                ALTER TABLE weather ALTER COLUMN code TYPE VARCHAR(60);
                ALTER TABLE weather ALTER COLUMN name TYPE VARCHAR(255);
                ALTER TABLE weather ALTER COLUMN description TYPE TEXT;
                ALTER TABLE weather ALTER COLUMN condition TYPE VARCHAR(100);

                -- Cột mới: temperature, humidity, hourly, pattern_code, hour, precipitation, weather_code
                ALTER TABLE weather ADD COLUMN IF NOT EXISTS temperature DOUBLE PRECISION DEFAULT NULL;
                ALTER TABLE weather ADD COLUMN IF NOT EXISTS humidity DOUBLE PRECISION DEFAULT NULL;
                ALTER TABLE weather DROP COLUMN IF EXISTS hourly CASCADE;
                ALTER TABLE weather ADD COLUMN IF NOT EXISTS pattern_code VARCHAR(50);
                ALTER TABLE weather ADD COLUMN IF NOT EXISTS hour INTEGER DEFAULT NULL;
                ALTER TABLE weather ADD COLUMN IF NOT EXISTS precipitation DOUBLE PRECISION DEFAULT 0.0;
                ALTER TABLE weather ADD COLUMN IF NOT EXISTS weather_code INTEGER DEFAULT 0;
                ALTER TABLE weather DROP COLUMN IF EXISTS date CASCADE;

                -- Backfill từ cột cũ nếu còn tồn tại
                IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='weather' AND column_name='min_temp') THEN
                    UPDATE weather SET
                        temperature = COALESCE(temperature, (COALESCE(min_temp, 0) + COALESCE(max_temp, 0)) / 2.0)
                    WHERE temperature IS NULL AND (min_temp IS NOT NULL OR max_temp IS NOT NULL);
                END IF;

                IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='weather' AND column_name='min_humidity') THEN
                    UPDATE weather SET
                        humidity = COALESCE(humidity, (COALESCE(min_humidity, 0) + COALESCE(max_humidity, 0)) / 2.0)
                    WHERE humidity IS NULL AND (min_humidity IS NOT NULL OR max_humidity IS NOT NULL);
                END IF;

                -- Xóa các check constraints cũ
                ALTER TABLE weather DROP CONSTRAINT IF EXISTS ck_weather_temp_range;
                ALTER TABLE weather DROP CONSTRAINT IF EXISTS ck_weather_humidity_range;
                ALTER TABLE weather DROP CONSTRAINT IF EXISTS ck_weather_humidity_valid;
                ALTER TABLE weather DROP CONSTRAINT IF EXISTS ck_weather_temperature_valid;
                ALTER TABLE weather DROP CONSTRAINT IF EXISTS ck_weather_hour_valid;

                -- Thêm lại constraints mới chuẩn hóa
                ALTER TABLE weather ADD CONSTRAINT ck_weather_temperature_valid
                    CHECK (temperature IS NULL OR (temperature >= -50.0 AND temperature <= 60.0));
                ALTER TABLE weather ADD CONSTRAINT ck_weather_humidity_valid
                    CHECK (humidity IS NULL OR (humidity >= 0.0 AND humidity <= 100.0));
                ALTER TABLE weather ADD CONSTRAINT ck_weather_hour_valid
                    CHECK (hour IS NULL OR (hour >= 0 AND hour <= 23));

                -- Xóa các cột cũ không còn trong bảng
                ALTER TABLE weather DROP COLUMN IF EXISTS min_temp;
                ALTER TABLE weather DROP COLUMN IF EXISTS max_temp;
                ALTER TABLE weather DROP COLUMN IF EXISTS min_humidity;
                ALTER TABLE weather DROP COLUMN IF EXISTS max_humidity;
                ALTER TABLE weather DROP COLUMN IF EXISTS avg_temp;
                ALTER TABLE weather DROP COLUMN IF EXISTS avg_humidity;
                ALTER TABLE weather DROP COLUMN IF EXISTS apparent_temp;
                ALTER TABLE weather DROP COLUMN IF EXISTS weather_label;

                -- Dọn sạch các mã mẫu cũ không đúng chuẩn
                DELETE FROM weather WHERE code IN ('hot', 'rainy', 'cold', 'mild');
            END IF;
        END $$;
    """))


    # --- TASK-145: Chuẩn hóa bảng seasons (4 ID cố định 1..4) và liên kết weather.season_id ---
    conn.execute(text("""
        CREATE TABLE IF NOT EXISTS seasons (
            id INTEGER PRIMARY KEY,
            code VARCHAR(20) NOT NULL UNIQUE,
            name VARCHAR(50) NOT NULL,
            description VARCHAR(255) DEFAULT NULL,
            sort_order INTEGER NOT NULL DEFAULT 0,
            is_active BOOLEAN NOT NULL DEFAULT TRUE,
            created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
            CONSTRAINT ck_seasons_id CHECK (id >= 1 AND id <= 4)
        );
    """))
    conn.execute(text("CREATE UNIQUE INDEX IF NOT EXISTS uq_seasons_code ON seasons (code);"))

    conn.execute(text("""
        INSERT INTO seasons (id, code, name, description, sort_order, is_active) VALUES
            (1, 'spring', 'Xuân', 'Mùa xuân ấm áp', 1, TRUE),
            (2, 'summer', 'Hạ', 'Mùa hè nắng nóng', 2, TRUE),
            (3, 'autumn', 'Thu', 'Mùa thu mát mẻ', 3, TRUE),
            (4, 'winter', 'Đông', 'Mùa đông lạnh giá', 4, TRUE)
        ON CONFLICT (id) DO UPDATE SET
            code = EXCLUDED.code,
            name = EXCLUDED.name,
            description = EXCLUDED.description,
            sort_order = EXCLUDED.sort_order;
    """))

    conn.execute(text("ALTER TABLE IF EXISTS weather ADD COLUMN IF NOT EXISTS season_id INTEGER REFERENCES seasons(id) ON DELETE SET NULL;"))
    conn.execute(text("CREATE INDEX IF NOT EXISTS ix_weather_season_id ON weather (season_id);"))

    conn.execute(text("""
        UPDATE weather
        SET season_id = CASE lower(season)
            WHEN 'spring' THEN 1
            WHEN 'summer' THEN 2
            WHEN 'autumn' THEN 3
            WHEN 'winter' THEN 4
            ELSE 1
        END
        WHERE season_id IS NULL;
    """))


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
        CategoryService.seed_default_categories(db)
        WeatherService.seed_weather_patterns(db)
        if getattr(settings, "AUTO_SEED_INITIAL_DATA", True):
            from server.app.services.initial_seed_service import InitialSeedService
            InitialSeedService.seed_initial_data_if_needed(db)
            InitialSeedService.sync_restaurant_ratings(db)
