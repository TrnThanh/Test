from typing import List
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from server.app.db.session import get_db
from server.app.services.ingredient_service import IngredientService
from server.app.api.v1.endpoints import (
    auth_user,
    auth_admin,
    admin,
    map,
    restaurants,
    categories,
    dishes,
    meal_types,
    weather,
    option_user,
    weather_categories,
    user_profiles,
    recommendations,
    seasons,
    ingredients,
    ingredient_groups,
)

api_router = APIRouter()

api_router.include_router(
    admin.router,
    prefix="/admin",
    tags=["Admin Operations"],
)

api_router.include_router(
    auth_user.router,
    prefix="/auth/user",
    tags=["User Authentication"],
)

api_router.include_router(
    auth_admin.router,
    prefix="/auth/admin",
    tags=["Admin Authentication"],
)

api_router.include_router(
    map.router,
    prefix="/map",
    tags=["Map (OpenStreetMap)"],
)

api_router.include_router(
    restaurants.router,
)

api_router.include_router(
    categories.router,
    tags=["Categories"],
)

api_router.include_router(
    dishes.router,
    tags=["Dishes & Favourites"],
)

api_router.include_router(
    meal_types.router,
    prefix="/meal-types",
    tags=["Meal Types"],
)

api_router.include_router(
    weather.router,
    prefix="/weather",
    tags=["Weather"],
)

api_router.include_router(
    option_user.router,
    prefix="/users",
    tags=["User Options"],
)

api_router.include_router(
    weather_categories.router,
    prefix="/weather-categories",
    tags=["Weather Categories"],
)

api_router.include_router(
    user_profiles.router,
    prefix="/users",
    tags=["User Profiles & Onboarding"],
)

api_router.include_router(
    seasons.router,
    prefix="/seasons",
    tags=["Seasons"],
)

api_router.include_router(
    recommendations.router,
    prefix="/recommendations",
    tags=["Contextual Recommendations (CARS)"],
)

api_router.include_router(
    ingredients.router,
    prefix="/ingredients",
    tags=["Ingredients Management"],
)

api_router.include_router(
    ingredient_groups.router,
    prefix="/ingredient-groups",
    tags=["Ingredient Groups Management"],
)

@api_router.get(
    "/allergens",
    response_model=List[str],
    tags=["Allergens"],
    summary="Lấy danh sách các dị ứng thực phẩm có trong hệ thống",
)
def get_allergens(db: Session = Depends(get_db)):
    return IngredientService.get_allergen_options(db=db)
