import { UPLOAD_BASE_URL } from './config'

export const normalizeImageUrl = (image) => {
  if (!image) return ''
  if (/^https?:\/\//i.test(image)) return image
  return `${UPLOAD_BASE_URL}${image.startsWith('/') ? image : `/${image}`}`
}

export const formatDate = (value) => {
  if (!value) return 'Not available'
  return new Intl.DateTimeFormat('en-IN', {
    dateStyle: 'medium',
    timeStyle: 'short',
  }).format(new Date(value))
}

export const emptyPolicySection = () => ({ title: '', body: '' })
