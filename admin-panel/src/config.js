export const API_BASE_URL =
  import.meta.env.VITE_API_BASE_URL || 'http://127.0.0.1:8000/api/v1'

export const UPLOAD_BASE_URL =
  import.meta.env.VITE_UPLOAD_BASE_URL || API_BASE_URL.replace('/api/v1', '')

export const TOKEN_STORAGE_KEY = 'vaultone_admin_token'
export const REFRESH_TOKEN_STORAGE_KEY = 'vaultone_admin_refresh_token'
