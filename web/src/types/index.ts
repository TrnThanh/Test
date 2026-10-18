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
