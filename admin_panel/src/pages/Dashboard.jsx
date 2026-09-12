import React from 'react';
import {
  ShoppingBag,
  TrendingUp,
  Clock,
  AlertTriangle,
  ChevronRight,
  ExternalLink,
  CheckCircle2,
  Package,
  Truck
} from 'lucide-react';
import { formatDateTimeIST } from '../utils/dateUtils';

export default function Dashboard({
  orders,
  products,
  categories,
  onNavigate,
  onUpdateOrderStatus
}) {
  // Calculations
  const totalOrdersCount = orders.length;
  const pendingOrders = orders.filter(o => ['PLACED', 'CONFIRMED', 'PACKED', 'OUT_FOR_DELIVERY'].includes(o.status));
  const completedOrders = orders.filter(o => o.status === 'DELIVERED');
  const totalRevenue = orders
    .filter(o => o.status !== 'CANCELLED')
    .reduce((sum, o) => sum + Number(o.total || 0), 0);

  const lowStockProducts = products.filter(
    p => (!p.in_stock || (p.stock_left !== null && p.stock_left !== undefined && p.stock_left <= 8))
  );

  const formatCurrency = (amount) => `₹${Number(amount).toLocaleString('en-IN')}`;

  const getStatusBadge = (status) => {
    switch (status) {
      case 'PLACED':
        return <span className="badge badge-placed">Placed</span>;
      case 'CONFIRMED':
        return <span className="badge badge-confirmed">Confirmed</span>;
      case 'PACKED':
        return <span className="badge badge-packed">Packed</span>;
      case 'OUT_FOR_DELIVERY':
        return <span className="badge badge-out_for_delivery">Out for Delivery</span>;
      case 'DELIVERED':
        return <span className="badge badge-delivered">Delivered</span>;
      case 'CANCELLED':
        return <span className="badge badge-cancelled">Cancelled</span>;
      default:
        return <span className="badge">{status}</span>;
    }
  };

  return (
    <div>
      {/* Top Banner */}
      <div style={{
        background: 'linear-gradient(135deg, #059669 0%, #064e3b 100%)',
        borderRadius: '20px',
        padding: '28px 32px',
        color: '#ffffff',
        marginBottom: '32px',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'space-between',
        boxShadow: '0 10px 25px -5px rgba(5, 150, 105, 0.35)',
        position: 'relative',
        overflow: 'hidden'
      }}>
        <div style={{ zIndex: 2 }}>
          <span style={{
            background: 'rgba(255, 255, 255, 0.2)',
            padding: '4px 12px',
            borderRadius: '9999px',
            fontSize: '0.75rem',
            fontWeight: 700,
            letterSpacing: '0.05em',
            textTransform: 'uppercase'
          }}>
            APMC Mandi Direct Operations
          </span>
          <h2 style={{ fontSize: '1.85rem', fontWeight: 800, color: 'white', marginTop: '10px', marginBottom: '6px' }}>
            Good Morning, Store Manager! 🥦
          </h2>
          <p style={{ color: '#d1fae5', fontSize: '0.95rem', maxWidth: '540px' }}>
            Here is your live delivery operations summary for today. You have {pendingOrders.length} pending orders requiring fulfillment.
          </p>
        </div>
        <div style={{ display: 'flex', gap: '12px', zIndex: 2 }}>
          <button
            onClick={() => onNavigate('orders')}
            className="btn"
            style={{ backgroundColor: '#ffffff', color: '#064e3b', fontWeight: 700, boxShadow: '0 4px 12px rgba(0,0,0,0.15)' }}
          >
            Manage Orders ({pendingOrders.length})
            <ChevronRight size={16} />
          </button>
        </div>
      </div>

      {/* KPI Cards */}
      <div className="metrics-grid">
        <div className="metric-card">
          <div className="metric-header">
            <span className="metric-title">Today's Orders</span>
            <div className="metric-icon-wrap" style={{ backgroundColor: '#ecfdf5', color: '#059669' }}>
              <ShoppingBag size={22} />
            </div>
          </div>
          <div className="metric-value">{totalOrdersCount}</div>
          <div className="metric-subtitle">
            <span style={{ color: '#059669', fontWeight: 700 }}>{completedOrders.length} delivered</span> so far
          </div>
        </div>

        <div className="metric-card">
          <div className="metric-header">
            <span className="metric-title">Pending Fulfillment</span>
            <div className="metric-icon-wrap" style={{ backgroundColor: '#fef3c7', color: '#d97706' }}>
              <Clock size={22} />
            </div>
          </div>
          <div className="metric-value" style={{ color: '#d97706' }}>{pendingOrders.length}</div>
          <div className="metric-subtitle">Needs packing & delivery handoff</div>
        </div>

        <div className="metric-card">
          <div className="metric-header">
            <span className="metric-title">Gross Revenue</span>
            <div className="metric-icon-wrap" style={{ backgroundColor: '#f0fdf4', color: '#16a34a' }}>
              <TrendingUp size={22} />
            </div>
          </div>
          <div className="metric-value">{formatCurrency(totalRevenue)}</div>
          <div className="metric-subtitle">From WhatsApp direct orders</div>
        </div>

        <div className="metric-card">
          <div className="metric-header">
            <span className="metric-title">Low Stock Alert</span>
            <div className="metric-icon-wrap" style={{ backgroundColor: '#fee2e2', color: '#dc2626' }}>
              <AlertTriangle size={22} />
            </div>
          </div>
          <div className="metric-value" style={{ color: lowStockProducts.length > 0 ? '#dc2626' : '#16a34a' }}>
            {lowStockProducts.length}
          </div>
          <div className="metric-subtitle">Items running out at Mandi</div>
        </div>
      </div>

      {/* Grid: Recent Orders & Stock Alerts */}
      <div style={{ display: 'grid', gridTemplateColumns: '2fr 1fr', gap: '28px' }}>
        {/* Recent Orders Table */}
        <div className="card-table-wrapper">
          <div className="table-header-bar">
            <div>
              <h3 style={{ fontSize: '1.15rem' }}>Recent Customer Orders</h3>
              <p style={{ fontSize: '0.82rem', color: '#64748b' }}>Latest WhatsApp handoffs received from mobile app</p>
            </div>
            <button
              onClick={() => onNavigate('orders')}
              className="btn btn-secondary btn-sm"
            >
              View All Orders
            </button>
          </div>

          <table className="custom-table">
            <thead>
              <tr>
                <th>Order ID</th>
                <th>Customer</th>
                <th>Items</th>
                <th>Total</th>
                <th>Status</th>
                <th>Quick Action</th>
              </tr>
            </thead>
            <tbody>
              {orders.slice(0, 5).map((order) => (
                <tr key={order.id}>
                  <td>
                    <div style={{ fontWeight: 700, color: '#059669' }}>{order.id}</div>
                    <div style={{ fontSize: '0.75rem', color: '#94a3b8' }}>
                      {formatDateTimeIST(order.created_at)}
                    </div>
                  </td>
                  <td>
                    <div style={{ fontWeight: 600 }}>{order.customer_name || 'Direct Customer'}</div>
                    <div style={{ fontSize: '0.78rem', color: '#64748b' }}>+91 {order.customer_phone}</div>
                  </td>
                  <td>
                    <div style={{ fontSize: '0.85rem' }}>{order.items?.length || 0} items</div>
                  </td>
                  <td>
                    <div style={{ fontWeight: 700 }}>{formatCurrency(order.total)}</div>
                  </td>
                  <td>{getStatusBadge(order.status)}</td>
                  <td>
                    <select
                      className="status-pill-select"
                      value={order.status}
                      onChange={(e) => onUpdateOrderStatus(order.id, e.target.value)}
                    >
                      <option value="PLACED">Placed</option>
                      <option value="CONFIRMED">Confirmed</option>
                      <option value="PACKED">Packed</option>
                      <option value="OUT_FOR_DELIVERY">Out for Delivery</option>
                      <option value="DELIVERED">Delivered</option>
                      <option value="CANCELLED">Cancelled</option>
                    </select>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>

        {/* Low Stock Rail */}
        <div style={{
          background: 'white',
          borderRadius: '16px',
          border: '1px solid #e2e8f0',
          padding: '24px',
          boxShadow: 'var(--shadow-sm)'
        }}>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '18px' }}>
            <h3 style={{ fontSize: '1.1rem', display: 'flex', alignItems: 'center', gap: '8px' }}>
              <AlertTriangle size={18} color="#d97706" />
              Stock Health
            </h3>
            <button
              onClick={() => onNavigate('products')}
              className="btn btn-secondary btn-sm"
            >
              Catalog
            </button>
          </div>

          {lowStockProducts.length === 0 ? (
            <div style={{ textAlign: 'center', padding: '32px 16px', color: '#64748b' }}>
              <CheckCircle2 size={36} color="#10b981" style={{ margin: '0 auto 12px' }} />
              <p style={{ fontWeight: 600, color: '#0f172a' }}>All Products Well Stocked!</p>
              <p style={{ fontSize: '0.82rem' }}>No out of stock or low-inventory items currently.</p>
            </div>
          ) : (
            <div style={{ display: 'flex', flexDirection: 'column', gap: '14px' }}>
              {lowStockProducts.map((p) => (
                <div
                  key={p.id}
                  style={{
                    display: 'flex',
                    alignItems: 'center',
                    gap: '12px',
                    padding: '12px',
                    borderRadius: '10px',
                    backgroundColor: '#f8fafc',
                    border: '1px solid #e2e8f0'
                  }}
                >
                  <img
                    src={p.photo_url}
                    alt={p.name}
                    style={{ width: '40px', height: '40px', borderRadius: '8px', objectFit: 'cover' }}
                  />
                  <div style={{ flex: 1, minWidth: 0 }}>
                    <div style={{ fontWeight: 600, fontSize: '0.85rem', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
                      {p.name}
                    </div>
                    <div style={{ fontSize: '0.75rem', color: p.in_stock ? '#d97706' : '#dc2626', fontWeight: 600 }}>
                      {!p.in_stock ? 'Marked Out of Stock' : `Only ${p.stock_left} left!`}
                    </div>
                  </div>
                </div>
              ))}
            </div>
          )}

          {/* Quick APMC Info */}
          <div style={{
            marginTop: '24px',
            padding: '16px',
            backgroundColor: '#ecfdf5',
            borderRadius: '12px',
            border: '1px solid #a7f3d0',
            fontSize: '0.82rem',
            color: '#065f46'
          }}>
            <strong>Next APMC Mandi Lot:</strong>
            <p style={{ marginTop: '4px' }}>
              Fresh procurement scheduled tomorrow at 4:30 AM (Yeshwanthpur APMC Yard).
            </p>
          </div>
        </div>
      </div>
    </div>
  );
}
