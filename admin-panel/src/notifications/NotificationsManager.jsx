import { useMemo, useState } from 'react'
import { BellRing, Send } from 'lucide-react'
import { ErrorMessage, SuccessMessage } from '../components/Feedback'
import { TextArea, TextInput } from '../components/FormControls'
import { ResourceTable } from '../components/ResourceLayout'
import { adminApi } from '../services/api'
import { formatDate } from '../utils'

export function NotificationsManager({ users, history, loading, onChanged }) {
  const [form, setForm] = useState({ title: '', body: '', target: 'all', user_id: '', route: '' })
  const [sending, setSending] = useState(false)
  const [error, setError] = useState('')
  const [success, setSuccess] = useState('')
  const activeUsers = useMemo(() => users.filter((user) => user.is_active), [users])

  const update = (key, value) => setForm((current) => ({ ...current, [key]: value }))
  const submit = async (event) => {
    event.preventDefault()
    setError(''); setSuccess(''); setSending(true)
    try {
      const payload = { ...form, user_id: form.target === 'user' ? Number(form.user_id) : null }
      const response = await adminApi.sendNotification(payload)
      const sent = response.data?.success_count ?? 0
      const failed = response.data?.failure_count ?? 0
      setSuccess(`Notification sent to ${sent} device(s)${failed ? `; ${failed} failed` : ''}.`)
      setForm((current) => ({ ...current, title: '', body: '' }))
      await onChanged()
    } catch (err) { setError(err.message) } finally { setSending(false) }
  }

  return (
    <div className="space-y-6">
      <ResourceTable title="Send push notification" loading={loading}>
        <form onSubmit={submit} className="space-y-4 rounded-xl border border-slate-200 bg-white p-5 shadow-sm">
          <ErrorMessage message={error} /><SuccessMessage message={success} />
          <div className="grid gap-4 md:grid-cols-2">
            <TextInput label="Title" value={form.title} onChange={(value) => update('title', value)} required maxLength={160} />
            <label className="block"><span className="mb-2 block text-sm font-bold text-slate-700">Audience</span>
              <select value={form.target} onChange={(event) => update('target', event.target.value)} className="w-full rounded-lg border border-slate-300 px-4 py-3">
                <option value="all">All users</option><option value="user">Individual user</option>
              </select>
            </label>
          </div>
          {form.target === 'user' && <label className="block"><span className="mb-2 block text-sm font-bold text-slate-700">User</span>
            <select required value={form.user_id} onChange={(event) => update('user_id', event.target.value)} className="w-full rounded-lg border border-slate-300 px-4 py-3">
              <option value="">Select a user</option>{activeUsers.map((user) => <option key={user.id} value={user.id}>{user.full_name} — {user.email}</option>)}
            </select>
          </label>}
          <TextArea label="Message" value={form.body} onChange={(value) => update('body', value)} required maxLength={2000} />
          <TextInput label="App route (optional)" value={form.route} onChange={(value) => update('route', value)} placeholder="/subscriptions" maxLength={160} />
          <button disabled={sending} className="inline-flex items-center gap-2 rounded-lg bg-blue-700 px-5 py-3 text-sm font-black text-white disabled:opacity-60"><Send size={17} />{sending ? 'Sending...' : 'Send notification'}</button>
        </form>
      </ResourceTable>
      <ResourceTable title="Notification history" loading={loading}>
        <div className="divide-y divide-slate-100 overflow-hidden rounded-xl border border-slate-200 bg-white">
          {history.map((item) => <article key={item.id} className="flex gap-3 p-4"><BellRing className="mt-1 shrink-0 text-blue-700" size={19} /><div className="min-w-0 flex-1"><div className="flex flex-wrap items-center justify-between gap-2"><p className="font-black text-slate-950">{item.title}</p><span className="text-xs font-semibold text-slate-500">{formatDate(item.created_at)}</span></div><p className="mt-1 text-sm text-slate-600">{item.body}</p><p className="mt-2 text-xs font-bold uppercase text-slate-500">{item.target_type === 'all' ? 'All users' : `User #${item.target_user_id}`} · {item.success_count} delivered · {item.failure_count} failed · {item.event_type}</p></div></article>)}
          {!history.length && <p className="p-8 text-center text-sm font-semibold text-slate-500">No notifications sent yet.</p>}
        </div>
      </ResourceTable>
    </div>
  )
}
