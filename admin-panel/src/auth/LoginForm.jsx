import { useState } from 'react'
import { Lock, Mail } from 'lucide-react'
import { PrimaryButton } from '../components/Buttons'
import { ErrorMessage } from '../components/Feedback'
import { Field } from '../components/FormControls'
import { adminApi } from '../services/api'

export function LoginForm({ onAuthenticated, onForgot }) {
  const [form, setForm] = useState({ email: '', password: '' })
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(false)

  const submit = async (event) => {
    event.preventDefault()
    setError('')
    setLoading(true)
    try {
      const response = await adminApi.login({
        email: form.email.trim().toLowerCase(),
        password: form.password,
      })
      onAuthenticated(response.data.access_token, response.data.refresh_token)
    } catch (err) {
      setError(err.message)
    } finally {
      setLoading(false)
    }
  }

  return (
    <form onSubmit={submit} className="space-y-5">
      <div>
        <p className="text-sm font-bold uppercase tracking-[0.18em] text-blue-600">
          Welcome back
        </p>
        <h2 className="mt-2 text-2xl font-black text-slate-950">Admin login</h2>
      </div>

      <Field label="Email address" icon={Mail}>
        <input
          type="email"
          required
          autoComplete="email"
          value={form.email}
          onChange={(event) => setForm({ ...form, email: event.target.value })}
          className="w-full rounded-lg border border-slate-300 px-4 py-3 outline-none focus:border-blue-600 focus:ring-4 focus:ring-blue-100"
          placeholder="admin@vaultone.app"
        />
      </Field>

      <Field label="Password" icon={Lock}>
        <input
          type="password"
          required
          minLength={8}
          autoComplete="current-password"
          value={form.password}
          onChange={(event) => setForm({ ...form, password: event.target.value })}
          className="w-full rounded-lg border border-slate-300 px-4 py-3 outline-none focus:border-blue-600 focus:ring-4 focus:ring-blue-100"
          placeholder="Enter password"
        />
      </Field>

      <button
        type="button"
        onClick={onForgot}
        className="text-sm font-bold text-blue-700 hover:text-blue-900"
      >
        Forgot password?
      </button>

      <ErrorMessage message={error} />
      <PrimaryButton loading={loading} label="Sign in securely" />
    </form>
  )
}
