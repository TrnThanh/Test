from fastapi import APIRouter
from server.app.api.v1.endpoints import (
    auth_user,
    auth_seller,
    auth_admin,
    map,
    restaurants,
    categories,
    dishes,
    meal_types,
    weather,
)

api_router = APIRouter()

api_router.include_router(
    auth_user.router,
    prefix="/auth/user",
    tags=["User Authentication"],
)

api_router.include_router(
    auth_seller.router,
    prefix="/auth/seller",
    tags=["Seller Authentication"],
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


