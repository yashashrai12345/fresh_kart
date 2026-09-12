import React, { useState, useEffect } from 'react';
import { X, Clock, AlertTriangle, MessageCircle, RefreshCw, ShoppingBag } from 'lucide-react';
import { formatDateTimeIST } from '../utils/dateUtils';

export default function MaintenancePreviewModal({ settings, onClose }) {
  const [timeLeft, setTimeLeft] = useState('');

  const title = settings?.maintenance_title || 'Store Under Maintenance';
  const message = settings?.maintenance_message || 'We are currently restocking fresh produce from the APMC Mandi. Ordering will resume shortly!';
  const allowBrowsing = settings?.maintenance_allow_browsing ?? true;
  const estimatedResume = settings?.maintenance_estimated_resume;
  const whatsappNumber = settings?.whatsapp_number || '918970050327';

  // Live countdown calculation
  useEffect(() => {
    if (!estimatedResume) {
      setTimeLeft('');
      return;
    }

    const updateTimer = () => {
      const now = new Date().getTime();
      const target = new Date(estimatedResume).getTime();
      const diff = target - now;

      if (diff <= 0) {
        setTimeLeft('Resuming any moment now');
        return;
      }

      const hours = Math.floor(diff / (1000 * 60 * 60));
      const minutes = Math.floor((diff % (1000 * 60 * 60)) / (1000 * 60));
      const seconds = Math.floor((diff % (1000 * 60)) / 1000);

      setTimeLeft(`${hours}h ${minutes}m ${seconds}s`);
    };

    updateTimer();
    const interval = setInterval(updateTimer, 1000);
    return () => clearInterval(interval);
  }, [estimatedResume]);

  return (
    <div className="modal-backdrop" style={{ zIndex: 1000, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
      <div
        className="modal-card"
        style={{
          maxWidth: '520px',
          width: '94%',
          maxHeight: '92vh',
          overflowY: 'auto',
          borderRadius: '20px',
          padding: '0',
          boxShadow: '0 25px 50px -12px rgba(0, 0, 0, 0.25)',
          background: '#0f172a',
          color: '#f8fafc'
        }}
      >
        {/* Header bar */}
        <div style={{
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between',
          padding: '16px 20px',
          borderBottom: '1px solid #1e293b',
          background: '#1e293b'
        }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
            <span style={{
              display: 'inline-block',
              width: '8px',
              height: '8px',
              borderRadius: '50%',
              background: '#f59e0b',
              boxShadow: '0 0 8px #f59e0b'
            }} />
            <span style={{ fontSize: '0.88rem', fontWeight: 700, letterSpacing: '0.3px', color: '#e2e8f0' }}>
              CUSTOMER VIEW PREVIEW
            </span>
            <span style={{
              fontSize: '0.72rem',
              padding: '2px 8px',
              borderRadius: '999px',
              background: allowBrowsing ? 'rgba(16, 185, 129, 0.2)' : 'rgba(239, 68, 68, 0.2)',
              color: allowBrowsing ? '#34d399' : '#f87171',
              fontWeight: 600
            }}>
              {allowBrowsing ? 'Browse Only (Checkout Blocked)' : 'Full Lockout Screen'}
            </span>
          </div>
          <button
            onClick={onClose}
            className="btn-icon"
            style={{ color: '#94a3b8', border: 'none', background: 'transparent', cursor: 'pointer' }}
          >
            <X size={20} />
          </button>
        </div>

        {/* Mock Mobile Viewport Screen */}
        <div style={{ padding: '24px', background: '#0b1120' }}>
          <div style={{
            background: 'white',
            borderRadius: '24px',
            color: '#0f172a',
            overflow: 'hidden',
            boxShadow: '0 12px 32px rgba(0,0,0,0.5)',
            border: '6px solid #1e293b'
          }}>
            {/* Mock App Status Bar */}
            <div style={{
              background: '#064e3b',
              color: 'white',
              padding: '12px 16px',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'space-between',
              fontSize: '0.78rem',
              fontWeight: 700
            }}>
              <span>GREEN BASKET</span>
              <span style={{ opacity: 0.8 }}>9:41 AM (IST)</span>
            </div>

            {/* If Browse Only: Show Mock Store Banner */}
            {allowBrowsing ? (
              <div style={{ padding: '16px' }}>
                {/* Amber Announcement Banner */}
                <div style={{
                  background: '#fffbeb',
                  border: '1.5px solid #fde68a',
                  borderRadius: '12px',
                  padding: '14px 16px',
                  marginBottom: '16px'
                }}>
                  <div style={{ display: 'flex', alignItems: 'flex-start', gap: '10px' }}>
                    <AlertTriangle size={20} color="#d97706" style={{ flexShrink: 0, marginTop: '2px' }} />
                    <div>
                      <div style={{ fontWeight: 800, color: '#92400e', fontSize: '0.92rem' }}>
                        {title}
                      </div>
                      <p style={{ margin: '4px 0 0', fontSize: '0.8rem', color: '#b45309', lineHeight: '1.4' }}>
                        {message}
                      </p>
                      {estimatedResume && (
                        <div style={{
                          marginTop: '8px',
                          display: 'inline-flex',
                          alignItems: 'center',
                          gap: '6px',
                          background: '#fef3c7',
                          padding: '3px 8px',
                          borderRadius: '6px',
                          fontSize: '0.75rem',
                          fontWeight: 700,
                          color: '#78350f'
                        }}>
                          <Clock size={12} />
                          <span>Expected Resume: {formatDateTimeIST(estimatedResume)}</span>
                          {timeLeft && <span style={{ color: '#059669' }}>({timeLeft})</span>}
                        </div>
                      )}
                    </div>
                  </div>
                </div>

                {/* Mock Cart & Checkout Disabled state */}
                <div style={{
                  padding: '16px',
                  border: '1px dashed #cbd5e1',
                  borderRadius: '12px',
                  textAlign: 'center',
                  background: '#f8fafc'
                }}>
                  <ShoppingBag size={28} color="#94a3b8" style={{ margin: '0 auto 8px' }} />
                  <div style={{ fontSize: '0.85rem', fontWeight: 700, color: '#334155' }}>
                    Catalog Browsing Active
                  </div>
                  <p style={{ fontSize: '0.78rem', color: '#64748b', margin: '4px 0 12px' }}>
                    Customers can browse all fresh vegetables & fruits, but checkout buttons are paused.
                  </p>
                  <button
                    disabled
                    style={{
                      width: '100%',
                      background: '#94a3b8',
                      color: 'white',
                      border: 'none',
                      padding: '10px',
                      borderRadius: '8px',
                      fontWeight: 700,
                      fontSize: '0.85rem',
                      cursor: 'not-allowed'
                    }}
                  >
                    Checkout Paused During Maintenance
                  </button>
                </div>
              </div>
            ) : (
              /* Full Screen Lockout Screen */
              <div style={{ padding: '36px 20px', textAlign: 'center' }}>
                <div style={{
                  width: '64px',
                  height: '64px',
                  borderRadius: '50%',
                  background: '#fef3c7',
                  color: '#d97706',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  margin: '0 auto 16px',
                  boxShadow: '0 8px 16px rgba(245, 158, 11, 0.2)'
                }}>
                  <AlertTriangle size={32} />
                </div>

                <h3 style={{ fontSize: '1.25rem', fontWeight: 800, color: '#0f172a', margin: '0 0 8px' }}>
                  {title}
                </h3>
                <p style={{ fontSize: '0.88rem', color: '#64748b', margin: '0 0 20px', lineHeight: '1.5' }}>
                  {message}
                </p>

                {estimatedResume && (
                  <div style={{
                    background: '#f8fafc',
                    border: '1px solid #e2e8f0',
                    borderRadius: '12px',
                    padding: '12px 16px',
                    marginBottom: '20px',
                    display: 'inline-block'
                  }}>
                    <div style={{ fontSize: '0.72rem', color: '#64748b', fontWeight: 600, textTransform: 'uppercase' }}>
                      Estimated Reopening (IST)
                    </div>
                    <div style={{ fontSize: '0.95rem', fontWeight: 800, color: '#059669', marginTop: '2px' }}>
                      {formatDateTimeIST(estimatedResume)}
                    </div>
                    {timeLeft && (
                      <div style={{ fontSize: '0.75rem', color: '#d97706', fontWeight: 700, marginTop: '4px' }}>
                        ⏳ {timeLeft} remaining
                      </div>
                    )}
                  </div>
                )}

                {/* WhatsApp Support button */}
                <div>
                  <a
                    href={`https://wa.me/${whatsappNumber}`}
                    target="_blank"
                    rel="noreferrer"
                    style={{
                      display: 'inline-flex',
                      alignItems: 'center',
                      gap: '8px',
                      background: '#25d366',
                      color: 'white',
                      textDecoration: 'none',
                      padding: '10px 18px',
                      borderRadius: '999px',
                      fontWeight: 700,
                      fontSize: '0.85rem'
                    }}
                  >
                    <MessageCircle size={16} />
                    Need Help? Chat on WhatsApp
                  </a>
                </div>
              </div>
            )}
          </div>
        </div>

        {/* Footer info */}
        <div style={{
          padding: '14px 20px',
          borderTop: '1px solid #1e293b',
          background: '#1e293b',
          display: 'flex',
          justifyContent: 'flex-end'
        }}>
          <button
            onClick={onClose}
            className="btn-primary"
            style={{ padding: '8px 18px', fontSize: '0.85rem' }}
          >
            Close Preview
          </button>
        </div>
      </div>
    </div>
  );
}
