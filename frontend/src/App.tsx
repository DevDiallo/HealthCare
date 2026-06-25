import { Navigate, Route, Routes } from "react-router-dom";
import AppLayout from "./layout/AppLayout";
import PrivateRoute from "./routes/PrivateRoute";
import HomePage from "./pages/HomePage";
import LoginPage from "./pages/LoginPage";
import RegisterPage from "./pages/RegisterPage";
import DashboardPage from "./pages/DashboardPage";
import HospitalsPage from "./pages/HospitalsPage";
import PatientsPage from "./pages/PatientsPage";
import DoctorsPage from "./pages/DoctorsPage";
import AppointmentsPage from "./pages/AppointmentsPage";
import NotificationsPage from "./pages/NotificationsPage";
import ProfilePage from "./pages/ProfilePage";
import AdminPage from "./pages/AdminPage";
import PatientSpacePage from "./pages/PatientSpacePage";
import DoctorSpacePage from "./pages/DoctorSpacePage";
import { useAppSelector } from "./app/hooks";

function DefaultRoute() {
  const role = useAppSelector((state) => state.auth.role);
  if (role === "PATIENT") return <Navigate to="/patient-dashboard" replace />;
  if (role === "DOCTOR") return <Navigate to="/doctor-dashboard" replace />;
  return <Navigate to="/dashboard" replace />;
}

export default function App() {
  return (
    <Routes>
      <Route path="/" element={<HomePage />} />
      <Route path="/login" element={<LoginPage />} />
      <Route path="/register" element={<RegisterPage />} />

      <Route element={<PrivateRoute />}>
        <Route element={<AppLayout />}>
          <Route path="/home" element={<DefaultRoute />} />

          {/* Espace patient */}
          <Route
            path="/patient-space"
            element={<Navigate to="/patient-dashboard" replace />}
          />
          <Route
            path="/patient-dashboard"
            element={<PatientSpacePage initialTab="dashboard" />}
          />
          <Route
            path="/patient-medical-record"
            element={<PatientSpacePage initialTab="dossier" />}
          />
          <Route
            path="/patient-appointments"
            element={<PatientSpacePage initialTab="appointments" />}
          />
          <Route
            path="/patient-contact"
            element={<PatientSpacePage initialTab="messages" />}
          />

          {/* Espace médecin */}
          <Route
            path="/doctor-space"
            element={<Navigate to="/doctor-dashboard" replace />}
          />
          <Route
            path="/doctor-dashboard"
            element={<DoctorSpacePage initialTab="dashboard" />}
          />
          <Route
            path="/doctor-patients"
            element={<DoctorSpacePage initialTab="patients" />}
          />
          <Route
            path="/doctor-appointments"
            element={<DoctorSpacePage initialTab="planning" />}
          />
          <Route
            path="/doctor-contact"
            element={<DoctorSpacePage initialTab="messages" />}
          />

          {/* Back-office admin */}
          <Route path="/dashboard" element={<DashboardPage />} />
          <Route path="/hospitals" element={<HospitalsPage />} />
          <Route path="/patients" element={<PatientsPage />} />
          <Route path="/doctors" element={<DoctorsPage />} />
          <Route path="/appointments" element={<AppointmentsPage />} />
          <Route path="/notifications" element={<NotificationsPage />} />
          <Route path="/admin" element={<AdminPage />} />

          {/* Commun */}
          <Route path="/profile" element={<ProfilePage />} />
        </Route>
      </Route>

      <Route path="*" element={<Navigate to="/" replace />} />
    </Routes>
  );
}
