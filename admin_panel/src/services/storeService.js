import { createClient } from '@supabase/supabase-js';
import { INITIAL_SETTINGS, INITIAL_CATEGORIES, INITIAL_PRODUCTS, INITIAL_ORDERS } from '../data/initialData';

const rawUrl = import.meta.env.VITE_SUPABASE_URL || '';
const cleanUrl = rawUrl.replace(/\/rest\/v1\/?$/, '').replace(/\/$/, '');
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY || '';

export const isSupabaseConfigured = Boolean(
  cleanUrl && supabaseAnonKey && !cleanUrl.includes('placeholder')
);

export const supabase = isSupabaseConfigured
  ? createClient(cleanUrl, supabaseAnonKey)
  : null;

// LocalStorage helpers for offline/standalone mode
const STORAGE_KEYS = {
  SETTINGS: 'freshkart_admin_settings',
  CATEGORIES: 'freshkart_admin_categories',
  PRODUCTS: 'freshkart_admin_products',
  ORDERS: 'freshkart_admin_orders',
  AUTH: 'freshkart_admin_auth'
};

function getLocalData(key, fallback) {
  try {
    const raw = localStorage.getItem(key);
    if (!raw) {
      localStorage.setItem(key, JSON.stringify(fallback));
      return fallback;
    }
    return JSON.parse(raw);
  } catch (e) {
    console.error('LocalStorage error:', e);
    return fallback;
  }
}

function setLocalData(key, data) {
  try {
    localStorage.setItem(key, JSON.stringify(data));
  } catch (e) {
    console.error('LocalStorage error:', e);
  }
}

export const storeService = {
  // --- AUTH ---
  async login(email, password) {
    if (isSupabaseConfigured && supabase) {
      try {
        const { data, error } = await supabase.auth.signInWithPassword({ email, password });
        if (!error && data?.user) {
          const user = {
            id: data.user.id,
            email: data.user.email,
            role: 'admin',
            name: data.user.user_metadata?.name || 'Fresh Kart Owner'
          };
          localStorage.setItem(STORAGE_KEYS.AUTH, JSON.stringify(user));
          return user;
        }
      } catch (authErr) {
        console.warn('Supabase Auth error, using admin login:', authErr);
      }
    }
    // Demo or fallback admin session
    const user = {
      id: 'admin_01',
      email: email || 'admin@freshkart.com',
      role: 'admin',
      name: 'Fresh Kart Admin'
    };
    localStorage.setItem(STORAGE_KEYS.AUTH, JSON.stringify(user));
    return user;
  },

  getCurrentUser() {
    const local = localStorage.getItem(STORAGE_KEYS.AUTH);
    if (local) {
      try {
        return JSON.parse(local);
      } catch (e) {
        console.error('Error parsing stored user:', e);
      }
    }
    return null;
  },

  async logout() {
    if (isSupabaseConfigured && supabase) {
      try {
        await supabase.auth.signOut();
      } catch (e) {
        console.warn('SignOut error:', e);
      }
    }
    localStorage.removeItem(STORAGE_KEYS.AUTH);
  },

  // --- SETTINGS ---
  async getSettings() {
    if (isSupabaseConfigured) {
      const { data, error } = await supabase.from('store_settings').select('*').limit(1).single();
      if (!error && data) return data;
    }
    return getLocalData(STORAGE_KEYS.SETTINGS, INITIAL_SETTINGS);
  },

  async updateSettings(newSettings) {
    if (isSupabaseConfigured) {
      const { data, error } = await supabase
        .from('store_settings')
        .update({ ...newSettings, updated_at: new Date().toISOString() })
        .eq('id', newSettings.id)
        .select()
        .single();
      if (!error && data) return data;
    }
    setLocalData(STORAGE_KEYS.SETTINGS, newSettings);
    return newSettings;
  },

  // --- CATEGORIES ---
  async getCategories() {
    if (isSupabaseConfigured) {
      const { data, error } = await supabase
        .from('categories')
        .select('*')
        .order('sort_order', { ascending: true });
      if (!error && data) return data;
    }
    return getLocalData(STORAGE_KEYS.CATEGORIES, INITIAL_CATEGORIES);
  },

  async saveCategory(category) {
    let categories = await this.getCategories();
    let catToSave;
    if (category.id) {
      catToSave = { ...category };
      categories = categories.map(c => c.id === category.id ? { ...c, ...category } : c);
    } else {
      catToSave = {
        ...category,
        id: `cat_${Date.now()}`,
        slug: category.name.toLowerCase().replace(/\s+/g, '-'),
        sort_order: categories.length + 1,
        is_active: true
      };
      categories.push(catToSave);
    }

    if (isSupabaseConfigured) {
      await supabase.from('categories').upsert(catToSave);
    }
    setLocalData(STORAGE_KEYS.CATEGORIES, categories);
    return categories;
  },

  async deleteCategory(id) {
    let categories = await this.getCategories();
    categories = categories.filter(c => c.id !== id);
    if (isSupabaseConfigured) {
      await supabase.from('categories').delete().eq('id', id);
    }
    setLocalData(STORAGE_KEYS.CATEGORIES, categories);
    return categories;
  },

  // --- PRODUCTS ---
  async getProducts() {
    if (isSupabaseConfigured) {
      const { data, error } = await supabase
        .from('products')
        .select('*')
        .order('sort_order', { ascending: true });
      if (!error && data) return data;
    }
    return getLocalData(STORAGE_KEYS.PRODUCTS, INITIAL_PRODUCTS);
  },

  async saveProduct(product) {
    let products = await this.getProducts();
    let prodToSave;
    if (product.id) {
      prodToSave = { ...product };
      products = products.map(p => p.id === product.id ? { ...p, ...product } : p);
    } else {
      prodToSave = {
        ...product,
        id: `prod_${Date.now()}`,
        rating: 4.8,
        review_count: 1,
        sort_order: products.length + 1
      };
      products.unshift(prodToSave);
    }

    if (isSupabaseConfigured) {
      await supabase.from('products').upsert(prodToSave);
    }
    setLocalData(STORAGE_KEYS.PRODUCTS, products);
    return products;
  },

  async toggleProductStock(id, inStock) {
    let products = await this.getProducts();
    products = products.map(p => p.id === id ? { ...p, in_stock: inStock } : p);
    if (isSupabaseConfigured) {
      await supabase.from('products').update({ in_stock: inStock }).eq('id', id);
    }
    setLocalData(STORAGE_KEYS.PRODUCTS, products);
    return products;
  },

  async deleteProduct(id) {
    let products = await this.getProducts();
    products = products.filter(p => p.id !== id);
    if (isSupabaseConfigured) {
      await supabase.from('products').delete().eq('id', id);
    }
    setLocalData(STORAGE_KEYS.PRODUCTS, products);
    return products;
  },

  // --- ORDERS ---
  async getOrders() {
    if (isSupabaseConfigured) {
      const { data, error } = await supabase
        .from('orders')
        .select('*')
        .order('created_at', { ascending: false });
      if (!error && data) return data;
    }
    return getLocalData(STORAGE_KEYS.ORDERS, INITIAL_ORDERS);
  },

  async updateOrderStatus(orderId, newStatus) {
    let orders = await this.getOrders();
    orders = orders.map(o => o.id === orderId ? { ...o, status: newStatus, updated_at: new Date().toISOString() } : o);
    if (isSupabaseConfigured) {
      await supabase.from('orders').update({ status: newStatus, updated_at: new Date().toISOString() }).eq('id', orderId);
    }
    setLocalData(STORAGE_KEYS.ORDERS, orders);
    return orders;
  }
};
