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

// LocalStorage helpers for offline/standalone mode (catalog data only - NOT auth)
const STORAGE_KEYS = {
  SETTINGS: 'freshkart_admin_settings',
  CATEGORIES: 'freshkart_admin_categories',
  PRODUCTS: 'freshkart_admin_products',
  ORDERS: 'freshkart_admin_orders',
};

function getLocalData(key, fallback) {
  try {
    const raw = localStorage.getItem(key);
    if (!raw) {
      localStorage.setItem(key, JSON.stringify(fallback));
      return fallback;
    }
    const data = JSON.parse(raw);
    if (key === STORAGE_KEYS.SETTINGS && data && data.whatsapp_number === '919876543210') {
      data.whatsapp_number = '918970050327';
      localStorage.setItem(key, JSON.stringify(data));
    }
    return data;
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
  // SECURITY: Admin login strictly requires successful Supabase Auth.
  // There is NO fallback fake session — if Supabase auth fails, login fails.
  async login(email, password) {
    if (!isSupabaseConfigured || !supabase) {
      throw new Error(
        'Supabase is not configured. Admin login requires a live Supabase connection. ' +
        'Please check your VITE_SUPABASE_URL and VITE_SUPABASE_ANON_KEY environment variables.'
      );
    }

    const { data, error } = await supabase.auth.signInWithPassword({ email, password });

    if (error || !data?.user) {
      throw new Error(error?.message || 'Invalid email or password. Please try again.');
    }

    return {
      id: data.user.id,
      email: data.user.email,
      name: data.user.user_metadata?.name || 'Fresh Kart Admin',
    };
  },

  // Restore session from Supabase (call on app startup)
  async restoreSession() {
    if (!isSupabaseConfigured || !supabase) return null;
    try {
      const { data: { session }, error } = await supabase.auth.getSession();
      if (error || !session?.user) return null;
      return {
        id: session.user.id,
        email: session.user.email,
        name: session.user.user_metadata?.name || 'Fresh Kart Admin',
      };
    } catch (e) {
      console.warn('Session restore error:', e);
      return null;
    }
  },

  async logout() {
    if (isSupabaseConfigured && supabase) {
      try {
        await supabase.auth.signOut();
      } catch (e) {
        console.warn('SignOut error:', e);
      }
    }
  },

  // --- SETTINGS ---
  async getSettings() {
    if (isSupabaseConfigured && supabase) {
      const { data, error } = await supabase.from('store_settings').select('*').limit(1).single();
      if (!error && data) {
        setLocalData(STORAGE_KEYS.SETTINGS, data);
        return data;
      }
    }
    return getLocalData(STORAGE_KEYS.SETTINGS, INITIAL_SETTINGS);
  },

  async updateSettings(newSettings) {
    if (isSupabaseConfigured && supabase) {
      const { data, error } = await supabase
        .from('store_settings')
        .update({ ...newSettings, updated_at: new Date().toISOString() })
        .eq('id', newSettings.id)
        .select()
        .single();
      if (error) throw new Error(error.message || 'Failed to update settings');
      if (data) {
        setLocalData(STORAGE_KEYS.SETTINGS, data);
        return data;
      }
    }
    setLocalData(STORAGE_KEYS.SETTINGS, newSettings);
    return newSettings;
  },

  // --- CATEGORIES ---
  async getCategories() {
    if (isSupabaseConfigured && supabase) {
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

    if (isSupabaseConfigured && supabase) {
      const { error } = await supabase.from('categories').upsert(catToSave);
      if (error) throw new Error(error.message || 'Failed to save category');
    }
    setLocalData(STORAGE_KEYS.CATEGORIES, categories);
    return categories;
  },

  async deleteCategory(id) {
    // First check if category has products — Supabase cascade will handle it
    // but we want to warn the admin explicitly
    const products = await this.getProducts();
    const productCount = products.filter(p => p.category_id === id).length;
    if (productCount > 0) {
      throw new Error(
        `Cannot delete: this category has ${productCount} product(s). ` +
        `Please reassign or delete those products first.`
      );
    }

    if (isSupabaseConfigured && supabase) {
      const { error } = await supabase.from('categories').delete().eq('id', id);
      if (error) throw new Error(error.message || 'Failed to delete category from database');
    }

    // Only update local cache after successful Supabase deletion
    let categories = await this.getCategories();
    categories = categories.filter(c => c.id !== id);
    setLocalData(STORAGE_KEYS.CATEGORIES, categories);
    return categories;
  },

  // --- PRODUCTS ---
  async getProducts() {
    if (isSupabaseConfigured && supabase) {
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

    if (isSupabaseConfigured && supabase) {
      const { error } = await supabase.from('products').upsert(prodToSave);
      if (error) throw new Error(error.message || 'Failed to save product');
    }
    setLocalData(STORAGE_KEYS.PRODUCTS, products);
    return products;
  },

  async toggleProductStock(id, inStock) {
    let products = await this.getProducts();
    products = products.map(p => p.id === id ? { ...p, in_stock: inStock } : p);
    if (isSupabaseConfigured && supabase) {
      const { error } = await supabase.from('products').update({ in_stock: inStock }).eq('id', id);
      if (error) throw new Error(error.message || 'Failed to update stock status');
    }
    setLocalData(STORAGE_KEYS.PRODUCTS, products);
    return products;
  },

  async deleteProduct(id) {
    if (isSupabaseConfigured && supabase) {
      const { error } = await supabase.from('products').delete().eq('id', id);
      if (error) throw new Error(error.message || 'Failed to delete product from database');
    }

    // Only update local cache after successful Supabase deletion
    let products = await this.getProducts();
    products = products.filter(p => p.id !== id);
    setLocalData(STORAGE_KEYS.PRODUCTS, products);
    return products;
  },

  // --- ORDERS ---
  async getOrders() {
    if (isSupabaseConfigured && supabase) {
      const { data, error } = await supabase
        .from('orders')
        .select('*')
        .order('created_at', { ascending: false });
      if (!error && data) return data;
    }
    return getLocalData(STORAGE_KEYS.ORDERS, INITIAL_ORDERS);
  },

  async updateOrderStatus(orderId, newStatus) {
    if (isSupabaseConfigured && supabase) {
      const { error } = await supabase
        .from('orders')
        .update({ status: newStatus, updated_at: new Date().toISOString() })
        .eq('id', orderId);
      if (error) throw new Error(error.message || 'Failed to update order status');
    }

    let orders = await this.getOrders();
    orders = orders.map(o => o.id === orderId
      ? { ...o, status: newStatus, updated_at: new Date().toISOString() }
      : o
    );
    setLocalData(STORAGE_KEYS.ORDERS, orders);
    return orders;
  }
};
