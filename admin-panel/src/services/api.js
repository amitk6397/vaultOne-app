import { API_BASE_URL, REFRESH_TOKEN_STORAGE_KEY, TOKEN_STORAGE_KEY } from '../config'

let refreshPromise = null

const notify = (detail) => {
  window.dispatchEvent(new CustomEvent('vaultone:notification', { detail }))
}

const parseResponse = async (response) => {
  const contentType = response.headers.get('content-type') || ''
  const payload = contentType.includes('application/json')
    ? await response.json()
    : { message: await response.text() }

  if (!response.ok) {
    const detail = payload?.detail
    const message = Array.isArray(detail)
      ? detail.map((item) => item.msg).join(', ')
      : detail || payload?.message || 'Request failed'
    throw new Error(message)
  }

  return payload
}

const clearAdminSession = () => {
  localStorage.removeItem(TOKEN_STORAGE_KEY)
  localStorage.removeItem(REFRESH_TOKEN_STORAGE_KEY)
  window.dispatchEvent(new Event('vaultone:auth-expired'))
}

const refreshAdminSession = async () => {
  const refreshToken = localStorage.getItem(REFRESH_TOKEN_STORAGE_KEY)
  if (!refreshToken) {
    clearAdminSession()
    return null
  }

  const response = await fetch(`${API_BASE_URL}/admin/auth/refresh`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ refresh_token: refreshToken }),
  })

  if (!response.ok) {
    clearAdminSession()
    return null
  }

  const payload = await response.json()
  const accessToken = payload?.data?.access_token
  const rotatedRefreshToken = payload?.data?.refresh_token

  if (!accessToken) {
    clearAdminSession()
    return null
  }

  localStorage.setItem(TOKEN_STORAGE_KEY, accessToken)
  if (rotatedRefreshToken) {
    localStorage.setItem(REFRESH_TOKEN_STORAGE_KEY, rotatedRefreshToken)
  }

  return accessToken
}

const request = async (
  path,
  options = {},
  retried = false,
  notificationId = null,
) => {
  const method = (options.method || 'GET').toUpperCase()
  const shouldNotify = method !== 'GET' && path !== '/admin/auth/refresh'
  const operationId =
    notificationId ||
    `admin-${Date.now()}-${Math.random().toString(36).slice(2)}`

  if (shouldNotify && !notificationId) {
    notify({
      id: operationId,
      type: 'loading',
      message: 'Processing admin action…',
    })
  }

  const token = localStorage.getItem(TOKEN_STORAGE_KEY)
  const headers = new Headers(options.headers || {})

  if (!(options.body instanceof FormData) && !headers.has('Content-Type')) {
    headers.set('Content-Type', 'application/json')
  }
  if (token) {
    headers.set('Authorization', `Bearer ${token}`)
  }

  let response = await fetch(`${API_BASE_URL}${path}`, {
    ...options,
    headers,
  })

  if (response.status === 401 && !retried && path !== '/admin/auth/refresh') {
    try {
      refreshPromise ||= refreshAdminSession()
      const accessToken = await refreshPromise
      refreshPromise = null

      if (accessToken) {
        return request(path, options, true, operationId)
      }
    } catch {
      refreshPromise = null
      clearAdminSession()
    }
  }
  try {
    const payload = await parseResponse(response)
    if (shouldNotify) {
      notify({
        id: operationId,
        type: 'success',
        message: payload?.message || 'Action completed successfully',
      })
    }
    return payload
  } catch (error) {
    if (shouldNotify) {
      notify({
        id: operationId,
        type: 'error',
        message: error.message || 'Admin action failed',
      })
    }
    throw error
  }
}

