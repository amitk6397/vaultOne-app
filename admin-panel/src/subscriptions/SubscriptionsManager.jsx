import { useEffect, useMemo, useState } from 'react'
import {
  CheckCircle2,
  CreditCard,
  Edit3,
  Eye,
  Loader2,
  Plus,
  Save,
  X,
} from 'lucide-react'
import { PrimaryButton, SecondaryButton } from '../components/Buttons'
import { EmptyState, ErrorMessage, SuccessMessage } from '../components/Feedback'
import { TextArea, TextInput, Toggle } from '../components/FormControls'
import { adminApi } from '../services/api'

const emptyPlan = {
  id: null,
  code: '',
  name: '',
  description: '',
  storage_gb: 1,
  price_per_gb: 49,
  billing_days: 30,
  features: '',
  why_purchase: '',
  is_premium: false,
  is_active: true,
  sort_order: 0,
}

const emptyPaymentSettings = {
  upi_id: '',
  receiver_name: '',
  instructions: '',
  payments_enabled: false,
  request_expiry_minutes: 30,
  qr: null,
}

export function SubscriptionsManager({
  plans = [],
  payments = [],
  settings,
  history = [],
  loading = false,
  onChanged,
}) {
  const [paymentTab, setPaymentTab] = useState('pending_verification')
  const [planForm, setPlanForm] = useState(emptyPlan)
  const [paymentForm, setPaymentForm] = useState(emptyPaymentSettings)
  const [showPaymentForm, setShowPaymentForm] = useState(false)
  const [showPlanForm, setShowPlanForm] = useState(false)
  const [savingPayment, setSavingPayment] = useState(false)
  const [savingPlan, setSavingPlan] = useState(false)
  const [reviewingPaymentId, setReviewingPaymentId] = useState(null)
  const [error, setError] = useState('')
  const [success, setSuccess] = useState('')

  const hasPaymentSettings = Boolean(settings?.upi_id?.trim())
  const selectedPayments = payments.filter((item) => item.status === paymentTab)

  const paymentCounts = useMemo(
    () => ({
      pending_verification: payments.filter(
        (item) => item.status === 'pending_verification',
      ).length,
      approved: payments.filter((item) => item.status === 'approved').length,
      rejected: payments.filter((item) => item.status === 'rejected').length,
    }),
    [payments],
  )

  useEffect(() => {
    if (!settings) {
      setPaymentForm(emptyPaymentSettings)
      setShowPaymentForm(true)
      return
    }

    setPaymentForm({
      upi_id: settings.upi_id || '',
      receiver_name: settings.receiver_name || '',
      instructions: settings.instructions || '',
      payments_enabled: Boolean(settings.payments_enabled),
      request_expiry_minutes: settings.request_expiry_minutes || 30,
      qr: null,
    })
    setShowPaymentForm(!settings.upi_id?.trim())
  }, [settings])

  useEffect(() => {
    if (!loading && plans.length === 0) {
      setShowPlanForm(true)
    }
  }, [loading, plans.length])

  const clearMessages = () => {
    setError('')
    setSuccess('')
  }

  const startAddPlan = () => {
    clearMessages()
    setPlanForm(emptyPlan)
    setShowPlanForm(true)
  }

  const startEditPlan = (plan) => {
    clearMessages()
    setPlanForm({
      ...plan,
      price_per_gb: plan.storage_gb ? plan.price_paise / 100 / plan.storage_gb : 0,
      features: Array.isArray(plan.features) ? plan.features.join('\n') : '',
      why_purchase: Array.isArray(plan.why_purchase)
        ? plan.why_purchase.join('\n')
        : '',
    })
    setShowPlanForm(true)
  }

  const submitPlan = async (event) => {
    event.preventDefault()
    clearMessages()
    setSavingPlan(true)

    const payload = {
      code: planForm.code.trim(),
      name: planForm.name.trim(),
      description: planForm.description.trim(),
      storage_gb: Number(planForm.storage_gb),
      price_paise: Math.round(
        Number(planForm.price_per_gb) * Number(planForm.storage_gb) * 100,
      ),
      billing_days: Number(planForm.billing_days),
      features: lines(planForm.features),
      why_purchase: lines(planForm.why_purchase),
      is_premium: Boolean(planForm.is_premium),
      is_active: Boolean(planForm.is_active),
      sort_order: Number(planForm.sort_order || 0),
    }

    try {
      if (planForm.id) {
        await adminApi.updatePlan(planForm.id, payload)
        setSuccess('Plan updated successfully.')
      } else {
        await adminApi.createPlan(payload)
        setSuccess('Plan created successfully.')
      }
      setPlanForm(emptyPlan)
      setShowPlanForm(false)
      await onChanged()
    } catch (err) {
      setError(err.message)
    } finally {
      setSavingPlan(false)
    }
  }

  const savePaymentSettings = async (event) => {
    event.preventDefault()
    clearMessages()
    setSavingPayment(true)

    const formData = new FormData()
    formData.append('upi_id', paymentForm.upi_id.trim())
    formData.append('receiver_name', paymentForm.receiver_name.trim())
    formData.append('instructions', paymentForm.instructions.trim())
    formData.append('payments_enabled', String(paymentForm.payments_enabled))
    formData.append(
      'request_expiry_minutes',
      String(paymentForm.request_expiry_minutes),
    )
    if (paymentForm.qr) {
      formData.append('qr_code', paymentForm.qr)
    }

    try {
      await adminApi.updatePaymentSettings(formData)
      setSuccess('Payment settings saved successfully.')
      setShowPaymentForm(false)
      await onChanged()
    } catch (err) {
      setError(err.message)
    } finally {
      setSavingPayment(false)
    }
  }

  const approve = async (paymentId) => {
    if (!confirm('Approve this verified payment and activate subscription?')) {
      return
    }
    clearMessages()
    setReviewingPaymentId(paymentId)
    try {
      await adminApi.approvePayment(paymentId, 'UPI proof manually verified')
      setSuccess('Payment approved and subscription activated.')
      await onChanged()
    } catch (err) {
      setError(err.message)
    } finally {
      setReviewingPaymentId(null)
    }
  }

  const reject = async (paymentId) => {
    const reason = prompt('Rejection reason shown to user')
    if (!reason) return

    clearMessages()
    setReviewingPaymentId(paymentId)
    try {
      await adminApi.rejectPayment(paymentId, reason)
      setSuccess('Payment rejected.')
      await onChanged()
    } catch (err) {
      setError(err.message)
    } finally {
      setReviewingPaymentId(null)
    }
  }

  const openScreenshot = async (paymentId) => {
    clearMessages()
    try {
      const blob = await adminApi.paymentScreenshot(paymentId)
      window.open(URL.createObjectURL(blob), '_blank', 'noopener,noreferrer')
    } catch (err) {
      setError(err.message)
    }
  }

  return (
    <div className="space-y-6">
      <ErrorMessage message={error} />
      <SuccessMessage message={success} />

      <div className="grid gap-6 xl:grid-cols-[0.95fr_1.05fr]">
        <PaymentSettingsPanel
          form={paymentForm}
          hasSettings={hasPaymentSettings}
          loading={loading}
          saving={savingPayment}
          settings={settings}
          showForm={showPaymentForm}
          onCancel={() => setShowPaymentForm(false)}
          onChange={setPaymentForm}
          onEdit={() => {
            clearMessages()
            setShowPaymentForm(true)
          }}
          onSubmit={savePaymentSettings}
        />

        <PlanPanel
          form={planForm}
          loading={loading}
          plans={plans}
          saving={savingPlan}
          showForm={showPlanForm}
          onAdd={startAddPlan}
          onCancel={() => {
            setPlanForm(emptyPlan)
            setShowPlanForm(false)
          }}
          onChange={setPlanForm}
          onEdit={startEditPlan}
          onSubmit={submitPlan}
        />
      </div>

      <PaymentsPanel
        counts={paymentCounts}
        payments={selectedPayments}
        reviewingPaymentId={reviewingPaymentId}
        tab={paymentTab}
        onApprove={approve}
        onReject={reject}
        onScreenshot={openScreenshot}
        onTabChange={setPaymentTab}
      />

      <HistoryPanel history={history} />
    </div>
  )
}

