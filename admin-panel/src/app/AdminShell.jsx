import {
  BookOpen,
  Images,
  ImagePlus,
  LayoutDashboard,
  LogOut,
  ShieldCheck,
  Users,
  CreditCard,
  ChartNoAxesCombined,
  BellRing,
  MessagesSquare,
  MessageSquareLock,
} from 'lucide-react'

const navItems = [
  { id: 'dashboard', label: 'Overview', icon: LayoutDashboard },
  { id: 'users', label: 'Users', icon: Users },
  { id: 'banners', label: 'Banners', icon: Images },
  { id: 'onboarding', label: 'Onboarding', icon: ImagePlus },
  { id: 'policies', label: 'Policies', icon: BookOpen },
  { id: 'subscriptions', label: 'Subscriptions', icon: CreditCard },
  { id: 'analytics', label: 'Storage analytics', icon: ChartNoAxesCombined },
  { id: 'notifications', label: 'Notifications', icon: BellRing },
  { id: 'support', label: 'Help & support', icon: MessagesSquare },
  { id: 'vault-connect', label: 'Vault Connect', icon: MessageSquareLock },
]

export function AdminShell({ children, activeView, onNavigate, onLogout }) {
  return (
    <div className="admin-shell min-h-screen bg-[#f6f8fb] lg:h-screen lg:overflow-hidden">
      <aside className="fixed inset-y-0 left-0 z-30 hidden h-screen w-72 flex-col overflow-hidden bg-white px-5 py-6 shadow-[12px_0_40px_-28px_rgba(15,23,42,0.4)] lg:flex">
        <div className="flex shrink-0 items-center gap-3">
          <div className="grid h-11 w-11 place-items-center rounded-xl bg-blue-700 text-white">
            <ShieldCheck size={24} />
          </div>
          <div>
            <p className="text-lg font-black text-slate-950">VaultOne</p>
            <p className="text-xs font-semibold uppercase tracking-widest text-slate-500">
              Admin
            </p>
          </div>
        </div>

        <nav className="sidebar-scroll mt-10 min-h-0 flex-1 space-y-2 overflow-y-auto overscroll-contain pr-1">
          {navItems.map((item) => (
            <button
              key={item.id}
              type="button"
              onClick={() => onNavigate(item.id)}
              className={`flex w-full items-center gap-3 rounded-lg px-4 py-3 text-left text-sm font-bold ${
                activeView === item.id
                  ? 'bg-blue-700 text-white shadow-lg shadow-blue-700/20'
                  : 'text-slate-600 hover:bg-slate-100 hover:text-slate-950'
              }`}
            >
              <item.icon size={19} />
              {item.label}
            </button>
          ))}
        </nav>

        <button
          type="button"
          onClick={onLogout}
          className="mt-4 flex shrink-0 items-center justify-center gap-2 rounded-xl bg-slate-100 px-4 py-3 text-sm font-bold text-slate-700 transition hover:bg-slate-200 hover:text-slate-950"
        >
          <LogOut size={18} />
          Logout
        </button>
      </aside>

      <header className="sticky top-0 z-20 bg-white/95 px-4 py-3 shadow-sm backdrop-blur lg:hidden">
        <div className="flex items-center justify-between">
          <strong>VaultOne Admin</strong>
          <button
            type="button"
            onClick={onLogout}
            className="rounded-lg border px-3 py-2 text-sm font-bold"
          >
            Logout
          </button>
        </div>
        <div className="sidebar-scroll mt-3 flex gap-2 overflow-x-auto overscroll-contain pb-1">
          {navItems.map((item) => (
            <button
              key={item.id}
              type="button"
              onClick={() => onNavigate(item.id)}
              className={`shrink-0 rounded-lg px-3 py-2 text-xs font-bold ${
                activeView === item.id
                  ? 'bg-blue-700 text-white'
                  : 'bg-slate-100 text-slate-700'
              }`}
            >
              {item.label}
            </button>
          ))}
        </div>
      </header>

      <main className="lg:h-screen lg:overflow-y-auto lg:overscroll-contain lg:pl-72">
        {children}
      </main>
    </div>
  )
}
