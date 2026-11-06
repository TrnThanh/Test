"""SQLModel models package."""
# Nạp toàn bộ các model SQLModel để khởi tạo quan hệ và metadata CSDL
from server.app.models.user import User
from server.app.models.admin import Admin
from server.app.models.restaurant import Restaurant
from server.app.models.category import Category
from server.app.models.dish import Dish
from server.app.models.ingredient import Ingredient, DishIngredient
from server.app.models.ingredient_group import IngredientGroup
from server.app.models.favourite_dish import FavouriteDish
from server.app.models.meal_type import MealType
from server.app.models.weather import Weather
from server.app.models.season import Season
from server.app.models.option_user import OptionUser
from server.app.models.weather_category import WeatherCategory
from server.app.models.seed_meta import SeedMeta

__all__ = [
    "User",
    "Admin",
    "Restaurant",
    "Category",
    "Dish",
    "Ingredient",
    "DishIngredient",
    "IngredientGroup",
    "FavouriteDish",
    "MealType",
    "Weather",
    "Season",
    "OptionUser",
    "WeatherCategory",
    "SeedMeta",
]
