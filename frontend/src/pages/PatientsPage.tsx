import { useEffect, useState } from "react";
import type { FormEvent } from "react";
import PageHeader from "../components/PageHeader";
import { domainApi } from "../services/domainApi";
import type {
  ApiEnvelope,
  Appointment,
  Notification,
  PageResponse,
  Patient,
} from "../types/domain";
import { dateTimeLabel } from "../utils/format";

type PatientForm = {
  id?: string;
  firstName: string;
  lastName: string;
  email: string;
  bloodType: string;
  allergies: string;
  chronicConditions: string;
  emergencyContact: string;
};

export default function PatientsPage() {
  const [rows, setRows] = useState<Patient[]>([]);
  const [appointments, setAppointments] = useState<Appointment[]>([]);
  const [notifications, setNotifications] = useState<Notification[]>([]);
  const [selectedPatientId, setSelectedPatientId] = useState<string>("");
  const [search, setSearch] = useState("");
  const [loading, setLoading] = useState(false);
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [form, setForm] = useState<PatientForm>({
    firstName: "",
    lastName: "",
    email: "",
    bloodType: "",
    allergies: "",
    chronicConditions: "",
    emergencyContact: "",
  });

  const selectedPatient = rows.find((row) => row.id === selectedPatientId);

  async function loadPatients() {
    setLoading(true);
    setError(null);
    try {
      const [patientsRes, appointmentsRes, notificationsRes] =
        await Promise.all([
          domainApi.patients({ page: 0, size: 200, search }),
          domainApi.appointments({ page: 0, size: 200 }),
          domainApi.notifications({ page: 0, size: 200 }),
        ]);

      const patientsData =
        (patientsRes.data as ApiEnvelope<PageResponse<Patient>>)?.data
          ?.content || [];
      setRows(patientsData);
      if (!selectedPatientId && patientsData[0]) {
        setSelectedPatientId(patientsData[0].id);
      }

      setAppointments(
        (appointmentsRes.data as ApiEnvelope<PageResponse<Appointment>>)?.data
          ?.content || [],
      );
      setNotifications(
        (notificationsRes.data as ApiEnvelope<PageResponse<Notification>>)?.data
          ?.content || [],
      );
    } catch {
      setError("Chargement des patients impossible pour le moment.");
      setRows([]);
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    loadPatients();
  }, [search]);

  function startEditPatient(patient: Patient) {
    setForm({
      id: patient.id,
      firstName: patient.firstName,
      lastName: patient.lastName,
      email: patient.email,
      bloodType: patient.bloodType || "",
      allergies: patient.allergies || "",
      chronicConditions: patient.chronicConditions || "",
      emergencyContact: patient.emergencyContact || "",
    });
  }

  function resetForm() {
    setForm({
      firstName: "",
      lastName: "",
      email: "",
      bloodType: "",
      allergies: "",
      chronicConditions: "",
      emergencyContact: "",
    });
  }

  async function onSubmit(event: FormEvent) {
    event.preventDefault();
    setSubmitting(true);
    setError(null);
    try {
      const payload = {
        firstName: form.firstName,
        lastName: form.lastName,
        email: form.email,
        bloodType: form.bloodType || null,
        allergies: form.allergies || null,
        chronicConditions: form.chronicConditions || null,
        emergencyContact: form.emergencyContact || null,
      };

      if (form.id) {
        await domainApi.updatePatient(form.id, payload);
      } else {
        await domainApi.createPatient(payload);
      }

      resetForm();
      await loadPatients();
    } catch {
      setError(
        "Enregistrement du patient impossible. Verifie les informations saisies.",
      );
    } finally {
      setSubmitting(false);
    }
  }

  async function onDeletePatient(id: string) {
    setError(null);
    try {
      await domainApi.deletePatient(id);
      if (selectedPatientId === id) {
        setSelectedPatientId("");
      }
      await loadPatients();
    } catch {
      setError("Suppression impossible pour ce patient.");
    }
  }

  const selectedPatientAppointments = appointments
    .filter((item) => item.patientId === selectedPatientId)
    .sort(
      (a, b) =>
        new Date(b.appointmentAt).getTime() -
        new Date(a.appointmentAt).getTime(),
    );

  const selectedPatientMessages = notifications
    .filter((item) => item.recipientUserId === selectedPatientId)
    .sort(
      (a, b) =>
        new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime(),
    );

  return (
    <section>
      <PageHeader
        title="Patients"
        subtitle="Dossiers medicaux, suivi clinique et communication continue"
      />

      <div className="profile-card toolbar-row">
        <input
          placeholder="Rechercher par nom, email, allergies, pathologies..."
          value={search}
          onChange={(e) => setSearch(e.target.value)}
        />
        <button type="button" onClick={() => loadPatients()} disabled={loading}>
          {loading ? "Chargement..." : "Rafraichir"}
        </button>
      </div>

      <div className="card-grid-two">
        <form className="profile-card form-grid" onSubmit={onSubmit}>
          <h3>{form.id ? "Editer un patient" : "Nouveau patient"}</h3>
          <label>Prenom</label>
          <input
            value={form.firstName}
            onChange={(e) =>
              setForm((p) => ({ ...p, firstName: e.target.value }))
            }
            required
          />
          <label>Nom</label>
          <input
            value={form.lastName}
            onChange={(e) =>
              setForm((p) => ({ ...p, lastName: e.target.value }))
            }
            required
          />
          <label>Email</label>
          <input
            type="email"
            value={form.email}
            onChange={(e) => setForm((p) => ({ ...p, email: e.target.value }))}
            required
          />
          <label>Groupe sanguin</label>
          <input
            value={form.bloodType}
            onChange={(e) =>
              setForm((p) => ({ ...p, bloodType: e.target.value }))
            }
            placeholder="A+, O-, AB..."
          />
          <label>Allergies</label>
          <textarea
            value={form.allergies}
            onChange={(e) =>
              setForm((p) => ({ ...p, allergies: e.target.value }))
            }
          />
          <label>Pathologies chroniques</label>
          <textarea
            value={form.chronicConditions}
            onChange={(e) =>
              setForm((p) => ({ ...p, chronicConditions: e.target.value }))
            }
          />
          <label>Contact urgence</label>
          <input
            value={form.emergencyContact}
            onChange={(e) =>
              setForm((p) => ({ ...p, emergencyContact: e.target.value }))
            }
            placeholder="Nom + telephone"
          />
          <div className="row-actions">
            <button type="submit" disabled={submitting}>
              {submitting ? "Enregistrement..." : "Enregistrer"}
            </button>
            <button type="button" onClick={resetForm}>
              Reinitialiser
            </button>
          </div>
        </form>

        <div className="table-wrap">
          <table>
            <thead>
              <tr>
                <th>Patient</th>
                <th>Email</th>
                <th>Groupe</th>
                <th>Urgence</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {rows.map((row) => (
                <tr
                  key={row.id}
                  className={selectedPatientId === row.id ? "row-selected" : ""}
                >
                  <td>{`${row.firstName} ${row.lastName}`}</td>
                  <td>{row.email}</td>
                  <td>{row.bloodType || "-"}</td>
                  <td>{row.emergencyContact || "-"}</td>
                  <td>
                    <div className="row-actions">
                      <button
                        type="button"
                        onClick={() => setSelectedPatientId(row.id)}
                      >
                        Dossier
                      </button>
                      <button
                        type="button"
                        onClick={() => startEditPatient(row)}
                      >
                        Editer
                      </button>
                      <button
                        type="button"
                        className="danger"
                        onClick={() => onDeletePatient(row.id)}
                      >
                        Supprimer
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
              {!rows.length && (
                <tr>
                  <td colSpan={5}>
                    {loading ? "Chargement..." : "Aucun patient trouve."}
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </div>

      {error && <p className="inline-error">{error}</p>}

      <div className="card-grid-two">
        <div className="profile-card">
          <h3>
            Dossier medical{" "}
            {selectedPatient
              ? `- ${selectedPatient.firstName} ${selectedPatient.lastName}`
              : ""}
          </h3>
          {!selectedPatient && (
            <p>Selectionne un patient pour consulter son dossier detaille.</p>
          )}
          {selectedPatient && (
            <>
              <p>
                <strong>Allergies:</strong>{" "}
                {selectedPatient.allergies || "Aucune information"}
              </p>
              <p>
                <strong>Pathologies chroniques:</strong>{" "}
                {selectedPatient.chronicConditions || "Aucune information"}
              </p>
              <p>
                <strong>Contact urgence:</strong>{" "}
                {selectedPatient.emergencyContact || "Aucune information"}
              </p>
            </>
          )}
        </div>

        <div className="profile-card">
          <h3>Historique de suivi</h3>
          {!selectedPatient && <p>Aucun patient selectionne.</p>}
          {selectedPatient && (
            <>
              <h4>Rendez-vous</h4>
              <ul className="timeline-list">
                {selectedPatientAppointments.slice(0, 5).map((item) => (
                  <li
                    key={item.id}
                  >{`${dateTimeLabel(item.appointmentAt)} - ${item.status}`}</li>
                ))}
                {!selectedPatientAppointments.length && (
                  <li>Aucun rendez-vous enregistre.</li>
                )}
              </ul>

              <h4>Messages recus</h4>
              <ul className="timeline-list">
                {selectedPatientMessages.slice(0, 5).map((item) => (
                  <li
                    key={item.id}
                  >{`${dateTimeLabel(item.createdAt)} - ${item.title}`}</li>
                ))}
                {!selectedPatientMessages.length && (
                  <li>Aucun message enregistre.</li>
                )}
              </ul>
            </>
          )}
        </div>
      </div>
    </section>
  );
}
