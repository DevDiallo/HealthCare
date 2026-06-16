import { NavLink, Outlet } from 'react-router-dom'
import { useAppDispatch, useAppSelector } from '../app/hooks'
import { logout } from '../features/auth/authSlice'

const links = [
  { to: '/dashboard', label: 'Dashboard' },
  { to: '/hospitals', label: 'Hopitaux' },
  { to: '/patients', label: 'Patients' },
  { to: '/doctors', label: 'Medecins' },
  { to: '/appointments', label: 'Rendez-vous' },
  { to: '/notifications', label: 'Notifications' },
  { to: '/profile', label: 'Profil' },
  { to: '/admin', label: 'Administration' },
]

export default function AppLayout() {
  const dispatch = useAppDispatch()
  const role = useAppSelector((state) => state.auth.role)

  return (
    <div className="layout-shell">
      <aside className="sidebar">
        <h2>HealthCare SaaS</h2>
        <p className="role">Role: {role || 'Guest'}</p>
        <nav>
          {links.map((item) => (
            <NavLink key={item.to} to={item.to} className={({ isActive }) => (isActive ? 'active' : '')}>
              {item.label}
            </NavLink>
          ))}
        </nav>
        <button onClick={() => dispatch(logout())}>Se deconnecter</button>
      </aside>
      <main className="content">
        <Outlet />
      </main>
    </div>
  )
}
