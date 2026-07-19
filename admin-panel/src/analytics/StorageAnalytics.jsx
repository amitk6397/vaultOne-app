import { useMemo, useState } from 'react'
import { BarChart3, Database, Gift, HardDrive, Search, Users } from 'lucide-react'
import { ErrorMessage, EmptyState } from '../components/Feedback'
import { adminApi } from '../services/api'

const MB = 1024 * 1024
const moduleColors = { files: '#2563eb', documents: '#7c3aed', media: '#0d9488' }
const bytes = (value = 0) => {
  if (value >= 1024 ** 3) return `${(value / 1024 ** 3).toFixed(2)} GB`
  return `${(value / MB).toFixed(value < MB ? 2 : 1)} MB`
}

export function StorageAnalytics({ analytics, plans, loading, onChanged }) {
  const [query, setQuery] = useState('')
  const [selected, setSelected] = useState(null)
  const [error, setError] = useState('')
  const [saving, setSaving] = useState(false)
  const [limitMb, setLimitMb] = useState('')
  const [offer, setOffer] = useState({ title: '', description: '', plan_id: '', discount_percent: 0, offer_price_paise: '', expires_at: '' })
  const users = useMemo(() => analytics?.users || [], [analytics])
  const summary = analytics?.summary || {}
  const filtered = useMemo(() => users.filter(({ user }) => `${user.full_name} ${user.email} ${user.phone}`.toLowerCase().includes(query.toLowerCase())), [users, query])

  const openUser = async (row) => {
    setError(''); setSelected(row); setLimitMb(Math.round(row.limit_bytes / MB).toString())
    try { const response = await adminApi.userAnalytics(row.user.id); setSelected(response.data) } catch (err) { setError(err.message) }
  }
  const saveLimit = async (reset = false) => {
    if (!selected) return
    setSaving(true); setError('')
    try { await adminApi.setStorageLimit(selected.user.id, reset ? null : Number(limitMb)); await onChanged(); setSelected(null) } catch (err) { setError(err.message) } finally { setSaving(false) }
  }
  const sendOffer = async (event) => {
    event.preventDefault(); if (!selected) return
    setSaving(true); setError('')
    try {
      await adminApi.createOffer({ user_id: selected.user.id, title: offer.title, description: offer.description, plan_id: offer.plan_id ? Number(offer.plan_id) : null, discount_percent: Number(offer.discount_percent), offer_price_paise: offer.offer_price_paise ? Number(offer.offer_price_paise) : null, expires_at: new Date(offer.expires_at).toISOString() })
      setOffer({ title: '', description: '', plan_id: '', discount_percent: 0, offer_price_paise: '', expires_at: '' }); await onChanged(); setSelected(null)
    } catch (err) { setError(err.message) } finally { setSaving(false) }
  }

  return <div className="space-y-6">
    <ErrorMessage message={error} />
    <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
      <Metric icon={Users} label="Total users" value={summary.total_users ?? '-'} />
      <Metric icon={Database} label="Database storage" value={bytes(summary.total_used_bytes)} />
      <Metric icon={HardDrive} label="At storage limit" value={summary.users_at_limit ?? '-'} danger />
      <Metric icon={BarChart3} label="Above 80%" value={summary.users_above_80_percent ?? '-'} />
    </div>

    <section className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm">
      <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
        <div><h2 className="text-xl font-black text-slate-950">Live user storage</h2><p className="mt-1 text-sm text-slate-500">Database records only; device-local data is excluded.</p></div>
        <label className="relative"><Search className="absolute left-3 top-3 text-slate-400" size={18}/><input value={query} onChange={e => setQuery(e.target.value)} placeholder="Search users" className="rounded-lg border border-slate-300 py-2.5 pl-10 pr-3 outline-none focus:border-blue-600"/></label>
      </div>
      <div className="mt-5 space-y-3">
        {filtered.map(row => <button key={row.user.id} onClick={() => openUser(row)} className="grid w-full gap-4 rounded-xl border border-slate-200 p-4 text-left hover:border-blue-300 hover:bg-blue-50/30 lg:grid-cols-[1.2fr_1fr_1.4fr_auto] lg:items-center">
          <div><p className="font-black text-slate-950">{row.user.full_name}</p><p className="text-xs text-slate-500">{row.user.email}</p></div>
          <div><p className="text-sm font-bold">{bytes(row.used_bytes)} / {bytes(row.limit_bytes)}</p><p className="text-xs capitalize text-slate-500">{row.limit_source.replace('_', ' ')}</p></div>
          <UsageBar row={row}/>
          <span className={`rounded-full px-3 py-1 text-xs font-black ${row.usage_percent >= 100 ? 'bg-red-100 text-red-700' : row.usage_percent >= 80 ? 'bg-amber-100 text-amber-700' : 'bg-emerald-100 text-emerald-700'}`}>{row.usage_percent}%</span>
        </button>)}
        {!loading && !filtered.length && <EmptyState text="No analytics found."/>}
      </div>
    </section>

    {selected && <div className="fixed inset-0 z-50 grid place-items-center bg-slate-950/55 p-4" onMouseDown={e => e.target === e.currentTarget && setSelected(null)}>
      <div className="max-h-[92vh] w-full max-w-3xl overflow-y-auto rounded-2xl bg-white p-6 shadow-2xl">
        <div className="flex justify-between gap-4"><div><h3 className="text-2xl font-black">{selected.user.full_name}</h3><p className="text-sm text-slate-500">{selected.user.email}</p></div><button onClick={() => setSelected(null)} className="h-10 rounded-lg border px-4 font-bold">Close</button></div>
        <div className="mt-6 grid gap-3 sm:grid-cols-3">{Object.entries(selected.module_bytes || {}).map(([name, value]) => <div key={name} className="rounded-xl bg-slate-50 p-4"><p className="text-xs font-black uppercase text-slate-500">{name}</p><p className="mt-2 text-xl font-black">{bytes(value)}</p><p className="text-xs text-slate-500">{selected.module_counts?.[name] || 0} records</p></div>)}</div>
        <div className="mt-6 rounded-xl border border-slate-200 p-4"><h4 className="font-black">Storage limit</h4><div className="mt-3 flex flex-wrap gap-2"><input type="number" min="1" value={limitMb} onChange={e => setLimitMb(e.target.value)} className="min-w-0 flex-1 rounded-lg border px-3 py-2" placeholder="Limit in MB"/><button disabled={saving} onClick={() => saveLimit(false)} className="rounded-lg bg-blue-700 px-4 py-2 font-bold text-white">Save limit</button><button disabled={saving} onClick={() => saveLimit(true)} className="rounded-lg border px-4 py-2 font-bold">Use plan/default</button></div></div>
        <form onSubmit={sendOffer} className="mt-6 rounded-xl border border-violet-200 bg-violet-50/40 p-4"><h4 className="flex items-center gap-2 font-black"><Gift size={18}/> Send in-app offer</h4><div className="mt-3 grid gap-3 sm:grid-cols-2"><input required value={offer.title} onChange={e => setOffer({...offer, title:e.target.value})} className="rounded-lg border px-3 py-2" placeholder="Offer title"/><select value={offer.plan_id} onChange={e => setOffer({...offer, plan_id:e.target.value})} className="rounded-lg border px-3 py-2"><option value="">Any plan</option>{plans.map(p => <option key={p.id} value={p.id}>{p.name}</option>)}</select><input type="number" min="0" max="100" value={offer.discount_percent} onChange={e => setOffer({...offer, discount_percent:e.target.value})} className="rounded-lg border px-3 py-2" placeholder="Discount %"/><input type="number" min="0" value={offer.offer_price_paise} onChange={e => setOffer({...offer, offer_price_paise:e.target.value})} className="rounded-lg border px-3 py-2" placeholder="Offer price (paise)"/><input required type="datetime-local" value={offer.expires_at} onChange={e => setOffer({...offer, expires_at:e.target.value})} className="rounded-lg border px-3 py-2 sm:col-span-2"/><textarea value={offer.description} onChange={e => setOffer({...offer, description:e.target.value})} className="rounded-lg border px-3 py-2 sm:col-span-2" placeholder="Offer message"/><button disabled={saving} className="rounded-lg bg-violet-700 px-4 py-2.5 font-black text-white sm:col-span-2">Send offer</button></div></form>
      </div>
    </div>}
  </div>
}

function Metric({ icon: Icon, label, value, danger }) { return <div className="rounded-xl border border-slate-200 bg-white p-5 shadow-sm"><div className="flex items-center justify-between"><div><p className="text-sm font-semibold text-slate-500">{label}</p><p className={`mt-2 text-2xl font-black ${danger ? 'text-red-600' : 'text-slate-950'}`}>{value}</p></div><div className="rounded-xl bg-blue-50 p-3 text-blue-700"><Icon size={22}/></div></div></div> }
function UsageBar({ row }) { const total = Math.max(1, row.used_bytes); return <div><div className="mb-1 flex justify-between text-[11px] font-bold text-slate-500"><span>Module usage</span><span>{row.module_counts?.passwords || 0} passwords · {row.module_counts?.secure_notes || 0} notes</span></div><div className="flex h-3 overflow-hidden rounded-full bg-slate-100">{Object.entries(row.module_bytes || {}).map(([key,value]) => <span key={key} title={`${key}: ${bytes(value)}`} style={{width:`${value / total * 100}%`, background:moduleColors[key]}}/>)}</div></div> }
