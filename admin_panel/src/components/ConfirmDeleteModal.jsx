import React from 'react';
import { AlertTriangle, Trash2, X, Loader2 } from 'lucide-react';

/**
 * Reusable confirmation modal for destructive delete actions.
 * 
 * Props:
 * - isOpen: boolean
 * - itemName: string — name of the item to delete (shown in dialog)
 * - itemType: string — e.g. "product", "category"
 * - onConfirm: async function — called when admin confirms deletion
 * - onCancel: function — called when admin cancels
 * - isDeleting: boolean — show loading spinner during deletion
 * - errorMessage: string | null — error from last deletion attempt
 * - warningMessage: string | null — optional warning (e.g., "has X products")
 */
export default function ConfirmDeleteModal({
  isOpen,
  itemName,
  itemType = 'item',
  onConfirm,
  onCancel,
  isDeleting = false,
  errorMessage = null,
  warningMessage = null,
}) {
  if (!isOpen) return null;

  return (
    <div
      style={{
        position: 'fixed',
        inset: 0,
        backgroundColor: 'rgba(0, 0, 0, 0.55)',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        zIndex: 1000,
        backdropFilter: 'blur(2px)',
        padding: '16px',
      }}
      onClick={(e) => {
        if (e.target === e.currentTarget && !isDeleting) onCancel();
      }}
    >
      <div
        style={{
          backgroundColor: '#ffffff',
          borderRadius: '20px',
          padding: '28px',
          maxWidth: '420px',
          width: '100%',
          boxShadow: '0 25px 50px -12px rgba(0, 0, 0, 0.4)',
        }}
      >
        {/* Warning Icon */}
        <div style={{ textAlign: 'center', marginBottom: '20px' }}>
          <div
            style={{
              width: '56px',
              height: '56px',
              backgroundColor: '#fee2e2',
              borderRadius: '50%',
              display: 'inline-flex',
              alignItems: 'center',
              justifyContent: 'center',
              marginBottom: '16px',
            }}
          >
            <AlertTriangle size={28} color="#ef4444" />
          </div>
          <h3
            style={{
              fontSize: '1.15rem',
              fontWeight: 700,
              color: '#0f172a',
              margin: 0,
            }}
          >
            Delete {itemType.charAt(0).toUpperCase() + itemType.slice(1)}?
          </h3>
        </div>

        {/* Item name highlight */}
        <div
          style={{
            backgroundColor: '#fef2f2',
            border: '1px solid #fecaca',
            borderRadius: '10px',
            padding: '12px 16px',
            marginBottom: '16px',
            textAlign: 'center',
          }}
        >
          <p style={{ margin: 0, fontSize: '0.85rem', color: '#64748b' }}>
            You are about to permanently delete:
          </p>
          <p
            style={{
              margin: '4px 0 0',
              fontSize: '1rem',
              fontWeight: 700,
              color: '#0f172a',
              wordBreak: 'break-word',
            }}
          >
            "{itemName}"
          </p>
        </div>

        {/* Warning message (e.g., has products) */}
        {warningMessage && (
          <div
            style={{
              backgroundColor: '#fef3c7',
              border: '1px solid #fde68a',
              borderRadius: '10px',
              padding: '10px 14px',
              marginBottom: '16px',
              fontSize: '0.85rem',
              color: '#92400e',
              fontWeight: 500,
            }}
          >
            ⚠️ {warningMessage}
          </div>
        )}

        <p
          style={{
            fontSize: '0.875rem',
            color: '#64748b',
            textAlign: 'center',
            margin: '0 0 20px',
            lineHeight: 1.5,
          }}
        >
          This action <strong>cannot be undone</strong>. The {itemType} will be
          permanently removed from the database.
        </p>

        {/* Error message */}
        {errorMessage && (
          <div
            style={{
              backgroundColor: '#fee2e2',
              border: '1px solid #fecaca',
              borderRadius: '10px',
              padding: '10px 14px',
              marginBottom: '16px',
              fontSize: '0.85rem',
              color: '#991b1b',
              fontWeight: 500,
            }}
          >
            ❌ {errorMessage}
          </div>
        )}

        {/* Actions */}
        <div style={{ display: 'flex', gap: '10px' }}>
          <button
            onClick={onCancel}
            disabled={isDeleting}
            style={{
              flex: 1,
              padding: '11px',
              borderRadius: '10px',
              border: '1px solid #e2e8f0',
              backgroundColor: '#f8fafc',
              color: '#475569',
              fontWeight: 600,
              fontSize: '0.9rem',
              cursor: isDeleting ? 'not-allowed' : 'pointer',
              opacity: isDeleting ? 0.6 : 1,
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              gap: '6px',
            }}
          >
            <X size={16} />
            Cancel
          </button>

          <button
            onClick={onConfirm}
            disabled={isDeleting}
            style={{
              flex: 1,
              padding: '11px',
              borderRadius: '10px',
              border: 'none',
              backgroundColor: isDeleting ? '#fca5a5' : '#ef4444',
              color: '#ffffff',
              fontWeight: 700,
              fontSize: '0.9rem',
              cursor: isDeleting ? 'not-allowed' : 'pointer',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              gap: '6px',
              transition: 'background-color 0.15s',
            }}
          >
            {isDeleting ? (
              <>
                <Loader2 size={16} style={{ animation: 'spin 1s linear infinite' }} />
                Deleting...
              </>
            ) : (
              <>
                <Trash2 size={16} />
                Delete {itemType.charAt(0).toUpperCase() + itemType.slice(1)}
              </>
            )}
          </button>
        </div>
      </div>

      <style>{`
        @keyframes spin {
          from { transform: rotate(0deg); }
          to { transform: rotate(360deg); }
        }
      `}</style>
    </div>
  );
}
