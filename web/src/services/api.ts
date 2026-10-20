import type { Restaurant, GeocodePlace, RoleLoginResponse, SystemStats, AdminUser } from '../types';

const API_BASE = 'http://localhost:8001/api/v1';

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
  registerUser: async (data: { email: string; password: string; full_name?: string }) => {
    const res = await request<any>('/auth/user/register', {
      method: 'POST',
      body: JSON.stringify(data),
    });
    return {
      role: res.role || 'user',
      ...(res.data || {}),
      access_token: res.access_token || '',
    } as RoleLoginResponse;
  },

  loginUser: async (data: { email: string; password: string }) => {
    const res = await request<any>('/auth/user/login', {
      method: 'POST',
      body: JSON.stringify(data),
    });
    return {
      role: res.role || 'user',
      ...(res.data || {}),
      access_token: res.access_token || '',
    } as RoleLoginResponse;
  },

  loginAdmin: async (data: { email: string; password: string }) => {
    const res = await request<any>('/auth/admin/login', {
      method: 'POST',
      body: JSON.stringify(data),
    });
    return {
      role: res.role || 'admin',
      ...(res.data || {}),
      access_token: res.access_token || '',
    } as RoleLoginResponse;
  },

  // --- ADMIN OPERATIONS ---
  getAdminStats: () =>
    request<SystemStats>('/admin/stats'),

  getAdminUsers: () =>
    request<AdminUser[]>('/admin/users'),

  toggleRestaurantStatus: (restaurantId: number, isActive: boolean) =>
    request<Restaurant>(`/admin/restaurants/${restaurantId}/status`, {
      method: 'PATCH',
      body: JSON.stringify({ is_active: isActive }),
    }),

  createRestaurantAsAdmin: (data: Partial<Restaurant>) =>
    request<Restaurant>('/admin/restaurants', {
      method: 'POST',
      body: JSON.stringify(data),
    }),

  updateRestaurantAsAdmin: (restaurantId: number, data: Partial<Restaurant>) =>
    request<Restaurant>(`/admin/restaurants/${restaurantId}`, {
      method: 'PUT',
      body: JSON.stringify(data),
    }),

  getAdminRestaurants: (skip = 0, limit = 100, activeOnly = false) =>
    request<Restaurant[]>(`/admin/restaurants?skip=${skip}&limit=${limit}&active_only=${activeOnly}`),

  deleteRestaurantAsAdmin: (restaurantId: number) =>
    request<{ message: string; restaurant_id: number }>(`/admin/restaurants/${restaurantId}`, {
      method: 'DELETE',
    }),

  // --- RESTAURANTS (PUBLIC) ---
  getRestaurants: (skip = 0, limit = 50) =>
    request<Restaurant[]>(`/restaurants?skip=${skip}&limit=${Math.min(limit, 100)}`),

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

  createRestaurant: (
    data: {
      name: string;
      address?: string;
      phone?: string;
      description?: string;
      open_time?: string | null;
      close_time?: string | null;
      latitude: number;
      longitude: number;
    }
  ) =>
    request<Restaurant>('/restaurants', {
      method: 'POST',
      body: JSON.stringify(data),
    }),

  updateRestaurant: (
    restaurantId: number,
    data: {
      name?: string;
      address?: string;
      phone?: string;
      description?: string;
      open_time?: string | null;
      close_time?: string | null;
      latitude?: number;
      longitude?: number;
      is_active?: boolean;
    }
  ) =>
    request<Restaurant>(`/restaurants/${restaurantId}`, {
      method: 'PUT',
      body: JSON.stringify(data),
    }),

  deleteRestaurant: (restaurantId: number) =>
    request<void>(`/restaurants/${restaurantId}`, {
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

  // --- CATEGORIES ---
  getRestaurantCategories: (restaurantId: number, isActiveOnly = false) =>
    request<import('../types').Category[]>(
      `/restaurants/${restaurantId}/categories?is_active_only=${isActiveOnly}`
    ),

  createCategory: (
    restaurantId: number,
    data: { name: string; description?: string; display_order?: number; is_active?: boolean }
  ) =>
    request<import('../types').Category>(
      `/restaurants/${restaurantId}/categories`,
      {
        method: 'POST',
        body: JSON.stringify(data),
      }
    ),

  updateCategory: (
    categoryId: number,
    data: { name?: string; description?: string; display_order?: number; is_active?: boolean }
  ) =>
    request<import('../types').Category>(`/categories/${categoryId}`, {
      method: 'PUT',
      body: JSON.stringify(data),
    }),

  deleteCategory: (categoryId: number) =>
    request<{ message: string }>(`/categories/${categoryId}`, {
      method: 'DELETE',
    }),

  // --- DISHES ---
  getRestaurantDishes: (
    restaurantId: number,
    params?: { category_id?: number; category?: string; meal_type?: string; tag?: string }
  ) => {
    const query = new URLSearchParams();
    if (params?.category_id != null) query.append('category_id', String(params.category_id));
    if (params?.category) query.append('category', params.category);
    if (params?.meal_type) query.append('meal_type', params.meal_type);
    if (params?.tag) query.append('tag', params.tag);
    const qs = query.toString() ? `?${query.toString()}` : '';
    return request<import('../types').Dish[]>(`/restaurants/${restaurantId}/dishes${qs}`);
  },

  createDish: (restaurantId: number, data: Partial<import('../types').Dish>) =>
    request<import('../types').Dish>(
      `/restaurants/${restaurantId}/dishes`,
      {
        method: 'POST',
        body: JSON.stringify(data),
      }
    ),

  updateDish: (dishId: number, data: Partial<import('../types').Dish>) =>
    request<import('../types').Dish>(`/dishes/${dishId}`, {
      method: 'PUT',
      body: JSON.stringify(data),
    }),

  deleteDish: (dishId: number) =>
    request<{ message: string }>(`/dishes/${dishId}`, {
      method: 'DELETE',
    }),

  // --- FAVOURITES ---
  addFavouriteDish: (userId: number, dishId: number) =>
    request<import('../types').FavouriteDish>(`/users/${userId}/favourites/${dishId}`, {
      method: 'POST',
    }),

  removeFavouriteDish: (userId: number, dishId: number) =>
    request<{ message: string }>(`/users/${userId}/favourites/${dishId}`, {
      method: 'DELETE',
    }),

  getUserFavourites: (userId: number) =>
    request<import('../types').FavouriteDish[]>(`/users/${userId}/favourites`),

  // --- USER OPTIONS (CATEGORY HIDE PREFERENCES) ---
  getUserOptions: (userId: number, hide?: boolean) => {
    const qs = hide !== undefined ? `?hide=${hide}` : '';
    return request<import('../types').OptionUser[]>(`/users/${userId}/options${qs}`);
  },

  setUserCategoryOption: (userId: number, categoryId: number, hide: boolean) =>
    request<import('../types').OptionUser>(`/users/${userId}/options`, {
      method: 'POST',
      body: JSON.stringify({ category_id: categoryId, hide }),
    }),

  deleteUserCategoryOption: (userId: number, optionId: number) =>
    request<void>(`/users/${userId}/options/${optionId}`, {
      method: 'DELETE',
    }),
};
