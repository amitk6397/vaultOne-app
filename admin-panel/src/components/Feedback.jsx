import { useEffect, useState } from 'react'
import { AlertCircle, CheckCircle2, Loader2, X } from 'lucide-react'

export function ToastViewport() {
  const [items, setItems] = useState([])

  useEffect(() => {
    const timers = new Map()
    const onNotification = (event) => {
      const item = event.detail || {}
      if (!item.id || !item.message) return
      setItems((current) => {
        const exists = current.some((entry) => entry.id === item.id)
        return exists
          ? current.map((entry) => (entry.id === item.id ? item : entry))
          : [...current, item]
      })
      if (timers.has(item.id)) window.clearTimeout(timers.get(item.id))
      if (item.type !== 'loading') {
        timers.set(
          item.id,
          window.setTimeout(() => {
            setItems((current) =>
              current.filter((entry) => entry.id !== item.id),
            )
            timers.delete(item.id)
          }, item.type === 'error' ? 6500 : 4000),
        )
      }
    }
    window.addEventListener('vaultone:notification', onNotification)
    return () => {
      window.removeEventListener('vaultone:notification', onNotification)
      timers.forEach((timer) => window.clearTimeout(timer))
    }
  }, [])

  const dismiss = (id) =>
    setItems((current) => current.filter((item) => item.id !== id))

  return (
    <div
      className="pointer-events-none fixed right-4 top-4 z-[100] flex w-[min(380px,calc(100vw-2rem))] flex-col gap-3"
      aria-live="polite"
      aria-atomic="true"
    >
      {items.map((item) => {
        const Icon =
          item.type === 'loading'
            ? Loader2
            : item.type === 'success'
              ? CheckCircle2
              : AlertCircle
        return (
          <div
            key={item.id}
            className={`pointer-events-auto flex items-start gap-3 rounded-2xl bg-white p-4 shadow-2xl shadow-slate-900/15 ${
              item.type === 'error'
                ? 'text-red-700'
                : item.type === 'success'
                  ? 'text-emerald-700'
                  : 'text-blue-700'
            }`}
            role={item.type === 'error' ? 'alert' : 'status'}
          >
            <Icon
              className={item.type === 'loading' ? 'mt-0.5 animate-spin' : 'mt-0.5'}
              size={20}
            />
            <div className="min-w-0 flex-1">
              <p className="text-xs font-black uppercase tracking-wider">
                {item.type === 'loading'
                  ? 'Working'
                  : item.type === 'success'
                    ? 'Completed'
                    : 'Action failed'}
              </p>
              <p className="mt-0.5 text-sm font-semibold text-slate-700">
                {item.message}
              </p>
            </div>
            {item.type !== 'loading' && (
              <button
                type="button"
                onClick={() => dismiss(item.id)}
                className="rounded-lg p-1 text-slate-400 hover:bg-slate-100 hover:text-slate-700"
                aria-label="Dismiss notification"
              >
                <X size={17} />
              </button>
            )}
          </div>
        )
      })}
    </div>
  )
}

export function ErrorMessage({ message }) {
  if (!message) return null
  return (
    <div className="rounded-lg border border-red-200 bg-red-50 px-4 py-3 text-sm font-semibold text-red-700">
      {message}
    </div>
  )
}

export function SuccessMessage({ message }) {
  if (!message) return null
  return (
    <div className="rounded-lg border border-emerald-200 bg-emerald-50 px-4 py-3 text-sm font-semibold text-emerald-700">
      {message}
    </div>
  )
}

export function EmptyState({ text }) {
  return (
    <div className="rounded-xl border border-dashed border-slate-300 bg-white p-8 text-center text-sm font-semibold text-slate-500">
      {text}
    </div>
  )
}
