import re
import random
import unicodedata
from datetime import datetime, time, timezone
from typing import List, Optional, Tuple, Dict, Any, Set
from zoneinfo import ZoneInfo
from sqlalchemy import text, select
from sqlalchemy.orm import Session

from server.app.models.user import User
from server.app.models.dish import Dish
from server.app.models.restaurant import Restaurant
from server.app.models.favourite_dish import FavouriteDish
from server.app.models.option_user import OptionUser
from server.app.models.weather import Weather
from server.app.models.weather_category import WeatherCategory
from server.app.schemas.recommendation import (
    ContextInfo,
    FeaturedDishInfo,
    RecommendationDetail,
    RecommendedRestaurant,
    ContextualRecommendationResponse,
)

from server.app.services.recommendation_constants import (
    MEAL_PERIOD_CONFIG,
    VALID_ALLERGENS,
    ALLERGEN_GROUPS,
    NAME_ALLERGEN_REGEX,
    DISCLAIMER_TEXT,
)


def normalize_text(text_val: Optional[str]) -> str:
    if not text_val:
        return ""
    return unicodedata.normalize("NFC", str(text_val)).strip()


def expand_allergies(user_allergies: List[str]) -> Tuple[List[str], List[str]]:
    """Bung dị ứng 2 pha không lặp và trích xuất nhãn lạ chưa kiểm định."""
    declared = {normalize_text(a) for a in user_allergies if a and str(a).strip()}
    out = set(declared)
    # Pha 1: Nhãn cha trong declared -> bung toàn bộ nhãn con của nhóm
    for group, members in ALLERGEN_GROUPS.items():
        if group in declared:
            out.update(members)
    # Pha 2: Nhãn con trong out -> chỉ thêm nhãn cha trực tiếp (không lặp lại)
    for group, members in ALLERGEN_GROUPS.items():
        if out & set(members):
            out.add(group)

    unverified = [a for a in declared if a not in VALID_ALLERGENS]
    return list(out), unverified


def get_current_period_info(now_time: time) -> dict:
    t = now_time.hour * 60 + now_time.minute
    for key, match_code, name, time_range, s_min, e_min, ratio, fb_cal in MEAL_PERIOD_CONFIG:
        if key == "late_night":
            if t >= 23 * 60 or t < 6 * 60:
                return {
                    "key": key, "match_code": match_code, "name": name,
                    "time_range": time_range, "ratio": ratio, "fallback_cal": fb_cal
                }
        else:
            if s_min <= t < e_min:
                return {
                    "key": key, "match_code": match_code, "name": name,
                    "time_range": time_range, "ratio": ratio, "fallback_cal": fb_cal
                }
    return {
        "key": "snack", "match_code": "snack", "name": "Bữa xế",
        "time_range": "14:00 - 17:00", "ratio": 0.10, "fallback_cal": 250
    }


def is_valid_profile(user: Optional[User]) -> bool:
    if not user:
        return False
    if not (user.height_cm and user.weight_kg and user.birth_year and user.gender):
        return False
    now_year = datetime.now(ZoneInfo("Asia/Ho_Chi_Minh")).year
    age = now_year - user.birth_year
    if not (100.0 <= user.height_cm <= 230.0):
        return False
    if not (25.0 <= user.weight_kg <= 250.0):
        return False
    if not (10 <= age <= 100):
        return False
    gender_norm = normalize_text(user.gender).casefold()
    if gender_norm not in ("male", "female", "nam", "nữ", "nu"):
        return False
    return True


def calculate_tdee(user: User) -> float:
    now_year = datetime.now(ZoneInfo("Asia/Ho_Chi_Minh")).year
    age = now_year - user.birth_year
    gender_norm = normalize_text(user.gender).casefold()

    if gender_norm in ("male", "nam"):
        bmr = 10 * user.weight_kg + 6.25 * user.height_cm - 5 * age + 5
    else:
        bmr = 10 * user.weight_kg + 6.25 * user.height_cm - 5 * age - 161

    pal_map = {
        "sedentary": 1.2,
        "light": 1.375,
        "moderate": 1.55,
        "active": 1.725,
        "very_active": 1.9,
    }
    pal = pal_map.get(normalize_text(user.activity_level).casefold(), 1.375)
    return bmr * pal


