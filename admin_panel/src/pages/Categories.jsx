import React, { useState } from 'react';
import { Plus, Edit2, Trash2, X, CheckCircle, AlertCircle } from 'lucide-react';
import ConfirmDeleteModal from '../components/ConfirmDeleteModal';

export default function Categories({
  categories,
  products,
  onSaveCategory,
  onDeleteCategory
}) {
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingCategory, setEditingCategory] = useState(null);
  const [name, setName] = useState('');
  const [icon, setIcon] = useState('Carrot');
  const [sortOrder, setSortOrder] = useState(1);
  const [isActive, setIsActive] = useState(true);
  const [isSaving, setIsSaving] = useState(false);
  const [saveError, setSaveError] = useState('');

  // Delete state
  const [deleteTarget, setDeleteTarget] = useState(null); // { id, name, productCount }
  const [isDeleting, setIsDeleting] = useState(false);
  const [deleteError, setDeleteError] = useState('');

  // Success notification
  const [successMessage, setSuccessMessage] = useState('');

  const showSuccess = (msg) => {
    setSuccessMessage(msg);
    setTimeout(() => setSuccessMessage(''), 3000);
  };

  const handleOpenAdd = () => {
    setEditingCategory(null);
    setName('');
    setIcon('Carrot');
    setSortOrder(categories.length + 1);
    setIsActive(true);
    setSaveError('');
    setIsModalOpen(true);
  };

  const handleOpenEdit = (c) => {
    setEditingCategory(c);
    setName(c.name);
    setIcon(c.icon || 'Carrot');
    setSortOrder(c.sort_order || 1);
    setIsActive(c.is_active);
    setSaveError('');
    setIsModalOpen(true);
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setSaveError('');
    setIsSaving(true);
    try {
      await onSaveCategory({
        ...(editingCategory ? { id: editingCategory.id } : {}),
        name,
        icon,
        sort_order: Number(sortOrder),
        is_active: isActive
      });
      setIsModalOpen(false);
      showSuccess(editingCategory ? `"${name}" updated successfully.` : `"${name}" category created.`);
    } catch (err) {
      setSaveError(err.message || 'Failed to save category');
    } finally {
      setIsSaving(false);
    }
  };

  const handleDeleteClick = (c) => {
    const productCount = products.filter((p) => p.category_id === c.id).length;
    setDeleteTarget({ id: c.id, name: c.name, productCount });
    setDeleteError('');
  };

  const handleDeleteConfirm = async () => {
    if (!deleteTarget) return;
    setIsDeleting(true);
    setDeleteError('');
    try {
      await onDeleteCategory(deleteTarget.id);
      showSuccess(`"${deleteTarget.name}" category deleted.`);
      setDeleteTarget(null);
    } catch (err) {
      setDeleteError(err.message || 'Failed to delete category');
    } finally {
      setIsDeleting(false);
    }
  };

  return (
    <div>
      {/* Success notification */}
      {successMessage && (
        <div style={{
          display: 'flex',
          alignItems: 'center',
          gap: '8px',
          backgroundColor: '#dcfce7',
          color: '#166534',
          padding: '12px 16px',
          borderRadius: '10px',
          marginBottom: '16px',
          fontWeight: 600,
          fontSize: '0.875rem',
          border: '1px solid #bbf7d0',
        }}>
          <CheckCircle size={18} />
          {successMessage}
        </div>
      )}

      <div style={{
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'space-between',
        marginBottom: '24px',
        flexWrap: 'wrap',
        gap: '16px'
      }}>
        <div>
          <h2 style={{ fontSize: '1.5rem', fontWeight: 800 }}>Category Taxonomy</h2>
          <p style={{ fontSize: '0.85rem', color: '#64748b' }}>
            Configure main navigation sections and store collections
          </p>
        </div>

        <button
          onClick={handleOpenAdd}
          className="btn btn-primary"
        >
          <Plus size={18} />
          Add Category
        </button>
      </div>

      <div className="card-table-wrapper">
        <table className="custom-table">
          <thead>
            <tr>
              <th>Order</th>
              <th>Category Name</th>
              <th>Slug / Identifier</th>
              <th>Produce Count</th>
              <th>Status</th>
              <th style={{ textAlign: 'right' }}>Actions</th>
            </tr>
          </thead>
          <tbody>
            {categories.length === 0 ? (
              <tr>
                <td colSpan="6" style={{ textAlign: 'center', padding: '32px', color: '#94a3b8' }}>
                  No categories yet. Click "Add Category" to create one.
                </td>
              </tr>
            ) : (
              categories.map((c) => {
                const productCount = products.filter((p) => p.category_id === c.id).length;
                return (
                  <tr key={c.id}>
                    <td>
                      <span style={{
                        fontWeight: 700,
                        color: '#059669',
                        backgroundColor: '#ecfdf5',
                        padding: '4px 8px',
                        borderRadius: '6px'
                      }}>
                        #{c.sort_order}
                      </span>
                    </td>
                    <td>
                      <div style={{ fontWeight: 700, fontSize: '0.95rem' }}>{c.name}</div>
                    </td>
                    <td>
                      <code style={{ fontSize: '0.8rem', color: '#64748b' }}>{c.slug}</code>
                    </td>
                    <td>
                      <span style={{ fontWeight: 600 }}>{productCount} items</span>
                    </td>
                    <td>
                      <span style={{
                        display: 'inline-flex',
                        alignItems: 'center',
                        gap: '4px',
                        padding: '4px 10px',
                        borderRadius: '9999px',
                        fontSize: '0.75rem',
                        fontWeight: 700,
                        backgroundColor: c.is_active ? '#dcfce7' : '#fee2e2',
                        color: c.is_active ? '#166534' : '#991b1b'
                      }}>
                        ● {c.is_active ? 'Active on App' : 'Hidden'}
                      </span>
                    </td>
                    <td style={{ textAlign: 'right' }}>
                      <div style={{ display: 'inline-flex', gap: '6px' }}>
                        <button
                          onClick={() => handleOpenEdit(c)}
                          className="btn-icon"
                          title="Edit Category"
                        >
                          <Edit2 size={16} />
                        </button>
                        <button
                          onClick={() => handleDeleteClick(c)}
                          className="btn-icon"
                          style={{ color: '#ef4444' }}
                          title="Delete Category"
                        >
                          <Trash2 size={16} />
                        </button>
                      </div>
                    </td>
                  </tr>
                );
              })
            )}
          </tbody>
        </table>
      </div>

      {/* Edit/Create Modal */}
      {isModalOpen && (
        <div className="modal-backdrop">
          <div className="modal-card">
            <div className="modal-header">
              <h3 style={{ fontSize: '1.25rem', fontWeight: 700 }}>
                {editingCategory ? 'Edit Category' : 'Create New Category'}
              </h3>
              <button
                onClick={() => setIsModalOpen(false)}
                className="btn-icon"
                style={{ border: 'none' }}
                disabled={isSaving}
              >
                <X size={20} />
              </button>
            </div>

            <form onSubmit={handleSubmit}>
              <div className="modal-body">
                <div className="form-group">
                  <label className="form-label">Category Name *</label>
                  <input
                    type="text"
                    required
                    className="form-input"
                    value={name}
                    onChange={(e) => setName(e.target.value)}
                    placeholder="e.g. Exotic Herbs & Microgreens"
                  />
                </div>

                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '16px' }}>
                  <div className="form-group">
                    <label className="form-label">Sort Order *</label>
                    <input
                      type="number"
                      required
                      className="form-input"
                      value={sortOrder}
                      onChange={(e) => setSortOrder(e.target.value)}
                    />
                  </div>

                  <div className="form-group">
                    <label className="form-label">Theme Icon</label>
                    <select
                      className="form-select"
                      value={icon}
                      onChange={(e) => setIcon(e.target.value)}
                    >
                      <option value="Carrot">Vegetables (Carrot)</option>
                      <option value="Sprout">Greens (Sprout)</option>
                      <option value="Apple">Fruits (Apple)</option>
                      <option value="ShoppingBag">Combos (Shopping Bag)</option>
                    </select>
                  </div>
                </div>

                <div className="form-group">
                  <label style={{ display: 'flex', alignItems: 'center', gap: '8px', cursor: 'pointer' }}>
                    <input
                      type="checkbox"
                      checked={isActive}
                      onChange={(e) => setIsActive(e.target.checked)}
                      style={{ width: '18px', height: '18px', accentColor: '#059669' }}
                    />
                    <span style={{ fontWeight: 600, fontSize: '0.9rem' }}>Visible in Mobile App Navigation</span>
                  </label>
                </div>

                {saveError && (
                  <div style={{
                    display: 'flex',
                    alignItems: 'center',
                    gap: '8px',
                    backgroundColor: '#fee2e2',
                    color: '#991b1b',
                    padding: '10px 14px',
                    borderRadius: '8px',
                    fontSize: '0.85rem',
                    fontWeight: 500,
                  }}>
                    <AlertCircle size={16} />
                    {saveError}
                  </div>
                )}
              </div>

              <div className="modal-footer">
                <button
                  type="button"
                  onClick={() => setIsModalOpen(false)}
                  className="btn btn-secondary"
                  disabled={isSaving}
                >
                  Cancel
                </button>
                <button type="submit" className="btn btn-primary" disabled={isSaving}>
                  {isSaving ? 'Saving...' : (editingCategory ? 'Save Changes' : 'Create Category')}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Delete Confirmation Modal */}
      <ConfirmDeleteModal
        isOpen={!!deleteTarget}
        itemName={deleteTarget?.name || ''}
        itemType="category"
        onConfirm={handleDeleteConfirm}
        onCancel={() => { setDeleteTarget(null); setDeleteError(''); }}
        isDeleting={isDeleting}
        errorMessage={deleteError}
        warningMessage={
          deleteTarget?.productCount > 0
            ? `This category contains ${deleteTarget.productCount} product(s). Please reassign or delete those products first.`
            : null
        }
      />
    </div>
  );
}
