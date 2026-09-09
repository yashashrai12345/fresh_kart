import React, { useState } from 'react';
import {
  Plus,
  Search,
  Edit2,
  Trash2,
  X,
  CheckCircle,
  AlertCircle,
} from 'lucide-react';
import ConfirmDeleteModal from '../components/ConfirmDeleteModal';

export default function Products({
  products,
  categories,
  onSaveProduct,
  onToggleStock,
  onDeleteProduct
}) {
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedCategory, setSelectedCategory] = useState('ALL');
  const [stockFilter, setStockFilter] = useState('ALL');
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingProduct, setEditingProduct] = useState(null);
  const [isSaving, setIsSaving] = useState(false);
  const [saveError, setSaveError] = useState('');

  // Delete state
  const [deleteTarget, setDeleteTarget] = useState(null); // { id, name }
  const [isDeleting, setIsDeleting] = useState(false);
  const [deleteError, setDeleteError] = useState('');

  // Success notification
  const [successMessage, setSuccessMessage] = useState('');

  const showSuccess = (msg) => {
    setSuccessMessage(msg);
    setTimeout(() => setSuccessMessage(''), 3500);
  };

  // Form state
  const [formData, setFormData] = useState({
    name: '',
    category_id: categories[0]?.id || 'cat_veg',
    description: '',
    price: 30,
    mrp: 45,
    unit: '/kg',
    diet_tag: 'veg',
    photo_url: '',
    in_stock: true,
    stock_left: ''
  });

  const handleOpenAddModal = () => {
    setEditingProduct(null);
    setFormData({
      name: '',
      category_id: categories[0]?.id || 'cat_veg',
      description: '',
      price: 40,
      mrp: 55,
      unit: '/kg',
      diet_tag: 'veg',
      photo_url: 'https://images.unsplash.com/photo-1592924357228-91a4daadcfea?w=600&auto=format&fit=crop&q=80',
      in_stock: true,
      stock_left: ''
    });
    setIsModalOpen(true);
  };

  const handleOpenEditModal = (product) => {
    setEditingProduct(product);
    setFormData({
      name: product.name,
      category_id: product.category_id,
      description: product.description || '',
      price: product.price,
      mrp: product.mrp,
      unit: product.unit || '/kg',
      diet_tag: product.diet_tag || 'veg',
      photo_url: product.photo_url || '',
      in_stock: product.in_stock,
      stock_left: product.stock_left !== null && product.stock_left !== undefined ? product.stock_left : ''
    });
    setIsModalOpen(true);
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setSaveError('');
    setIsSaving(true);
    try {
      const productToSave = {
        ...(editingProduct ? { id: editingProduct.id } : {}),
        name: formData.name,
        category_id: formData.category_id,
        description: formData.description,
        price: Number(formData.price),
        mrp: Number(formData.mrp),
        unit: formData.unit,
        diet_tag: formData.diet_tag,
        photo_url: formData.photo_url,
        in_stock: Boolean(formData.in_stock),
        stock_left: formData.stock_left !== '' ? Number(formData.stock_left) : null
      };
      await onSaveProduct(productToSave);
      setIsModalOpen(false);
      showSuccess(editingProduct ? `"${formData.name}" updated.` : `"${formData.name}" added to catalog.`);
    } catch (err) {
      setSaveError(err.message || 'Failed to save product');
    } finally {
      setIsSaving(false);
    }
  };

  const handleDeleteClick = (p) => {
    setDeleteTarget({ id: p.id, name: p.name });
    setDeleteError('');
  };

  const handleDeleteConfirm = async () => {
    if (!deleteTarget) return;
    setIsDeleting(true);
    setDeleteError('');
    try {
      await onDeleteProduct(deleteTarget.id);
      showSuccess(`"${deleteTarget.name}" removed from catalog.`);
      setDeleteTarget(null);
    } catch (err) {
      setDeleteError(err.message || 'Failed to delete product');
    } finally {
      setIsDeleting(false);
    }
  };

  // Filter products
  const filteredProducts = products.filter((p) => {
    const matchesSearch = p.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
      (p.description && p.description.toLowerCase().includes(searchQuery.toLowerCase()));
    const matchesCategory = selectedCategory === 'ALL' || p.category_id === selectedCategory;
    const matchesStock = stockFilter === 'ALL'
      ? true
      : stockFilter === 'IN_STOCK'
      ? p.in_stock
      : stockFilter === 'OUT_OF_STOCK'
      ? !p.in_stock
      : p.stock_left !== null && p.stock_left <= 8;

    return matchesSearch && matchesCategory && matchesStock;
  });

  const getDiscountPercent = (price, mrp) => {
    if (!mrp || mrp <= price) return 0;
    return Math.round(((mrp - price) / mrp) * 100);
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
      {/* Top action bar */}
      <div style={{
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'space-between',
        marginBottom: '24px',
        flexWrap: 'wrap',
        gap: '16px'
      }}>
        <div>
          <h2 style={{ fontSize: '1.5rem', fontWeight: 800 }}>Produce Catalog Management</h2>
          <p style={{ fontSize: '0.85rem', color: '#64748b' }}>
            {products.length} products total across {categories.length} APMC categories
          </p>
        </div>

        <button
          onClick={handleOpenAddModal}
          className="btn btn-primary"
        >
          <Plus size={18} />
          Add Fresh Item
        </button>
      </div>

      {/* Filter and Search Bar */}
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
        {/* Search */}
        <div style={{ position: 'relative', minWidth: '280px', flex: 1 }}>
          <Search size={18} style={{ position: 'absolute', left: '12px', top: '50%', transform: 'translateY(-50%)', color: '#94a3b8' }} />
          <input
            type="text"
            className="form-input"
            style={{ paddingLeft: '38px' }}
            placeholder="Search produce by name, Hindi/local name..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
          />
        </div>

        {/* Category Pills */}
        <div style={{ display: 'flex', gap: '8px', flexWrap: 'wrap' }}>
          <button
            onClick={() => setSelectedCategory('ALL')}
            className={`btn btn-sm ${selectedCategory === 'ALL' ? 'btn-primary' : 'btn-secondary'}`}
          >
            All
          </button>
          {categories.map((c) => (
            <button
              key={c.id}
              onClick={() => setSelectedCategory(c.id)}
              className={`btn btn-sm ${selectedCategory === c.id ? 'btn-primary' : 'btn-secondary'}`}
            >
              {c.name}
            </button>
          ))}
        </div>

        {/* Stock Filter */}
        <div>
          <select
            className="form-select"
            style={{ width: 'auto', padding: '8px 12px', fontSize: '0.85rem' }}
            value={stockFilter}
            onChange={(e) => setStockFilter(e.target.value)}
          >
            <option value="ALL">All Stock Status</option>
            <option value="IN_STOCK">In Stock Only</option>
            <option value="OUT_OF_STOCK">Out of Stock</option>
            <option value="LOW_STOCK">Low Stock Alert (≤8)</option>
          </select>
        </div>
      </div>

      {/* Products Table */}
      <div className="card-table-wrapper">
        <table className="custom-table">
          <thead>
            <tr>
              <th>Produce Item</th>
              <th>Category</th>
              <th>Price / MRP</th>
              <th>Unit</th>
              <th>Diet & Quality</th>
              <th>Stock Status</th>
              <th style={{ textAlign: 'right' }}>Actions</th>
            </tr>
          </thead>
          <tbody>
            {filteredProducts.length === 0 ? (
              <tr>
                <td colSpan={7} style={{ textAlign: 'center', padding: '48px', color: '#64748b' }}>
                  No produce found matching your filters.
                </td>
              </tr>
            ) : (
              filteredProducts.map((p) => {
                const discount = getDiscountPercent(p.price, p.mrp);
                const category = categories.find((c) => c.id === p.category_id);

                return (
                  <tr key={p.id}>
                    <td>
                      <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
                        <img
                          src={p.photo_url || 'https://images.unsplash.com/photo-1592924357228-91a4daadcfea?w=100'}
                          alt={p.name}
                          className="product-thumb"
                          onError={(e) => {
                            e.target.src = 'https://images.unsplash.com/photo-1540420773420-3366772f4999?w=100';
                          }}
                        />
                        <div>
                          <div style={{ fontWeight: 700 }}>{p.name}</div>
                          <div style={{ fontSize: '0.78rem', color: '#64748b', maxWidth: '280px', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
                            {p.description}
                          </div>
                        </div>
                      </div>
                    </td>
                    <td>
                      <span style={{
                        fontSize: '0.8rem',
                        fontWeight: 600,
                        backgroundColor: '#f1f5f9',
                        padding: '4px 8px',
                        borderRadius: '6px'
                      }}>
                        {category ? category.name : p.category_id}
                      </span>
                    </td>
                    <td>
                      <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                        <span style={{ fontWeight: 800, color: '#059669', fontSize: '1rem' }}>
                          ₹{p.price}
                        </span>
                        <span style={{ textDecoration: 'line-through', color: '#94a3b8', fontSize: '0.8rem' }}>
                          ₹{p.mrp}
                        </span>
                        {discount > 0 && (
                          <span style={{
                            backgroundColor: '#ecfdf5',
                            color: '#047857',
                            fontSize: '0.72rem',
                            fontWeight: 700,
                            padding: '2px 6px',
                            borderRadius: '4px'
                          }}>
                            {discount}% OFF
                          </span>
                        )}
                      </div>
                    </td>
                    <td>
                      <span style={{ fontWeight: 500, color: '#475569' }}>{p.unit}</span>
                    </td>
                    <td>
                      <span style={{
                        display: 'inline-flex',
                        alignItems: 'center',
                        gap: '4px',
                        fontSize: '0.75rem',
                        fontWeight: 700,
                        textTransform: 'uppercase',
                        color: p.diet_tag === 'veg' ? '#16a34a' : p.diet_tag === 'limited' ? '#d97706' : '#2563eb'
                      }}>
                        ● {p.diet_tag}
                      </span>
                    </td>
                    <td>
                      <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                        <button
                          onClick={() => onToggleStock(p.id, !p.in_stock)}
                          style={{
                            border: 'none',
                            background: p.in_stock ? '#dcfce7' : '#fee2e2',
                            color: p.in_stock ? '#15803d' : '#b91c1c',
                            padding: '4px 10px',
                            borderRadius: '9999px',
                            fontWeight: 700,
                            fontSize: '0.75rem',
                            cursor: 'pointer'
                          }}
                        >
                          {p.in_stock ? 'In Stock' : 'Out of Stock'}
                        </button>
                        {p.stock_left !== null && p.stock_left !== undefined && (
                          <span style={{ fontSize: '0.75rem', color: '#d97706', fontWeight: 600 }}>
                            ({p.stock_left} left)
                          </span>
                        )}
                      </div>
                    </td>
                    <td style={{ textAlign: 'right' }}>
                      <div style={{ display: 'inline-flex', gap: '6px' }}>
                        <button
                          onClick={() => handleOpenEditModal(p)}
                          className="btn-icon"
                          title="Edit Item"
                        >
                          <Edit2 size={16} />
                        </button>
                        <button
                          onClick={() => handleDeleteClick(p)}
                          className="btn-icon"
                          style={{ color: '#ef4444' }}
                          title="Delete Item"
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

      {/* Modal for Add / Edit Produce */}
      {isModalOpen && (
        <div className="modal-backdrop">
          <div className="modal-card">
            <div className="modal-header">
              <h3 style={{ fontSize: '1.25rem', fontWeight: 700 }}>
                {editingProduct ? 'Edit Produce Item' : 'Add New Produce Item'}
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
                  <label className="form-label">Produce Name *</label>
                  <input
                    type="text"
                    required
                    className="form-input"
                    value={formData.name}
                    onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                    placeholder="e.g. Farm Fresh Hybrid Tomatoes"
                  />
                </div>

                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '16px' }}>
                  <div className="form-group">
                    <label className="form-label">Category *</label>
                    <select
                      className="form-select"
                      value={formData.category_id}
                      onChange={(e) => setFormData({ ...formData, category_id: e.target.value })}
                    >
                      {categories.map((c) => (
                        <option key={c.id} value={c.id}>{c.name}</option>
                      ))}
                    </select>
                  </div>

                  <div className="form-group">
                    <label className="form-label">Unit of Measure *</label>
                    <select
                      className="form-select"
                      value={formData.unit}
                      onChange={(e) => setFormData({ ...formData, unit: e.target.value })}
                    >
                      <option value="/kg">Per Kilogram (/kg)</option>
                      <option value="/bunch">Per Bunch (/bunch)</option>
                      <option value="/pack">Per Pack (/pack)</option>
                      <option value="/pc">Per Piece (/pc)</option>
                    </select>
                  </div>
                </div>

                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '16px' }}>
                  <div className="form-group">
                    <label className="form-label">Selling Price (₹) *</label>
                    <input
                      type="number"
                      required
                      min="1"
                      className="form-input"
                      value={formData.price}
                      onChange={(e) => setFormData({ ...formData, price: e.target.value })}
                    />
                  </div>

                  <div className="form-group">
                    <label className="form-label">MRP (₹) *</label>
                    <input
                      type="number"
                      required
                      min="1"
                      className="form-input"
                      value={formData.mrp}
                      onChange={(e) => setFormData({ ...formData, mrp: e.target.value })}
                    />
                  </div>
                </div>

                <div className="form-group">
                  <label className="form-label">Photo Image URL</label>
                  <input
                    type="url"
                    className="form-input"
                    value={formData.photo_url}
                    onChange={(e) => setFormData({ ...formData, photo_url: e.target.value })}
                    placeholder="https://images.unsplash.com/..."
                  />
                  {formData.photo_url && (
                    <div style={{ marginTop: '10px', display: 'flex', alignItems: 'center', gap: '12px' }}>
                      <img
                        src={formData.photo_url}
                        alt="Preview"
                        style={{ width: '60px', height: '60px', borderRadius: '8px', objectFit: 'cover' }}
                      />
                      <span style={{ fontSize: '0.8rem', color: '#64748b' }}>Image preview</span>
                    </div>
                  )}
                </div>

                <div className="form-group">
                  <label className="form-label">Description & Freshness Notes</label>
                  <textarea
                    rows={3}
                    className="form-textarea"
                    value={formData.description}
                    onChange={(e) => setFormData({ ...formData, description: e.target.value })}
                    placeholder="Crisp, farm-washed, daily morning harvest..."
                  />
                </div>

                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '16px' }}>
                  <div className="form-group">
                    <label className="form-label">Dietary Tag</label>
                    <select
                      className="form-select"
                      value={formData.diet_tag}
                      onChange={(e) => setFormData({ ...formData, diet_tag: e.target.value })}
                    >
                      <option value="veg">Veg (Pure 100%)</option>
                      <option value="limited">Limited Season</option>
                      <option value="egg">Egg / Other</option>
                    </select>
                  </div>

                  <div className="form-group">
                    <label className="form-label">Low Stock Badge Count (Optional)</label>
                    <input
                      type="number"
                      min="0"
                      className="form-input"
                      value={formData.stock_left}
                      onChange={(e) => setFormData({ ...formData, stock_left: e.target.value })}
                      placeholder="Leave blank for abundant"
                    />
                  </div>
                </div>

                <div className="form-group">
                  <label style={{ display: 'flex', alignItems: 'center', gap: '8px', cursor: 'pointer' }}>
                    <input
                      type="checkbox"
                      checked={formData.in_stock}
                      onChange={(e) => setFormData({ ...formData, in_stock: e.target.checked })}
                      style={{ width: '18px', height: '18px', accentColor: '#059669' }}
                    />
                    <span style={{ fontWeight: 600, fontSize: '0.9rem' }}>Item is Available in Stock for Orders</span>
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
                <button
                  type="submit"
                  className="btn btn-primary"
                  disabled={isSaving}
                >
                  {isSaving ? 'Saving...' : (editingProduct ? 'Save Changes' : 'Create Item')}
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
        itemType="product"
        onConfirm={handleDeleteConfirm}
        onCancel={() => { setDeleteTarget(null); setDeleteError(''); }}
        isDeleting={isDeleting}
        errorMessage={deleteError}
      />
    </div>
  );
}

