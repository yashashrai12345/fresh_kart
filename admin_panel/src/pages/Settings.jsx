import React, { useState, useEffect } from 'react';
import { Save, CheckCircle2, MessageCircle, Clock, ShieldCheck, MapPin, Truck } from 'lucide-react';

export default function Settings({ settings, onUpdateSettings }) {
  const [formData, setFormData] = useState({ ...settings });
  const [savedSuccess, setSavedSuccess] = useState(false);

  useEffect(() => {
    if (settings) {
      setFormData({ ...settings });
    }
  }, [settings]);

  const handleSubmit = (e) => {
    e.preventDefault();
    onUpdateSettings(formData);
    setSavedSuccess(true);
    setTimeout(() => setSavedSuccess(false), 3500);
  };

  const handleHourChange = (day, val) => {
    setFormData({
      ...formData,
      operating_hours: {
        ...formData.operating_hours,
        [day]: val
      }
    });
  };

  const getLocalNumber = (fullNumber) => {
    if (!fullNumber) return '';
    const digits = String(fullNumber).replace(/\D/g, '');
    if (digits.startsWith('91') && digits.length > 10) {
      return digits.slice(2);
    }
    return digits;
  };

  const handleWhatsAppChange = (rawInput) => {
    const digits = rawInput.replace(/\D/g, '');
    let localDigits = digits;
    if (localDigits.startsWith('91') && localDigits.length > 10) {
      localDigits = localDigits.slice(2);
    }
    localDigits = localDigits.slice(0, 10);
    setFormData({
      ...formData,
      whatsapp_number: localDigits ? `91${localDigits}` : ''
    });
  };

  const daysOfWeek = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

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
          <h2 style={{ fontSize: '1.5rem', fontWeight: 800 }}>Store Settings & Configuration</h2>
          <p style={{ fontSize: '0.85rem', color: '#64748b' }}>
            Updates store details, WhatsApp order destination, and delivery policies across mobile app
          </p>
        </div>

        {savedSuccess && (
          <div style={{
            display: 'flex',
            alignItems: 'center',
            gap: '8px',
            backgroundColor: '#dcfce7',
            color: '#166534',
            padding: '8px 16px',
            borderRadius: '9999px',
            fontSize: '0.85rem',
            fontWeight: 600
          }}>
            <CheckCircle2 size={16} />
            Settings saved successfully!
          </div>
        )}
      </div>

      <form onSubmit={handleSubmit}>
        <div style={{ display: 'grid', gridTemplateColumns: '2fr 1fr', gap: '28px' }}>
          {/* Main settings column */}
          <div style={{ display: 'flex', flexDirection: 'column', gap: '24px' }}>
            {/* General Info */}
            <div style={{ background: 'white', borderRadius: '16px', border: '1px solid #e2e8f0', padding: '24px' }}>
              <h3 style={{ fontSize: '1.15rem', marginBottom: '16px', display: 'flex', alignItems: 'center', gap: '8px' }}>
                <MapPin size={18} color="#059669" />
                Store Identity & Sourcing Hub
              </h3>

              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '16px' }}>
                <div className="form-group">
                  <label className="form-label">Store Brand Name *</label>
                  <input
                    type="text"
                    required
                    className="form-input"
                    value={formData.name || ''}
                    onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                  />
                </div>

                <div className="form-group">
                  <label className="form-label">Tagline *</label>
                  <input
                    type="text"
                    required
                    className="form-input"
                    value={formData.tagline || ''}
                    onChange={(e) => setFormData({ ...formData, tagline: e.target.value })}
                  />
                </div>
              </div>

              <div className="form-group">
                <label className="form-label">Subtitle / Promise</label>
                <input
                  type="text"
                  className="form-input"
                  value={formData.subtitle || ''}
                  onChange={(e) => setFormData({ ...formData, subtitle: e.target.value })}
                />
              </div>

              <div className="form-group">
                <label className="form-label">APMC Mandi / Yard Address *</label>
                <textarea
                  rows={2}
                  required
                  className="form-textarea"
                  value={formData.address || ''}
                  onChange={(e) => setFormData({ ...formData, address: e.target.value })}
                />
              </div>
            </div>

            {/* Delivery & WhatsApp Checkout Engine */}
            <div style={{ background: 'white', borderRadius: '16px', border: '1px solid #e2e8f0', padding: '24px' }}>
              <h3 style={{ fontSize: '1.15rem', marginBottom: '16px', display: 'flex', alignItems: 'center', gap: '8px' }}>
                <Truck size={18} color="#059669" />
                Delivery Rules & WhatsApp Checkout
              </h3>

              <div className="form-group">
                <label className="form-label" style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '8px' }}>
                  <span>WhatsApp Order Handoff Number *</span>
                  <span style={{ fontSize: '0.75rem', fontWeight: 700, color: '#15803d', background: '#dcfce7', padding: '2px 8px', borderRadius: '4px' }}>
                    Default: +91 (India)
                  </span>
                </label>
                <div style={{
                  display: 'flex',
                  alignItems: 'stretch',
                  border: '1.5px solid #cbd5e1',
                  borderRadius: '10px',
                  overflow: 'hidden',
                  background: 'white',
                  boxShadow: '0 1px 2px rgba(0,0,0,0.04)'
                }}>
                  <div style={{
                    display: 'flex',
                    alignItems: 'center',
                    gap: '6px',
                    padding: '0 14px',
                    backgroundColor: '#f0fdf4',
                    borderRight: '1px solid #bbf7d0',
                    color: '#15803d',
                    fontWeight: 700,
                    fontSize: '0.95rem',
                    userSelect: 'none',
                    flexShrink: 0
                  }}>
                    <MessageCircle size={18} color="#16a34a" />
                    <span>+91</span>
                  </div>
                  <input
                    type="tel"
                    required
                    className="form-input"
                    style={{
                      border: 'none',
                      borderRadius: 0,
                      fontWeight: 600,
                      fontSize: '0.98rem',
                      letterSpacing: '0.5px',
                      padding: '10px 14px',
                      width: '100%',
                      outline: 'none',
                      boxShadow: 'none'
                    }}
                    value={getLocalNumber(formData.whatsapp_number)}
                    onChange={(e) => handleWhatsAppChange(e.target.value)}
                    placeholder="89700 50327"
                  />
                </div>
                <p style={{ fontSize: '0.78rem', color: '#64748b', marginTop: '6px' }}>
                  The Flutter mobile app will send formatted itemized order messages directly to{' '}
                  <strong style={{ color: '#059669' }}>
                    +91 {getLocalNumber(formData.whatsapp_number) || '89700 50327'}
                  </strong>.
                </p>
              </div>

              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '16px', marginTop: '16px' }}>
                <div className="form-group">
                  <label className="form-label">Free Delivery Threshold (₹) *</label>
                  <input
                    type="number"
                    min="0"
                    required
                    className="form-input"
                    value={formData.free_delivery_threshold}
                    onChange={(e) => setFormData({ ...formData, free_delivery_threshold: Number(e.target.value) })}
                  />
                  <span style={{ fontSize: '0.78rem', color: '#64748b' }}>
                    Orders above this amount get free delivery.
                  </span>
                </div>

                <div className="form-group">
                  <label className="form-label">Flat Delivery Fee (₹) *</label>
                  <input
                    type="number"
                    min="0"
                    required
                    className="form-input"
                    value={formData.delivery_fee}
                    onChange={(e) => setFormData({ ...formData, delivery_fee: Number(e.target.value) })}
                  />
                  <span style={{ fontSize: '0.78rem', color: '#64748b' }}>
                    Charged when order total is below threshold.
                  </span>
                </div>
              </div>
            </div>

            {/* About & Guarantee Texts */}
            <div style={{ background: 'white', borderRadius: '16px', border: '1px solid #e2e8f0', padding: '24px' }}>
              <h3 style={{ fontSize: '1.15rem', marginBottom: '16px', display: 'flex', alignItems: 'center', gap: '8px' }}>
                <ShieldCheck size={18} color="#059669" />
                Customer Trust & Freshness Guarantee
              </h3>

              <div className="form-group">
                <label className="form-label">Why Fresh Kart / About Us Story</label>
                <textarea
                  rows={3}
                  className="form-textarea"
                  value={formData.about_text || ''}
                  onChange={(e) => setFormData({ ...formData, about_text: e.target.value })}
                />
              </div>

              <div className="form-group">
                <label className="form-label">100% Freshness Guarantee Terms</label>
                <textarea
                  rows={3}
                  className="form-textarea"
                  value={formData.guarantee_text || ''}
                  onChange={(e) => setFormData({ ...formData, guarantee_text: e.target.value })}
                />
              </div>
            </div>
          </div>

          {/* Right column: Operating hours & Save */}
          <div style={{ display: 'flex', flexDirection: 'column', gap: '24px' }}>
            <div style={{ background: 'white', borderRadius: '16px', border: '1px solid #e2e8f0', padding: '24px' }}>
              <h3 style={{ fontSize: '1.15rem', marginBottom: '16px', display: 'flex', alignItems: 'center', gap: '8px' }}>
                <Clock size={18} color="#059669" />
                Weekly Operating Hours
              </h3>
              <p style={{ fontSize: '0.8rem', color: '#64748b', marginBottom: '16px' }}>
                Shown to customers on the mobile app store info tab.
              </p>

              <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
                {daysOfWeek.map((day) => (
                  <div key={day}>
                    <label style={{ fontSize: '0.8rem', fontWeight: 600, color: '#334155', display: 'block', marginBottom: '2px' }}>
                      {day}
                    </label>
                    <input
                      type="text"
                      className="form-input"
                      style={{ padding: '6px 10px', fontSize: '0.85rem' }}
                      value={formData.operating_hours?.[day] || '6:00 AM - 9:00 PM'}
                      onChange={(e) => handleHourChange(day, e.target.value)}
                    />
                  </div>
                ))}
              </div>
            </div>

            <button
              type="submit"
              className="btn btn-primary"
              style={{ width: '100%', padding: '14px', fontSize: '1rem' }}
            >
              <Save size={18} />
              Save All Settings
            </button>
          </div>
        </div>
      </form>
    </div>
  );
}