def clamp(val: float, low: float = 0.0, high: float = 100.0) -> float:
    return max(low, min(high, val))


def format_distance(dist_km: float) -> str:
    if dist_km < 1.0:
        return f"{int(round(dist_km * 1000))}m"
    return f"{dist_km:.1f} km"


class RecommendationService:
    @staticmethod
    def get_contextual_recommendations(
        db: Session,
        lat: float,
        lon: float,
        user_id: Optional[int] = None,
        temp: Optional[float] = None,
        weather_code: Optional[str] = None,
        seed: Optional[int] = None,
    ) -> ContextualRecommendationResponse:
        # Thời gian địa phương Việt Nam
        now_local = datetime.now(ZoneInfo("Asia/Ho_Chi_Minh"))
        now_time = now_local.time()
        period_info = get_current_period_info(now_time)

        # 1. Xác định hồ sơ người dùng (Native user_id)
        user: Optional[User] = None
        guest_notice: Optional[str] = None
        if user_id:
            user = db.get(User, user_id)
        if not user:
            guest_notice = "Đăng nhập và cập nhật hồ sơ sức khỏe để nhận gợi ý chính xác theo thể trạng & tự động lọc dị ứng."

        # 2. Xử lý Dị ứng (Allergens)
        raw_allergies = (user.allergies if user else []) or []
        expanded_allergies, unverified_allergies = expand_allergies(raw_allergies)

        # 3. Xử lý Độ cay & Chế độ ăn chay (Dietary)
        spicy_tolerance_map = {"none": 0, "mild": 1, "medium": 2, "hot": 3}
        spicy_max = None
        if user and user.spicy_tolerance:
            spicy_max = spicy_tolerance_map.get(normalize_text(user.spicy_tolerance).casefold(), 3)

        user_dietary = [normalize_text(p).casefold() for p in (user.dietary_preferences if user else []) or []]
        is_vegan = any(p in ("vegan", "thuần chay") for p in user_dietary)
        is_vegetarian = is_vegan or any(p in ("vegetarian", "ăn chay", "chay") for p in user_dietary)

        # 4. Tính toán Nhu cầu Calo bữa ăn (TargetMealCalo)
        effective_goal = "maintain"
        target_meal_cal = float(period_info["fallback_cal"])

        if is_valid_profile(user):
            bmi = user.weight_kg / ((user.height_cm / 100.0) ** 2)
            goal_raw = normalize_text(user.target_goal).casefold()
            effective_goal = goal_raw if goal_raw in ("maintain", "lose_weight", "gain_muscle", "eat_healthy") else "maintain"

            # Safe Guard Mode cho người gầy (BMI < 18.5)
            if bmi < 18.5 and effective_goal == "lose_weight":
                effective_goal = "maintain"

            tdee = calculate_tdee(user)
            # Điều chỉnh theo goal
            if effective_goal == "lose_weight":
                tdee *= 0.85
            elif effective_goal == "gain_muscle":
                tdee *= 1.10

            target_meal_cal = tdee * period_info["ratio"]

        target_min_display = int(round(target_meal_cal * 0.85))
        target_max_display = int(round(target_meal_cal * 1.15))
        goal_text = f" ({user.activity_level})" if user and user.activity_level else ""
        target_cal_display = f"{target_min_display} - {target_max_display} kcal{goal_text}"

        # 5. Xử lý Thời tiết (Weather)
        if temp is not None and not (-10.0 <= temp <= 50.0):
            temp = None

        final_weather_code = "mild"
        if weather_code and weather_code.casefold() in ("hot", "cold", "rainy", "mild"):
            final_weather_code = weather_code.casefold()
        elif temp is not None:
            if temp >= 30.0:
                final_weather_code = "hot"
            elif temp < 19.0:
                final_weather_code = "cold"
            else:
                final_weather_code = "mild"

        weather_desc_map = {
            "hot": f"Nắng nóng oi bức ({int(temp)}°C)" if temp is not None else "Nắng nóng oi bức",
            "cold": f"Trời lạnh gió rét ({int(temp)}°C)" if temp is not None else "Trời lạnh gió rét",
            "rainy": f"Trời mưa ẩm ướt ({int(temp)}°C)" if temp is not None else "Trời mưa ẩm ướt",
            "mild": f"Mát mẻ dễ chịu ({int(temp)}°C)" if temp is not None else "Mát mẻ dễ chịu (26°C)",
        }
        weather_desc = weather_desc_map.get(final_weather_code, "Mát mẻ dễ chịu")

        # Lấy danh sách category_id phù hợp thời tiết
        weather_category_ids: Set[int] = set()
        weather_row = db.scalar(select(Weather).where(Weather.code == final_weather_code))
        if weather_row:
            cat_rows = db.scalars(
                select(WeatherCategory.category_id).where(WeatherCategory.weather_id == weather_row.id)
            ).all()
            weather_category_ids = set(cat_rows)

        # 6. Tải sở thích cá nhân của User (Favourited, Explicit, Implicit)
        favourite_dish_ids: Set[int] = set()
        explicit_category_ids: Set[int] = set()
        implicit_category_ids: Set[int] = set()

        if user:
            # Thả tim
            fav_dishes = db.scalars(select(FavouriteDish.dish_id).where(FavouriteDish.user_id == user.id)).all()
            favourite_dish_ids = set(fav_dishes)

            # Explicit Categories từ user.favorite_category_ids
            explicit_category_ids.update(user.favorite_category_ids or [])

            # Categories từ option_users
            opts = db.scalars(select(OptionUser).where(OptionUser.user_id == user.id)).all()
            for opt in opts:
                if not opt.hide:
                    explicit_category_ids.add(opt.category_id)
                else:
                    if opt.category_id not in explicit_category_ids:
                        implicit_category_ids.add(opt.category_id)

        # 7. TẦNG 1: TRUY VẤN SQL POSTGIS LỌC QUÁN & MÓN AN TOÀN
        sql_query = text("""
        WITH nearby_restaurants AS (
            SELECT r.id, r.name, r.address, r.phone, r.latitude, r.longitude,
                   r.open_time, r.close_time, r.is_sponsor, r.service_licenses, r.rating,
                   ST_Distance(r.location, ST_SetSRID(ST_MakePoint(:lon, :lat), 4326)::geography) / 1000.0 AS distance_km
            FROM restaurants r
            WHERE r.is_active = TRUE
              AND ST_DWithin(r.location, ST_SetSRID(ST_MakePoint(:lon, :lat), 4326)::geography, 15000)
              AND (
                  (r.open_time IS NULL AND r.close_time IS NULL) OR (r.open_time = r.close_time)
                  OR (
                      (
                          (r.open_time < r.close_time AND CAST(:now_time AS time) BETWEEN r.open_time AND r.close_time)
                          OR (r.open_time > r.close_time AND (CAST(:now_time AS time) >= r.open_time OR CAST(:now_time AS time) <= r.close_time))
                      )
                      AND ((EXTRACT(EPOCH FROM (r.close_time - CAST(:now_time AS time))) / 60)::int + 1440) % 1440 >= 30
                  )
              )
              AND EXISTS (
                  SELECT 1 FROM dishes d2
                  WHERE d2.restaurant_id = r.id AND d2.is_available = TRUE
                    AND (CAST(:spicy_max AS int) IS NULL OR d2.spicy_level <= CAST(:spicy_max AS int))
                    AND (
                        :is_vegetarian = FALSE 
                        OR ('Món chay' = ANY(d2.dietary_tags))
                    )
                    AND (
                        :is_vegan = FALSE 
                        OR (NOT (d2.allergens && ARRAY['Sữa', 'Bơ (sữa)', 'Phô mai', 'Trứng']))
                    )
                    AND (
                        :expanded_allergies_count = 0
                        OR (d2.allergens IS NOT NULL AND NOT (d2.allergens && CAST(:expanded_allergies AS text[])))
                    )
              )
            ORDER BY distance_km ASC
            LIMIT 80
        )
        SELECT nr.id, nr.name, nr.address, nr.phone, nr.latitude, nr.longitude,
               nr.open_time, nr.close_time, nr.is_sponsor, nr.service_licenses, nr.rating, nr.distance_km,
               d.id as dish_id, d.name as dish_name, d.price as dish_price,
               d.calories as dish_calories, d.spicy_level as dish_spicy_level,
               d.allergens as dish_allergens, d.dietary_tags as dish_dietary_tags,
               d.meal_types as dish_meal_types, d.category_id as dish_category_id,
               d.image_url as dish_image_url
        FROM nearby_restaurants nr
        JOIN dishes d ON nr.id = d.restaurant_id
        WHERE d.is_available = TRUE
          AND (CAST(:spicy_max AS int) IS NULL OR d.spicy_level <= CAST(:spicy_max AS int))
          AND (
              :is_vegetarian = FALSE 
              OR ('Món chay' = ANY(d.dietary_tags))
          )
          AND (
              :is_vegan = FALSE 
              OR (NOT (d.allergens && ARRAY['Sữa', 'Bơ (sữa)', 'Phô mai', 'Trứng']))
          )
          AND (
              :expanded_allergies_count = 0
              OR (d.allergens IS NOT NULL AND NOT (d.allergens && CAST(:expanded_allergies AS text[])))
          );
        """)

        params = {
            "lon": lon,
            "lat": lat,
            "now_time": now_time.strftime("%H:%M:%S"),
            "spicy_max": spicy_max,
            "is_vegetarian": is_vegetarian,
            "is_vegan": is_vegan,
            "expanded_allergies_count": len(expanded_allergies),
            "expanded_allergies": expanded_allergies,
        }

        rows = db.execute(sql_query, params).fetchall()

        if not rows:
            # Fallback nếu quán đóng cửa đêm muộn / ngoài giờ phục vụ
            sql_fallback = text("""
            WITH nearby_restaurants AS (
                SELECT r.id, r.name, r.address, r.phone, r.latitude, r.longitude,
                       r.open_time, r.close_time, r.is_sponsor, r.service_licenses, r.rating,
                       ST_Distance(r.location, ST_SetSRID(ST_MakePoint(:lon, :lat), 4326)::geography) / 1000.0 AS distance_km
                FROM restaurants r
                WHERE r.is_active = TRUE
                  AND ST_DWithin(r.location, ST_SetSRID(ST_MakePoint(:lon, :lat), 4326)::geography, 15000)
                  AND EXISTS (
                      SELECT 1 FROM dishes d2
                      WHERE d2.restaurant_id = r.id AND d2.is_available = TRUE
                        AND (CAST(:spicy_max AS int) IS NULL OR d2.spicy_level <= CAST(:spicy_max AS int))
                        AND (
                            :is_vegetarian = FALSE 
                            OR ('Món chay' = ANY(d2.dietary_tags))
                        )
                        AND (
                            :is_vegan = FALSE 
                            OR (NOT (d2.allergens && ARRAY['Sữa', 'Bơ (sữa)', 'Phô mai', 'Trứng']))
                        )
                        AND (
                            :expanded_allergies_count = 0
                            OR (d2.allergens IS NOT NULL AND NOT (d2.allergens && CAST(:expanded_allergies AS text[])))
                        )
                  )
                ORDER BY distance_km ASC
                LIMIT 80
            )
            SELECT nr.id, nr.name, nr.address, nr.phone, nr.latitude, nr.longitude,
                   nr.open_time, nr.close_time, nr.is_sponsor, nr.service_licenses, nr.rating, nr.distance_km,
                   d.id as dish_id, d.name as dish_name, d.price as dish_price,
                   d.calories as dish_calories, d.spicy_level as dish_spicy_level,
                   d.allergens as dish_allergens, d.dietary_tags as dish_dietary_tags,
                   d.meal_types as dish_meal_types, d.category_id as dish_category_id,
                   d.image_url as dish_image_url
            FROM nearby_restaurants nr
            JOIN dishes d ON nr.id = d.restaurant_id
            WHERE d.is_available = TRUE
              AND (CAST(:spicy_max AS int) IS NULL OR d.spicy_level <= CAST(:spicy_max AS int))
              AND (
                  :is_vegetarian = FALSE 
                  OR ('Món chay' = ANY(d.dietary_tags))
              )
              AND (
                  :is_vegan = FALSE 
                  OR (NOT (d.allergens && ARRAY['Sữa', 'Bơ (sữa)', 'Phô mai', 'Trứng']))
              )
              AND (
                  :expanded_allergies_count = 0
                  OR (d.allergens IS NOT NULL AND NOT (d.allergens && CAST(:expanded_allergies AS text[])))
              );
            """)
            rows = db.execute(sql_fallback, params).fetchall()

        # 8. TẦNG 2: CHẤM ĐIỂM & ĐÁNH GIÁ MÔN PHÁI (Python RAM Processing)
        # Chuẩn bị Regex lọc Heuristic tên món dị ứng
        active_name_regexes: List[re.Pattern] = []
        for allergy_label in expanded_allergies:
            if allergy_label in NAME_ALLERGEN_REGEX:
                active_name_regexes.append(re.compile(NAME_ALLERGEN_REGEX[allergy_label], re.IGNORECASE))

        # Gom nhóm món ăn theo quán
        restaurant_dishes_map: Dict[int, Dict[str, Any]] = {}

        for row in rows:
            dish_name = row.dish_name or ""
            # Lớp 2: Heuristic Name Filter
            is_unsafe_name = False
            for reg in active_name_regexes:
                if reg.search(dish_name):
                    is_unsafe_name = True
                    break
            if is_unsafe_name:
                continue

            r_id = row.id
            if r_id not in restaurant_dishes_map:
                restaurant_dishes_map[r_id] = {
                    "info": {
                        "id": row.id,
                        "name": row.name,
                        "address": row.address,
                        "phone": row.phone,
                        "latitude": row.latitude,
                        "longitude": row.longitude,
                        "open_time": row.open_time,
                        "close_time": row.close_time,
                        "is_sponsor": row.is_sponsor,
                        "rating": getattr(row, "rating", None),
                        "service_licenses": row.service_licenses or [],
                        "distance_km": float(row.distance_km),
                        "distance_display": format_distance(float(row.distance_km)),
                    },
                    "dishes": [],
                }

            dish_item = {
                "id": row.dish_id,
                "name": row.dish_name,
                "price": float(row.dish_price),
                "calories": row.dish_calories,
                "spicy_level": row.dish_spicy_level,
                "allergens": row.dish_allergens or [],
                "dietary_tags": row.dish_dietary_tags or [],
                "meal_types": row.dish_meal_types or [],
                "category_id": row.dish_category_id,
                "image_url": row.dish_image_url,
            }
            restaurant_dishes_map[r_id]["dishes"].append(dish_item)

        # Chấm điểm chi tiết từng món ăn
        scored_restaurants: List[Dict[str, Any]] = []

        budget_ceiling_map = {"budget": 50000.0, "moderate": 120000.0, "premium": 300000.0}
        budget_ceiling = budget_ceiling_map.get(normalize_text(user.budget_range if user else "").casefold(), None)
        user_budget_type = normalize_text(user.budget_range if user else "").casefold()

        match_code = period_info["match_code"]

        for r_id, r_data in restaurant_dishes_map.items():
            r_info = r_data["info"]
            dishes = r_data["dishes"]
            if not dishes:
                continue

            best_dish = None
            best_dish_score = -1.0
            best_badges: List[str] = []

            for d in dishes:
                # 1. S_time (25%)
                d_meal_types = [m.lower() for m in d["meal_types"]]
                if match_code in d_meal_types:
                    s_time = 100.0
                elif "all_day" in d_meal_types:
                    s_time = 70.0
                else:
                    s_time = 20.0

                # 2. S_nutrition (25%)
                if d["calories"] is None:
                    s_nutrition = 35.0
                else:
                    cal = float(d["calories"])
                    delta = (cal - target_meal_cal) / target_meal_cal
                    if effective_goal == "lose_weight":
                        s_nutrition = clamp(100.0 - (80.0 * abs(delta) if delta <= 0 else 180.0 * delta))
                    elif effective_goal == "gain_muscle":
                        s_nutrition = clamp(100.0 - (160.0 * abs(delta) if delta < 0 else 60.0 * delta))
                    else:  # maintain
                        s_nutrition = clamp(100.0 - 120.0 * abs(delta))

                # 3. S_distance (20%)
                dist_km = r_info["distance_km"]
                s_distance = 100.0 * max(0.0, 1.0 - (dist_km / 15.0))

                # 4. S_personal (20%)
                s_personal_raw = 0.0
                if d["id"] in favourite_dish_ids:
                    s_personal_raw += 40.0
                if d["category_id"] in explicit_category_ids:
                    s_personal_raw += 30.0
                elif d["category_id"] in implicit_category_ids:
                    s_personal_raw += 20.0

                # Khớp sở thích mềm
                dish_tags_clean = [normalize_text(t).casefold() for t in d["dietary_tags"]]
                for u_pref in user_dietary:
                    if u_pref not in ("vegan", "thuần chay", "vegetarian", "ăn chay", "chay"):
                        if u_pref in dish_tags_clean:
                            s_personal_raw += 15.0
                            break
                s_personal = min(100.0, s_personal_raw)

                # 5. S_weather (10%)
                if d["category_id"] in weather_category_ids:
                    s_weather = 100.0
                else:
                    s_weather = 40.0

                # Điểm món thô
                raw_dish_score = (
                    0.25 * s_time
                    + 0.25 * s_nutrition
                    + 0.20 * s_distance
                    + 0.20 * s_personal
                    + 0.10 * s_weather
                )

                # Hệ số ngân sách liên tục
                price = d["price"]
                budget_multiplier = 1.0
                if budget_ceiling is not None:
                    if price <= budget_ceiling:
                        budget_multiplier = 1.05 if user_budget_type in ("budget", "moderate") else 1.0
                    else:
                        budget_multiplier = max(0.40, 1.0 - 0.60 * ((price - budget_ceiling) / budget_ceiling))

                final_dish_score = clamp(raw_dish_score * budget_multiplier, 0.0, 100.0)

                if final_dish_score > best_dish_score:
                    best_dish_score = final_dish_score
                    best_dish = d

                    # Sinh badges
                    badges = [f"Hợp {period_info['name']}"]
                    if d["calories"]:
                        badges.append(f"{d['calories']} kcal")
                    badges.append(f"Cách {r_info['distance_display']}")
                    if "ATTP" in r_info["service_licenses"]:
                        badges.append("Chuẩn ATTP")
                    best_badges = badges

            if not best_dish:
                continue

            # Trust Boost
            trust_boost = 0.0
            if "ATTP" in r_info["service_licenses"]:
                trust_boost += 5.0
            if r_info["is_sponsor"]:
                trust_boost += 3.0

            final_restaurant_score = min(100.0, best_dish_score + trust_boost)

            explanation = (
                f"{best_dish['name']} phù hợp khẩu vị và mục tiêu {period_info['name']} của bạn, "
                f"chỉ cách {r_info['distance_display']}."
            )

            scored_restaurants.append({
                "restaurant": r_info,
                "score": round(final_restaurant_score, 1),
                "featured_dish": best_dish,
                "badges": best_badges,
                "explanation": explanation,
                "category_id": best_dish["category_id"],
            })

        # 9. TẦNG 3: XẾP HẠNG, DIVERSITY & BỐC HERO
        # Xếp hạng giảm dần
        scored_restaurants.sort(key=lambda x: x["score"], reverse=True)

        # Đa dạng hóa Category (Tối đa 2 quán / category, nới nếu thiếu)
        def filter_diversity(items: List[Dict[str, Any]], max_per_cat: int) -> List[Dict[str, Any]]:
            counts: Dict[int, int] = {}
            res = []
            for item in items:
                cat_id = item["category_id"] or 0
                if counts.get(cat_id, 0) < max_per_cat:
                    res.append(item)
                    counts[cat_id] = counts.get(cat_id, 0) + 1
            return res

        filtered_restaurants = filter_diversity(scored_restaurants, 2)
        if len(filtered_restaurants) < 5:
            filtered_restaurants = filter_diversity(scored_restaurants, 3)
        if len(filtered_restaurants) < 5:
            filtered_restaurants = scored_restaurants

        # Bốc Hero Restaurant bằng Weighted Random trong Top 3
        hero_item = None
        remaining_restaurants = list(filtered_restaurants)

        if remaining_restaurants:
            top_pool = remaining_restaurants[: min(3, len(remaining_restaurants))]
            rng = random.Random(seed) if seed is not None else random.Random()

            if len(top_pool) == 1:
                hero_item = top_pool[0]
            elif len(top_pool) == 2:
                weights = [70.6, 29.4]
                hero_item = rng.choices(top_pool, weights=weights, k=1)[0]
            else:
                weights = [60.0, 25.0, 15.0]
                hero_item = rng.choices(top_pool, weights=weights, k=1)[0]

            # LOẠI TRỪ HERO HOÀN TOÀN KHỎI DANH SÁCH DƯỚI
            remaining_restaurants.remove(hero_item)

        # Chèn Quán Khám Phá (Exploration) nếu có
        known_category_ids = explicit_category_ids | implicit_category_ids
        exploration_item = None
        for item in scored_restaurants:
            if hero_item and item["restaurant"]["id"] == hero_item["restaurant"]["id"]:
                continue
            if any(r["restaurant"]["id"] == item["restaurant"]["id"] for r in remaining_restaurants):
                continue
            cat = item["category_id"]
            if cat and cat not in known_category_ids and "ATTP" in item["restaurant"]["service_licenses"]:
                exploration_item = item
                item["badges"].append("✨ Khám phá hương vị mới")
                break

        if exploration_item:
            if len(remaining_restaurants) >= 3:
                remaining_restaurants.insert(2, exploration_item)
            else:
                remaining_restaurants.append(exploration_item)

        # 10. CHUYỂN ĐỔI SANG SCHEMA RESPONSE
        def to_recommended_restaurant(item: Dict[str, Any]) -> RecommendedRestaurant:
            r = item["restaurant"]
            d = item["featured_dish"]
            return RecommendedRestaurant(
                id=r["id"],
                name=r["name"],
                address=r["address"],
                latitude=r["latitude"],
                longitude=r["longitude"],
                phone=r["phone"],
                open_time=r["open_time"],
                close_time=r["close_time"],
                is_sponsor=r["is_sponsor"],
                rating=r.get("rating"),
                service_licenses=r["service_licenses"],
                distance_km=r["distance_km"],
                distance_display=r["distance_display"],
                recommendation=RecommendationDetail(
                    score=item["score"],
                    featured_dish=FeaturedDishInfo(
                        id=d["id"],
                        name=d["name"],
                        price=d["price"],
                        calories=d["calories"],
                        image_url=d["image_url"],
                        category_id=d["category_id"],
                        dietary_tags=d["dietary_tags"],
                    ),
                    badges=item["badges"],
                    explanation=item["explanation"],
                ),
            )

        hero_model = to_recommended_restaurant(hero_item) if hero_item else None
        recommended_models = [to_recommended_restaurant(it) for it in remaining_restaurants]

        return ContextualRecommendationResponse(
            context=ContextInfo(
                meal_period=period_info["name"],
                meal_time_range=period_info["time_range"],
                weather_desc=weather_desc,
                target_calories_display=target_cal_display,
                unverified_allergies=unverified_allergies,
                guest_notice=guest_notice,
                disclaimer=DISCLAIMER_TEXT,
            ),
            hero_restaurant=hero_model,
            recommended_restaurants=recommended_models,
        )
