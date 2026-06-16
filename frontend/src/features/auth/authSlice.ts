import { createSlice, type PayloadAction } from '@reduxjs/toolkit'
import type { AuthState, TokenResponse } from '../../types/auth'

const initialState: AuthState = {
  token: localStorage.getItem('hc_access_token'),
  refreshToken: localStorage.getItem('hc_refresh_token'),
  role: (localStorage.getItem('hc_role') as AuthState['role']) || null,
  userId: localStorage.getItem('hc_user_id') ? Number(localStorage.getItem('hc_user_id')) : null,
  hospitalId: localStorage.getItem('hc_hospital_id') ? Number(localStorage.getItem('hc_hospital_id')) : null,
}

const authSlice = createSlice({
  name: 'auth',
  initialState,
  reducers: {
    setSession: (state, action: PayloadAction<TokenResponse>) => {
      const payload = action.payload
      state.token = payload.accessToken
      state.refreshToken = payload.refreshToken
      state.role = payload.role
      state.userId = payload.userId
      state.hospitalId = payload.hospitalId

      localStorage.setItem('hc_access_token', payload.accessToken)
      localStorage.setItem('hc_refresh_token', payload.refreshToken)
      localStorage.setItem('hc_role', payload.role)
      localStorage.setItem('hc_user_id', String(payload.userId))
      localStorage.setItem('hc_hospital_id', String(payload.hospitalId))
    },
    logout: (state) => {
      state.token = null
      state.refreshToken = null
      state.role = null
      state.userId = null
      state.hospitalId = null
      localStorage.removeItem('hc_access_token')
      localStorage.removeItem('hc_refresh_token')
      localStorage.removeItem('hc_role')
      localStorage.removeItem('hc_user_id')
      localStorage.removeItem('hc_hospital_id')
    },
  },
})

export const { setSession, logout } = authSlice.actions
export default authSlice.reducer
