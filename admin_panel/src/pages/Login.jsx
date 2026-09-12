import React, { useState } from 'react';
import { Lock, Mail, ArrowRight } from 'lucide-react';
import { storeService, isSupabaseConfigured } from '../services/storeService';

export default function Login({ onLoginSuccess }) {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError('');
    setLoading(true);
    try {
      const user = await storeService.login(email, password);
      onLoginSuccess(user);
    } catch (err) {
      setError(err.message || 'Invalid email or password. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div style={{
      minHeight: '100vh',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      background: 'linear-gradient(135deg, #064e3b 0%, #0f172a 100%)',
      padding: '24px'
    }}>
      <div style={{
        background: '#ffffff',
        borderRadius: '24px',
        padding: '40px',
        maxWidth: '440px',
        width: '100%',
        boxShadow: '0 25px 50px -12px rgba(0, 0, 0, 0.35)',
        border: '1px solid rgba(255, 255, 255, 0.1)'
      }}>
        {/* Brand Header */}
        <div style={{ textAlign: 'center', marginBottom: '32px' }}>
          <div style={{
            width: '72px',
            height: '72px',
            borderRadius: '18px',
            overflow: 'hidden',
            display: 'inline-flex',
            alignItems: 'center',
            justifyContent: 'center',
            marginBottom: '16px',
            boxShadow: '0 10px 20px rgba(16, 185, 129, 0.25)',
          }}>
            <img
              src="/logo/fresh_kart_icon.jpg"
              alt="Green Basket Logo"
              style={{ width: '100%', height: '100%', objectFit: 'cover' }}
              onError={(e) => {
                e.target.style.display = 'none';
                e.target.parentElement.style.background = 'linear-gradient(135deg, #10b981 0%, #047857 100%)';
                e.target.parentElement.innerHTML = '<svg xmlns="http://www.w3.org/2000/svg" width="36" height="36" viewBox="0 0 24 24" fill="none" stroke="white" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><path d="M6 2L3 6v14a2 2 0 002 2h14a2 2 0 002-2V6l-3-4z"/><line x1="3" y1="6" x2="21" y2="6"/><path d="M16 10a4 4 0 01-8 0"/></svg>';
              }}
            />
          </div>
          <h1 style={{ fontSize: '1.75rem', fontWeight: 800, color: '#0f172a', letterSpacing: '-0.02em', margin: '0 0 4px' }}>
            GREEN BASKET
          </h1>
          <p style={{ fontSize: '0.88rem', color: '#64748b', margin: '0 0 12px' }}>
            Admin Operations Console
          </p>
          <div style={{
            display: 'inline-flex',
            alignItems: 'center',
            gap: '6px',
            padding: '4px 12px',
            borderRadius: '9999px',
            fontSize: '0.75rem',
            fontWeight: 600,
            background: isSupabaseConfigured ? '#ecfdf5' : '#fef2f2',
            color: isSupabaseConfigured ? '#047857' : '#991b1b'
          }}>
            <span style={{
              width: '6px',
              height: '6px',
              borderRadius: '50%',
              backgroundColor: isSupabaseConfigured ? '#10b981' : '#ef4444'
            }} />
            {isSupabaseConfigured ? 'Supabase Cloud Connected' : '⚠ Supabase Not Configured — Login Unavailable'}
          </div>
        </div>

        {!isSupabaseConfigured && (
          <div style={{
            backgroundColor: '#fef2f2',
            color: '#991b1b',
            padding: '14px 16px',
            borderRadius: '10px',
            fontSize: '0.85rem',
            marginBottom: '20px',
            fontWeight: 500,
            lineHeight: 1.5,
          }}>
            <strong>Configuration Required:</strong> Please set <code>VITE_SUPABASE_URL</code> and{' '}
            <code>VITE_SUPABASE_ANON_KEY</code> in your <code>.env</code> file to use the admin panel.
          </div>
        )}

        {error && (
          <div style={{
            backgroundColor: '#fee2e2',
            color: '#991b1b',
            padding: '12px 16px',
            borderRadius: '10px',
            fontSize: '0.85rem',
            marginBottom: '20px',
            fontWeight: 500
          }}>
            {error}
          </div>
        )}

        <form onSubmit={handleSubmit}>
          <div className="form-group">
            <label className="form-label" style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
              <Mail size={14} color="#64748b" /> Email Address
            </label>
            <input
              type="email"
              id="admin-email"
              className="form-input"
              required
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              placeholder="owner@greenbasket.com"
              disabled={!isSupabaseConfigured}
              autoComplete="username"
            />
          </div>

          <div className="form-group">
            <label className="form-label" style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
              <Lock size={14} color="#64748b" /> Password
            </label>
            <input
              type="password"
              id="admin-password"
              className="form-input"
              required
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              placeholder="••••••••"
              disabled={!isSupabaseConfigured}
              autoComplete="current-password"
            />
          </div>

          <button
            type="submit"
            disabled={loading || !isSupabaseConfigured}
            className="btn btn-primary"
            style={{
              width: '100%',
              padding: '12px',
              fontSize: '0.95rem',
              marginTop: '12px',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              gap: '8px',
              opacity: (!isSupabaseConfigured) ? 0.5 : 1,
              cursor: (!isSupabaseConfigured) ? 'not-allowed' : 'pointer',
            }}
          >
            {loading ? 'Authenticating...' : 'Sign In to Admin Panel'}
            {!loading && <ArrowRight size={18} />}
          </button>
        </form>

        <p style={{
          textAlign: 'center',
          fontSize: '0.75rem',
          color: '#94a3b8',
          marginTop: '20px',
        }}>
          Admin access requires valid Supabase credentials.
        </p>
      </div>
    </div>
  );
}
