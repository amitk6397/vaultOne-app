import { useCallback, useEffect, useState } from 'react'
import { AdminShell } from './app/AdminShell'
import { AuthScreen } from './auth/AuthScreen'
import { Dashboard } from './dashboard/Dashboard'
import { ToastViewport } from './components/Feedback'
import { REFRESH_TOKEN_STORAGE_KEY, TOKEN_STORAGE_KEY } from './config'

function App() {
  const [token, setToken] = useState(() => localStorage.getItem(TOKEN_STORAGE_KEY))
  const [authView, setAuthView] = useState('login')
  const [activeView, setActiveView] = useState('dashboard')

  const handleAuthenticated = (accessToken, refreshToken) => {
    localStorage.setItem(TOKEN_STORAGE_KEY, accessToken)
    localStorage.setItem(REFRESH_TOKEN_STORAGE_KEY, refreshToken)
    setToken(accessToken)
    setActiveView('dashboard')
  }

  const handleLogout = useCallback(() => {
    localStorage.removeItem(TOKEN_STORAGE_KEY)
    localStorage.removeItem(REFRESH_TOKEN_STORAGE_KEY)
    setToken(null)
    setAuthView('login')
  }, [])

  useEffect(() => {
    window.addEventListener('vaultone:auth-expired', handleLogout)
    return () => {
      window.removeEventListener('vaultone:auth-expired', handleLogout)
    }
  }, [handleLogout])

  if (!token) {
    return (
      <>
        <ToastViewport />
        <AuthScreen
          view={authView}
          onViewChange={setAuthView}
          onAuthenticated={handleAuthenticated}
        />
      </>
    )
  }

  return (
    <>
      <ToastViewport />
      <AdminShell
        activeView={activeView}
        onNavigate={setActiveView}
        onLogout={handleLogout}
      >
        <Dashboard activeView={activeView} onNavigate={setActiveView} />
      </AdminShell>
    </>
  )
}

export default App
