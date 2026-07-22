import { useState } from 'react'
import { CheckCircle2, Clock3, Trash2, XCircle } from 'lucide-react'
import { adminApi } from '../services/api'

const reasonLabels = {
  privacy: 'Privacy or data concerns',
  not_using: 'No longer using VaultOne',
  too_expensive: 'Subscription too expensive',
  technical_issues: 'Technical issues',
  switching_service: 'Switching to another service',
  other: 'Other reason',
}

export function AccountDeletionManager({ requests, loading, onChanged }) {
  const [busyId, setBusyId] = useState(null)

  const review = async (item, decision) => {
    const message = decision === 'approve'
      ? 'Approving permanently deletes this user and their associated data. Type an optional admin note:'
      : 'Enter the reason for rejecting this request:'
    const note = window.prompt(message, '')
    if (note === null || (decision === 'reject' && note.trim().length < 3)) return
    setBusyId(item.id)
    try {
      await adminApi.reviewDeletionRequest(item.id, decision, note.trim())
      await onChanged()
    } finally {
      setBusyId(null)
    }
  }

  if (loading) return <div className="rounded-2xl bg-white p-8 text-slate-500">Loading deletion requests…</div>

  return (
    <section>
      <div className="mb-5">
        <p className="text-sm font-bold uppercase tracking-[0.18em] text-rose-700">Account safety</p>
        <h2 className="mt-1 text-2xl font-black text-slate-950">Deletion requests</h2>
        <p className="mt-1 text-sm text-slate-500">Review user reasons before permanently deleting an account.</p>
      </div>
      <div className="grid gap-4">
        {requests.length === 0 && <div className="rounded-2xl border border-dashed bg-white p-10 text-center text-slate-500">No deletion requests.</div>}
        {requests.map((item) => (
          <article key={item.id} className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm">
            <div className="flex flex-col gap-4 md:flex-row md:items-start md:justify-between">
              <div>
                <div className="flex items-center gap-2">
                  <h3 className="font-black text-slate-950">{item.user_name}</h3>
                  <Status status={item.status} />
                </div>
                <p className="text-sm text-slate-500">{item.user_email}</p>
                <p className="mt-3 font-bold text-slate-800">{reasonLabels[item.reason_code] || item.reason_code}</p>
                {item.reason_text && <p className="mt-1 whitespace-pre-wrap text-sm text-slate-600">{item.reason_text}</p>}
                <p className="mt-3 text-xs text-slate-400">Requested {new Date(item.created_at).toLocaleString()}</p>
                {item.admin_note && <p className="mt-2 rounded-lg bg-slate-50 p-3 text-sm"><strong>Admin note:</strong> {item.admin_note}</p>}
              </div>
              {item.status === 'pending' && (
                <div className="flex gap-2">
                  <button disabled={busyId === item.id} onClick={() => review(item, 'reject')} className="rounded-lg border border-slate-300 px-4 py-2 text-sm font-bold text-slate-700 hover:bg-slate-50">Reject</button>
                  <button disabled={busyId === item.id} onClick={() => review(item, 'approve')} className="inline-flex items-center gap-2 rounded-lg bg-rose-600 px-4 py-2 text-sm font-bold text-white hover:bg-rose-700"><Trash2 size={16}/>Approve & delete</button>
                </div>
              )}
            </div>
          </article>
        ))}
      </div>
    </section>
  )
}

function Status({ status }) {
  const config = status === 'approved'
    ? [CheckCircle2, 'Approved', 'bg-emerald-100 text-emerald-700']
    : status === 'rejected'
      ? [XCircle, 'Rejected', 'bg-slate-100 text-slate-600']
      : [Clock3, 'Pending', 'bg-amber-100 text-amber-700']
  const Icon = config[0]
  return <span className={`inline-flex items-center gap-1 rounded-full px-2 py-1 text-xs font-bold ${config[2]}`}><Icon size={13}/>{config[1]}</span>
}
