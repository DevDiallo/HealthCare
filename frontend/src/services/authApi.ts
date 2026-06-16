import http from './http'
import type { LoginRequest, RegisterRequest, TokenResponse } from '../types/auth'

export const authApi = {
  login: async (payload: LoginRequest) => {
    const { data } = await http.post('/auth/login', payload)
    return data.data as TokenResponse
  },
  register: async (payload: RegisterRequest) => {
    const { data } = await http.post('/auth/register', payload)
    return data.data as TokenResponse
  },
}
