import { Loader2 } from 'lucide-react'

export function PrimaryButton({ loading, label, icon: Icon }) {
  return (
    <button
      type="submit"
      disabled={loading}
      className="inline-flex w-full items-center justify-center gap-2 rounded-lg bg-blue-700 px-4 py-3 text-sm font-black text-white shadow-lg shadow-blue-700/20 hover:bg-blue-800 disabled:opacity-70"
    >
      {loading ? (
        <Loader2 className="animate-spin" size={18} />
      ) : Icon ? (
        <Icon size={18} />
      ) : null}
      {label}
    </button>
  )
}

export function SecondaryButton({ label, icon: Icon, ...props }) {
  return (
    <button
      className="inline-flex items-center justify-center gap-2 rounded-lg border border-slate-300 bg-white px-4 py-3 text-sm font-bold text-slate-700 hover:bg-slate-50"
      {...props}
    >
      {Icon && <Icon size={18} />}
      {label}
    </button>
  )
}
