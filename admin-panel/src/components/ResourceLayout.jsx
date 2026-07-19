import { Loader2 } from 'lucide-react'

export function ResourceForm({ title, onSubmit, children }) {
  return (
    <form
      onSubmit={onSubmit}
      className="rounded-xl border border-slate-200 bg-white p-5 shadow-sm"
    >
      <h2 className="mb-5 text-xl font-black text-slate-950">{title}</h2>
      <div className="space-y-4">{children}</div>
    </form>
  )
}

export function ResourceTable({ title, loading, children }) {
  return (
    <section>
      <div className="mb-4 flex items-center justify-between">
        <h2 className="text-xl font-black text-slate-950">{title}</h2>
        {loading && <Loader2 className="animate-spin text-blue-700" size={20} />}
      </div>
      {children}
    </section>
  )
}

export function SummaryPanel({ title, action, onAction, children }) {
  return (
    <section className="group rounded-xl border border-slate-200 bg-white p-5 shadow-sm transition-all duration-300 hover:-translate-y-1 hover:border-blue-200 hover:shadow-xl hover:shadow-blue-900/10">
      <div className="mb-4 flex items-center justify-between">
        <h2 className="text-lg font-black text-slate-950 transition-colors group-hover:text-blue-700">
          {title}
        </h2>
        <button
          type="button"
          onClick={onAction}
          className="rounded-lg px-2 py-1 text-sm font-bold text-blue-700 transition-colors hover:bg-blue-50 hover:text-blue-900"
        >
          {action}
        </button>
      </div>
      <div className="space-y-3">{children}</div>
    </section>
  )
}
