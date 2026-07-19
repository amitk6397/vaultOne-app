import { useState } from 'react'
import { Save, UploadCloud, X } from 'lucide-react'
import { PrimaryButton, SecondaryButton } from '../components/Buttons'
import { EmptyState, ErrorMessage } from '../components/Feedback'
import { TextArea, TextInput, Toggle } from '../components/FormControls'
import { RowActions, StatusBadge } from '../components/ResourceItems'
import { ResourceForm, ResourceTable } from '../components/ResourceLayout'
import { adminApi } from '../services/api'
import { formatDate, normalizeImageUrl } from '../utils'

const initialBannerForm = {
  id: null,
  title: '',
  subtitle: '',
  ctaLabel: 'Explore',
  routeName: '',
  imageUrl: '',
  imageFile: null,
  isActive: true,
}

export function BannersManager({ banners, loading, onChanged }) {
  const [form, setForm] = useState(initialBannerForm)
  const [saving, setSaving] = useState(false)
  const [error, setError] = useState('')

  const resetForm = () => setForm(initialBannerForm)

  const editBanner = (banner) =>
    setForm({
      id: banner.id,
      title: banner.title,
      subtitle: banner.subtitle,
      ctaLabel: banner.cta_label,
      routeName: banner.route_name || '',
      imageUrl: banner.image,
      imageFile: null,
      isActive: banner.is_active,
    })

  const submit = async (event) => {
    event.preventDefault()
    setError('')
    setSaving(true)
    const formData = new FormData()
    formData.append('title', form.title.trim())
    formData.append('subtitle', form.subtitle.trim())
    formData.append('cta_label', form.ctaLabel.trim())
    formData.append('route_name', form.routeName.trim())
    formData.append('is_active', String(form.isActive))
    if (form.imageFile) {
      formData.append('image_file', form.imageFile)
    } else if (form.imageUrl.trim()) {
      formData.append('image_url', form.imageUrl.trim())
    }

    try {
      if (form.id) {
        await adminApi.updateBanner(form.id, formData)
      } else {
        await adminApi.createBanner(formData)
      }
      resetForm()
      await onChanged()
    } catch (err) {
      setError(err.message)
    } finally {
      setSaving(false)
    }
  }

  const deleteBanner = async (id) => {
    if (!confirm('Delete this banner?')) return
    setError('')
    try {
      await adminApi.deleteBanner(id)
      await onChanged()
    } catch (err) {
      setError(err.message)
    }
  }

  return (
    <div className="grid gap-6 xl:grid-cols-[420px_1fr]">
      <ResourceForm title={form.id ? 'Edit banner' : 'Create banner'} onSubmit={submit}>
        <ErrorMessage message={error} />
        <TextInput label="Title" value={form.title} onChange={(value) => setForm({ ...form, title: value })} required />
        <TextArea label="Subtitle" value={form.subtitle} onChange={(value) => setForm({ ...form, subtitle: value })} required />
        <TextInput label="Button label" value={form.ctaLabel} onChange={(value) => setForm({ ...form, ctaLabel: value })} required />
        <TextInput label="Route name" value={form.routeName} onChange={(value) => setForm({ ...form, routeName: value })} placeholder="passwords, profile, documents" />
        <TextInput label="Image URL" value={form.imageUrl} onChange={(value) => setForm({ ...form, imageUrl: value, imageFile: null })} placeholder="https://..." />
        <label className="block">
          <span className="mb-2 flex items-center gap-2 text-sm font-bold text-slate-700">
            <UploadCloud size={16} /> Upload image
          </span>
          <input
            type="file"
            accept="image/png,image/jpeg,image/webp"
            onChange={(event) => setForm({ ...form, imageFile: event.target.files?.[0] || null, imageUrl: '' })}
            className="w-full rounded-lg border border-dashed border-slate-300 bg-slate-50 px-3 py-3 text-sm"
          />
        </label>
        <Toggle label="Active" checked={form.isActive} onChange={(value) => setForm({ ...form, isActive: value })} />
        <div className="flex gap-3">
          <PrimaryButton loading={saving} label={form.id ? 'Update banner' : 'Create banner'} icon={Save} />
          {form.id && <SecondaryButton type="button" label="Cancel" onClick={resetForm} icon={X} />}
        </div>
      </ResourceForm>

      <ResourceTable title="Home banners" loading={loading}>
        <div className="grid gap-4">
          {banners.map((banner) => (
            <article key={banner.id} className="grid gap-4 rounded-xl border border-slate-200 bg-white p-4 shadow-sm md:grid-cols-[180px_1fr_auto]">
              <img src={normalizeImageUrl(banner.image)} alt={banner.title} className="h-32 w-full rounded-lg object-cover md:w-44" />
              <div>
                <div className="flex flex-wrap items-center gap-2">
                  <h3 className="font-black text-slate-950">{banner.title}</h3>
                  <StatusBadge active={banner.is_active} />
                </div>
                <p className="mt-2 text-sm leading-6 text-slate-600">{banner.subtitle}</p>
                <p className="mt-2 text-sm font-bold text-blue-700">{banner.cta_label}</p>
                <p className="mt-3 text-xs font-semibold text-slate-400">Updated {formatDate(banner.updated_at)}</p>
              </div>
              <RowActions onEdit={() => editBanner(banner)} onDelete={() => deleteBanner(banner.id)} />
            </article>
          ))}
          {!banners.length && <EmptyState text="Create your first home banner." />}
        </div>
      </ResourceTable>
    </div>
  )
}
