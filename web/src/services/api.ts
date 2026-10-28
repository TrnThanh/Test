import type { Restaurant, GeocodePlace, RoleLoginResponse, SystemStats, AdminUser, UserProfile } from '../types';

const API_BASE = 'http://localhost:8001/api/v1';

// Ham tien ich thuc hien goi API HTTP dung chung cho toan bo ung dung Web
/**
 * Gui HTTP Request toi backend FastAPI kem xu ly header JSON va bat loi tu dong.
 * @param path Duong dan tuong doi cua endpoint API (vi du: '/restaurants')
 * @param options Cau hinh RequestInit cua Fetch API
 * @returns Du lieu phan hoi da parse JSON kieu T
 */
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
    const sid = res.session_id || res.access_token || '';
    return {
      role: res.role || 'user',
      ...(res.data || {}),
      session_id: sid,
      access_token: sid,
    } as RoleLoginResponse;
  },

  loginUser: async (data: { email: string; password: string }) => {
    const res = await request<any>('/auth/user/login', {
      method: 'POST',
      body: JSON.stringify(data),
    });
    const sid = res.session_id || res.access_token || '';
    return {
      role: res.role || 'user',
      ...(res.data || {}),
      session_id: sid,
      access_token: sid,
    } as RoleLoginResponse;
  },

  loginAdmin: async (data: { email: string; password: string }) => {
    const res = await request<any>('/auth/admin/login', {
      method: 'POST',
      body: JSON.stringify(data),
    });
    const sid = res.session_id || res.access_token || '';
    return {
      role: res.role || 'admin',
      ...(res.data || {}),
      session_id: sid,
      access_token: sid,
    } as RoleLoginResponse;
  },

  // --- ADMIN OPERATIONS ---
  getAdminStats: () =>
    request<SystemStats>('/admin/stats'),

  getAdminUsers: () =>
    request<AdminUser[]>('/admin/users'),
  getUserProfile: (userId: number) =>
    request<UserProfile>(`/users/${userId}/profile`),

  updateUserProfile: (userId: number, data: any) =>
    request<UserProfile>(`/users/${userId}/profile`, {
      method: 'PUT',
      body: JSON.stringify(data),
    }),


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
  getAllCategories: (isActiveOnly = false) =>
    request<import('../types').Category[]>(`/categories?is_active_only=${isActiveOnly}`),

  getRestaurantCategories: (restaurantId: number, isActiveOnly = false) =>
    request<import('../types').Category[]>(
      `/restaurants/${restaurantId}/categories?is_active_only=${isActiveOnly}`
    ),

  createGlobalCategory: (
    data: { name: string; description?: string; display_order?: number; is_active?: boolean }
  ) =>
    request<import('../types').Category>(`/categories`, {
      method: 'POST',
      body: JSON.stringify(data),
    }),

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
    params?: {
      category_id?: number;
      category?: string;
      meal_type?: string;
      spicy_level?: number;
      dietary_tag?: string;
      allergen?: string;
      ingredient?: string;
    }
  ) => {
    const query = new URLSearchParams();
    if (params?.category_id != null) query.append('category_id', String(params.category_id));
    if (params?.category) query.append('category', params.category);
    if (params?.meal_type) query.append('meal_type', params.meal_type);
    if (params?.spicy_level != null) query.append('spicy_level', String(params.spicy_level));
    if (params?.dietary_tag) query.append('dietary_tag', params.dietary_tag);
    if (params?.allergen) query.append('allergen', params.allergen);
    if (params?.ingredient) query.append('ingredient', params.ingredient);
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
  // --- WEATHER & WEATHER-CATEGORY RULES ---
  getAllWeathers: (activeOnly: boolean = false) =>
    request<import('../types').Weather[]>(`/weather?active_only=${activeOnly}`),

  createWeather: (data: Partial<import('../types').Weather>) =>
    request<import('../types').Weather>('/weather', {
      method: 'POST',
      body: JSON.stringify(data),
    }),

  getCategoriesByWeather: (weatherId: number) =>
    request<import('../types').Category[]>(`/weather-categories/weathers/${weatherId}/categories`),

  linkWeatherCategory: (weatherId: number, categoryId: number) =>
    request<any>(`/weather-categories/weathers/${weatherId}/categories/${categoryId}`, {
      method: 'POST',
    }),

  unlinkWeatherCategory: (weatherId: number, categoryId: number) =>
    request<any>(`/weather-categories/weathers/${weatherId}/categories/${categoryId}`, {
      method: 'DELETE',
    }),
};