function PaymentSettingsPanel({
  form,
  hasSettings,
  loading,
  saving,
  settings,
  showForm,
  onCancel,
  onChange,
  onEdit,
  onSubmit,
}) {
  return (
    <section className="rounded-lg border border-slate-200 bg-white p-5 shadow-sm">
      <div className="mb-4 flex items-start justify-between gap-3">
        <div>
          <p className="text-xs font-black uppercase tracking-[0.18em] text-blue-700">
            Payment setup
          </p>
          <h2 className="mt-1 text-xl font-black text-slate-950">
            UPI Payment Settings
          </h2>
        </div>
        {!showForm && (
          <SecondaryButton
            icon={hasSettings ? Edit3 : Plus}
            label={hasSettings ? 'Edit' : 'Add'}
            type="button"
            onClick={onEdit}
          />
        )}
      </div>

      {loading && <LoadingBlock text="Loading payment settings..." />}

      {!loading && !showForm && hasSettings && (
        <div className="space-y-4">
          <div className="grid gap-3 sm:grid-cols-2">
            <Detail label="UPI ID" value={settings.upi_id} />
            <Detail label="Receiver" value={settings.receiver_name} />
            <Detail
              label="Request expiry"
              value={`${settings.request_expiry_minutes} minutes`}
            />
            <Detail
              label="Status"
              value={settings.payments_enabled ? 'Enabled' : 'Disabled'}
            />
          </div>
          <Detail label="Instructions" value={settings.instructions} large />
          <div className="flex items-center gap-2 rounded-lg border border-slate-200 bg-slate-50 px-4 py-3 text-sm font-bold text-slate-700">
            <CheckCircle2 size={17} className="text-emerald-600" />
            QR code {settings.qr_available ? 'uploaded' : 'not uploaded'}
          </div>
        </div>
      )}

      {!loading && !showForm && !hasSettings && (
        <EmptyState text="No payment settings added yet. Add UPI details to enable subscription purchases." />
      )}

      {!loading && showForm && (
        <form onSubmit={onSubmit} className="space-y-4">
          <TextInput
            label="UPI ID"
            required
            value={form.upi_id}
            onChange={(value) => onChange({ ...form, upi_id: value })}
          />
          <TextInput
            label="Receiver name"
            required
            value={form.receiver_name}
            onChange={(value) => onChange({ ...form, receiver_name: value })}
          />
          <TextArea
            label="Payment instructions"
            required
            value={form.instructions}
            onChange={(value) => onChange({ ...form, instructions: value })}
          />
          <TextInput
            label="Request expiry minutes"
            min="5"
            max="1440"
            required
            type="number"
            value={form.request_expiry_minutes}
            onChange={(value) =>
              onChange({ ...form, request_expiry_minutes: Number(value) })
            }
          />
          <label className="block">
            <span className="mb-2 block text-sm font-bold text-slate-700">
              QR code
            </span>
            <input
              accept="image/*"
              className="w-full rounded-lg border border-slate-300 px-4 py-3 text-sm outline-none focus:border-blue-600 focus:ring-4 focus:ring-blue-100"
              type="file"
              onChange={(event) =>
                onChange({ ...form, qr: event.target.files?.[0] || null })
              }
            />
          </label>
          <Toggle
            checked={form.payments_enabled}
            label="Enable UPI payments"
            onChange={(checked) =>
              onChange({ ...form, payments_enabled: checked })
            }
          />
          <div className="flex flex-col gap-3 sm:flex-row">
            <PrimaryButton
              icon={Save}
              label={saving ? 'Saving...' : 'Save payment settings'}
              loading={saving}
            />
            {hasSettings && (
              <SecondaryButton
                icon={X}
                label="Cancel"
                type="button"
                onClick={onCancel}
              />
            )}
          </div>
        </form>
      )}
    </section>
  )
}

