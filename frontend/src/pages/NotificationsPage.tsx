import { useEffect, useMemo, useState } from "react";
import type { FormEvent } from "react";
import PageHeader from "../components/PageHeader";
import { domainApi } from "../services/domainApi";
import type {
  ApiEnvelope,
  Doctor,
  Notification,
  PageResponse,
  Patient,
} from "../types/domain";
import { dateTimeLabel } from "../utils/format";

type MessageForm = {
  recipientUserId: string;
  title: string;
  message: string;
};

export default function NotificationsPage() {
  const [rows, setRows] = useState<Notification[]>([]);
  const [patients, setPatients] = useState<Patient[]>([]);
  const [doctors, setDoctors] = useState<Doctor[]>([]);
  const [recipientType, setRecipientType] = useState<"PATIENT" | "DOCTOR">(
    "PATIENT",
  );
  const [submitting, setSubmitting] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [form, setForm] = useState<MessageForm>({
    recipientUserId: "",
    title: "",
    message: "",
  });

  const recipientOptions = useMemo(
    () =>
      recipientType === "PATIENT"
        ? patients.map((p) => ({
            id: p.id,
            label: `${p.firstName} ${p.lastName} (Patient)`,
          }))
        : doctors.map((d) => ({
            id: d.id,
            label: `Dr ${d.firstName} ${d.lastName} (${d.speciality})`,
          })),
    [recipientType, patients, doctors],
  );

  async function loadData() {
    setLoading(true);
    setError(null);
    try {
      const [notificationsRes, patientsRes, doctorsRes] = await Promise.all([
        domainApi.notifications({ page: 0, size: 200 }),
        domainApi.patients({ page: 0, size: 200 }),
        domainApi.doctors({ page: 0, size: 200 }),
      ]);

      setRows(
        (notificationsRes.data as ApiEnvelope<PageResponse<Notification>>)?.data
          ?.content || [],
      );
      setPatients(
        (patientsRes.data as ApiEnvelope<PageResponse<Patient>>)?.data
          ?.content || [],
      );
      setDoctors(
        (doctorsRes.data as ApiEnvelope<PageResponse<Doctor>>)?.data?.content ||
          [],
      );
    } catch {
      setError("Impossible de charger les communications.");
      setRows([]);
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    loadData();
  }, []);

  useEffect(() => {
    setForm((prev) => ({ ...prev, recipientUserId: "" }));
  }, [recipientType]);

  async function onCreateMessage(event: FormEvent) {
    event.preventDefault();
    setSubmitting(true);
    setError(null);
    try {
      await domainApi.createNotification({
        recipientUserId: form.recipientUserId,
        title: form.title,
        message: form.message,
      });
      setForm({ recipientUserId: "", title: "", message: "" });
      await loadData();
    } catch {
      setError(
        "Envoi du message impossible. Verifie le destinataire et le contenu.",
      );
    } finally {
      setSubmitting(false);
    }
  }

  async function onSend(id: string) {
    setError(null);
    try {
      await domainApi.sendNotification(id);
      await loadData();
    } catch {
      setError("Le message ne peut pas etre marque comme envoye.");
    }
  }

  return (
    <section>
      <PageHeader
        title="Communication"
        subtitle="Messagerie securisee patient-medecin et notifications cliniques"
      />

      <div className="card-grid-two">
        <form className="profile-card form-grid" onSubmit={onCreateMessage}>
          <h3>Nouveau message</h3>

          <label>Type de destinataire</label>
          <select
            value={recipientType}
            onChange={(e) =>
              setRecipientType(e.target.value as "PATIENT" | "DOCTOR")
            }
          >
            <option value="PATIENT">Patient</option>
            <option value="DOCTOR">Medecin</option>
          </select>

          <label>Destinataire</label>
          <select
            value={form.recipientUserId}
            onChange={(e) =>
              setForm((prev) => ({ ...prev, recipientUserId: e.target.value }))
            }
            required
          >
            <option value="">Selectionner...</option>
            {recipientOptions.map((item) => (
              <option key={item.id} value={item.id}>
                {item.label}
              </option>
            ))}
          </select>

          <label>Titre</label>
          <input
            value={form.title}
            onChange={(e) =>
              setForm((prev) => ({ ...prev, title: e.target.value }))
            }
            required
          />

          <label>Message</label>
          <textarea
            value={form.message}
            onChange={(e) =>
              setForm((prev) => ({ ...prev, message: e.target.value }))
            }
            rows={5}
            required
          />

          <button type="submit" disabled={submitting}>
            {submitting ? "Creation..." : "Creer le message"}
          </button>
        </form>

        <div className="profile-card form-grid">
          <h3>Bonnes pratiques pro</h3>
          <ul className="timeline-list">
            <li>
              Informer le patient avec des messages clairs et actionnables.
            </li>
            <li>Centraliser les echanges sensibles dans ce canal trace.</li>
            <li>
              Associer chaque message au bon destinataire pour un suivi fiable.
            </li>
            <li>Marquer rapidement les messages traites comme envoyes.</li>
          </ul>
          <button type="button" onClick={() => loadData()} disabled={loading}>
            {loading ? "Chargement..." : "Rafraichir les echanges"}
          </button>
        </div>
      </div>

      {error && <p className="inline-error">{error}</p>}

      <div className="table-wrap">
        <table>
          <thead>
            <tr>
              <th>Titre</th>
              <th>Destinataire</th>
              <th>Statut</th>
              <th>Cree le</th>
              <th>Action</th>
            </tr>
          </thead>
          <tbody>
            {rows.map((row) => (
              <tr key={row.id}>
                <td>{row.title}</td>
                <td>{row.recipientUserId}</td>
                <td>{row.status}</td>
                <td>{dateTimeLabel(row.createdAt)}</td>
                <td>
                  <button
                    type="button"
                    disabled={row.status === "SENT"}
                    onClick={() => onSend(row.id)}
                  >
                    Marquer envoye
                  </button>
                </td>
              </tr>
            ))}
            {!rows.length && (
              <tr>
                <td colSpan={5}>
                  {loading ? "Chargement..." : "Aucun message disponible."}
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
    </section>
  );
}
