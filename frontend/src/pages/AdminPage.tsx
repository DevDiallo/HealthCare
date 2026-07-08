import { useEffect, useMemo, useState } from "react";
import PageHeader from "../components/PageHeader";
import { domainApi } from "../services/domainApi";
import type {
  ApiEnvelope,
  Appointment,
  Doctor,
  PageResponse,
  Patient,
} from "../types/domain";

export default function AdminPage() {
  const [patients, setPatients] = useState<Patient[]>([]);
  const [doctors, setDoctors] = useState<Doctor[]>([]);
  const [appointments, setAppointments] = useState<Appointment[]>([]);
  const [loading, setLoading] = useState(false);
  const [savingId, setSavingId] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);
  const [assignments, setAssignments] = useState<Record<string, string>>({});

  const doctorLabel = useMemo(
    () =>
      Object.fromEntries(
        doctors.map((doctor) => [
          doctor.userAccountId || doctor.id,
          `Dr ${doctor.firstName} ${doctor.lastName} (${doctor.speciality})`,
        ]),
      ),
    [doctors],
  );

  async function loadData() {
    setLoading(true);
    setError(null);
    try {
      const [patientsRes, doctorsRes, appointmentsRes] = await Promise.all([
        domainApi.patients({ page: 0, size: 300 }),
        domainApi.doctors({ page: 0, size: 300 }),
        domainApi.appointments({ page: 0, size: 300 }),
      ]);

      const patientRows =
        (patientsRes.data as ApiEnvelope<PageResponse<Patient>>)?.data
          ?.content || [];
      const doctorRows =
        (doctorsRes.data as ApiEnvelope<PageResponse<Doctor>>)?.data?.content ||
        [];
      const appointmentRows =
        (appointmentsRes.data as ApiEnvelope<PageResponse<Appointment>>)?.data
          ?.content || [];

      setPatients(patientRows);
      setDoctors(doctorRows);
      setAppointments(appointmentRows);
      setAssignments(
        Object.fromEntries(
          patientRows.map((patient) => [
            patient.id,
            patient.assignedDoctorUserId || "",
          ]),
        ),
      );
    } catch {
      setError("Impossible de charger la vue globale d'administration.");
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    loadData();
  }, []);

  async function assignDoctor(patient: Patient) {
    setSavingId(patient.id);
    setError(null);
    setSuccess(null);
    try {
      await domainApi.updatePatient(patient.id, {
        firstName: patient.firstName,
        lastName: patient.lastName,
        email: patient.email,
        bloodType: patient.bloodType || null,
        allergies: patient.allergies || null,
        chronicConditions: patient.chronicConditions || null,
        emergencyContact: patient.emergencyContact || null,
        userAccountId: patient.userAccountId || null,
        assignedDoctorUserId: assignments[patient.id] || null,
      });
      setSuccess("Affectation médecin mise à jour.");
      await loadData();
    } catch {
      setError("Impossible d'affecter ce patient au médecin sélectionné.");
    } finally {
      setSavingId(null);
    }
  }

  return (
    <section>
      <PageHeader
        title="Administration"
        subtitle="Vue globale de la plateforme, accès patients/médecins et affectation clinique"
      />

      <div className="stats-grid" style={{ marginBottom: "1rem" }}>
        <div className="stat-card">
          <p className="stat-label">Patients</p>
          <h3>{patients.length}</h3>
        </div>
        <div className="stat-card">
          <p className="stat-label">Médecins</p>
          <h3>{doctors.length}</h3>
        </div>
        <div className="stat-card">
          <p className="stat-label">Patients affectés</p>
          <h3>{patients.filter((p) => p.assignedDoctorUserId).length}</h3>
        </div>
        <div className="stat-card">
          <p className="stat-label">Rendez-vous</p>
          <h3>{appointments.length}</h3>
        </div>
      </div>

      {error ? <p className="inline-error">{error}</p> : null}
      {success ? <p className="inline-success">{success}</p> : null}

      <div className="profile-card toolbar-row">
        <button type="button" onClick={() => loadData()} disabled={loading}>
          {loading ? "Chargement..." : "Rafraichir la vue globale"}
        </button>
      </div>

      <div className="table-wrap">
        <table>
          <thead>
            <tr>
              <th>Patient</th>
              <th>Email</th>
              <th>Médecin affecté</th>
              <th>Compte lié</th>
              <th>Action</th>
            </tr>
          </thead>
          <tbody>
            {patients.map((patient) => (
              <tr key={patient.id}>
                <td>
                  {patient.firstName} {patient.lastName}
                </td>
                <td>{patient.email}</td>
                <td>
                  <select
                    value={assignments[patient.id] || ""}
                    onChange={(e) =>
                      setAssignments((prev) => ({
                        ...prev,
                        [patient.id]: e.target.value,
                      }))
                    }
                  >
                    <option value="">Aucun médecin</option>
                    {doctors
                      .filter((doctor) => doctor.userAccountId)
                      .map((doctor) => (
                        <option
                          key={doctor.id}
                          value={doctor.userAccountId || ""}
                        >
                          {`Dr ${doctor.firstName} ${doctor.lastName} (${doctor.speciality})`}
                        </option>
                      ))}
                  </select>
                </td>
                <td>{patient.userAccountId || "Non lié"}</td>
                <td>
                  <button
                    type="button"
                    onClick={() => assignDoctor(patient)}
                    disabled={savingId === patient.id}
                  >
                    {savingId === patient.id ? "Enregistrement..." : "Affecter"}
                  </button>
                </td>
              </tr>
            ))}
            {!patients.length ? (
              <tr>
                <td colSpan={5}>
                  {loading ? "Chargement..." : "Aucun patient disponible."}
                </td>
              </tr>
            ) : null}
          </tbody>
        </table>
      </div>

      <div className="card-grid-two" style={{ marginTop: "1rem" }}>
        <div className="profile-card">
          <h3>Médecins disponibles</h3>
          <ul className="timeline-list">
            {doctors.map((doctor) => (
              <li key={doctor.id}>
                {`Dr ${doctor.firstName} ${doctor.lastName} — ${doctor.speciality}`}
                {doctor.userAccountId
                  ? ` · Compte lié ${doctor.userAccountId}`
                  : " · Compte non lié"}
              </li>
            ))}
          </ul>
        </div>

        <div className="profile-card">
          <h3>Répartition actuelle</h3>
          <ul className="timeline-list">
            {patients.map((patient) => (
              <li key={patient.id}>
                {patient.firstName} {patient.lastName}
                {patient.assignedDoctorUserId
                  ? ` · ${doctorLabel[patient.assignedDoctorUserId] || patient.assignedDoctorUserId}`
                  : " · Aucun médecin affecté"}
              </li>
            ))}
          </ul>
        </div>
      </div>
    </section>
  );
}
