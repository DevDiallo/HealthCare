import { NavLink, Outlet } from "react-router-dom";
import { useAppDispatch, useAppSelector } from "../app/hooks";
import { logout } from "../features/auth/authSlice";
import type { UserRole } from "../types/auth";

type NavItem = { to: string; label: string };

const ADMIN_LINKS: NavItem[] = [
  { to: "/dashboard", label: "Dashboard" },
  { to: "/hospitals", label: "Hôpitaux" },
  { to: "/patients", label: "Patients" },
  { to: "/doctors", label: "Médecins" },
  { to: "/appointments", label: "Rendez-vous" },
  { to: "/notifications", label: "Communications" },
  { to: "/profile", label: "Profil" },
  { to: "/admin", label: "Administration" },
];

const DOCTOR_LINKS: NavItem[] = [
  { to: "/doctor-dashboard", label: "Dashboard" },
  { to: "/doctor-patients", label: "Mes patients" },
  { to: "/doctor-appointments", label: "Rendez-vous" },
  { to: "/doctor-contact", label: "Contact" },
];

const PATIENT_LINKS: NavItem[] = [
  { to: "/patient-dashboard", label: "Dashboard" },
  { to: "/patient-medical-record", label: "Mon dossier medical" },
  { to: "/patient-appointments", label: "Rendez-vous" },
  { to: "/patient-contact", label: "Contact" },
];

const ROLE_LABELS: Record<string, string> = {
  SUPER_ADMIN: "Super Administrateur",
  HOSPITAL_ADMIN: "Administrateur",
  DOCTOR: "Médecin",
  PATIENT: "Patient",
  NURSE: "Infirmier·e",
  RECEPTIONIST: "Réceptionniste",
};

function linksForRole(role: UserRole | null): NavItem[] {
  if (role === "PATIENT") return PATIENT_LINKS;
  if (role === "DOCTOR") return DOCTOR_LINKS;
  return ADMIN_LINKS;
}

export default function AppLayout() {
  const dispatch = useAppDispatch();
  const role = useAppSelector((state) => state.auth.role);
  const links = linksForRole(role);

  return (
    <div className="layout-shell">
      <aside className="sidebar">
        <div className="sidebar-brand">
          <span className="sidebar-logo">⚕</span>
          <h2>HealthCare</h2>
        </div>
        <p className="role-badge">
          {ROLE_LABELS[role || ""] || role || "Guest"}
        </p>
        <nav>
          {links.map((item) => (
            <NavLink
              key={item.to}
              to={item.to}
              className={({ isActive }) => (isActive ? "active" : "")}
            >
              {item.label}
            </NavLink>
          ))}
        </nav>
        <button className="logout-btn" onClick={() => dispatch(logout())}>
          Se déconnecter
        </button>
      </aside>
      <main className="content">
        <Outlet />
      </main>
    </div>
  );
}