function PlanPanel({
  form,
  loading,
  plans,
  saving,
  showForm,
  onAdd,
  onCancel,
  onChange,
  onEdit,
  onSubmit,
}) {
  return (
    <section className="rounded-lg border border-slate-200 bg-white p-5 shadow-sm">
      <div className="mb-4 flex items-start justify-between gap-3">
        <div>
          <p className="text-xs font-black uppercase tracking-[0.18em] text-blue-700">
            Storage plans
          </p>
          <h2 className="mt-1 text-xl font-black text-slate-950">
            Subscription Plans
          </h2>
        </div>
        {!showForm && (
          <SecondaryButton
            icon={Plus}
            label="Add plan"
            type="button"
            onClick={onAdd}
          />
        )}
      </div>

      {loading && <LoadingBlock text="Loading subscription plans..." />}

      {!loading && !showForm && plans.length === 0 && (
        <EmptyState text="No subscription plans added yet. Add your first plan to start selling storage." />
      )}

      {!loading && !showForm && plans.length > 0 && (
        <div className="grid gap-3 sm:grid-cols-2">
          {plans.map((plan) => (
            <button
              key={plan.id}
              className="rounded-lg border border-slate-200 p-4 text-left transition hover:border-blue-300 hover:bg-blue-50"
              type="button"
              onClick={() => onEdit(plan)}
            >
              <div className="flex items-start justify-between gap-3">
                <div>
                  <h3 className="font-black text-slate-950">{plan.name}</h3>
                  <p className="mt-1 text-sm font-semibold text-slate-600">
                    {plan.storage_gb} GB for Rs {plan.price_inr}
                  </p>
                </div>
                <span className="rounded-full bg-slate-100 px-3 py-1 text-xs font-black text-slate-700">
                  {plan.is_active ? 'Active' : 'Inactive'}
                </span>
              </div>
              <p className="mt-3 text-sm text-slate-600">
                {plan.billing_days} days. Rs{' '}
                {(plan.price_inr / plan.storage_gb).toFixed(2)} per GB.
              </p>
              {plan.description && (
                <p className="mt-2 line-clamp-2 text-sm text-slate-500">
                  {plan.description}
                </p>
              )}
              <div className="mt-4 inline-flex items-center gap-2 text-sm font-black text-blue-700">
                <Edit3 size={16} />
                Edit plan
              </div>
            </button>
          ))}
        </div>
      )}

      {!loading && showForm && (
        <form onSubmit={onSubmit} className="space-y-4">
          <div className="grid gap-4 sm:grid-cols-2">
            <TextInput
              label="Code"
              required
              value={form.code}
              onChange={(value) => onChange({ ...form, code: value })}
            />
            <TextInput
              label="Name"
              required
              value={form.name}
              onChange={(value) => onChange({ ...form, name: value })}
            />
            <TextInput
              label="Storage GB"
              min="1"
              required
              type="number"
              value={form.storage_gb}
              onChange={(value) =>
                onChange({ ...form, storage_gb: Number(value) })
              }
            />
            <TextInput
              label="Price per GB"
              min="1"
              required
              type="number"
              value={form.price_per_gb}
              onChange={(value) =>
                onChange({ ...form, price_per_gb: Number(value) })
              }
            />
            <TextInput
              label="Billing days"
              min="1"
              required
              type="number"
              value={form.billing_days}
              onChange={(value) =>
                onChange({ ...form, billing_days: Number(value) })
              }
            />
            <TextInput
              label="Sort order"
              min="0"
              type="number"
              value={form.sort_order}
              onChange={(value) =>
                onChange({ ...form, sort_order: Number(value) })
              }
            />
          </div>
          <TextInput
            label="Description"
            value={form.description}
            onChange={(value) => onChange({ ...form, description: value })}
          />
          <TextArea
            label="Features, one per line"
            value={form.features}
            onChange={(value) => onChange({ ...form, features: value })}
          />
          <TextArea
            label="Why purchase, one per line"
            value={form.why_purchase}
            onChange={(value) => onChange({ ...form, why_purchase: value })}
          />
          <div className="grid gap-3 sm:grid-cols-2">
            <Toggle
              checked={form.is_premium}
              label="Premium plan"
              onChange={(checked) => onChange({ ...form, is_premium: checked })}
            />
            <Toggle
              checked={form.is_active}
              label="Active"
              onChange={(checked) => onChange({ ...form, is_active: checked })}
            />
          </div>
          <div className="flex flex-col gap-3 sm:flex-row">
            <PrimaryButton
              icon={Save}
              label={saving ? 'Saving...' : form.id ? 'Update plan' : 'Save plan'}
              loading={saving}
            />
            <SecondaryButton
              icon={X}
              label="Cancel"
              type="button"
              onClick={onCancel}
            />
          </div>
        </form>
      )}
    </section>
  )
}

