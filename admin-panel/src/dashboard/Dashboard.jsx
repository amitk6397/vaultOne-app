import { useEffect, useState } from 'react'
import { RefreshCcw } from 'lucide-react'
import { ErrorMessage } from '../components/Feedback'
import { adminApi } from '../services/api'
import { BannersManager } from '../banners/BannersManager'
import { OnboardingManager } from '../onboarding/OnboardingManager'
import { PolicyManager } from '../policies/PolicyManager'
import { UsersManager } from '../users/UsersManager'
import { Overview } from './Overview'
import { SubscriptionsManager } from '../subscriptions/SubscriptionsManager'
import { StorageAnalytics } from '../analytics/StorageAnalytics'
import { NotificationsManager } from '../notifications/NotificationsManager'
import { SupportManager } from '../support/SupportManager'
import { VaultConnectManager } from '../vaultConnect/VaultConnectManager'
import { AccountDeletionManager } from '../users/AccountDeletionManager'

export function Dashboard({ activeView, onNavigate }) {
  const [slides, setSlides] = useState([])
  const [policies, setPolicies] = useState([])
  const [users, setUsers] = useState([])
  const [deletionRequests, setDeletionRequests] = useState([])
  const [banners, setBanners] = useState([])
  const [plans, setPlans] = useState([])
  const [orders, setOrders] = useState([])
  const [paymentSettings, setPaymentSettings] = useState(null)
  const [subscriptionHistory, setSubscriptionHistory] = useState([])
  const [analytics, setAnalytics] = useState(null)
  const [notificationHistory, setNotificationHistory] = useState([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [refreshVersion, setRefreshVersion] = useState(0)

  const loadData = async () => {
    setError('')
    setLoading(true)
    try {
      const [slideResponse, policyResponse, usersResponse, deletionResponse, bannersResponse, plansResponse, ordersResponse, settingsResponse, historyResponse, analyticsResponse, notificationsResponse] = await Promise.all([
        adminApi.listOnboarding(),
        adminApi.listPolicies(),
        adminApi.listUsers(),
        adminApi.listDeletionRequests(),
        adminApi.listBanners(),
        adminApi.listPlans(),
        adminApi.listPayments(),
        adminApi.paymentSettings(),
        adminApi.subscriptionHistory(),
        adminApi.storageAnalytics(),
        adminApi.notificationHistory(),
      ])
      setSlides(slideResponse.data || [])
      setPolicies(policyResponse.data || [])
      setUsers(usersResponse.data || [])
      setDeletionRequests(deletionResponse.data || [])
      setBanners(bannersResponse.data || [])
      setPlans(plansResponse.data || [])
      setOrders(ordersResponse.data || [])
      setPaymentSettings(settingsResponse.data || null)
      setSubscriptionHistory(historyResponse.data || [])
      setAnalytics(analyticsResponse.data || null)
      setNotificationHistory(notificationsResponse.data || [])
      setRefreshVersion((value) => value + 1)
    } catch (err) {
      setError(err.message)
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    // Initial server sync for protected admin resources.
    // eslint-disable-next-line react-hooks/set-state-in-effect
    loadData()
  }, [])

  return (
    <div className="mx-auto max-w-7xl px-4 py-6 sm:px-6 lg:px-8">
      <div className="mb-6 flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <p className="text-sm font-bold uppercase tracking-[0.18em] text-blue-700">
            Production console
          </p>
          <h1 className="mt-1 text-3xl font-black text-slate-950">
            VaultOne operations
          </h1>
        </div>
        <button
          type="button"
          onClick={loadData}
          className="inline-flex items-center justify-center gap-2 rounded-lg border border-slate-300 bg-white px-4 py-3 text-sm font-bold text-slate-700 shadow-sm hover:bg-slate-50"
        >
          <RefreshCcw size={17} />
          Refresh
        </button>
      </div>

      <ErrorMessage message={error} />

      {activeView === 'dashboard' && (
        <Overview
          users={users}
          loading={loading}
          onNavigate={onNavigate}
          refreshVersion={refreshVersion}
        />
      )}
      {activeView === 'users' && (
        <UsersManager users={users} loading={loading} onChanged={loadData} />
      )}
      {activeView === 'deletion-requests' && (
        <AccountDeletionManager
          requests={deletionRequests}
          loading={loading}
          onChanged={loadData}
        />
      )}
      {activeView === 'banners' && (
        <BannersManager banners={banners} loading={loading} onChanged={loadData} />
      )}
      {activeView === 'onboarding' && (
        <OnboardingManager
          slides={slides}
          loading={loading}
          onChanged={loadData}
        />
      )}
      {activeView === 'policies' && (
        <PolicyManager policies={policies} loading={loading} onChanged={loadData} />
      )}
      {activeView === 'subscriptions' && (
        <SubscriptionsManager
          history={subscriptionHistory}
          loading={loading}
          payments={orders}
          plans={plans}
          settings={paymentSettings}
          onChanged={loadData}
        />
      )}
      {activeView === 'analytics' && (
        <StorageAnalytics analytics={analytics} plans={plans} loading={loading} onChanged={loadData} />
      )}
      {activeView === 'notifications' && (
        <NotificationsManager users={users} history={notificationHistory} loading={loading} onChanged={loadData} />
      )}
      {activeView === 'support' && <SupportManager />}
      {activeView === 'vault-connect' && <VaultConnectManager users={users} />}
    </div>
  )
}
