import { useMemo, useState } from 'react'
import { Ban, CheckCircle2, Search, Trash2 } from 'lucide-react'
import { EmptyState, ErrorMessage } from '../components/Feedback'
import { StatusBadge } from '../components/ResourceItems'
import { ResourceTable } from '../components/ResourceLayout'
import { adminApi } from '../services/api'
import { formatDate } from '../utils'

export function UsersManager({ users, loading, onChanged }) {
  const [query, setQuery] = useState('')
  const [actionUserId, setActionUserId] = useState(null)
  const [error, setError] = useState('')

  const filteredUsers = useMemo(() => {
    const search = query.trim().toLowerCase()
    if (!search) return users
    return users.filter((user) =>
      [user.full_name, user.email, user.phone]
        .filter(Boolean)
        .some((value) => value.toLowerCase().includes(search)),
    )
  }, [query, users])

  const toggleUserStatus = async (user) => {
    const action = user.is_active ? 'block' : 'unblock'
    const confirmed = confirm(`Are you sure you want to ${action} ${user.full_name}?`)
    if (!confirmed) return

    setError('')
    setActionUserId(user.id)
    try {
      if (user.is_active) {
        await adminApi.blockUser(user.id)
      } else {
        await adminApi.unblockUser(user.id)
      }
      await onChanged()
    } catch (err) {
      setError(err.message)
    } finally {
      setActionUserId(null)
    }
  }

  const deleteUser = async (user) => {
    const confirmed = confirm(
      `Permanently delete ${user.full_name}? This removes the account, Vault data, media, files, chats, subscriptions and cannot be undone.`,
    )
    if (!confirmed) return
    const secondConfirmation = confirm(
      `Final confirmation: permanently delete ${user.email}?`,
    )
    if (!secondConfirmation) return
    setError('')
    setActionUserId(user.id)
    try {
      await adminApi.deleteUser(user.id)
      await onChanged()
    } catch (err) {
      setError(err.message)
    } finally {
      setActionUserId(null)
    }
  }

  return (
    <ResourceTable title="App users" loading={loading}>
      <div className="mb-4 space-y-4">
        <ErrorMessage message={error} />
        <label className="relative block">
          <Search
            className="pointer-events-none absolute left-3 top-1/2 -translate-y-1/2 text-slate-400"
            size={18}
          />
          <input
            value={query}
            onChange={(event) => setQuery(event.target.value)}
            placeholder="Search by name, email, or phone"
            className="w-full rounded-lg border border-slate-300 bg-white py-3 pl-10 pr-4 outline-none focus:border-blue-600 focus:ring-4 focus:ring-blue-100"
          />
        </label>
      </div>

      <div className="overflow-hidden rounded-xl border border-slate-200 bg-white shadow-sm">
        <div className="hidden grid-cols-[1.2fr_1.3fr_1fr_0.8fr_1fr_auto] gap-4 border-b border-slate-200 bg-slate-50 px-4 py-3 text-xs font-black uppercase tracking-wider text-slate-500 lg:grid">
          <span>Name</span>
          <span>Email</span>
          <span>Phone</span>
          <span>Status</span>
          <span>Joined</span>
          <span>Action</span>
        </div>

        <div className="divide-y divide-slate-100">
          {filteredUsers.map((user) => (
            <article
              key={user.id}
              className="grid gap-3 px-4 py-4 lg:grid-cols-[1.2fr_1.3fr_1fr_0.8fr_1fr_auto] lg:items-center"
            >
              <div>
                <p className="font-black text-slate-950">{user.full_name}</p>
                <p className="mt-1 text-xs font-semibold text-slate-500">
                  {user.is_verified ? 'Verified' : 'Not verified'}
                </p>
              </div>
              <p className="break-all text-sm font-semibold text-slate-700">
                {user.email}
              </p>
              <p className="text-sm text-slate-600">{user.phone}</p>
              <StatusBadge active={user.is_active} />
              <p className="text-sm text-slate-500">{formatDate(user.created_at)}</p>
              <div className="flex flex-wrap gap-2">
                <button
                  type="button"
                  disabled={actionUserId === user.id}
                  onClick={() => toggleUserStatus(user)}
                  className={`inline-flex items-center justify-center gap-2 rounded-lg px-3 py-2 text-sm font-black ${
                    user.is_active
                      ? 'border border-red-200 text-red-600 hover:bg-red-50'
                      : 'border border-emerald-200 text-emerald-700 hover:bg-emerald-50'
                  } disabled:opacity-60`}
                >
                  {user.is_active ? <Ban size={16} /> : <CheckCircle2 size={16} />}
                  {user.is_active ? 'Block' : 'Unblock'}
                </button>
                <button
                  type="button"
                  disabled={actionUserId === user.id}
                  onClick={() => deleteUser(user)}
                  className="inline-flex items-center justify-center gap-2 rounded-lg bg-red-600 px-3 py-2 text-sm font-black text-white hover:bg-red-700 disabled:opacity-60"
                >
                  <Trash2 size={16} /> Delete
                </button>
              </div>
            </article>
          ))}
        </div>
      </div>

      {!filteredUsers.length && (
        <div className="mt-4">
          <EmptyState text={query ? 'No users match your search.' : 'No users found yet.'} />
        </div>
      )}
    </ResourceTable>
  )
}