function PaymentsPanel({
  counts,
  payments,
  reviewingPaymentId,
  tab,
  onApprove,
  onReject,
  onScreenshot,
  onTabChange,
}) {
  const tabs = [
    ['pending_verification', 'Pending'],
    ['approved', 'Approved'],
    ['rejected', 'Rejected'],
  ]

  return (
    <section className="rounded-lg border border-slate-200 bg-white p-5 shadow-sm">
      <div className="mb-4 flex flex-wrap gap-2">
        {tabs.map(([id, label]) => (
          <button
            key={id}
            className={`rounded-lg px-4 py-2 text-sm font-black ${
              tab === id
                ? 'bg-blue-700 text-white'
                : 'bg-slate-100 text-slate-700 hover:bg-slate-200'
            }`}
            type="button"
            onClick={() => onTabChange(id)}
          >
            {label} ({counts[id] || 0})
          </button>
        ))}
      </div>

      {payments.length === 0 ? (
        <EmptyState text="No payments found in this tab." />
      ) : (
        <div className="overflow-auto">
          <table className="w-full min-w-[820px] text-left text-sm">
            <thead className="text-xs uppercase tracking-[0.12em] text-slate-500">
              <tr>
                <th className="py-3">Order/User</th>
                <th>UTR</th>
                <th>Amount</th>
                <th>Proof</th>
                <th>Status</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {payments.map((payment) => (
                <tr key={payment.id} className="border-t border-slate-100">
                  <td className="py-3">
                    <p className="font-black text-slate-950">
                      {payment.order_id}
                    </p>
                    <p className="text-xs font-semibold text-slate-500">
                      {payment.user_name} - {payment.user_email}
                    </p>
                  </td>
                  <td className="font-semibold">{payment.utr || '-'}</td>
                  <td className="font-semibold">
                    Rs {payment.amount_inr?.toFixed(2)}
                  </td>
                  <td>
                    <button
                      className="inline-flex items-center gap-2 font-black text-blue-700"
                      type="button"
                      onClick={() => onScreenshot(payment.id)}
                    >
                      <Eye size={16} />
                      View
                    </button>
                  </td>
                  <td className="max-w-[220px]">
                    {payment.rejection_reason || payment.status}
                  </td>
                  <td>
                    {payment.status === 'pending_verification' && (
                      <div className="flex flex-wrap gap-2">
                        <button
                          className="rounded-lg bg-emerald-600 px-3 py-2 text-xs font-black text-white disabled:opacity-60"
                          disabled={reviewingPaymentId === payment.id}
                          type="button"
                          onClick={() => onApprove(payment.id)}
                        >
                          {reviewingPaymentId === payment.id
                            ? 'Saving...'
                            : 'Approve'}
                        </button>
                        <button
                          className="rounded-lg bg-red-600 px-3 py-2 text-xs font-black text-white disabled:opacity-60"
                          disabled={reviewingPaymentId === payment.id}
                          type="button"
                          onClick={() => onReject(payment.id)}
                        >
                          Reject
                        </button>
                      </div>
                    )}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </section>
  )
}

function HistoryPanel({ history }) {
  return (
    <section className="rounded-lg border border-slate-200 bg-white p-5 shadow-sm">
      <h2 className="text-xl font-black text-slate-950">Subscription History</h2>
      {history.length === 0 ? (
        <div className="mt-4">
          <EmptyState text="No active subscription history yet." />
        </div>
      ) : (
        <div className="mt-4 grid gap-3 md:grid-cols-2">
          {history.map((item) => (
            <div key={item.id} className="rounded-lg border border-slate-200 p-4">
              <div className="flex items-center gap-2 font-black text-slate-950">
                <CreditCard size={17} />
                User #{item.user_id}
              </div>
              <p className="mt-2 text-sm font-semibold text-slate-600">
                Plan #{item.plan_id} - {item.storage_gb} GB - {item.status}
              </p>
              <p className="mt-1 text-xs font-semibold text-slate-500">
                {dateOnly(item.starts_at)} to {dateOnly(item.expires_at)}
              </p>
            </div>
          ))}
        </div>
      )}
    </section>
  )
}

function Detail({ label, value, large = false }) {
  return (
    <div
      className={`rounded-lg border border-slate-200 bg-slate-50 px-4 py-3 ${
        large ? 'sm:col-span-2' : ''
      }`}
    >
      <p className="text-xs font-black uppercase tracking-[0.12em] text-slate-500">
        {label}
      </p>
      <p className="mt-1 whitespace-pre-wrap break-words text-sm font-bold text-slate-900">
        {value || '-'}
      </p>
    </div>
  )
}

function LoadingBlock({ text }) {
  return (
    <div className="flex items-center gap-3 rounded-lg border border-slate-200 bg-slate-50 px-4 py-6 text-sm font-bold text-slate-600">
      <Loader2 className="animate-spin text-blue-700" size={18} />
      {text}
    </div>
  )
}

function lines(value) {
  return String(value || '')
    .split('\n')
    .map((item) => item.trim())
    .filter(Boolean)
}

function dateOnly(value) {
  return String(value || '').split('T')[0]
}
