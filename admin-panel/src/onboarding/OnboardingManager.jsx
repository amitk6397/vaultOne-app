import { useState } from 'react'
import { Save, UploadCloud, X } from 'lucide-react'
import { PrimaryButton, SecondaryButton } from '../components/Buttons'
import { EmptyState, ErrorMessage } from '../components/Feedback'
import { TextArea, TextInput, Toggle } from '../components/FormControls'
import { RowActions, StatusBadge } from '../components/ResourceItems'
import { ResourceForm, ResourceTable } from '../components/ResourceLayout'
import { adminApi } from '../services/api'
import { formatDate, normalizeImageUrl } from '../utils'

const initialOnboardingForm = {
  id: null,
  title: '',
  subtitle: '',
  imageUrl: '',
  imageFile: null,
  isActive: true,
}

export function OnboardingManager({ slides, loading, onChanged }) {
  const [form, setForm] = useState(initialOnboardingForm)
  const [saving, setSaving] = useState(false)
  const [error, setError] = useState('')

  const resetForm = () => setForm(initialOnboardingForm)

  const editSlide = (slide) =>
    setForm({
      id: slide.id,
      title: slide.title,
      subtitle: slide.subtitle,
      imageUrl: slide.image,
      imageFile: null,
      isActive: slide.is_active,
    })

  const submit = async (event) => {
    event.preventDefault()
    setError('')
    setSaving(true)

    const formData = new FormData()
    formData.append('title', form.title.trim())
    formData.append('subtitle', form.subtitle.trim())
    formData.append('is_active', String(form.isActive))
    if (form.imageFile) {
      formData.append('image_file', form.imageFile)
    } else if (form.imageUrl.trim()) {
      formData.append('image_url', form.imageUrl.trim())
    }

    try {
      if (form.id) {
        await adminApi.updateOnboarding(form.id, formData)
      } else {
        await adminApi.createOnboarding(formData)
      }
      resetForm()
      await onChanged()
    } catch (err) {
      setError(err.message)
    } finally {
      setSaving(false)
    }
  }

  const deleteSlide = async (id) => {
    if (!confirm('Delete this onboarding slide?')) return
    setError('')
    try {
      await adminApi.deleteOnboarding(id)
      await onChanged()
    } catch (err) {
      setError(err.message)
    }
  }

  return (
    <div className="grid gap-6 xl:grid-cols-[420px_1fr]">
      <ResourceForm
        title={form.id ? 'Edit onboarding slide' : 'Create onboarding slide'}
        onSubmit={submit}
      >
        <ErrorMessage message={error} />
        <TextInput
          label="Title"
          value={form.title}
          onChange={(value) => setForm({ ...form, title: value })}
          required
        />
        <TextArea
          label="Subtitle"
          value={form.subtitle}
          onChange={(value) => setForm({ ...form, subtitle: value })}
          required
        />
        <TextInput
          label="Image URL"
          value={form.imageUrl}
          onChange={(value) =>
            setForm({ ...form, imageUrl: value, imageFile: null })
          }
          placeholder="https://..."
        />
        <label className="block">
          <span className="mb-2 flex items-center gap-2 text-sm font-bold text-slate-700">
            <UploadCloud size={16} /> Upload image
          </span>
          <input
            type="file"
            accept="image/png,image/jpeg,image/webp"
            onChange={(event) =>
              setForm({
                ...form,
                imageFile: event.target.files?.[0] || null,
                imageUrl: '',
              })
            }
            className="w-full rounded-lg border border-dashed border-slate-300 bg-slate-50 px-3 py-3 text-sm"
          />
        </label>
        <Toggle
          label="Active"
          checked={form.isActive}
          onChange={(value) => setForm({ ...form, isActive: value })}
        />
        <div className="flex gap-3">
          <PrimaryButton
            loading={saving}
            label={form.id ? 'Update slide' : 'Create slide'}
            icon={Save}
          />
          {form.id && (
            <SecondaryButton
              type="button"
              label="Cancel"
              onClick={resetForm}
              icon={X}
            />
          )}
        </div>
      </ResourceForm>

      <ResourceTable title="Onboarding slides" loading={loading}>
        <div className="grid gap-4">
          {slides.map((slide) => (
            <article
              key={slide.id}
              className="grid gap-4 rounded-xl border border-slate-200 bg-white p-4 shadow-sm md:grid-cols-[130px_1fr_auto]"
            >
              <img
                src={normalizeImageUrl(slide.image)}
                alt={slide.title}
                className="h-28 w-full rounded-lg object-cover md:w-32"
              />
              <div>
                <div className="flex flex-wrap items-center gap-2">
                  <h3 className="font-black text-slate-950">{slide.title}</h3>
                  <StatusBadge active={slide.is_active} />
                </div>
                <p className="mt-2 text-sm leading-6 text-slate-600">
                  {slide.subtitle}
                </p>
                <p className="mt-3 text-xs font-semibold text-slate-400">
                  Updated {formatDate(slide.updated_at)}
                </p>
              </div>
              <RowActions
                onEdit={() => editSlide(slide)}
                onDelete={() => deleteSlide(slide.id)}
              />
            </article>
          ))}
          {!slides.length && <EmptyState text="Create your first onboarding slide." />}
        </div>
      </ResourceTable>
    </div>
  )
}
