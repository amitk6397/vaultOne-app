import { useEffect, useState } from 'react'
import { Loader2, RefreshCcw, ShieldCheck } from 'lucide-react'
import { adminApi } from '../services/api'

const bytes = (value = 0) => {
  if (value < 1024 * 1024) return '${(value / 1024).toFixed(1)} KB'
  if (value < 1024 * 1024 * 1024) return '${(value / 1024 / 1024).toFixed(1)} MB'
  return '${(value / 1024 / 1024 / 1024).toFixed(2)} GB'
}

export function VaultConnectManager({ users = [] }) {
  const [overview, setOverview] = useState(null)
  const [config, setConfig] = useState(null)
  const [reports, setReports] = useState([])
  const [accessUsers, setAccessUsers] = useState([])
  const [error, setError] = useState('')
  const [busy, setBusy] = useState(false)
  const [pendingAction, setPendingAction] = useState('')

  const load = async () => {
    setError('')
    try {
      const [summary, settings, reportRows, userRows] = await Promise.all([
        adminApi.vaultConnectOverview(),
        adminApi.vaultConnectConfig(),
        adminApi.vaultConnectReports(),
        adminApi.vaultConnectUsers(),
      ])
      setOverview(summary.data)
      setConfig(settings.data)
      setReports(reportRows.data || [])
      setAccessUsers(userRows.data || users.map((user) => ({...user, is_enabled: true})))
    } catch (err) {
      setError(err.message)
    }
  }

  useEffect(() => { load() }, [])

  const saveConfig = async () => {
    setBusy(true)
    try {
      await adminApi.updateVaultConnectConfig({
        ...config,
        image_limit_bytes: Number(config.image_limit_bytes),
        video_limit_bytes: Number(config.video_limit_bytes),
        document_limit_bytes: Number(config.document_limit_bytes),
        contact_batch_limit: Number(config.contact_batch_limit),
        message_rate_limit: Number(config.message_rate_limit),
        delete_for_everyone_seconds: Number(config.delete_for_everyone_seconds),
      })
      await load()
    } catch (err) { setError(err.message) } finally { setBusy(false) }
  }

  const updateAccess = async (userId, isEnabled) => {
    const actionKey = `access-${userId}`
    setPendingAction(actionKey)
    setError('')
    try {
      const response = await adminApi.setVaultConnectAccess(userId, {
        is_enabled: isEnabled,
      })
      setAccessUsers((current) =>
        current.map((user) =>
          user.id === userId ? {...user, ...response.data} : user,
        ),
      )
    } catch (err) {
      setError(err.message)
    } finally {
      setPendingAction('')
    }
  }

  const revokeSessions = async (userId) => {
    const actionKey = `sessions-${userId}`
    setPendingAction(actionKey)
    setError('')
    try {
      await adminApi.revokeVaultConnectSessions(userId)
    } catch (err) {
      setError(err.message)
    } finally {
      setPendingAction('')
    }
  }

  if (!overview || !config) return <div className="rounded-xl bg-white p-8">Loading Vault Connect…</div>

  const cards = [
    ['Chat users', overview.total_chat_users],
    ['Conversations', overview.conversations_count],
    ['Messages', overview.messages_count],
    ['Files shared', overview.files_shared],
    ['Storage', bytes(overview.storage_usage)],
    ['Failed uploads', overview.failed_uploads],
    ['Pending reports', overview.pending_reports],
    ['Blocks', overview.blocked_user_statistics?.total_blocks || 0],
  ]

  return <section className="space-y-6">
    <div className="flex items-center justify-between">
      <div>
        <p className="text-sm font-bold uppercase tracking-widest text-blue-700">Private messaging operations</p>
        <h2 className="text-2xl font-black text-slate-950">Vault Connect</h2>
        <p className="text-sm text-slate-500">Private message content and files are never exposed in this console.</p>
      </div>
      <button onClick={load} className="rounded-lg border bg-white p-3"><RefreshCcw size={18}/></button>
    </div>
    {error && <div className="rounded-lg bg-red-50 p-3 font-semibold text-red-700">{error}</div>}

    <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-4">
      {cards.map(([label, value]) => <div key={label} className="rounded-xl border bg-white p-4 shadow-sm">
        <p className="text-xs font-bold uppercase tracking-wider text-slate-500">{label}</p>
        <p className="mt-2 text-2xl font-black text-slate-950">{value}</p>
      </div>)}
    </div>

    <div className="rounded-xl border bg-white p-5 shadow-sm">
      <h3 className="text-lg font-black">Security and limit configuration</h3>
      <div className="mt-4 grid gap-4 md:grid-cols-3">
        {[
          ['image_limit_bytes', 'Image limit (bytes)'],
          ['video_limit_bytes', 'Video limit (bytes)'],
          ['document_limit_bytes', 'Document limit (bytes)'],
          ['contact_batch_limit', 'Contact batch limit'],
          ['message_rate_limit', 'Messages/minute'],
          ['delete_for_everyone_seconds', 'Delete window (seconds)'],
        ].map(([key, label]) => <label key={key} className="text-sm font-bold text-slate-700">
          {label}
          <input type="number" value={config[key]} onChange={(event) => setConfig({...config, [key]: event.target.value})} className="mt-1 w-full rounded-lg border px-3 py-2"/>
        </label>)}
      </div>
      <button disabled={busy} onClick={saveConfig} className="mt-4 rounded-lg bg-blue-700 px-4 py-2 font-bold text-white disabled:opacity-50">Save configuration</button>
      <button disabled={busy} onClick={async () => { setBusy(true); try { await adminApi.runVaultConnectCleanup(); await load() } finally { setBusy(false) } }} className="ml-3 rounded-lg border px-4 py-2 font-bold">Run cleanup now</button>
    </div>

    <div className="rounded-xl border bg-white p-5 shadow-sm">
      <h3 className="text-lg font-black">Reports</h3>
      <p className="text-sm text-slate-500">Only evidence explicitly included by the reporter is shown.</p>
      <div className="mt-3 space-y-3">
        {reports.length === 0 && <p className="py-5 text-center text-slate-500">No reports</p>}
        {reports.map((report) => <div key={report.id} className="rounded-lg border p-4">
          <div className="flex flex-wrap items-center justify-between gap-2">
            <strong>{report.category.replaceAll('_', ' ')}</strong>
            <select value={report.status} onChange={async (event) => { await adminApi.updateVaultConnectReport(report.id, {status: event.target.value, admin_notes: report.admin_notes || ''}); await load() }} className="rounded-lg border px-2 py-1">
              {['pending','reviewing','resolved','dismissed'].map((x) => <option key={x}>{x}</option>)}
            </select>
          </div>
          <p className="mt-2 text-sm text-slate-700">{report.description || 'No description provided'}</p>
          {report.evidence && <pre className="mt-2 max-h-40 overflow-auto rounded bg-slate-50 p-2 text-xs">{JSON.stringify(report.evidence, null, 2)}</pre>}
        </div>)}
      </div>
    </div>

    <div className="rounded-xl border bg-white p-5 shadow-sm">
      <h3 className="flex items-center gap-2 text-lg font-black"><ShieldCheck size={20}/> User access & sessions</h3>
      <div className="mt-3 max-h-96 divide-y overflow-auto">
        {accessUsers.map((user) => <div key={user.id} className="flex flex-wrap items-center justify-between gap-3 py-3">
          <div>
            <div className="flex flex-wrap items-center gap-2">
              <strong>{user.full_name}</strong>
              <span className={`rounded-full px-2.5 py-1 text-[11px] font-black uppercase tracking-wide ${user.is_enabled ? 'bg-emerald-100 text-emerald-700' : 'bg-red-100 text-red-700'}`}>
                {user.is_enabled ? 'Enabled' : 'Disabled'}
              </span>
            </div>
            <p className="text-xs text-slate-500">{user.phone}</p>
          </div>
          <div className="flex flex-wrap gap-2">
            <button
              disabled={pendingAction === `access-${user.id}` || user.is_enabled}
              onClick={() => updateAccess(user.id, true)}
              className="rounded-lg bg-emerald-50 px-3 py-2 text-sm font-bold text-emerald-700 disabled:cursor-not-allowed disabled:opacity-40"
            >
              {pendingAction === `access-${user.id}` ? <Loader2 className="animate-spin" size={16}/> : 'Enable'}
            </button>
            <button
              disabled={pendingAction === `access-${user.id}` || !user.is_enabled}
              onClick={() => updateAccess(user.id, false)}
              className="rounded-lg bg-red-50 px-3 py-2 text-sm font-bold text-red-700 disabled:cursor-not-allowed disabled:opacity-40"
            >
              {pendingAction === `access-${user.id}` ? <Loader2 className="animate-spin" size={16}/> : 'Disable'}
            </button>
            <button
              disabled={pendingAction === `sessions-${user.id}`}
              onClick={() => revokeSessions(user.id)}
              className="inline-flex items-center gap-2 rounded-lg bg-slate-100 px-3 py-2 text-sm font-bold text-slate-700 disabled:opacity-50"
            >
              {pendingAction === `sessions-${user.id}` && <Loader2 className="animate-spin" size={16}/>}
              Revoke device sessions
            </button>
          </div>
        </div>)}
      </div>
    </div>
  </section>
}
