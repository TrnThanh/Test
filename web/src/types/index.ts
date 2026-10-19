export type UserRole = 'user' | 'seller' | 'admin' | 'guest';

export interface User {
  id: number;
  email: string;
  full_name?: string | null;
  is_active: boolean;
  created_at?: string;
}

export interface Seller {
  id: number;
  email: string;
  full_name?: string | null;
  shop_name: string;
  phone?: string | null;
  is_active: boolean;
  created_at?: string;
}

export interface Restaurant {
  id: number;
  name: string;
  address?: string | null;
  phone?: string | null;
  description?: string | null;
  open_time?: string | null;
  close_time?: string | null;
  latitude: number;
  longitude: number;
  seller_id: number;
  is_active: boolean;
  distance_meters?: number | null;
  distance_km?: number | null;
  created_at?: string;
}

export interface GeocodePlace {
  place_id: number | string;
  display_name: string;
  latitude: number;
  longitude: number;
  type?: string;
  importance?: number;
}

export interface RoleLoginResponse {
  role: 'user' | 'seller' | 'admin';
  id: number;
  email: string;
  full_name?: string | null;
  shop_name?: string | null;
  phone?: string | null;
  access_token: string;
}

export interface Category {
  id: number;
  restaurant_id: number;
  name: string;
  description?: string | null;
  display_order: number;
  is_active: boolean;
  dish_count?: number;
  created_at?: string;
}

export type MealType = 'breakfast' | 'lunch' | 'dinner' | 'snack' | 'all_day';

export interface MealTypeEntity {
  id: number;
  code: string;
  name: string;
  description?: string | null;
  start_time?: string | null;
  end_time?: string | null;
  sort_order: number;
  is_active: boolean;
  created_at: string;
}

export interface Weather {
  id: number;
  code: string;
  name: string;
  description?: string | null;
  min_temp?: number | null;
  max_temp?: number | null;
  condition?: string | null;
  icon?: string | null;
  sort_order: number;
  is_active: boolean;
  created_at: string;
}

export interface Dish {
  id: number;
  restaurant_id: number;
  category_id?: number | null;
  category?: string | null;
  category_name?: string | null;
  meal_type_id?: number | null;
  meal_type_name?: string | null;
  name: string;
  price: number;
  description?: string | null;
  image_url?: string | null;
  meal_type: MealType;
  ingredients?: string[];
  is_available: boolean;
  created_at?: string;
}

export interface FavouriteDish {
  id: number;
  user_id: number;
  dish_id: number;
  created_at: string;
  dish?: Dish;
}

export interface OptionUser {
  id: number;
  user_id: number;
  category_id: number;
  hide: boolean;
  created_at: string;
  updated_at: string;
}


