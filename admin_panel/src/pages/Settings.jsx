import React, { useState, useEffect } from 'react';
import {
  Save,
  CheckCircle2,
  MessageCircle,
  Clock,
  ShieldCheck,
  MapPin,
  Truck,
  AlertTriangle,
  Eye,
  Power,
  Sparkles,
  Calendar,
  Info,
  RefreshCw,
  ShoppingBag,
  Sliders
} from 'lucide-react';
import MaintenancePreviewModal from '../components/MaintenancePreviewModal';
import { formatDateTimeIST } from '../utils/dateUtils';

export default function Settings({ settings, onUpdateSettings }) {
  const [activeTab, setActiveTab] = useState('maintenance'); // 'maintenance' or 'general'
  const [formData, setFormData] = useState({ ...settings });
  const [savedSuccess, setSavedSuccess] = useState(false);
  const [isSaving, setIsSaving] = useState(false);
  const [previewOpen, setPreviewOpen] = useState(false);

  useEffect(() => {
    if (settings) {
      setFormData({ ...settings });
    }
  }, [settings]);

  const handleSubmit = async (e) => {
    e.preventDefault();
    setIsSaving(true);
    try {
      await onUpdateSettings(formData);
      setSavedSuccess(true);
      setTimeout(() => setSavedSuccess(false), 3500);
    } catch (err) {
      console.error('Failed to save settings:', err);
    } finally {
      setIsSaving(false);
    }
  };

  const handleMasterSwitchToggle = async () => {
    const nextMode = !formData.is_maintenance_mode;
    const nextData = { ...formData, is_maintenance_mode: nextMode };
    setFormData(nextData);
    setIsSaving(true);
    try {
      await onUpdateSettings(nextData);
      setSavedSuccess(true);
      setTimeout(() => setSavedSuccess(false), 3500);
    } catch (err) {
      console.error('Failed to toggle maintenance mode:', err);
    } finally {
      setIsSaving(false);
    }
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

  // Quick preset templates for maintenance mode
  const PRESET_TEMPLATES = [
    {
      id: 'mandi_restock',
      name: '🌅 Mandi Restocking',
      title: 'Restocking Fresh Mandi Produce',
      message: 'We are currently sourcing crisp, fresh vegetables & fruits directly from the APMC Yeshwanthpur Mandi. Orders will reopen at 6:00 AM!',
      hoursAhead: 2,
      allowBrowsing: true,
    },
    {
      id: 'system_upgrade',
      name: '🛠️ System Upgrade',
      title: 'System Upgrades & Maintenance',
      message: 'We are upgrading our catalog & delivery systems to serve you better. Ordering is temporarily paused and will resume shortly.',
      hoursAhead: 1,
      allowBrowsing: true,
    },
    {
      id: 'weather_halt',
      name: '🌧️ Heavy Rain / Weather',
      title: 'Deliveries Paused for Driver Safety',
      message: 'Due to severe weather and waterlogging in Bengaluru, deliveries are temporarily paused for our delivery partners’ safety. We will resume as soon as conditions improve.',
      hoursAhead: 3,
      allowBrowsing: true,
    },
    {
      id: 'holiday_closure',
      name: '🎉 Festival / Holiday',
      title: 'Festival Store Closure',
      message: 'Our store is closed for the holiday. Wishing you a wonderful celebration! Fresh deliveries will resume early tomorrow morning.',
      hoursAhead: 12,
      allowBrowsing: false,
    }
  ];

  const applyPreset = async (preset, activate = true) => {
    const resumeDate = new Date(Date.now() + preset.hoursAhead * 60 * 60 * 1000);
    const nextData = {
      ...formData,
      is_maintenance_mode: true,
      maintenance_title: preset.title,
      maintenance_message: preset.message,
      maintenance_allow_browsing: preset.allowBrowsing,
      maintenance_estimated_resume: resumeDate.toISOString()
    };
    setFormData(nextData);
    if (activate) {
      setIsSaving(true);
      try {
        await onUpdateSettings(nextData);
        setSavedSuccess(true);
        setTimeout(() => setSavedSuccess(false), 3500);
      } catch (err) {
        console.error('Preset save error:', err);
      } finally {
        setIsSaving(false);
      }
    }
  };

  const setQuickTime = (hoursFromNow) => {
    if (hoursFromNow === null) {
      setFormData({ ...formData, maintenance_estimated_resume: null });
      return;
    }
    const target = new Date(Date.now() + hoursFromNow * 60 * 60 * 1000);
    setFormData({ ...formData, maintenance_estimated_resume: target.toISOString() });
  };

  const setNextMorning6AM = () => {
    const d = new Date();
    d.setDate(d.getDate() + 1);
    d.setHours(6, 0, 0, 0);
    setFormData({ ...formData, maintenance_estimated_resume: d.toISOString() });
  };

  const daysOfWeek = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  const isMaintenanceActive = Boolean(formData.is_maintenance_mode);

  return (
    <div>
      {/* Top Header & Save Alert */}
      <div style={{
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'space-between',
        marginBottom: '20px',
        flexWrap: 'wrap',
        gap: '16px'
      }}>
        <div>
          <h2 style={{ fontSize: '1.5rem', fontWeight: 800 }}>Store Settings & Operations</h2>
          <p style={{ fontSize: '0.85rem', color: '#64748b' }}>
            Manage store identity, delivery rules, and emergency maintenance downtime
          </p>
        </div>

        <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
          {/* Live Store Status Badge */}
          <div style={{
            display: 'inline-flex',
            alignItems: 'center',
            gap: '8px',
            padding: '6px 14px',
            borderRadius: '999px',
            fontSize: '0.8rem',
            fontWeight: 700,
            background: isMaintenanceActive ? '#fef3c7' : '#ecfdf5',
            color: isMaintenanceActive ? '#b45309' : '#047857',
            border: isMaintenanceActive ? '1px solid #fde68a' : '1px solid #a7f3d0'
          }}>
            <span style={{
              width: '8px',
              height: '8px',
              borderRadius: '50%',
              backgroundColor: isMaintenanceActive ? '#d97706' : '#10b981',
              boxShadow: isMaintenanceActive ? '0 0 6px #d97706' : '0 0 6px #10b981'
            }} />
            {isMaintenanceActive ? 'Maintenance Active (Ordering Paused)' : 'Store Live & Accepting Orders'}
          </div>

          {isSaving && (
            <div style={{
              display: 'flex',
              alignItems: 'center',
              gap: '8px',
              backgroundColor: '#e0f2fe',
              color: '#0369a1',
              padding: '8px 16px',
              borderRadius: '9999px',
              fontSize: '0.85rem',
              fontWeight: 600
            }}>
              <RefreshCw size={15} style={{ animation: 'spin 1s linear infinite' }} />
              Saving changes...
            </div>
          )}

          {savedSuccess && !isSaving && (
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
      </div>

      {/* Tab Navigation */}
      <div style={{
        display: 'flex',
        gap: '8px',
        marginBottom: '24px',
        borderBottom: '2px solid #e2e8f0',
        paddingBottom: '2px'
      }}>
        <button
          type="button"
          onClick={() => setActiveTab('maintenance')}
          style={{
            display: 'flex',
            alignItems: 'center',
            gap: '8px',
            padding: '10px 18px',
            borderRadius: '10px 10px 0 0',
            border: 'none',
            background: activeTab === 'maintenance' ? '#f8fafc' : 'transparent',
            borderBottom: activeTab === 'maintenance' ? '3px solid #d97706' : '3px solid transparent',
            color: activeTab === 'maintenance' ? '#b45309' : '#64748b',
            fontWeight: activeTab === 'maintenance' ? 800 : 600,
            fontSize: '0.92rem',
            cursor: 'pointer',
            transition: 'all 0.15s ease'
          }}
        >
          <AlertTriangle size={18} color={activeTab === 'maintenance' ? '#d97706' : '#94a3b8'} />
          <span>Maintenance Mode Hub</span>
          {isMaintenanceActive && (
            <span style={{
              background: '#ef4444',
              color: 'white',
              fontSize: '0.68rem',
              padding: '2px 6px',
              borderRadius: '999px',
              fontWeight: 700
            }}>
              ACTIVE
            </span>
          )}
        </button>

        <button
          type="button"
          onClick={() => setActiveTab('general')}
          style={{
            display: 'flex',
            alignItems: 'center',
            gap: '8px',
            padding: '10px 18px',
            borderRadius: '10px 10px 0 0',
            border: 'none',
            background: activeTab === 'general' ? '#f8fafc' : 'transparent',
            borderBottom: activeTab === 'general' ? '3px solid #059669' : '3px solid transparent',
            color: activeTab === 'general' ? '#059669' : '#64748b',
            fontWeight: activeTab === 'general' ? 800 : 600,
            fontSize: '0.92rem',
            cursor: 'pointer',
            transition: 'all 0.15s ease'
          }}
        >
          <Sliders size={18} color={activeTab === 'general' ? '#059669' : '#94a3b8'} />
          <span>General Store Operations</span>
        </button>
      </div>

      {/* TAB 1: MAINTENANCE MODE COMMAND CENTER */}
      {activeTab === 'maintenance' && (
        <form onSubmit={handleSubmit}>
          <div style={{ display: 'flex', flexDirection: 'column', gap: '20px' }}>
            {/* Supabase Migration Notice Banner */}
            <div style={{
              background: '#eff6ff',
              border: '1px solid #bfdbfe',
              borderRadius: '12px',
              padding: '12px 18px',
              display: 'flex',
              alignItems: 'center',
              gap: '12px',
              fontSize: '0.84rem',
              color: '#1e40af'
            }}>
              <Info size={18} color="#2563eb" style={{ flexShrink: 0 }} />
              <div>
                <span style={{ fontWeight: 700 }}>Realtime Persistence Active:</span> Toggling maintenance mode below saves immediately and persists across browser refreshes. To also sync live with the customer mobile app, execute{' '}
                <code style={{ background: '#dbeafe', padding: '2px 6px', borderRadius: '4px', fontWeight: 700 }}>
                  supabase/migration_003_maintenance_mode.sql
                </code>{' '}
                in your Supabase SQL Editor.
              </div>
            </div>

            {/* Master Control Card */}
            <div style={{
              background: isMaintenanceActive ? 'linear-gradient(135deg, #fffbeb 0%, #fef3c7 100%)' : '#ffffff',
              borderRadius: '16px',
              border: isMaintenanceActive ? '2px solid #f59e0b' : '1px solid #e2e8f0',
              padding: '24px',
              boxShadow: isMaintenanceActive ? '0 10px 25px -5px rgba(245, 158, 11, 0.15)' : 'none'
            }}>
              <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', flexWrap: 'wrap', gap: '16px' }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: '16px' }}>
                  <div style={{
                    width: '54px',
                    height: '54px',
                    borderRadius: '14px',
                    background: isMaintenanceActive ? '#d97706' : '#f1f5f9',
                    color: isMaintenanceActive ? 'white' : '#64748b',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    boxShadow: isMaintenanceActive ? '0 4px 12px rgba(217, 119, 6, 0.3)' : 'none'
                  }}>
                    <Power size={28} />
                  </div>
                  <div>
                    <h3 style={{ fontSize: '1.25rem', fontWeight: 800, color: isMaintenanceActive ? '#92400e' : '#0f172a', margin: 0 }}>
                      Store Maintenance Mode
                    </h3>
                    <p style={{ fontSize: '0.85rem', color: isMaintenanceActive ? '#b45309' : '#64748b', margin: '4px 0 0' }}>
                      {isMaintenanceActive
                        ? 'Ordering is paused. Mobile app and web customers see your maintenance notice.'
                        : 'Store is live. All catalog items and WhatsApp checkouts are active.'}
                    </p>
                  </div>
                </div>

                {/* Master Switch */}
                <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
                  <span style={{ fontSize: '0.9rem', fontWeight: 700, color: isMaintenanceActive ? '#b45309' : '#64748b' }}>
                    {isMaintenanceActive ? 'MAINTENANCE ON' : 'MAINTENANCE OFF'}
                  </span>
                  <button
                    type="button"
                    disabled={isSaving}
                    onClick={handleMasterSwitchToggle}
                    title={isMaintenanceActive ? 'Click to turn OFF maintenance' : 'Click to turn ON maintenance'}
                    style={{
                      width: '64px',
                      height: '34px',
                      borderRadius: '999px',
                      background: isMaintenanceActive ? '#d97706' : '#cbd5e1',
                      border: 'none',
                      cursor: isSaving ? 'wait' : 'pointer',
                      position: 'relative',
                      transition: 'background 0.2s ease',
                      padding: '3px',
                      opacity: isSaving ? 0.7 : 1
                    }}
                  >
                    <div style={{
                      width: '28px',
                      height: '28px',
                      borderRadius: '50%',
                      background: 'white',
                      transform: isMaintenanceActive ? 'translateX(30px)' : 'translateX(0)',
                      transition: 'transform 0.2s ease',
                      boxShadow: '0 2px 5px rgba(0,0,0,0.2)'
                    }} />
                  </button>
                </div>
              </div>
            </div>

            {/* Quick Presets Section */}
            <div style={{ background: 'white', borderRadius: '16px', border: '1px solid #e2e8f0', padding: '24px' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginBottom: '8px' }}>
                <Sparkles size={18} color="#d97706" />
                <h4 style={{ fontSize: '1.05rem', fontWeight: 800, margin: 0 }}>1-Click Scenario Templates</h4>
              </div>
              <p style={{ fontSize: '0.82rem', color: '#64748b', margin: '0 0 16px' }}>
                Quickly populate customer notices and estimated resume times for common store events:
              </p>

              <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(220px, 1fr))', gap: '12px' }}>
                {PRESET_TEMPLATES.map((p) => (
                  <button
                    key={p.id}
                    type="button"
                    onClick={() => applyPreset(p)}
                    style={{
                      display: 'flex',
                      flexDirection: 'column',
                      alignItems: 'flex-start',
                      padding: '14px',
                      borderRadius: '12px',
                      border: '1.5px solid #e2e8f0',
                      background: '#f8fafc',
                      textAlign: 'left',
                      cursor: 'pointer',
                      transition: 'all 0.15s ease'
                    }}
                    onMouseEnter={(e) => {
                      e.currentTarget.style.borderColor = '#d97706';
                      e.currentTarget.style.background = '#fffbeb';
                    }}
                    onMouseLeave={(e) => {
                      e.currentTarget.style.borderColor = '#e2e8f0';
                      e.currentTarget.style.background = '#f8fafc';
                    }}
                  >
                    <span style={{ fontWeight: 800, fontSize: '0.9rem', color: '#0f172a' }}>{p.name}</span>
                    <span style={{ fontSize: '0.78rem', color: '#64748b', marginTop: '4px', lineHeight: '1.3' }}>
                      {p.title}
                    </span>
                    <span style={{ fontSize: '0.72rem', color: '#059669', fontWeight: 700, marginTop: '8px' }}>
                      +{p.hoursAhead}h duration • {p.allowBrowsing ? 'Browse OK' : 'Lockout'}
                    </span>
                  </button>
                ))}
              </div>
            </div>

            {/* Customer Notice & Strategy */}
            <div style={{ background: 'white', borderRadius: '16px', border: '1px solid #e2e8f0', padding: '24px' }}>
              <h4 style={{ fontSize: '1.05rem', fontWeight: 800, margin: '0 0 16px' }}>
                Customer Display & Access Policy
              </h4>

              {/* Access Mode Selector */}
              <div style={{ marginBottom: '20px' }}>
                <label className="form-label">Customer Access Strategy</label>
                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '16px' }}>
                  <div
                    onClick={() => setFormData({ ...formData, maintenance_allow_browsing: true })}
                    style={{
                      padding: '16px',
                      borderRadius: '12px',
                      border: formData.maintenance_allow_browsing ? '2px solid #059669' : '1px solid #e2e8f0',
                      background: formData.maintenance_allow_browsing ? '#ecfdf5' : '#f8fafc',
                      cursor: 'pointer'
                    }}
                  >
                    <div style={{ display: 'flex', alignItems: 'center', gap: '8px', fontWeight: 700, fontSize: '0.92rem', color: '#0f172a' }}>
                      <input
                        type="radio"
                        checked={formData.maintenance_allow_browsing === true}
                        onChange={() => setFormData({ ...formData, maintenance_allow_browsing: true })}
                      />
                      <span>Catalog Browsing Allowed (Recommended)</span>
                    </div>
                    <p style={{ fontSize: '0.78rem', color: '#64748b', margin: '6px 0 0 24px', lineHeight: '1.4' }}>
                      Customers can view fresh items, prices, and search the catalog. A friendly banner explains ordering is paused during checkout.
                    </p>
                  </div>

                  <div
                    onClick={() => setFormData({ ...formData, maintenance_allow_browsing: false })}
                    style={{
                      padding: '16px',
                      borderRadius: '12px',
                      border: !formData.maintenance_allow_browsing ? '2px solid #d97706' : '1px solid #e2e8f0',
                      background: !formData.maintenance_allow_browsing ? '#fffbeb' : '#f8fafc',
                      cursor: 'pointer'
                    }}
                  >
                    <div style={{ display: 'flex', alignItems: 'center', gap: '8px', fontWeight: 700, fontSize: '0.92rem', color: '#0f172a' }}>
                      <input
                        type="radio"
                        checked={formData.maintenance_allow_browsing === false}
                        onChange={() => setFormData({ ...formData, maintenance_allow_browsing: false })}
                      />
                      <span>Full Storefront Takeover</span>
                    </div>
                    <p style={{ fontSize: '0.78rem', color: '#64748b', margin: '6px 0 0 24px', lineHeight: '1.4' }}>
                      Completely takes over the screen with a clean maintenance graphic, countdown timer, and WhatsApp support button.
                    </p>
                  </div>
                </div>
              </div>

              {/* Title & Message inputs */}
              <div className="form-group" style={{ marginBottom: '16px' }}>
                <label className="form-label">Notice Headline *</label>
                <input
                  type="text"
                  required
                  className="form-input"
                  value={formData.maintenance_title || ''}
                  onChange={(e) => setFormData({ ...formData, maintenance_title: e.target.value })}
                  placeholder="e.g. Restocking Fresh Mandi Produce"
                />
              </div>

              <div className="form-group" style={{ marginBottom: '20px' }}>
                <label className="form-label">Detailed Notice Message for Customers *</label>
                <textarea
                  required
                  className="form-input"
                  rows={3}
                  value={formData.maintenance_message || ''}
                  onChange={(e) => setFormData({ ...formData, maintenance_message: e.target.value })}
                  placeholder="Explain why ordering is paused and when fresh items will be available..."
                />
              </div>

              {/* Estimated Back Online Time */}
              <div className="form-group">
                <label className="form-label" style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                  <span>Estimated Back Online Time (IST)</span>
                  {formData.maintenance_estimated_resume && (
                    <span style={{ fontSize: '0.78rem', fontWeight: 700, color: '#059669' }}>
                      Formatted: {formatDateTimeIST(formData.maintenance_estimated_resume)}
                    </span>
                  )}
                </label>

                {/* Quick Add Buttons */}
                <div style={{ display: 'flex', gap: '8px', marginBottom: '10px', flexWrap: 'wrap' }}>
                  <button
                    type="button"
                    onClick={() => setQuickTime(1)}
                    className="btn"
                    style={{ fontSize: '0.78rem', padding: '6px 12px', background: '#f1f5f9', border: '1px solid #cbd5e1' }}
                  >
                    +1 Hour
                  </button>
                  <button
                    type="button"
                    onClick={() => setQuickTime(2)}
                    className="btn"
                    style={{ fontSize: '0.78rem', padding: '6px 12px', background: '#f1f5f9', border: '1px solid #cbd5e1' }}
                  >
                    +2 Hours
                  </button>
                  <button
                    type="button"
                    onClick={() => setQuickTime(4)}
                    className="btn"
                    style={{ fontSize: '0.78rem', padding: '6px 12px', background: '#f1f5f9', border: '1px solid #cbd5e1' }}
                  >
                    +4 Hours
                  </button>
                  <button
                    type="button"
                    onClick={setNextMorning6AM}
                    className="btn"
                    style={{ fontSize: '0.78rem', padding: '6px 12px', background: '#f1f5f9', border: '1px solid #cbd5e1' }}
                  >
                    🌅 Tomorrow 6:00 AM
                  </button>
                  {formData.maintenance_estimated_resume && (
                    <button
                      type="button"
                      onClick={() => setQuickTime(null)}
                      className="btn"
                      style={{ fontSize: '0.78rem', padding: '6px 12px', background: '#fee2e2', color: '#991b1b', border: '1px solid #fecaca' }}
                    >
                      Clear Time
                    </button>
                  )}
                </div>

                <input
                  type="datetime-local"
                  className="form-input"
                  value={
                    formData.maintenance_estimated_resume
                      ? new Date(new Date(formData.maintenance_estimated_resume).getTime() - new Date().getTimezoneOffset() * 60000)
                          .toISOString()
                          .slice(0, 16)
                      : ''
                  }
                  onChange={(e) => {
                    if (!e.target.value) {
                      setFormData({ ...formData, maintenance_estimated_resume: null });
                    } else {
                      setFormData({
                        ...formData,
                        maintenance_estimated_resume: new Date(e.target.value).toISOString()
                      });
                    }
                  }}
                />
              </div>
            </div>

            {/* Action Bar */}
            <div style={{
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'space-between',
              background: 'white',
              borderRadius: '16px',
              border: '1px solid #e2e8f0',
              padding: '18px 24px',
              flexWrap: 'wrap',
              gap: '16px'
            }}>
              <button
                type="button"
                onClick={() => setPreviewOpen(true)}
                className="btn"
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  gap: '8px',
                  background: '#f8fafc',
                  border: '1.5px solid #cbd5e1',
                  color: '#334155',
                  padding: '12px 20px',
                  fontWeight: 700,
                  fontSize: '0.9rem'
                }}
              >
                <Eye size={18} />
                Preview What Customers See
              </button>

              <button
                type="submit"
                disabled={isSaving}
                className="btn btn-primary"
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  gap: '8px',
                  padding: '12px 28px',
                  fontSize: '0.95rem',
                  background: isMaintenanceActive ? '#d97706' : '#059669',
                  opacity: isSaving ? 0.75 : 1,
                  cursor: isSaving ? 'wait' : 'pointer'
                }}
              >
                {isSaving ? (
                  <>
                    <RefreshCw size={18} style={{ animation: 'spin 1s linear infinite' }} />
                    Saving Changes...
                  </>
                ) : (
                  <>
                    <Save size={18} />
                    {isMaintenanceActive ? 'Broadcast Maintenance Settings' : 'Save Settings'}
                  </>
                )}
              </button>
            </div>
          </div>
        </form>
      )}

      {/* TAB 2: GENERAL STORE OPERATIONS */}
      {activeTab === 'general' && (
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
                    <label className="form-label">Primary Tagline *</label>
                    <input
                      type="text"
                      required
                      className="form-input"
                      value={formData.tagline || ''}
                      onChange={(e) => setFormData({ ...formData, tagline: e.target.value })}
                    />
                  </div>
                </div>

                <div className="form-group" style={{ marginTop: '16px' }}>
                  <label className="form-label">Subtitle / Promise Banner</label>
                  <input
                    type="text"
                    className="form-input"
                    value={formData.subtitle || ''}
                    onChange={(e) => setFormData({ ...formData, subtitle: e.target.value })}
                  />
                </div>

                <div className="form-group" style={{ marginTop: '16px' }}>
                  <label className="form-label">Physical Warehouse / Mandi Dispatch Address *</label>
                  <textarea
                    rows={2}
                    required
                    className="form-input"
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
                    <label className="form-label">Standard Delivery Fee (₹) *</label>
                    <input
                      type="number"
                      min="0"
                      required
                      className="form-input"
                      value={formData.delivery_fee}
                      onChange={(e) => setFormData({ ...formData, delivery_fee: Number(e.target.value) })}
                    />
                    <span style={{ fontSize: '0.78rem', color: '#64748b' }}>
                      Charged for orders under the threshold.
                    </span>
                  </div>
                </div>
              </div>

              {/* Story & Guarantee */}
              <div style={{ background: 'white', borderRadius: '16px', border: '1px solid #e2e8f0', padding: '24px' }}>
                <h3 style={{ fontSize: '1.15rem', marginBottom: '16px', display: 'flex', alignItems: 'center', gap: '8px' }}>
                  <ShieldCheck size={18} color="#059669" />
                  Farm Sourcing Philosophy & Guarantee
                </h3>

                <div className="form-group">
                  <label className="form-label">About Store (Mandi Sourcing Story)</label>
                  <textarea
                    rows={3}
                    className="form-input"
                    value={formData.about_text || ''}
                    onChange={(e) => setFormData({ ...formData, about_text: e.target.value })}
                  />
                </div>

                <div className="form-group" style={{ marginTop: '16px' }}>
                  <label className="form-label">Freshness Guarantee Statement</label>
                  <textarea
                    rows={2}
                    className="form-input"
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
                disabled={isSaving}
                className="btn btn-primary"
                style={{
                  width: '100%',
                  padding: '14px',
                  fontSize: '1rem',
                  opacity: isSaving ? 0.75 : 1,
                  cursor: isSaving ? 'wait' : 'pointer'
                }}
              >
                {isSaving ? (
                  <>
                    <RefreshCw size={18} style={{ animation: 'spin 1s linear infinite' }} />
                    Saving All Settings...
                  </>
                ) : (
                  <>
                    <Save size={18} />
                    Save All Settings
                  </>
                )}
              </button>
            </div>
          </div>
        </form>
      )}

      {/* Customer View Preview Modal */}
      {previewOpen && (
        <MaintenancePreviewModal
          settings={formData}
          onClose={() => setPreviewOpen(false)}
        />
      )}
    </div>
  );
}
