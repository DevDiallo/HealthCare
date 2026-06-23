import { useEffect, useMemo, useState } from "react";
import type { FormEvent } from "react";
import PageHeader from "../components/PageHeader";
import { domainApi } from "../services/domainApi";
import type {
  ApiEnvelope,
  Appointment,
  Doctor,
  PageResponse,
  Patient,
} from "../types/domain";
import { dateTimeLabel } from "../utils/format";

type CreateAppointmentForm = {
  patientId: string;
  doctorId: string;
  appointmentAt: string;
};

export default function AppointmentsPage() {
  const [rows, setRows] = useState<Appointment[]>([]);
  const [patients, setPatients] = useState<Patient[]>([]);
  const [doctors, setDoctors] = useState<Doctor[]>([]);
  const [statusFilter, setStatusFilter] = useState<string>("");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [submitting, setSubmitting] = useState(false);
  const [form, setForm] = useState<CreateAppointmentForm>({
    patientId: "",
    doctorId: "",
    appointmentAt: "",
  });

  const patientLabel = useMemo(
    () =>
      Object.fromEntries(
        patients.map((p) => [p.id, `${p.firstName} ${p.lastName}`]),
      ),
    [patients],
  );

  const doctorLabel = useMemo(
    () =>
      Object.fromEntries(
        doctors.map((d) => [
          d.id,
          `Dr ${d.firstName} ${d.lastName} (${d.speciality})`,
        ]),
      ),
    [doctors],
  );

  async function loadAppointments() {
    setLoading(true);
    setError(null);
    try {
      const params: Record<string, unknown> = { page: 0, size: 50 };
      if (statusFilter) params.status = statusFilter;
      const [appointmentsRes, patientsRes, doctorsRes] = await Promise.all([
        domainApi.appointments(params),
        domainApi.patients({ page: 0, size: 200 }),
        domainApi.doctors({ page: 0, size: 200 }),
      ]);

      const appointmentsData =
        (appointmentsRes.data as ApiEnvelope<PageResponse<Appointment>>)?.data
          ?.content || [];
      const patientsData =
        (patientsRes.data as ApiEnvelope<PageResponse<Patient>>)?.data
          ?.content || [];
      const doctorsData =
        (doctorsRes.data as ApiEnvelope<PageResponse<Doctor>>)?.data?.content ||
        [];

      setRows(appointmentsData);
      setPatients(patientsData);
      setDoctors(doctorsData);
    } catch {
      setError("Impossible de charger les rendez-vous pour le moment.");
      setRows([]);
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    loadAppointments();
  }, [statusFilter]);

  async function onCreateAppointment(event: FormEvent) {
    event.preventDefault();
    setSubmitting(true);
    setError(null);
    try {
      await domainApi.createAppointment({
        patientId: form.patientId,
        doctorId: form.doctorId,
        appointmentAt: new Date(form.appointmentAt).toISOString().slice(0, 19),
      });
      setForm({ patientId: "", doctorId: "", appointmentAt: "" });
      await loadAppointments();
    } catch {
      setError(
        "Creation du rendez-vous impossible. Verifie les champs et les droits.",
      );
    } finally {
      setSubmitting(false);
    }
  }

  async function onWorkflowAction(
    action: "confirm" | "cancel" | "delete",
    id: string,
  ) {
    setError(null);
    try {
      if (action === "confirm") await domainApi.confirmAppointment(id);
      if (action === "cancel") await domainApi.cancelAppointment(id);
      if (action === "delete") await domainApi.deleteAppointment(id);
      await loadAppointments();
    } catch {
      setError(
        "Action impossible sur ce rendez-vous. Essaie de rafraichir l'ecran.",
      );
    }
  }

  return (
    <section>
      <PageHeader
        title="Rendez-vous"
        subtitle="Prise de rendez-vous, validation clinique et suivi du planning"
      />

      <div className="card-grid-two">
        <form className="profile-card form-grid" onSubmit={onCreateAppointment}>
          <h3>Nouveau rendez-vous</h3>
          <label>Patient</label>
          <select
            value={form.patientId}
            onChange={(e) =>
              setForm((prev) => ({ ...prev, patientId: e.target.value }))
            }
            required
          >
            <option value="">Selectionner un patient</option>
            {patients.map((p) => (
              <option
                key={p.id}
                value={p.id}
              >{`${p.firstName} ${p.lastName}`}</option>
            ))}
          </select>

          <label>Medecin</label>
          <select
            value={form.doctorId}
            onChange={(e) =>
              setForm((prev) => ({ ...prev, doctorId: e.target.value }))
            }
            required
          >
            <option value="">Selectionner un medecin</option>
            {doctors.map((d) => (
              <option
                key={d.id}
                value={d.id}
              >{`Dr ${d.firstName} ${d.lastName} - ${d.speciality}`}</option>
            ))}
          </select>

          <label>Date et heure</label>
          <input
            type="datetime-local"
            value={form.appointmentAt}
            onChange={(e) =>
              setForm((prev) => ({ ...prev, appointmentAt: e.target.value }))
            }
            required
          />

          <button type="submit" disabled={submitting}>
            {submitting ? "Creation..." : "Creer le rendez-vous"}
          </button>
        </form>

        <div className="profile-card form-grid">
          <h3>Filtrage & supervision</h3>
          <label>Statut</label>
          <select
            value={statusFilter}
            onChange={(e) => setStatusFilter(e.target.value)}
          >
            <option value="">Tous</option>
            <option value="PENDING">PENDING</option>
            <option value="CONFIRMED">CONFIRMED</option>
            <option value="CANCELLED">CANCELLED</option>
          </select>
          <button
            type="button"
            onClick={() => loadAppointments()}
            disabled={loading}
          >
            {loading ? "Chargement..." : "Rafraichir la liste"}
          </button>
        </div>
      </div>

      {error && <p className="inline-error">{error}</p>}

      <div className="table-wrap">
        <table>
          <thead>
            <tr>
              <th>Patient</th>
              <th>Medecin</th>
              <th>Date</th>
              <th>Statut</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            {rows.map((row) => (
              <tr key={row.id}>
                <td>{patientLabel[row.patientId] || row.patientId}</td>
                <td>{doctorLabel[row.doctorId] || row.doctorId}</td>
                <td>{dateTimeLabel(row.appointmentAt)}</td>
                <td>{row.status}</td>
                <td>
                  <div className="row-actions">
                    <button
                      type="button"
                      disabled={row.status !== "PENDING"}
                      onClick={() => onWorkflowAction("confirm", row.id)}
                    >
                      Confirmer
                    </button>
                    <button
                      type="button"
                      disabled={row.status === "CANCELLED"}
                      onClick={() => onWorkflowAction("cancel", row.id)}
                    >
                      Annuler
                    </button>
                    <button
                      type="button"
                      className="danger"
                      onClick={() => onWorkflowAction("delete", row.id)}
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
                  {loading ? "Chargement..." : "Aucun rendez-vous trouve."}
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
    </section>
  );
}
