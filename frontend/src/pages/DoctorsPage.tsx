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

type DoctorForm = {
  id?: string;
  firstName: string;
  lastName: string;
  speciality: string;
};

export default function DoctorsPage() {
  const [rows, setRows] = useState<Doctor[]>([]);
  const [patients, setPatients] = useState<Patient[]>([]);
  const [appointments, setAppointments] = useState<Appointment[]>([]);
  const [search, setSearch] = useState("");
  const [speciality, setSpeciality] = useState("");
  const [selectedDoctorId, setSelectedDoctorId] = useState<string>("");
  const [loading, setLoading] = useState(false);
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [form, setForm] = useState<DoctorForm>({
    firstName: "",
    lastName: "",
    speciality: "",
  });

  const patientLabel = useMemo(
    () =>
      Object.fromEntries(
        patients.map((p) => [p.id, `${p.firstName} ${p.lastName}`]),
      ),
    [patients],
  );

  const selectedDoctorAppointments = appointments
    .filter((item) => item.doctorId === selectedDoctorId)
    .sort(
      (a, b) =>
        new Date(b.appointmentAt).getTime() -
        new Date(a.appointmentAt).getTime(),
    );

  async function loadDoctors() {
    setLoading(true);
    setError(null);
    try {
      const [doctorsRes, patientsRes, appointmentsRes] = await Promise.all([
        domainApi.doctors({ page: 0, size: 200, search, speciality }),
        domainApi.patients({ page: 0, size: 200 }),
        domainApi.appointments({ page: 0, size: 400 }),
      ]);

      const doctorsData =
        (doctorsRes.data as ApiEnvelope<PageResponse<Doctor>>)?.data?.content ||
        [];
      setRows(doctorsData);
      if (!selectedDoctorId && doctorsData[0]) {
        setSelectedDoctorId(doctorsData[0].id);
      }

      setPatients(
        (patientsRes.data as ApiEnvelope<PageResponse<Patient>>)?.data
          ?.content || [],
      );
      setAppointments(
        (appointmentsRes.data as ApiEnvelope<PageResponse<Appointment>>)?.data
          ?.content || [],
      );
    } catch {
      setError("Impossible de charger les medecins pour le moment.");
      setRows([]);
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    loadDoctors();
  }, [search, speciality]);

  function onEditDoctor(doctor: Doctor) {
    setForm({
      id: doctor.id,
      firstName: doctor.firstName,
      lastName: doctor.lastName,
      speciality: doctor.speciality,
    });
  }

  function resetForm() {
    setForm({ firstName: "", lastName: "", speciality: "" });
  }

  async function onSubmit(event: FormEvent) {
    event.preventDefault();
    setSubmitting(true);
    setError(null);
    try {
      const payload = {
        firstName: form.firstName,
        lastName: form.lastName,
        speciality: form.speciality,
      };

      if (form.id) {
        await domainApi.updateDoctor(form.id, payload);
      } else {
        await domainApi.createDoctor(payload);
      }

      resetForm();
      await loadDoctors();
    } catch {
      setError("Enregistrement du medecin impossible.");
    } finally {
      setSubmitting(false);
    }
  }

  async function onDeleteDoctor(id: string) {
    setError(null);
    try {
      await domainApi.deleteDoctor(id);
      if (selectedDoctorId === id) {
        setSelectedDoctorId("");
      }
      await loadDoctors();
    } catch {
      setError("Suppression du medecin impossible.");
    }
  }

  return (
    <section>
      <PageHeader
        title="Medecins"
        subtitle="Pilotage professionnel des patients, specialites et planning clinique"
      />

      <div className="profile-card toolbar-row">
        <input
          placeholder="Rechercher un medecin"
          value={search}
          onChange={(e) => setSearch(e.target.value)}
        />
        <input
          placeholder="Filtrer par specialite"
          value={speciality}
          onChange={(e) => setSpeciality(e.target.value)}
        />
        <button type="button" onClick={() => loadDoctors()} disabled={loading}>
          {loading ? "Chargement..." : "Rafraichir"}
        </button>
      </div>

      <div className="card-grid-two">
        <form className="profile-card form-grid" onSubmit={onSubmit}>
          <h3>{form.id ? "Editer un medecin" : "Nouveau medecin"}</h3>
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
          <label>Specialite</label>
          <input
            value={form.speciality}
            onChange={(e) =>
              setForm((p) => ({ ...p, speciality: e.target.value }))
            }
            required
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
                <th>Medecin</th>
                <th>Specialite</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {rows.map((row) => (
                <tr
                  key={row.id}
                  className={selectedDoctorId === row.id ? "row-selected" : ""}
                >
                  <td>{`Dr ${row.firstName} ${row.lastName}`}</td>
                  <td>{row.speciality}</td>
                  <td>
                    <div className="row-actions">
                      <button
                        type="button"
                        onClick={() => setSelectedDoctorId(row.id)}
                      >
                        Suivi patients
                      </button>
                      <button type="button" onClick={() => onEditDoctor(row)}>
                        Editer
                      </button>
                      <button
                        type="button"
                        className="danger"
                        onClick={() => onDeleteDoctor(row.id)}
                      >
                        Supprimer
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
              {!rows.length && (
                <tr>
                  <td colSpan={3}>
                    {loading ? "Chargement..." : "Aucun medecin trouve."}
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </div>

      {error && <p className="inline-error">{error}</p>}

      <div className="profile-card">
        <h3>Suivi clinique du medecin</h3>
        {!selectedDoctorId && (
          <p>
            Selectionne un medecin pour afficher ses patients et rendez-vous.
          </p>
        )}
        {!!selectedDoctorId && (
          <div className="table-wrap">
            <table>
              <thead>
                <tr>
                  <th>Date</th>
                  <th>Patient</th>
                  <th>Statut</th>
                </tr>
              </thead>
              <tbody>
                {selectedDoctorAppointments.slice(0, 15).map((item) => (
                  <tr key={item.id}>
                    <td>{dateTimeLabel(item.appointmentAt)}</td>
                    <td>{patientLabel[item.patientId] || item.patientId}</td>
                    <td>{item.status}</td>
                  </tr>
                ))}
                {!selectedDoctorAppointments.length && (
                  <tr>
                    <td colSpan={3}>Aucun rendez-vous pour ce medecin.</td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </section>
  );
}
