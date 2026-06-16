import http from './http'

export const domainApi = {
  hospitals: (params?: Record<string, unknown>) => http.get('/hospitals', { params }),
  patients: (params?: Record<string, unknown>) => http.get('/patients', { params }),
  doctors: (params?: Record<string, unknown>) => http.get('/doctors', { params }),
  appointments: (params?: Record<string, unknown>) => http.get('/appointments', { params }),
  notifications: (params?: Record<string, unknown>) => http.get('/notifications', { params }),
}
