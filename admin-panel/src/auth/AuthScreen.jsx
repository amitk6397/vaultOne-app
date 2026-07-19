import { CheckCircle2, ShieldCheck } from 'lucide-react'
import { ForgotPasswordForm } from './ForgotPasswordForm'
import { LoginForm } from './LoginForm'

export function AuthScreen({ view, onViewChange, onAuthenticated }) {
  return (
    <main className="min-h-screen bg-[#eef4ff] px-4 py-8">
      <div className="mx-auto grid min-h-[calc(100vh-4rem)] max-w-6xl items-center gap-8 lg:grid-cols-[1fr_440px]">
        <section className="rounded-2xl bg-[#101828] p-8 text-white shadow-xl lg:p-10">
          <div className="mb-12 inline-flex items-center gap-3 rounded-full bg-white/10 px-4 py-2 text-sm">
            <ShieldCheck size={18} />
            VaultOne Admin Console
          </div>
          <h1 className="max-w-xl text-4xl font-black tracking-tight lg:text-5xl">
            Control onboarding, policies, and secure app content from one place.
          </h1>
          <p className="mt-5 max-w-2xl text-base leading-7 text-slate-300">
            Built for production workflows with protected API calls, explicit
            loading states, clean validation, and responsive layouts for daily
            operations.
          </p>
          <div className="mt-8 grid gap-3 sm:grid-cols-3">
            {['JWT protected', 'Tailwind UI', 'API connected'].map((item) => (
              <div
                key={item}
                className="rounded-lg border border-white/10 bg-white/5 p-4"
              >
                <CheckCircle2 className="mb-3 text-emerald-300" size={22} />
                <p className="text-sm font-semibold">{item}</p>
              </div>
            ))}
          </div>
        </section>

        <section className="rounded-2xl border border-slate-200 bg-white p-6 shadow-xl">
          {view === 'login' ? (
            <LoginForm
              onAuthenticated={onAuthenticated}
              onForgot={() => onViewChange('forgot')}
            />
          ) : (
            <ForgotPasswordForm onBack={() => onViewChange('login')} />
          )}
        </section>
      </div>
    </main>
  )
}