export const adminApi = {
  login: (payload) =>
    request('/admin/auth/login', {
      method: 'POST',
      body: JSON.stringify(payload),
    }),
  forgotPassword: (payload) =>
    request('/admin/auth/forgot-password', {
      method: 'POST',
      body: JSON.stringify(payload),
    }),
  resetPassword: (payload) =>
    request('/admin/auth/reset-password', {
      method: 'POST',
      body: JSON.stringify(payload),
    }),
  listOnboarding: () => request('/admin/auth/onboarding'),
  createOnboarding: (formData) =>
    request('/admin/auth/onboarding', {
      method: 'POST',
      body: formData,
    }),
  updateOnboarding: (id, formData) =>
    request(`/admin/auth/onboarding/${id}`, {
      method: 'PUT',
      body: formData,
    }),
  deleteOnboarding: (id) =>
    request(`/admin/auth/onboarding/${id}`, { method: 'DELETE' }),
  listPolicies: () => request('/admin/policies'),
  createPolicy: (payload) =>
    request('/admin/policies', {
      method: 'POST',
      body: JSON.stringify(payload),
    }),
  updatePolicy: (id, payload) =>
    request(`/admin/policies/${id}`, {
      method: 'PUT',
      body: JSON.stringify(payload),
    }),
  deletePolicy: (id) => request(`/admin/policies/${id}`, { method: 'DELETE' }),
  listBanners: () => request('/admin/banners'),
  createBanner: (formData) =>
    request('/admin/banners', {
      method: 'POST',
      body: formData,
    }),
  updateBanner: (id, formData) =>
    request(`/admin/banners/${id}`, {
      method: 'PUT',
      body: formData,
    }),
  deleteBanner: (id) => request(`/admin/banners/${id}`, { method: 'DELETE' }),
  listUsers: () => request('/admin/users'),
  blockUser: (id) =>
    request(`/admin/users/${id}/block`, {
      method: 'PATCH',
    }),
  unblockUser: (id) =>
    request(`/admin/users/${id}/unblock`, {
      method: 'PATCH',
    }),
  listPlans: () => request('/admin/subscriptions/plans'),
  createPlan: (payload) => request('/admin/subscriptions/plans', { method: 'POST', body: JSON.stringify(payload) }),
  updatePlan: (id, payload) => request(`/admin/subscriptions/plans/${id}`, { method: 'PUT', body: JSON.stringify(payload) }),
  listPayments: () => request('/admin/payments'),
  approvePayment: (payment_id, reason = '') => request('/admin/payment/approve', { method: 'POST', body: JSON.stringify({ payment_id, reason }) }),
  rejectPayment: (payment_id, reason) => request('/admin/payment/reject', { method: 'POST', body: JSON.stringify({ payment_id, reason }) }),
  paymentSettings: () => request('/admin/payment-settings'),
  updatePaymentSettings: (formData) => request('/admin/payment-settings', { method: 'PUT', body: formData }),
  subscriptionHistory: () => request('/admin/subscriptions/history'),
  storageAnalytics: () => request('/admin/analytics/storage'),
  overviewAnalytics: (period = 'week') => request(`/admin/analytics/overview?period=${encodeURIComponent(period)}`),
  userAnalytics: (id) => request(`/admin/analytics/users/${id}`),
  setStorageLimit: (id, limit_mb) => request(`/admin/users/${id}/storage-limit`, { method: 'PATCH', body: JSON.stringify({ limit_mb }) }),
  listOffers: () => request('/admin/offers'),
  createOffer: (payload) => request('/admin/offers', { method: 'POST', body: JSON.stringify(payload) }),
  deactivateOffer: (id) => request(`/admin/offers/${id}/deactivate`, { method: 'PATCH' }),
  notificationHistory: () => request('/admin/notifications/history'),
  sendNotification: (payload) => request('/admin/notifications/send', {
    method: 'POST', body: JSON.stringify(payload),
  }),
  supportContent: (key) => request(`/admin/support/content/${key}`),
  saveSupportContent: (key, payload) => request(`/admin/support/content/${key}`, { method: 'PUT', body: JSON.stringify(payload) }),
  supportThreads: () => request('/admin/support/threads'),
  supportMessages: (id) => request(`/admin/support/threads/${id}/messages`),
  vaultConnectOverview: () => request('/admin/vault-connect/overview'),
  vaultConnectConfig: () => request('/admin/vault-connect/config'),
  updateVaultConnectConfig: (payload) => request('/admin/vault-connect/config', { method: 'PATCH', body: JSON.stringify(payload) }),
  vaultConnectReports: (status = '') => request(`/admin/vault-connect/reports${status ? `?status=${encodeURIComponent(status)}` : ''}`),
  vaultConnectUsers: () => request('/admin/vault-connect/users'),
  updateVaultConnectReport: (id, payload) => request(`/admin/vault-connect/reports/${id}`, { method: 'PATCH', body: JSON.stringify(payload) }),
  setVaultConnectAccess: (id, payload) => request(`/admin/vault-connect/users/${id}/access`, { method: 'PATCH', body: JSON.stringify(payload) }),
  revokeVaultConnectSessions: (id) => request(`/admin/vault-connect/users/${id}/revoke-sessions`, { method: 'POST' }),
  runVaultConnectCleanup: () => request('/admin/vault-connect/cleanup/run', { method: 'POST' }),
  replySupport: (id, message) => request(`/admin/support/threads/${id}/reply`, { method: 'POST', body: JSON.stringify({ message }) }),
  paymentScreenshot: async (id) => {
    const response = await fetch(`${API_BASE_URL}/admin/payments/${id}/screenshot`, { headers: { Authorization: `Bearer ${localStorage.getItem(TOKEN_STORAGE_KEY)}` } })
    if (!response.ok) throw new Error('Could not load screenshot')
    return response.blob()
  },
}
