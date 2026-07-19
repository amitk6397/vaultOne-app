import { useState } from 'react'
import { Mail } from 'lucide-react'
import { PrimaryButton } from '../components/Buttons'
import { ErrorMessage, SuccessMessage } from '../components/Feedback'
import { Field } from '../components/FormControls'
import { adminApi } from '../services/api'

export function ForgotPasswordForm({ onBack }) {
  const [step, setStep] = useState('request')
  const [form, setForm] = useState({
    email: '',
    otp: '',
    password: '',
    confirmPassword: '',
  })
  const [message, setMessage] = useState('')
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(false)

  const requestOtp = async (event) => {
    event.preventDefault()
    setError('')
    setLoading(true)
    try {
      const response = await adminApi.forgotPassword({
        email: form.email.trim().toLowerCase(),
      })
      setMessage(response.message)
      setStep('reset')
    } catch (err) {
      setError(err.message)
    } finally {
      setLoading(false)
    }
  }

  const resetPassword = async (event) => {
    event.preventDefault()
    setError('')
    setLoading(true)
    try {
      const response = await adminApi.resetPassword({
        email: form.email.trim().toLowerCase(),
        otp: form.otp.trim(),
        password: form.password,
        confirm_password: form.confirmPassword,
      })
      setMessage(response.message)
      setTimeout(onBack, 900)
    } catch (err) {
      setError(err.message)
    } finally {
      setLoading(false)
    }
  }

  return (
    <form
      onSubmit={step === 'request' ? requestOtp : resetPassword}
      className="space-y-5"
    >
      <div>
        <p className="text-sm font-bold uppercase tracking-[0.18em] text-blue-600">
          Account recovery
        </p>
        <h2 className="mt-2 text-2xl font-black text-slate-950">
          Reset admin password
        </h2>
      </div>

      <Field label="Admin email" icon={Mail}>
        <input
          type="email"
          required
          disabled={step === 'reset'}
          value={form.email}
          onChange={(event) => setForm({ ...form, email: event.target.value })}
          className="w-full rounded-lg border border-slate-300 px-4 py-3 outline-none focus:border-blue-600 focus:ring-4 focus:ring-blue-100 disabled:bg-slate-100"
          placeholder="admin@vaultone.app"
        />
      </Field>

      {step === 'reset' && (
        <>
          <Field label="OTP">
            <input
              required
              minLength={6}
              maxLength={6}
              value={form.otp}
              onChange={(event) => setForm({ ...form, otp: event.target.value })}
              className="w-full rounded-lg border border-slate-300 px-4 py-3 outline-none focus:border-blue-600 focus:ring-4 focus:ring-blue-100"
              placeholder="6 digit OTP"
            />
          </Field>
          <Field label="New password">
            <input
              type="password"
              required
              minLength={8}
              value={form.password}
              onChange={(event) =>
                setForm({ ...form, password: event.target.value })
              }
              className="w-full rounded-lg border border-slate-300 px-4 py-3 outline-none focus:border-blue-600 focus:ring-4 focus:ring-blue-100"
              placeholder="New password"
            />
          </Field>
          <Field label="Confirm password">
            <input
              type="password"
              required
              minLength={8}
              value={form.confirmPassword}
              onChange={(event) =>
                setForm({ ...form, confirmPassword: event.target.value })
              }
              className="w-full rounded-lg border border-slate-300 px-4 py-3 outline-none focus:border-blue-600 focus:ring-4 focus:ring-blue-100"
              placeholder="Confirm password"
            />
          </Field>
        </>
      )}

      <SuccessMessage message={message} />
      <ErrorMessage message={error} />
      <PrimaryButton
        loading={loading}
        label={step === 'request' ? 'Send reset OTP' : 'Reset password'}
      />
      <button
        type="button"
        onClick={onBack}
        className="w-full rounded-lg border border-slate-300 px-4 py-3 text-sm font-bold text-slate-700 hover:bg-slate-50"
      >
        Back to login
      </button>
    </form>
  )
}
