import type { Restaurant, GeocodePlace, RoleLoginResponse } from '../types';

const API_BASE = 'http://localhost:8000/api/v1';

async function request<T>(path: string, options: RequestInit = {}): Promise<T> {
  const url = `${API_BASE}${path}`;
  const headers = new Headers(options.headers || {});

  if (!headers.has('Content-Type') && options.body && typeof options.body === 'string') {
    headers.set('Content-Type', 'application/json');
  }

  const response = await fetch(url, {
    ...options,
    headers,
  });

  if (!response.ok) {
    let errorDetail = `Lỗi mạng: ${response.status} ${response.statusText}`;
    try {
      const errJson = await response.json();
      if (errJson.detail) {
        errorDetail = typeof errJson.detail === 'string' ? errJson.detail : JSON.stringify(errJson.detail);
      }
    } catch {
      // ignore
    }
    throw new Error(errorDetail);
  }

  if (response.status === 204) {
    return {} as T;
  }

  return response.json();
}

export const api = {
  // --- AUTH ---
  registerUser: (data: { email: string; password: string; full_name?: string }) =>
    request<RoleLoginResponse>('/auth/user/register', {
      method: 'POST',
      body: JSON.stringify(data),
    }),

  loginUser: (data: { email: string; password: string }) =>
    request<RoleLoginResponse>('/auth/user/login', {
      method: 'POST',
      body: JSON.stringify(data),
    }),

  registerSeller: (data: { email: string; password: string; full_name?: string; shop_name: string; phone?: string }) =>
    request<RoleLoginResponse>('/auth/seller/register', {
      method: 'POST',
      body: JSON.stringify(data),
    }),

  loginSeller: (data: { email: string; password: string }) =>
    request<RoleLoginResponse>('/auth/seller/login', {
      method: 'POST',
      body: JSON.stringify(data),
    }),

  // --- RESTAURANTS (PUBLIC) ---
  getRestaurants: (skip = 0, limit = 50) =>
    request<Restaurant[]>(`/restaurants?skip=${skip}&limit=${limit}`),

  getRestaurantDetail: (id: number) =>
    request<Restaurant>(`/restaurants/${id}`),

  getNearbyRestaurants: (lat: number, lon: number, radiusKm: number, signal?: AbortSignal) =>
    request<Restaurant[]>(`/restaurants/nearby?lat=${lat}&lon=${lon}&radius_km=${radiusKm}`, {
      signal,
    }),

  getRestaurantDistance: (id: number, lat: number, lon: number) =>
    request<{ restaurant_id: number; distance_meters: number; distance_km: number }>(
      `/restaurants/${id}/distance?lat=${lat}&lon=${lon}`
    ),

  // --- SELLER RESTAURANTS MANAGEMENT ---
  getSellerRestaurants: (sellerId: number) =>
    request<Restaurant[]>(`/sellers/${sellerId}/restaurants`),

  createSellerRestaurant: (
    sellerId: number,
    data: {
      name: string;
      address?: string;
      phone?: string;
      description?: string;
      latitude: number;
      longitude: number;
    }
  ) =>
    request<Restaurant>(`/sellers/${sellerId}/restaurants`, {
      method: 'POST',
      body: JSON.stringify(data),
    }),

  updateSellerRestaurant: (
    sellerId: number,
    restaurantId: number,
    data: {
      name?: string;
      address?: string;
      phone?: string;
      description?: string;
      latitude?: number;
      longitude?: number;
      is_active?: boolean;
    }
  ) =>
    request<Restaurant>(`/sellers/${sellerId}/restaurants/${restaurantId}`, {
      method: 'PUT',
      body: JSON.stringify(data),
    }),

  deleteSellerRestaurant: (sellerId: number, restaurantId: number) =>
    request<void>(`/sellers/${sellerId}/restaurants/${restaurantId}`, {
      method: 'DELETE',
    }),

  // --- MAP (OPENSTREETMAP NOMINATIM) ---
  searchMap: async (query: string, limit = 5, signal?: AbortSignal) => {
    const res = await request<{ places: any[] }>(
      `/map/search?q=${encodeURIComponent(query)}&limit=${limit}`,
      { signal }
    );
    return res.places.map((p) => ({
      place_id: p.place_id || p.osm_id || Math.random(),
      display_name: p.display_name || p.address || query,
      latitude: Number(p.latitude ?? p.lat),
      longitude: Number(p.longitude ?? p.lon),
      type: p.type,
      importance: p.importance,
    })) as GeocodePlace[];
  },

  reverseMap: async (lat: number, lon: number) => {
    return request<{ address: string; latitude: number; longitude: number }>(
      `/map/reverse?lat=${lat}&lon=${lon}`
    );
  },
};
