import React, { useState, useEffect } from 'react';
import {
  LayoutDashboard,
  ShoppingBag,
  FolderTree,
  ClipboardList,
  Settings as SettingsIcon,
  LogOut,
  Sparkles,
  Bell,
  Menu,
  X
} from 'lucide-react';
import { storeService, isSupabaseConfigured, supabase, initAdminPushNotifications } from './services/storeService';
import Login from './pages/Login';
import Dashboard from './pages/Dashboard';
import Products from './pages/Products';
import Categories from './pages/Categories';
import Orders from './pages/Orders';
import Settings from './pages/Settings';

export default function App() {
  const [currentUser, setCurrentUser] = useState(null);
  const [currentPage, setCurrentPage] = useState('dashboard');
  const [loading, setLoading] = useState(true);

  // Core store state
  const [settings, setSettings] = useState(null);
  const [categories, setCategories] = useState([]);
  const [products, setProducts] = useState([]);
  const [orders, setOrders] = useState([]);

  // Load initial data
  const loadStoreData = async () => {
    try {
      const [sett, cats, prods, ords] = await Promise.all([
        storeService.getSettings(),
        storeService.getCategories(),
        storeService.getProducts(),
        storeService.getOrders()
      ]);
      setSettings(sett);
      setCategories(cats);
      setProducts(prods);
      setOrders(ords);
    } catch (e) {
      console.error('Failed to load store data:', e);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    // SECURITY: Restore session from Supabase, not just from localStorage
    const initApp = async () => {
      const user = await storeService.restoreSession();
      if (user) {
        setCurrentUser(user);
        // Re-register for push notifications on session restore
        initAdminPushNotifications().catch(console.warn);
      }
      await loadStoreData();
    };
    initApp();

    // Setup Supabase Realtime listeners if connected
    if (isSupabaseConfigured && supabase) {
      // Orders: new orders from the Flutter app appear instantly
      const ordersChannel = supabase
        .channel('realtime:orders')
        .on('postgres_changes', { event: '*', schema: 'public', table: 'orders' }, () => {
          storeService.getOrders().then(setOrders);
        })
        .subscribe();

      // Products: in-stock toggles, price edits, new products sync across sessions
      const productsChannel = supabase
        .channel('realtime:products')
        .on('postgres_changes', { event: '*', schema: 'public', table: 'products' }, () => {
          storeService.getProducts().then(setProducts);
        })
        .subscribe();

      // Categories: new/deleted categories sync across sessions
      const categoriesChannel = supabase
        .channel('realtime:categories')
        .on('postgres_changes', { event: '*', schema: 'public', table: 'categories' }, () => {
          storeService.getCategories().then(setCategories);
        })
        .subscribe();

      return () => {
        supabase.removeChannel(ordersChannel);
        supabase.removeChannel(productsChannel);
        supabase.removeChannel(categoriesChannel);
      };
    }
  }, []);

  const handleLogout = async () => {
    await storeService.logout();
    setCurrentUser(null);
  };

  // Called by Login page after successful authentication
  const handleLoginSuccess = (user) => {
    setCurrentUser(user);
    // Register admin browser for FCM push notifications
    initAdminPushNotifications().catch(console.warn);
  };

  // Mutators
  const handleUpdateOrderStatus = async (orderId, newStatus) => {
    const updated = await storeService.updateOrderStatus(orderId, newStatus);
    setOrders([...updated]);
  };

  const handleSaveProduct = async (product) => {
    const updated = await storeService.saveProduct(product);
    setProducts([...updated]);
  };

  const handleToggleProductStock = async (id, inStock) => {
    const updated = await storeService.toggleProductStock(id, inStock);
    setProducts([...updated]);
  };

  const handleDeleteProduct = async (id) => {
    const updated = await storeService.deleteProduct(id);
    setProducts([...updated]);
  };

  const handleSaveCategory = async (category) => {
    const updated = await storeService.saveCategory(category);
    setCategories([...updated]);
  };

  const handleDeleteCategory = async (id) => {
    const updated = await storeService.deleteCategory(id);
    setCategories([...updated]);
  };

  const handleUpdateSettings = async (newSettings) => {
    const updated = await storeService.updateSettings(newSettings);
    setSettings(updated);
  };

  // If not logged in, render Login
  if (!currentUser) {
    return <Login onLoginSuccess={handleLoginSuccess} />;
  }

  if (loading || !settings) {
    return (
      <div style={{
        height: '100vh',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        background: '#f8fafc',
        fontFamily: 'var(--font-sans)',
        color: '#059669',
        fontSize: '1.2rem',
        fontWeight: 700
      }}>
        Loading Fresh Kart Store Operations...
      </div>
    );
  }

  const pendingOrdersCount = orders.filter(
    (o) => ['PLACED', 'CONFIRMED', 'PACKED', 'OUT_FOR_DELIVERY'].includes(o.status)
  ).length;

  return (
    <div className="app-container">
      {/* Sidebar */}
      <aside className="sidebar">
        <div className="sidebar-brand">
          <div style={{
            width: '36px',
            height: '36px',
            borderRadius: '10px',
            overflow: 'hidden',
            flexShrink: 0,
          }}>
            <img
              src="/logo/fresh_kart_icon.jpg"
              alt="Fresh Kart"
              style={{ width: '100%', height: '100%', objectFit: 'cover' }}
              onError={(e) => {
                e.target.style.display = 'none';
                e.target.parentElement.style.background = 'linear-gradient(135deg, #10b981, #047857)';
                e.target.parentElement.style.display = 'flex';
                e.target.parentElement.style.alignItems = 'center';
                e.target.parentElement.style.justifyContent = 'center';
              }}
            />
          </div>
          <div>
            <div className="brand-title">FRESH KART</div>
            <div style={{ fontSize: '0.72rem', color: '#94a3b8' }}>Admin Portal</div>
          </div>
          <span className="brand-badge">APMC v1.0</span>
        </div>

        <nav className="sidebar-nav">
          <button
            onClick={() => setCurrentPage('dashboard')}
            className={`nav-item ${currentPage === 'dashboard' ? 'active' : ''}`}
            style={{ background: 'none', border: 'none', width: '100%', textAlign: 'left' }}
          >
            <LayoutDashboard size={18} />
            <span>Dashboard</span>
          </button>

          <button
            onClick={() => setCurrentPage('orders')}
            className={`nav-item ${currentPage === 'orders' ? 'active' : ''}`}
            style={{ background: 'none', border: 'none', width: '100%', textAlign: 'left' }}
          >
            <ClipboardList size={18} />
            <span>Orders</span>
            {pendingOrdersCount > 0 && <span className="badge">{pendingOrdersCount}</span>}
          </button>

          <button
            onClick={() => setCurrentPage('products')}
            className={`nav-item ${currentPage === 'products' ? 'active' : ''}`}
            style={{ background: 'none', border: 'none', width: '100%', textAlign: 'left' }}
          >
            <ShoppingBag size={18} />
            <span>Produce Catalog</span>
          </button>

          <button
            onClick={() => setCurrentPage('categories')}
            className={`nav-item ${currentPage === 'categories' ? 'active' : ''}`}
            style={{ background: 'none', border: 'none', width: '100%', textAlign: 'left' }}
          >
            <FolderTree size={18} />
            <span>Categories</span>
          </button>

          <button
            onClick={() => setCurrentPage('settings')}
            className={`nav-item ${currentPage === 'settings' ? 'active' : ''}`}
            style={{ background: 'none', border: 'none', width: '100%', textAlign: 'left' }}
          >
            <SettingsIcon size={18} />
            <span>Store Settings</span>
          </button>
        </nav>

        <div className="sidebar-footer">
          <div className="user-info">
            <div className="user-avatar">FK</div>
            <div className="user-text">
              <div className="user-name">{currentUser.email?.split('@')[0] || 'Store Owner'}</div>
              <div className="user-role">Administrator</div>
            </div>
          </div>
          <button
            onClick={handleLogout}
            className="btn-icon"
            style={{ background: 'transparent', color: '#94a3b8', border: 'none' }}
            title="Log Out"
          >
            <LogOut size={18} />
          </button>
        </div>
      </aside>

      {/* Main content wrapper */}
      <div className="main-wrapper">
        {/* Top bar */}
        <header className="topbar">
          <div className="page-title">
            <h1>
              {currentPage === 'dashboard' && 'Operations Overview'}
              {currentPage === 'orders' && 'Customer Orders'}
              {currentPage === 'products' && 'Fresh Produce Catalog'}
              {currentPage === 'categories' && 'Catalog Categories'}
              {currentPage === 'settings' && 'Store Settings & Policies'}
            </h1>
          </div>

          <div className="topbar-actions">
            <div style={{
              display: 'flex',
              alignItems: 'center',
              gap: '8px',
              backgroundColor: '#f8fafc',
              border: '1px solid #e2e8f0',
              padding: '6px 14px',
              borderRadius: '9999px',
              fontSize: '0.8rem',
              color: '#475569',
              fontWeight: 600
            }}>
              <span style={{
                width: '8px',
                height: '8px',
                borderRadius: '50%',
                backgroundColor: isSupabaseConfigured ? '#10b981' : '#f59e0b',
                boxShadow: isSupabaseConfigured ? '0 0 0 3px rgba(16, 185, 129, 0.2)' : 'none'
              }} />
              {isSupabaseConfigured ? 'Live Cloud Sync' : 'Local Mode'}
            </div>
          </div>
        </header>

        {/* Page content */}
        <main className="content-container">
          {currentPage === 'dashboard' && (
            <Dashboard
              orders={orders}
              products={products}
              categories={categories}
              onNavigate={setCurrentPage}
              onUpdateOrderStatus={handleUpdateOrderStatus}
            />
          )}

          {currentPage === 'orders' && (
            <Orders
              orders={orders}
              onUpdateOrderStatus={handleUpdateOrderStatus}
            />
          )}

          {currentPage === 'products' && (
            <Products
              products={products}
              categories={categories}
              onSaveProduct={handleSaveProduct}
              onToggleStock={handleToggleProductStock}
              onDeleteProduct={handleDeleteProduct}
            />
          )}

          {currentPage === 'categories' && (
            <Categories
              categories={categories}
              products={products}
              onSaveCategory={handleSaveCategory}
              onDeleteCategory={handleDeleteCategory}
            />
          )}

          {currentPage === 'settings' && (
            <Settings
              settings={settings}
              onUpdateSettings={handleUpdateSettings}
            />
          )}
        </main>
      </div>
    </div>
  );
}
