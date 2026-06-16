export type UserRole =
  | 'SUPER_ADMIN'
  | 'HOSPITAL_ADMIN'
  | 'DOCTOR'
  | 'PATIENT'
  | 'NURSE'
  | 'RECEPTIONIST'

export interface LoginRequest {
  email: string
  password: string
}

export interface RegisterRequest {
  firstName: string
  lastName: string
  email: string
  password: string
  phone: string
  hospitalId: number
  role: UserRole
}

export interface TokenResponse {
  accessToken: string
  refreshToken: string
  userId: number
  hospitalId: number
  role: UserRole
  tokenType: string
  expiresIn: number
}

export interface AuthState {
  token: string | null
  refreshToken: string | null
  role: UserRole | null
  userId: number | null
  hospitalId: number | null
}
