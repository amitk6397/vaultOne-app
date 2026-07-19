import { useEffect, useMemo, useState } from 'react'
import {
  Activity, ArrowRight, Ban, CheckCircle2, FileKey2, Files,
  FolderLock, Image, ShieldCheck, StickyNote, UserPlus, Users, LogIn, LogOut,
} from 'lucide-react'
import {
  Cell, Pie, PieChart, ResponsiveContainer, Tooltip,
} from 'recharts'
import { ErrorMessage, EmptyState } from '../components/Feedback'
import { adminApi } from '../services/api'
import { formatDate } from '../utils'

const periods = [
  { id: 'day', label: 'Today' },
  { id: 'week', label: 'Week' },
  { id: 'month', label: 'Month' },
  { id: 'year', label: 'Year' },
]

const modules = [
  { id: 'files', label: 'Files', icon: Files, color: '#2563eb' },
  { id: 'documents', label: 'Documents', icon: FolderLock, color: '#7c3aed' },
  { id: 'media', label: 'Media', icon: Image, color: '#0d9488' },
  { id: 'passwords', label: 'Passwords', icon: FileKey2, color: '#e11d48' },
  { id: 'secure_notes', label: 'Secure notes', icon: StickyNote, color: '#d97706' },
]

export function Overview({ users, loading: appLoading, onNavigate, refreshVersion = 0 }) {
  const [period, setPeriod] = useState('week')
  const [data, setData] = useState(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')

  useEffect(() => {
    let active = true
    adminApi.overviewAnalytics(period)
      .then((response) => { if (active) setData(response.data || null) })
      .catch((err) => { if (active) setError(err.message) })
      .finally(() => { if (active) setLoading(false) })
    return () => { active = false }
  }, [period, refreshVersion])

  const summary = data?.summary || {}
  const timeline = useMemo(() => data?.timeline || [], [data])
  const periodName = periods.find((item) => item.id === period)?.label
  const changePeriod = (nextPeriod) => {
    if (nextPeriod === period) return
    setLoading(true)
    setError('')
    setPeriod(nextPeriod)
  }

  return <div className="space-y-6">
    <ErrorMessage message={error} />

    <section className="overflow-hidden rounded-3xl bg-gradient-to-br from-slate-950 via-blue-950 to-blue-800 text-white shadow-xl shadow-blue-950/15">
      <div className="grid gap-7 p-6 sm:p-8 lg:grid-cols-[1fr_auto] lg:items-end">
        <div>
          <div className="inline-flex items-center gap-2 rounded-full border border-white/15 bg-white/10 px-3 py-1.5 text-xs font-black uppercase tracking-[0.16em] text-blue-100"><Activity size={15}/> Live user intelligence</div>
          <h2 className="mt-5 max-w-2xl text-3xl font-black tracking-tight sm:text-4xl">Understand user growth and module activity in real time.</h2>
          <p className="mt-3 max-w-2xl text-sm leading-6 text-blue-100/80">Every number and graph comes directly from VaultOne database records. Last synced {data?.generated_at ? formatDate(data.generated_at) : 'now'}.</p>
        </div>
        <button type="button" onClick={() => onNavigate('users')} className="inline-flex items-center justify-center gap-2 rounded-xl bg-white px-5 py-3 text-sm font-black text-blue-900 shadow-lg hover:bg-blue-50">Manage users <ArrowRight size={17}/></button>
      </div>
    </section>

    <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-5">
      <Stat label="Total users" value={summary.total_users} icon={Users} tone="blue" loading={loading}/>
      <Stat label="Active users" value={summary.active_users} icon={CheckCircle2} tone="emerald" loading={loading}/>
      <Stat label="Blocked users" value={summary.blocked_users} icon={Ban} tone="rose" loading={loading}/>
      <Stat label="Verified users" value={summary.verified_users} icon={ShieldCheck} tone="violet" loading={loading}/>
      <Stat label={`New this ${periodName?.toLowerCase()}`} value={summary.new_users} icon={UserPlus} tone="amber" loading={loading}/>
    </div>

    <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
      <Stat label={`Logins this ${periodName?.toLowerCase()}`} value={summary.period_logins} icon={LogIn} tone="emerald" loading={loading}/>
      <Stat label={`Logouts this ${periodName?.toLowerCase()}`} value={summary.period_logouts} icon={LogOut} tone="rose" loading={loading}/>
      <Stat label="All-time logins" value={summary.total_logins} icon={Activity} tone="blue" loading={loading}/>
      <Stat label="All-time logouts" value={summary.total_logouts} icon={LogOut} tone="amber" loading={loading}/>
    </div>

    <div className="flex flex-wrap items-center justify-between gap-3 rounded-2xl border border-slate-200 bg-white p-3 shadow-sm">
      <div><p className="px-2 text-sm font-black text-slate-950">Analytics range</p><p className="px-2 text-xs text-slate-500">Change graph grouping</p></div>
      <div className="flex rounded-xl bg-slate-100 p-1">{periods.map((item) => <button key={item.id} type="button" onClick={() => changePeriod(item.id)} className={`rounded-lg px-4 py-2 text-sm font-black transition ${period === item.id ? 'bg-white text-blue-700 shadow-sm' : 'text-slate-500 hover:text-slate-900'}`}>{item.label}</button>)}</div>
    </div>

    <div className="grid gap-5 xl:grid-cols-2">
      <ChartCard title="User registrations" subtitle={`New accounts by ${period === 'day' ? 'hour' : period === 'year' ? 'month' : 'date'}`}>
        <RegistrationChart timeline={timeline} loading={loading}/>
      </ChartCard>
      <ChartCard title="Module activity" subtitle="New database records created in each module">
        <ModuleChart timeline={timeline} loading={loading}/>
      </ChartCard>
    </div>

    <ChartCard title="Login and logout activity" subtitle="Successful app authentication events">
      <AuthActivityChart timeline={timeline} loading={loading}/>
    </ChartCard>

    <section className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm">
      <div className="flex items-center justify-between gap-4"><div><h3 className="text-lg font-black text-slate-950">Module totals</h3><p className="text-sm text-slate-500">All-time server database records</p></div><button onClick={() => onNavigate('analytics')} className="text-sm font-black text-blue-700 hover:text-blue-900">Storage analytics</button></div>
      <div className="mt-5 grid gap-3 sm:grid-cols-2 lg:grid-cols-5">{modules.map((module) => <ModuleTotal key={module.id} module={module} value={data?.module_totals?.[module.id]} loading={loading}/>)}</div>
    </section>

    <section className="rounded-2xl border border-slate-200 bg-white shadow-sm">
      <div className="flex items-center justify-between border-b border-slate-100 p-5"><div><h3 className="text-lg font-black text-slate-950">Latest users</h3><p className="text-sm text-slate-500">Most recently registered accounts</p></div><button onClick={() => onNavigate('users')} className="text-sm font-black text-blue-700">View all</button></div>
      <div className="divide-y divide-slate-100">{users.slice(0, 6).map((user) => <div key={user.id} className="grid gap-2 px-5 py-4 sm:grid-cols-[1.2fr_1.5fr_auto_auto] sm:items-center"><div><p className="font-black text-slate-950">{user.full_name}</p><p className="text-xs text-slate-500">{user.phone}</p></div><p className="break-all text-sm text-slate-600">{user.email}</p><span className={`w-fit rounded-full px-2.5 py-1 text-xs font-black ${user.is_active ? 'bg-emerald-50 text-emerald-700' : 'bg-red-50 text-red-700'}`}>{user.is_active ? 'Active' : 'Blocked'}</span><p className="text-xs font-semibold text-slate-500">{formatDate(user.created_at)}</p></div>)}</div>
      {!appLoading && !users.length && <div className="p-5"><EmptyState text="No users registered yet."/></div>}
    </section>
  </div>
}

const tones = {
  blue: 'bg-blue-50 text-blue-700', emerald: 'bg-emerald-50 text-emerald-700',
  rose: 'bg-rose-50 text-rose-700', violet: 'bg-violet-50 text-violet-700',
  amber: 'bg-amber-50 text-amber-700',
}
function Stat({ label, value, icon: Icon, tone, loading }) { return <div className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm"><div className={`grid h-11 w-11 place-items-center rounded-xl ${tones[tone]}`}><Icon size={21}/></div><p className="mt-5 text-sm font-bold text-slate-500">{label}</p><p className="mt-1 text-3xl font-black text-slate-950">{loading ? '—' : value ?? 0}</p></div> }
function ChartCard({ title, subtitle, children }) { return <section className="overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-sm"><div className="border-b border-slate-100 px-5 py-4"><h3 className="font-black text-slate-950">{title}</h3><p className="mt-0.5 text-xs text-slate-500">{subtitle}</p></div><div className="p-4 sm:p-5">{children}</div></section> }
function ModuleTotal({ module, value, loading }) { const Icon = module.icon; return <div className="rounded-xl border border-slate-100 bg-slate-50 p-4"><div className="flex items-center gap-2" style={{color:module.color}}><Icon size={18}/><span className="text-xs font-black uppercase">{module.label}</span></div><p className="mt-3 text-2xl font-black text-slate-950">{loading ? '—' : value ?? 0}</p></div> }

function RegistrationChart({ timeline, loading }) {
  if (loading) return <ChartSkeleton/>
  const max = Math.max(1, ...timeline.map((point) => point.users_registered || 0))
  const total = timeline.reduce((sum, point) => sum + (point.users_registered || 0), 0)
  const columns = timeline.length > 12 ? 6 : Math.min(4, Math.max(1, timeline.length))
  return <div className="flex min-h-[310px] flex-col">
    <div className="mb-5 flex items-end justify-between gap-4 rounded-2xl bg-gradient-to-r from-blue-700 to-indigo-700 p-5 text-white">
      <div><p className="text-xs font-black uppercase tracking-[0.15em] text-blue-100">Registrations</p><p className="mt-1 text-3xl font-black">{total}</p></div>
      <div className="text-right"><p className="text-xs text-blue-100">Peak activity</p><p className="font-black">{max === 1 && total === 0 ? 0 : max} users</p></div>
    </div>
    <div className="grid flex-1 gap-2" style={{ gridTemplateColumns: `repeat(${columns}, minmax(0, 1fr))` }}>
      {timeline.map((point) => {
        const value = point.users_registered || 0
        const intensity = value ? 0.25 + (value / max) * 0.75 : 0
        return <div key={point.key} title={`${point.label}: ${value} new users`} className="group relative grid min-h-14 place-items-center overflow-hidden rounded-xl border border-slate-200 transition hover:-translate-y-0.5 hover:border-blue-400 hover:shadow-md" style={{ backgroundColor: value ? `rgba(37, 99, 235, ${intensity})` : '#f8fafc' }}>
          <strong className={value && intensity > .55 ? 'text-white' : 'text-slate-700'}>{value}</strong>
          <span className={`absolute inset-x-1 bottom-1 truncate text-center text-[9px] font-bold ${value && intensity > .55 ? 'text-blue-100' : 'text-slate-400'}`}>{point.label}</span>
        </div>
      })}
    </div>
  </div>
}

function ModuleChart({ timeline, loading }) {
  if (loading) return <ChartSkeleton/>
  const chartData = modules.map((module) => ({
    ...module,
    value: timeline.reduce((sum, point) => sum + (point.modules?.[module.id] || 0), 0),
  }))
  const total = chartData.reduce((sum, item) => sum + item.value, 0)
  const displayData = total ? chartData : [{ id: 'empty', label: 'No activity', value: 1, color: '#e2e8f0' }]
  return <div className="grid min-h-[310px] gap-4 sm:grid-cols-[1.05fr_.95fr] sm:items-center">
    <div className="relative h-[280px]">
      <ResponsiveContainer width="100%" height="100%">
        <PieChart>
          <Pie data={displayData} dataKey="value" nameKey="label" cx="50%" cy="50%" innerRadius="60%" outerRadius="86%" paddingAngle={total ? 4 : 0} cornerRadius={7} stroke="none">
            {displayData.map((item) => <Cell key={item.id} fill={item.color}/>) }
          </Pie>
          {total > 0 && <Tooltip content={<ChartTooltip/>}/>} 
        </PieChart>
      </ResponsiveContainer>
      <div className="pointer-events-none absolute inset-0 grid place-items-center"><div className="text-center"><p className="text-3xl font-black text-slate-950">{total}</p><p className="text-xs font-bold text-slate-500">Total activity</p></div></div>
    </div>
    <div className="space-y-2">{chartData.map((item) => {
      const percent = total ? Math.round(item.value / total * 100) : 0
      return <div key={item.id} className="rounded-xl border border-slate-100 bg-slate-50 p-3"><div className="flex items-center justify-between gap-3"><span className="flex items-center gap-2 text-xs font-black text-slate-700"><span className="h-2.5 w-2.5 rounded-full" style={{background:item.color}}/>{item.label}</span><strong className="text-sm text-slate-950">{item.value}</strong></div><div className="mt-2 h-1.5 overflow-hidden rounded-full bg-slate-200"><div className="h-full rounded-full transition-all" style={{width:`${percent}%`, background:item.color}}/></div></div>
    })}</div>
  </div>
}

function AuthActivityChart({ timeline, loading }) {
  if (loading) return <ChartSkeleton/>
  const max = Math.max(1, ...timeline.flatMap((point) => [point.auth?.login || 0, point.auth?.logout || 0]))
  return <div className="space-y-3">
    <div className="flex gap-5 text-xs font-black"><span className="text-emerald-700">● Logins</span><span className="text-rose-700">● Logouts</span></div>
    <div className="overflow-x-auto pb-2"><div className="flex min-w-[680px] items-end gap-2" style={{height:260}}>
      {timeline.map((point) => {
        const logins = point.auth?.login || 0
        const logouts = point.auth?.logout || 0
        return <div key={point.key} className="flex h-full min-w-12 flex-1 flex-col justify-end">
          <div className="flex flex-1 items-end justify-center gap-1">
            <div title={`${point.label}: ${logins} logins`} className="w-3 rounded-t bg-emerald-500" style={{height:`${Math.max(logins ? 8 : 2, logins / max * 100)}%`}}/>
            <div title={`${point.label}: ${logouts} logouts`} className="w-3 rounded-t bg-rose-500" style={{height:`${Math.max(logouts ? 8 : 2, logouts / max * 100)}%`}}/>
          </div>
          <p className="mt-2 truncate text-center text-[9px] font-bold text-slate-400">{point.label}</p>
        </div>
      })}
    </div></div>
  </div>
}

function ChartTooltip({ active, payload, label }) {
  if (!active || !payload?.length) return null
  const visible = payload.filter((item) => Number(item.value) > 0)
  return <div className="min-w-36 rounded-xl border border-slate-200 bg-white/95 p-3 shadow-xl backdrop-blur"><p className="mb-2 text-xs font-black text-slate-900">{label}</p>{visible.length ? visible.map((item) => <div key={item.dataKey} className="flex items-center justify-between gap-5 py-0.5 text-xs"><span className="flex items-center gap-2 font-semibold text-slate-600"><span className="h-2 w-2 rounded-full" style={{background:item.color}}/>{item.name}</span><strong className="text-slate-950">{item.value}</strong></div>) : <p className="text-xs text-slate-500">No activity</p>}</div>
}
function ChartSkeleton() { return <div className="h-[310px] animate-pulse rounded-xl bg-gradient-to-r from-slate-100 via-slate-50 to-slate-100"/> }
