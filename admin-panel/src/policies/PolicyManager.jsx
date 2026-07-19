import { useState } from 'react'
import { Plus, Save, X } from 'lucide-react'
import { PrimaryButton, SecondaryButton } from '../components/Buttons'
import { EmptyState, ErrorMessage } from '../components/Feedback'
import { TextArea, TextInput, Toggle } from '../components/FormControls'
import { RowActions, StatusBadge } from '../components/ResourceItems'
import { ResourceForm, ResourceTable } from '../components/ResourceLayout'
import { adminApi } from '../services/api'
import { emptyPolicySection, formatDate } from '../utils'

const initialPolicyForm = {
  id: null,
  policyType: 'privacy',
  title: '',
  sections: [emptyPolicySection()],
  isActive: true,
}

export function PolicyManager({ policies, loading, onChanged }) {
  const [form, setForm] = useState(initialPolicyForm)
  const [saving, setSaving] = useState(false)
  const [error, setError] = useState('')

  const resetForm = () => setForm(initialPolicyForm)

  const editPolicy = (policy) =>
    setForm({
      id: policy.id,
      policyType: policy.policy_type,
      title: policy.title,
      sections: policy.sections?.length ? policy.sections : [emptyPolicySection()],
      isActive: policy.is_active,
    })

  const updateSection = (index, field, value) => {
    setForm({
      ...form,
      sections: form.sections.map((section, sectionIndex) =>
        sectionIndex === index ? { ...section, [field]: value } : section,
      ),
    })
  }

  const submit = async (event) => {
    event.preventDefault()
    setError('')
    setSaving(true)

    const payload = {
      policy_type: form.policyType,
      title: form.title.trim(),
      sections: form.sections.map((section) => ({
        title: section.title.trim(),
        body: section.body.trim(),
      })),
      is_active: form.isActive,
    }

    try {
      if (form.id) {
        await adminApi.updatePolicy(form.id, payload)
      } else {
        await adminApi.createPolicy(payload)
      }
      resetForm()
      await onChanged()
    } catch (err) {
      setError(err.message)
    } finally {
      setSaving(false)
    }
  }

  const deletePolicy = async (id) => {
    if (!confirm('Delete this policy page?')) return
    setError('')
    try {
      await adminApi.deletePolicy(id)
      await onChanged()
    } catch (err) {
      setError(err.message)
    }
  }

  return (
    <div className="grid gap-6 xl:grid-cols-[460px_1fr]">
      <ResourceForm
        title={form.id ? 'Edit policy page' : 'Create policy page'}
        onSubmit={submit}
      >
        <ErrorMessage message={error} />
        <label className="block">
          <span className="mb-2 block text-sm font-bold text-slate-700">
            Policy type
          </span>
          <select
            value={form.policyType}
            onChange={(event) =>
              setForm({ ...form, policyType: event.target.value })
            }
            className="w-full rounded-lg border border-slate-300 px-4 py-3 outline-none focus:border-blue-600 focus:ring-4 focus:ring-blue-100"
          >
            <option value="privacy">Privacy Policy</option>
            <option value="terms_and_conditions">Terms and Conditions</option>
          </select>
        </label>

        <TextInput
          label="Title"
          value={form.title}
          onChange={(value) => setForm({ ...form, title: value })}
          required
        />

        <div className="space-y-4">
          <div className="flex items-center justify-between">
            <span className="text-sm font-bold text-slate-700">Sections</span>
            <button
              type="button"
              onClick={() =>
                setForm({
                  ...form,
                  sections: [...form.sections, emptyPolicySection()],
                })
              }
              className="inline-flex items-center gap-1 text-sm font-bold text-blue-700"
            >
              <Plus size={16} /> Add
            </button>
          </div>

          {form.sections.map((section, index) => (
            <div
              key={index}
              className="rounded-lg border border-slate-200 bg-slate-50 p-3"
            >
              <TextInput
                label={`Section ${index + 1} title`}
                value={section.title}
                onChange={(value) => updateSection(index, 'title', value)}
                required
              />
              <div className="mt-3">
                <TextArea
                  label="Body"
                  value={section.body}
                  onChange={(value) => updateSection(index, 'body', value)}
                  required
                />
              </div>
              {form.sections.length > 1 && (
                <button
                  type="button"
                  onClick={() =>
                    setForm({
                      ...form,
                      sections: form.sections.filter(
                        (_, sectionIndex) => sectionIndex !== index,
                      ),
                    })
                  }
                  className="mt-3 text-sm font-bold text-red-600"
                >
                  Remove section
                </button>
              )}
            </div>
          ))}
        </div>

        <Toggle
          label="Active"
          checked={form.isActive}
          onChange={(value) => setForm({ ...form, isActive: value })}
        />
        <div className="flex gap-3">
          <PrimaryButton
            loading={saving}
            label={form.id ? 'Update policy' : 'Create policy'}
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

      <ResourceTable title="Policy pages" loading={loading}>
        <div className="grid gap-4">
          {policies.map((policy) => (
            <article
              key={policy.id}
              className="rounded-xl border border-slate-200 bg-white p-4 shadow-sm"
            >
              <div className="flex flex-col gap-4 md:flex-row md:items-start md:justify-between">
                <div>
                  <div className="flex flex-wrap items-center gap-2">
                    <h3 className="font-black text-slate-950">{policy.title}</h3>
                    <StatusBadge active={policy.is_active} />
                  </div>
                  <p className="mt-2 text-sm font-semibold capitalize text-blue-700">
                    {policy.policy_type.replaceAll('_', ' ')}
                  </p>
                  <p className="mt-2 text-sm text-slate-600">
                    {policy.sections?.length || 0} sections
                  </p>
                  <p className="mt-3 text-xs font-semibold text-slate-400">
                    Updated {formatDate(policy.updated_at)}
                  </p>
                </div>
                <RowActions
                  onEdit={() => editPolicy(policy)}
                  onDelete={() => deletePolicy(policy.id)}
                />
              </div>
            </article>
          ))}
          {!policies.length && <EmptyState text="Create your first policy page." />}
        </div>
      </ResourceTable>
    </div>
  )
}
