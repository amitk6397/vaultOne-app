import { Trash2 } from 'lucide-react'

export function RowActions({ onEdit, onDelete }) {
  return (
    <div className="flex gap-2 md:flex-col">
      <button
        type="button"
        onClick={onEdit}
        className="rounded-lg border border-slate-300 px-3 py-2 text-sm font-bold text-slate-700 hover:bg-slate-50"
      >
        Edit
      </button>
      <button
        type="button"
        onClick={onDelete}
        className="rounded-lg border border-red-200 px-3 py-2 text-sm font-bold text-red-600 hover:bg-red-50"
        aria-label="Delete"
      >
        <Trash2 size={16} />
      </button>
    </div>
  )
}

export function StatusBadge({ active }) {
  return (
    <span
      className={`rounded-full px-2.5 py-1 text-xs font-black ${
        active ? 'bg-emerald-100 text-emerald-700' : 'bg-slate-100 text-slate-500'
      }`}
    >
      {active ? 'Active' : 'Inactive'}
    </span>
  )
}

export function ListRow({ title, subtitle }) {
  return (
    <div className="group rounded-lg border border-slate-100 bg-slate-50 p-3 transition-all duration-200 hover:translate-x-1 hover:border-blue-100 hover:bg-blue-50/60">
      <p className="font-bold text-slate-900 transition-colors group-hover:text-blue-800">
        {title}
      </p>
      <p className="mt-1 text-sm capitalize text-slate-500">{subtitle}</p>
    </div>
  )
}
