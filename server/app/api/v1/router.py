from fastapi import APIRouter
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
