/**
 * Espace personnel du PATIENT.
 * Parcours : voir mes rendez-vous → en prendre un nouveau → consulter mon dossier → contacter mon médecin.
 */
import { useEffect, useMemo, useState } from "react";
import type { FormEvent } from "react";
import PageHeader from "../components/PageHeader";
import { domainApi } from "../services/domainApi";
import { useAppSelector } from "../app/hooks";
import type {
  ApiEnvelope,
  Appointment,
  Doctor,
  Notification,
  PageResponse,
  Patient,
} from "../types/domain";
import { dateTimeLabel } from "../utils/format";

type Tab = "appointments" | "dossier" | "messages";

type PatientSpaceProps = {
  initialTab?: "dashboard" | Tab;
};

type BookingForm = {
  doctorId: string;
  appointmentAt: string;
};

type MessageForm = {
  title: string;
  message: string;
  recipientUserId: string;
};

const STATUS_LABEL: Record<string, string> = {
  PENDING: "En attente",
  CONFIRMED: "Confirmé",
  CANCELLED: "Annulé",
};

const STATUS_CLASS: Record<string, string> = {
  PENDING: "badge badge-pending",
  CONFIRMED: "badge badge-confirmed",
  CANCELLED: "badge badge-cancelled",
};

export default function PatientSpacePage({ initialTab = "appointments" }: PatientSpaceProps) {
  const userId = useAppSelector((state) => state.auth.userId);

  const [tab, setTab] = useState<"dashboard" | Tab>(initialTab);
  const [appointments, setAppointments] = useState<Appointment[]>([]);
  const [doctors, setDoctors] = useState<Doctor[]>([]);
  const [myProfile, setMyProfile] = useState<Patient | null>(null);
  const [messages, setMessages] = useState<Notification[]>([]);
  const [loading, setLoading] = useState(false);
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);

  const [bookingForm, setBookingForm] = useState<BookingForm>({
    doctorId: "",
    appointmentAt: "",
  });
  const [msgForm, setMsgForm] = useState<MessageForm>({
    title: "",
    message: "",
    recipientUserId: "",
  });

  const doctorById = useMemo(
    () => Object.fromEntries(doctors.map((d) => [d.id, d])),
    [doctors],
  );

  async function loadAll() {
    setLoading(true);
    setError(null);
    try {
      const [apptRes, docRes, notifRes, patientsRes] = await Promise.all([
        domainApi.appointments({ page: 0, size: 100 }),
        domainApi.doctors({ page: 0, size: 200 }),
        domainApi.notifications({ page: 0, size: 100 }),
        domainApi.patients({ page: 0, size: 200 }),
      ]);
      const allAppointments =
        (apptRes.data as ApiEnvelope<PageResponse<Appointment>>)?.data
          ?.content || [];
      setAppointments(allAppointments);
      setDoctors(
        (docRes.data as ApiEnvelope<PageResponse<Doctor>>)?.data?.content || [],
      );

      const allNotifications =
        (notifRes.data as ApiEnvelope<PageResponse<Notification>>)?.data
          ?.content || [];
      const myMessages = allNotifications.filter(
        (n) => String(n.recipientUserId) === String(userId),
      );
      setMessages(myMessages);

      // find own patient profile by userId match (best-effort)
      const allPatients =
        (patientsRes.data as ApiEnvelope<PageResponse<Patient>>)?.data
          ?.content || [];
      const me =
        allPatients.find((p) => String(p.id) === String(userId)) ||
        allPatients[0] ||
        null;
      setMyProfile(me);
    } catch {
      setError("Impossible de charger vos données. Réessayez.");
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    loadAll();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  useEffect(() => {
    setTab(initialTab);
  }, [initialTab]);

  const myAppointments = appointments.sort(
    (a, b) =>
      new Date(b.appointmentAt).getTime() - new Date(a.appointmentAt).getTime(),
  );

  async function onBookAppointment(e: FormEvent) {
    e.preventDefault();
    setSubmitting(true);
    setError(null);
    setSuccess(null);
    try {
      await domainApi.createAppointment({
        doctorId: bookingForm.doctorId,
        appointmentAt: new Date(bookingForm.appointmentAt)
          .toISOString()
          .slice(0, 19),
      });
      setBookingForm({ doctorId: "", appointmentAt: "" });
      setSuccess(
        "Votre demande de rendez-vous a bien été envoyée. En attente de confirmation.",
      );
      await loadAll();
    } catch {
      setError(
        "La prise de rendez-vous a échoué. Vérifiez la date et le médecin choisi.",
      );
    } finally {
      setSubmitting(false);
    }
  }

  async function onCancelAppointment(id: string) {
    setError(null);
    setSuccess(null);
    try {
      await domainApi.cancelAppointment(id);
      setSuccess("Rendez-vous annulé.");
      await loadAll();
    } catch {
      setError("L'annulation du rendez-vous a échoué.");
    }
  }

  async function onSendMessage(e: FormEvent) {
    e.preventDefault();
    setSubmitting(true);
    setError(null);
    setSuccess(null);
    try {
      await domainApi.createNotification({
        recipientUserId: msgForm.recipientUserId,
        title: msgForm.title,
        message: msgForm.message,
      });
      setMsgForm({ title: "", message: "", recipientUserId: "" });
      setSuccess("Message envoyé à votre médecin.");
      await loadAll();
    } catch {
      setError("L'envoi du message a échoué.");
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <section>
      <PageHeader
        title="Mon espace santé"
        subtitle="Rendez-vous, dossier médical et échanges avec votre médecin"
      />

      <div className="tab-bar">
        <button
          type="button"
          className={tab === "dashboard" ? "tab-btn active" : "tab-btn"}
          onClick={() => setTab("dashboard")}
        >
          Dashboard
        </button>
        <button
          type="button"
          className={tab === "appointments" ? "tab-btn active" : "tab-btn"}
          onClick={() => setTab("appointments")}
        >
          Mes rendez-vous
        </button>
        <button
          type="button"
          className={tab === "dossier" ? "tab-btn active" : "tab-btn"}
          onClick={() => setTab("dossier")}
        >
          Mon dossier médical
        </button>
        <button
          type="button"
          className={tab === "messages" ? "tab-btn active" : "tab-btn"}
          onClick={() => setTab("messages")}
        >
          Mes messages
        </button>
      </div>

      {error && <p className="inline-error">{error}</p>}
      {success && <p className="inline-success">{success}</p>}

      {tab === "dashboard" && (
        <div className="card-grid-two">
          <div className="profile-card">
            <h3>Vue patient</h3>
            <ul className="timeline-list">
              <li>Total rendez-vous: {myAppointments.length}</li>
              <li>
                Rendez-vous a venir: {
                  myAppointments.filter((a) => new Date(a.appointmentAt).getTime() >= Date.now()).length
                }
              </li>
              <li>Messages recus: {messages.length}</li>
            </ul>
          </div>
          <div className="profile-card">
            <h3>Prochaine etape</h3>
            <p className="muted">
              Utilisez le menu de gauche pour consulter votre dossier medical,
              gerer vos rendez-vous et contacter votre medecin.
            </p>
          </div>
        </div>
      )}

      {/* ─── ONGLET RENDEZ-VOUS ─── */}
      {tab === "appointments" && (
        <div className="card-grid-two">
          <form className="profile-card form-grid" onSubmit={onBookAppointment}>
            <h3>Prendre un rendez-vous</h3>
            <label>Choisir un médecin</label>
            <select
              value={bookingForm.doctorId}
              onChange={(e) =>
                setBookingForm((p) => ({ ...p, doctorId: e.target.value }))
              }
              required
            >
              <option value="">Sélectionner…</option>
              {doctors.map((d) => (
                <option key={d.id} value={d.id}>
                  {`Dr ${d.firstName} ${d.lastName} — ${d.speciality}`}
                </option>
              ))}
            </select>
            <label>Date et heure souhaitées</label>
            <input
              type="datetime-local"
              value={bookingForm.appointmentAt}
              onChange={(e) =>
                setBookingForm((p) => ({ ...p, appointmentAt: e.target.value }))
              }
              required
            />
            <button type="submit" disabled={submitting}>
              {submitting ? "Envoi…" : "Demander le rendez-vous"}
            </button>
          </form>

          <div className="profile-card">
            <h3>Mes prochains rendez-vous</h3>
            {loading && <p className="muted">Chargement…</p>}
            {!loading && !myAppointments.length && (
              <p className="muted">Aucun rendez-vous enregistré.</p>
            )}
            <ul className="appt-list">
              {myAppointments.map((appt) => {
                const doc = doctorById[appt.doctorId];
                return (
                  <li key={appt.id} className="appt-item">
                    <div className="appt-main">
                      <span className="appt-date">
                        {dateTimeLabel(appt.appointmentAt)}
                      </span>
                      <span className="appt-doctor">
                        {doc
                          ? `Dr ${doc.firstName} ${doc.lastName} — ${doc.speciality}`
                          : appt.doctorId}
                      </span>
                    </div>
                    <div className="appt-right">
                      <span className={STATUS_CLASS[appt.status] || "badge"}>
                        {STATUS_LABEL[appt.status] || appt.status}
                      </span>
                      {appt.status !== "CANCELLED" && (
                        <button
                          type="button"
                          className="btn-ghost danger-text"
                          onClick={() => onCancelAppointment(appt.id)}
                        >
                          Annuler
                        </button>
                      )}
                    </div>
                  </li>
                );
              })}
            </ul>
          </div>
        </div>
      )}

      {/* ─── ONGLET DOSSIER MÉDICAL ─── */}
      {tab === "dossier" && (
        <div className="card-grid-two">
          <div className="profile-card dossier-card">
            <h3>Mon dossier médical</h3>
            {!myProfile && (
              <p className="muted">Aucun dossier trouvé pour votre compte.</p>
            )}
            {myProfile && (
              <dl className="dossier-dl">
                <dt>Nom complet</dt>
                <dd>
                  {myProfile.firstName} {myProfile.lastName}
                </dd>
                <dt>Email</dt>
                <dd>{myProfile.email}</dd>
                <dt>Groupe sanguin</dt>
                <dd>
                  {myProfile.bloodType || (
                    <span className="muted">Non renseigné</span>
                  )}
                </dd>
                <dt>Allergies</dt>
                <dd className="pre-wrap">
                  {myProfile.allergies || (
                    <span className="muted">Aucune allergie connue</span>
                  )}
                </dd>
                <dt>Pathologies chroniques</dt>
                <dd className="pre-wrap">
                  {myProfile.chronicConditions || (
                    <span className="muted">Aucune pathologie renseignée</span>
                  )}
                </dd>
                <dt>Contact d'urgence</dt>
                <dd>
                  {myProfile.emergencyContact || (
                    <span className="muted">Non renseigné</span>
                  )}
                </dd>
              </dl>
            )}
          </div>

          <div className="profile-card">
            <h3>Historique des consultations</h3>
            {!myAppointments.length && (
              <p className="muted">Aucune consultation enregistrée.</p>
            )}
            <ul className="timeline-list">
              {myAppointments.map((appt) => {
                const doc = doctorById[appt.doctorId];
                return (
                  <li key={appt.id}>
                    <span className={STATUS_CLASS[appt.status] || "badge"}>
                      {STATUS_LABEL[appt.status] || appt.status}
                    </span>{" "}
                    {dateTimeLabel(appt.appointmentAt)}
                    {doc && ` · Dr ${doc.firstName} ${doc.lastName}`}
                  </li>
                );
              })}
            </ul>
          </div>
        </div>
      )}

      {/* ─── ONGLET MESSAGES ─── */}
      {tab === "messages" && (
        <div className="card-grid-two">
          <form className="profile-card form-grid" onSubmit={onSendMessage}>
            <h3>Contacter mon médecin</h3>
            <label>Médecin destinataire</label>
            <select
              value={msgForm.recipientUserId}
              onChange={(e) =>
                setMsgForm((p) => ({ ...p, recipientUserId: e.target.value }))
              }
              required
            >
              <option value="">Sélectionner…</option>
              {doctors.map((d) => (
                <option key={d.id} value={d.id}>
                  {`Dr ${d.firstName} ${d.lastName} — ${d.speciality}`}
                </option>
              ))}
            </select>
            <label>Objet</label>
            <input
              value={msgForm.title}
              onChange={(e) =>
                setMsgForm((p) => ({ ...p, title: e.target.value }))
              }
              placeholder="Ex: Question sur mon traitement"
              required
            />
            <label>Message</label>
            <textarea
              value={msgForm.message}
              onChange={(e) =>
                setMsgForm((p) => ({ ...p, message: e.target.value }))
              }
              rows={5}
              placeholder="Décrivez votre question ou symptôme…"
              required
            />
            <button type="submit" disabled={submitting}>
              {submitting ? "Envoi…" : "Envoyer le message"}
            </button>
          </form>

          <div className="profile-card">
            <h3>Mes messages reçus</h3>
            {!messages.length && <p className="muted">Aucun message reçu.</p>}
            <ul className="msg-list">
              {messages.map((msg) => (
                <li key={msg.id} className="msg-item">
                  <div className="msg-header">
                    <strong>{msg.title}</strong>
                    <span className="muted">
                      {dateTimeLabel(msg.createdAt)}
                    </span>
                  </div>
                  <p className="msg-body">{msg.message}</p>
                </li>
              ))}
            </ul>
          </div>
        </div>
      )}
    </section>
  );
}
