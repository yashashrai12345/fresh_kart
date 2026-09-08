import React, { useState } from 'react';
import {
  Search,
  MessageCircle,
  Eye,
  MapPin,
  Phone,
  Calendar,
  Clock,
  CheckCircle2,
  Package,
  Truck,
  X
} from 'lucide-react';

export default function Orders({ orders, onUpdateOrderStatus }) {
  const [statusFilter, setStatusFilter] = useState('ALL');
  const [searchQuery, setSearchQuery] = useState('');
  const [activeModalOrder, setActiveModalOrder] = useState(null);

  const formatCurrency = (amount) => `₹${Number(amount).toLocaleString('en-IN')}`;

  const filteredOrders = orders.filter((o) => {
    const matchesStatus = statusFilter === 'ALL' || o.status === statusFilter;
    const matchesSearch =
      o.id.toLowerCase().includes(searchQuery.toLowerCase()) ||
      (o.customer_name && o.customer_name.toLowerCase().includes(searchQuery.toLowerCase())) ||
      o.customer_phone.includes(searchQuery);
    return matchesStatus && matchesSearch;
  });

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

  const openWhatsAppChat = (phone, orderId) => {
    const cleanPhone = phone.replace(/\D/g, '');
    const fullPhone = cleanPhone.startsWith('91') ? cleanPhone : `91${cleanPhone}`;
    const text = encodeURIComponent(`Hello! This is Fresh Kart regarding your order #${orderId}.`);
    window.open(`https://wa.me/${fullPhone}?text=${text}`, '_blank');
  };

  return (
    <div>
      <div style={{
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'space-between',
        marginBottom: '24px',
        flexWrap: 'wrap',
        gap: '16px'
      }}>
        <div>
          <h2 style={{ fontSize: '1.5rem', fontWeight: 800 }}>Order Fulfillment Hub</h2>
          <p style={{ fontSize: '0.85rem', color: '#64748b' }}>
            Track incoming WhatsApp orders and drive customer app live progress
          </p>
        </div>
      </div>

      {/* Filter and search */}
      <div style={{
        background: 'white',
        borderRadius: '16px',
        padding: '16px 20px',
        border: '1px solid #e2e8f0',
        marginBottom: '24px',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'space-between',
        flexWrap: 'wrap',
        gap: '16px'
      }}>
        <div style={{ position: 'relative', minWidth: '280px', flex: 1 }}>
          <Search size={18} style={{ position: 'absolute', left: '12px', top: '50%', transform: 'translateY(-50%)', color: '#94a3b8' }} />
          <input
            type="text"
            className="form-input"
            style={{ paddingLeft: '38px' }}
            placeholder="Search by Order #, Customer name, Phone..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
          />
        </div>

        <div style={{ display: 'flex', gap: '6px', flexWrap: 'wrap' }}>
          {[
            { key: 'ALL', label: 'All Orders' },
            { key: 'PLACED', label: 'Placed' },
            { key: 'CONFIRMED', label: 'Confirmed' },
            { key: 'PACKED', label: 'Packed' },
            { key: 'OUT_FOR_DELIVERY', label: 'Out for Delivery' },
            { key: 'DELIVERED', label: 'Delivered' }
          ].map((tab) => (
            <button
              key={tab.key}
              onClick={() => setStatusFilter(tab.key)}
              className={`btn btn-sm ${statusFilter === tab.key ? 'btn-primary' : 'btn-secondary'}`}
            >
              {tab.label}
            </button>
          ))}
        </div>
      </div>

      {/* Orders Table */}
      <div className="card-table-wrapper">
        <table className="custom-table">
          <thead>
            <tr>
              <th>Order ID & Time</th>
              <th>Customer</th>
              <th>Delivery Address</th>
              <th>Items</th>
              <th>Total & Fee</th>
              <th>Live Status</th>
              <th style={{ textAlign: 'right' }}>Actions</th>
            </tr>
          </thead>
          <tbody>
            {filteredOrders.length === 0 ? (
              <tr>
                <td colSpan={7} style={{ textAlign: 'center', padding: '48px', color: '#64748b' }}>
                  No orders found matching your criteria.
                </td>
              </tr>
            ) : (
              filteredOrders.map((order) => (
                <tr key={order.id}>
                  <td>
                    <div style={{ fontWeight: 800, color: '#059669', fontSize: '0.95rem' }}>
                      {order.id}
                    </div>
                    <div style={{ fontSize: '0.75rem', color: '#94a3b8', display: 'flex', alignItems: 'center', gap: '4px', marginTop: '2px' }}>
                      <Clock size={12} />
                      {new Date(order.created_at).toLocaleDateString()} {new Date(order.created_at).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                    </div>
                  </td>
                  <td>
                    <div style={{ fontWeight: 600 }}>{order.customer_name || 'Customer'}</div>
                    <div style={{ fontSize: '0.8rem', color: '#64748b', display: 'flex', alignItems: 'center', gap: '4px' }}>
                      <Phone size={12} />
                      +91 {order.customer_phone}
                    </div>
                  </td>
                  <td>
                    <div style={{ fontSize: '0.82rem', color: '#334155', maxWidth: '240px', lineHeight: '1.3' }}>
                      <MapPin size={12} style={{ display: 'inline', marginRight: '4px', color: '#059669' }} />
                      {order.delivery_address}
                    </div>
                  </td>
                  <td>
                    <div style={{ fontSize: '0.85rem', fontWeight: 600 }}>
                      {order.items?.length || 0} items
                    </div>
                    <div style={{ fontSize: '0.75rem', color: '#94a3b8', maxWidth: '160px', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
                      {order.items?.map(i => i.name).join(', ')}
                    </div>
                  </td>
                  <td>
                    <div style={{ fontWeight: 800, fontSize: '0.95rem' }}>
                      {formatCurrency(order.total)}
                    </div>
                    <div style={{ fontSize: '0.75rem', color: order.delivery_fee === 0 ? '#16a34a' : '#64748b' }}>
                      {order.delivery_fee === 0 ? 'FREE Delivery' : `+₹${order.delivery_fee} Fee`}
                    </div>
                  </td>
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
                  <td style={{ textAlign: 'right' }}>
                    <div style={{ display: 'inline-flex', gap: '6px' }}>
                      <button
                        onClick={() => openWhatsAppChat(order.customer_phone, order.id)}
                        className="btn-icon"
                        style={{ color: '#16a34a' }}
                        title="Chat with Customer on WhatsApp"
                      >
                        <MessageCircle size={16} />
                      </button>
                      <button
                        onClick={() => setActiveModalOrder(order)}
                        className="btn-icon"
                        title="View Full Order Receipt"
                      >
                        <Eye size={16} />
                      </button>
                    </div>
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>

      {/* Order Details Modal */}
      {activeModalOrder && (
        <div className="modal-backdrop">
          <div className="modal-card">
            <div className="modal-header">
              <div>
                <h3 style={{ fontSize: '1.25rem', fontWeight: 800 }}>Order Details: {activeModalOrder.id}</h3>
                <p style={{ fontSize: '0.8rem', color: '#64748b' }}>
                  Placed on {new Date(activeModalOrder.created_at).toLocaleString()}
                </p>
              </div>
              <button
                onClick={() => setActiveModalOrder(null)}
                className="btn-icon"
                style={{ border: 'none' }}
              >
                <X size={20} />
              </button>
            </div>

            <div className="modal-body">
              {/* Status Banner */}
              <div style={{
                padding: '14px 18px',
                borderRadius: '12px',
                backgroundColor: '#f8fafc',
                border: '1px solid #e2e8f0',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'space-between',
                marginBottom: '20px'
              }}>
                <div>
                  <span style={{ fontSize: '0.78rem', color: '#64748b', textTransform: 'uppercase', fontWeight: 700 }}>
                    Current Order Status
                  </span>
                  <div style={{ marginTop: '4px' }}>{getStatusBadge(activeModalOrder.status)}</div>
                </div>

                <div>
                  <label style={{ fontSize: '0.78rem', color: '#64748b', display: 'block', marginBottom: '4px' }}>
                    Update Status:
                  </label>
                  <select
                    className="status-pill-select"
                    value={activeModalOrder.status}
                    onChange={(e) => {
                      const newStatus = e.target.value;
                      onUpdateOrderStatus(activeModalOrder.id, newStatus);
                      setActiveModalOrder({ ...activeModalOrder, status: newStatus });
                    }}
                  >
                    <option value="PLACED">Placed</option>
                    <option value="CONFIRMED">Confirmed</option>
                    <option value="PACKED">Packed</option>
                    <option value="OUT_FOR_DELIVERY">Out for Delivery</option>
                    <option value="DELIVERED">Delivered</option>
                    <option value="CANCELLED">Cancelled</option>
                  </select>
                </div>
              </div>

              {/* Customer and Delivery info */}
              <div style={{
                display: 'grid',
                gridTemplateColumns: '1fr 1fr',
                gap: '16px',
                marginBottom: '24px',
                padding: '16px',
                backgroundColor: '#ffffff',
                border: '1px solid #e2e8f0',
                borderRadius: '12px'
              }}>
                <div>
                  <span style={{ fontSize: '0.75rem', fontWeight: 700, color: '#94a3b8', textTransform: 'uppercase' }}>
                    Customer Contact
                  </span>
                  <div style={{ fontWeight: 700, fontSize: '0.95rem', marginTop: '4px' }}>
                    {activeModalOrder.customer_name || 'Customer'}
                  </div>
                  <div style={{ fontSize: '0.85rem', color: '#475569', marginTop: '2px' }}>
                    +91 {activeModalOrder.customer_phone}
                  </div>
                  <button
                    onClick={() => openWhatsAppChat(activeModalOrder.customer_phone, activeModalOrder.id)}
                    className="btn btn-sm"
                    style={{ backgroundColor: '#25D366', color: 'white', marginTop: '8px' }}
                  >
                    <MessageCircle size={14} /> Open WhatsApp
                  </button>
                </div>

                <div>
                  <span style={{ fontSize: '0.75rem', fontWeight: 700, color: '#94a3b8', textTransform: 'uppercase' }}>
                    Delivery Address
                  </span>
                  <div style={{ fontSize: '0.88rem', color: '#0f172a', marginTop: '4px', lineHeight: '1.4' }}>
                    {activeModalOrder.delivery_address}
                  </div>
                  {activeModalOrder.notes && (
                    <div style={{ marginTop: '8px', fontSize: '0.8rem', color: '#d97706', backgroundColor: '#fef3c7', padding: '4px 8px', borderRadius: '6px' }}>
                      <strong>Note:</strong> {activeModalOrder.notes}
                    </div>
                  )}
                </div>
              </div>

              {/* Items Table */}
              <h4 style={{ fontSize: '0.95rem', marginBottom: '10px' }}>Ordered Items</h4>
              <div style={{ border: '1px solid #e2e8f0', borderRadius: '10px', overflow: 'hidden', marginBottom: '20px' }}>
                <table className="custom-table" style={{ margin: 0 }}>
                  <thead>
                    <tr>
                      <th>Item</th>
                      <th>Qty</th>
                      <th>Unit Price</th>
                      <th style={{ textAlign: 'right' }}>Total</th>
                    </tr>
                  </thead>
                  <tbody>
                    {activeModalOrder.items?.map((item, idx) => (
                      <tr key={idx}>
                        <td style={{ fontWeight: 600 }}>{item.name}</td>
                        <td>{item.qty} {item.unit || ''}</td>
                        <td>₹{item.unitPrice}</td>
                        <td style={{ textAlign: 'right', fontWeight: 700 }}>₹{item.subtotal || item.qty * item.unitPrice}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>

              {/* Totals */}
              <div style={{
                display: 'flex',
                flexDirection: 'column',
                gap: '8px',
                padding: '16px',
                backgroundColor: '#f8fafc',
                borderRadius: '10px',
                border: '1px solid #e2e8f0'
              }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.88rem', color: '#64748b' }}>
                  <span>Subtotal</span>
                  <span>{formatCurrency(activeModalOrder.subtotal)}</span>
                </div>
                <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.88rem', color: '#64748b' }}>
                  <span>Delivery Fee</span>
                  <span>{activeModalOrder.delivery_fee === 0 ? 'FREE' : formatCurrency(activeModalOrder.delivery_fee)}</span>
                </div>
                <div style={{
                  display: 'flex',
                  justifyContent: 'space-between',
                  fontSize: '1.15rem',
                  fontWeight: 800,
                  color: '#0f172a',
                  borderTop: '1px solid #e2e8f0',
                  paddingTop: '8px',
                  marginTop: '4px'
                }}>
                  <span>Grand Total (COD / UPI)</span>
                  <span style={{ color: '#059669' }}>{formatCurrency(activeModalOrder.total)}</span>
                </div>
              </div>
            </div>

            <div className="modal-footer">
              <button
                type="button"
                onClick={() => setActiveModalOrder(null)}
                className="btn btn-secondary"
              >
                Close
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
