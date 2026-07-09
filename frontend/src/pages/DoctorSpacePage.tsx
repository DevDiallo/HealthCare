/**
 * Espace de travail du MÉDECIN.
 * Parcours : tableau de bord clinique → liste patients assignés → planning → messagerie.
 */
import { useEffect, useMemo, useState } from "react";
import type { FormEvent } from "react";
import PageHeader from "../components/PageHeader";
import { domainApi } from "../services/domainApi";
import type {
  ApiEnvelope,
  Appointment,
  Doctor,
  Notification,
  PageResponse,
  Patient,
} from "../types/domain";
import { dateTimeLabel } from "../utils/format";

type Tab = "dashboard" | "planning" | "patients" | "messages";

type DoctorSpaceProps = {
  initialTab?: Tab;
};

type MsgForm = {
  recipientUserId: string;
  title: string;
  message: string;
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

export default function DoctorSpacePage({
  initialTab = "dashboard",
}: DoctorSpaceProps) {
  const [tab, setTab] = useState<Tab>(initialTab);
  const [appointments, setAppointments] = useState<Appointment[]>([]);
  const [patients, setPatients] = useState<Patient[]>([]);
  const [myProfile, setMyProfile] = useState<Doctor | null>(null);
  const [messages, setMessages] = useState<Notification[]>([]);
  const [selectedPatient, setSelectedPatient] = useState<Patient | null>(null);
  const [loading, setLoading] = useState(false);
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);
  const [msgForm, setMsgForm] = useState<MsgForm>({
    recipientUserId: "",
    title: "",
    message: "",
  });
  const [patientSearch, setPatientSearch] = useState("");

  const patientById = useMemo(
    () => Object.fromEntries(patients.map((p) => [p.id, p])),
    [patients],
  );
  const patientByUserAccountId = useMemo(
    () => Object.fromEntries(patients.map((p) => [p.userAccountId || p.id, p])),
    [patients],
  );

  async function loadAll() {
    setLoading(true);
    setError(null);
    try {
      const [apptRes, patientRes, docRes, notifRes] = await Promise.all([
        domainApi.appointments({ page: 0, size: 200 }),
        domainApi.patients({ page: 0, size: 200 }),
        domainApi.doctors({ page: 0, size: 200 }),
        domainApi.notifications({ page: 0, size: 100 }),
      ]);

      const allAppointments =
        (apptRes.data as ApiEnvelope<PageResponse<Appointment>>)?.data
          ?.content || [];
      setAppointments(allAppointments);

      setPatients(
        (patientRes.data as ApiEnvelope<PageResponse<Patient>>)?.data
          ?.content || [],
      );

      const allDoctors =
        (docRes.data as ApiEnvelope<PageResponse<Doctor>>)?.data?.content || [];
      const me = allDoctors[0] || null;
      setMyProfile(me);

      const allNotifications =
        (notifRes.data as ApiEnvelope<PageResponse<Notification>>)?.data
          ?.content || [];
      const myMessages = allNotifications.filter((n) =>
        me
          ? String(n.recipientUserId) === String(me.userAccountId || me.id)
          : false,
      );
      setMessages(myMessages);
    } catch {
      setError("Impossible de charger vos données cliniques. Réessayez.");
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

  const currentDoctorId = myProfile?.id || "";

  // Only appointments for this doctor
  const myAppointments = useMemo(
    () =>
      appointments
        .filter((a) => String(a.doctorId) === String(currentDoctorId))
        .sort(
          (a, b) =>
            new Date(a.appointmentAt).getTime() -
            new Date(b.appointmentAt).getTime(),
        ),
    [appointments, currentDoctorId],
  );

  const pending = myAppointments.filter((a) => a.status === "PENDING");
  const confirmed = myAppointments.filter((a) => a.status === "CONFIRMED");
  const cancelled = myAppointments.filter((a) => a.status === "CANCELLED");

  const todaysAppointments = myAppointments.filter((a) => {
    const now = new Date();
    const when = new Date(a.appointmentAt);
    return (
      when.getFullYear() === now.getFullYear() &&
      when.getMonth() === now.getMonth() &&
      when.getDate() === now.getDate()
    );
  });

  // Unique patients seen by this doctor
  const myPatientIds = useMemo(() => patients.map((p) => p.id), [patients]);

  const filteredPatients = patients.filter((p) => {
    if (!patientSearch) return true;
    const q = patientSearch.toLowerCase();
    return (
      p.firstName.toLowerCase().includes(q) ||
      p.lastName.toLowerCase().includes(q) ||
      p.email.toLowerCase().includes(q)
    );
  });

  const patientsByFollowup = useMemo(
    () =>
      filteredPatients
        .map((p) => ({
          patient: p,
          visits: myAppointments.filter((a) => a.patientId === p.id).length,
        }))
        .sort((a, b) => b.visits - a.visits)
        .slice(0, 6),
    [filteredPatients, myAppointments],
  );

  const patientsWithAlerts = useMemo(
    () =>
      filteredPatients.filter(
        (p) => Boolean(p.allergies) || Boolean(p.chronicConditions),
      ),
    [filteredPatients],
  );

  async function onConfirmAppointment(id: string) {
    setError(null);
    setSuccess(null);
    try {
      await domainApi.confirmAppointment(id);
      setSuccess("Rendez-vous confirmé.");
      await loadAll();
    } catch {
      setError("Impossible de confirmer ce rendez-vous.");
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
      setError("Impossible d'annuler ce rendez-vous.");
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
      setMsgForm({ recipientUserId: "", title: "", message: "" });
      setSuccess("Message envoyé au patient.");
      await loadAll();
    } catch {
      setError("L'envoi du message a échoué.");
    } finally {
      setSubmitting(false);
    }
  }

  const selectedPatientAppointments = selectedPatient
    ? myAppointments
        .filter((a) => a.patientId === selectedPatient.id)
        .sort(
          (a, b) =>
            new Date(b.appointmentAt).getTime() -
            new Date(a.appointmentAt).getTime(),
        )
    : [];

  return (
    <section>
      <PageHeader
        title={
          myProfile
            ? `Dr ${myProfile.firstName} ${myProfile.lastName}`
            : "Espace médecin"
        }
        subtitle={
          myProfile
            ? `${myProfile.speciality} — Suivi clinique & planning`
            : "Suivi clinique et gestion des patients"
        }
      />

      {/* KPIs */}
      <div className="stats-grid" style={{ marginBottom: "1rem" }}>
        <div className="stat-card">
          <p className="stat-label">Patients suivis</p>
          <h3>{myPatientIds.length}</h3>
        </div>
        <div className="stat-card">
          <p className="stat-label">En attente</p>
          <h3>{pending.length}</h3>
        </div>
        <div className="stat-card">
          <p className="stat-label">Confirmés</p>
          <h3>{confirmed.length}</h3>
        </div>
        <div className="stat-card">
          <p className="stat-label">Messages reçus</p>
          <h3>{messages.length}</h3>
        </div>
      </div>

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
          className={tab === "planning" ? "tab-btn active" : "tab-btn"}
          onClick={() => setTab("planning")}
        >
          Planning & RDV
        </button>
        <button
          type="button"
          className={tab === "patients" ? "tab-btn active" : "tab-btn"}
          onClick={() => setTab("patients")}
        >
          Mes patients
        </button>
        <button
          type="button"
          className={tab === "messages" ? "tab-btn active" : "tab-btn"}
          onClick={() => setTab("messages")}
        >
          Messagerie
        </button>
      </div>

      {error && <p className="inline-error">{error}</p>}
      {success && <p className="inline-success">{success}</p>}

      {/* ─── DASHBOARD ─── */}
      {tab === "dashboard" && (
        <div className="card-grid-two">
          <div className="profile-card">
            <h3>Vue globale patientèle</h3>
            <ul className="timeline-list">
              <li>Patients suivis: {myPatientIds.length}</li>
              <li>Rendez-vous aujourd hui: {todaysAppointments.length}</li>
              <li>Rendez-vous confirmés: {confirmed.length}</li>
              <li>Rendez-vous en attente: {pending.length}</li>
              <li>Rendez-vous annulés: {cancelled.length}</li>
              <li>
                Patients avec points de vigilance: {patientsWithAlerts.length}
              </li>
            </ul>
          </div>

          <div className="profile-card">
            <h3>Patients les plus suivis</h3>
            {!patientsByFollowup.length && (
              <p className="muted">Aucun suivi patient disponible.</p>
            )}
            <ul className="timeline-list">
              {patientsByFollowup.map((entry) => (
                <li key={entry.patient.id}>
                  {entry.patient.firstName} {entry.patient.lastName} -{" "}
                  {entry.visits} consultation(s)
                </li>
              ))}
            </ul>
          </div>

          <div className="profile-card">
            <h3>Prochains rendez-vous</h3>
            {!myAppointments.length && (
              <p className="muted">Aucun rendez-vous à venir.</p>
            )}
            <ul className="timeline-list">
              {myAppointments.slice(0, 6).map((appt) => {
                const patient = patientById[appt.patientId];
                return (
                  <li key={appt.id}>
                    {dateTimeLabel(appt.appointmentAt)} -{" "}
                    {patient
                      ? `${patient.firstName} ${patient.lastName}`
                      : appt.patientId}
                  </li>
                );
              })}
            </ul>
          </div>

          <div className="profile-card">
            <h3>Alertes dossier médical</h3>
            {!patientsWithAlerts.length && (
              <p className="muted">Aucune alerte clinique enregistrée.</p>
            )}
            <ul className="timeline-list">
              {patientsWithAlerts.slice(0, 8).map((p) => (
                <li key={p.id}>
                  {p.firstName} {p.lastName}
                  {p.allergies ? ` - Allergies: ${p.allergies}` : ""}
                  {!p.allergies && p.chronicConditions
                    ? ` - Pathologies: ${p.chronicConditions}`
                    : ""}
                </li>
              ))}
            </ul>
          </div>
        </div>
      )}

      {/* ─── PLANNING ─── */}
      {tab === "planning" && (
        <div className="profile-card">
          <h3>Rendez-vous à traiter</h3>
          {loading && <p className="muted">Chargement...</p>}
          {!loading && !myAppointments.length && (
            <p className="muted">Aucun rendez-vous pour le moment.</p>
          )}
          <ul className="appt-list">
            {myAppointments.map((appt) => {
              const patient = patientById[appt.patientId];
              return (
                <li key={appt.id} className="appt-item">
                  <div className="appt-main">
                    <span className="appt-date">
                      {dateTimeLabel(appt.appointmentAt)}
                    </span>
                    <span className="appt-doctor">
                      {patient
                        ? `${patient.firstName} ${patient.lastName}`
                        : appt.patientId}
                    </span>
                    {patient?.allergies && (
                      <span className="appt-alert">
                        Alerte: {patient.allergies}
                      </span>
                    )}
                  </div>
                  <div className="appt-right">
                    <span className={STATUS_CLASS[appt.status] || "badge"}>
                      {STATUS_LABEL[appt.status] || appt.status}
                    </span>
                    {appt.status === "PENDING" && (
                      <>
                        <button
                          type="button"
                          className="btn-action"
                          onClick={() => onConfirmAppointment(appt.id)}
                        >
                          Confirmer
                        </button>
                        <button
                          type="button"
                          className="btn-ghost danger-text"
                          onClick={() => onCancelAppointment(appt.id)}
                        >
                          Refuser
                        </button>
                      </>
                    )}
                    {appt.status === "CONFIRMED" && (
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
      )}

      {/* ─── MES PATIENTS ─── */}
      {tab === "patients" && (
        <div className="card-grid-two">
          <div className="profile-card">
            <h3>Mes patients ({filteredPatients.length})</h3>
            <div className="toolbar-row" style={{ marginBottom: "0.75rem" }}>
              <input
                placeholder="Rechercher par nom, email..."
                value={patientSearch}
                onChange={(e) => setPatientSearch(e.target.value)}
              />
            </div>
            <ul className="patient-list">
              {filteredPatients.map((p) => {
                const lastAppt = appointments
                  .filter((a) => a.patientId === p.id)
                  .sort(
                    (a, b) =>
                      new Date(b.appointmentAt).getTime() -
                      new Date(a.appointmentAt).getTime(),
                  )[0];
                return (
                  <li
                    key={p.id}
                    className={`patient-item ${selectedPatient?.id === p.id ? "row-selected" : ""}`}
                    onClick={() => setSelectedPatient(p)}
                    style={{ cursor: "pointer" }}
                  >
                    <div className="patient-avatar">
                      {p.firstName[0]}
                      {p.lastName[0]}
                    </div>
                    <div className="patient-info">
                      <strong>
                        {p.firstName} {p.lastName}
                      </strong>
                      <span className="muted">{p.email}</span>
                      {lastAppt && (
                        <span className="muted">
                          Dernière visite :{" "}
                          {dateTimeLabel(lastAppt.appointmentAt)}
                        </span>
                      )}
                    </div>
                    {p.bloodType && (
                      <span className="badge badge-blood">{p.bloodType}</span>
                    )}
                  </li>
                );
              })}
              {!filteredPatients.length && (
                <li className="muted">Aucun patient trouvé.</li>
              )}
            </ul>
          </div>

          <div className="profile-card dossier-card">
            <h3>
              {selectedPatient
                ? `Dossier — ${selectedPatient.firstName} ${selectedPatient.lastName}`
                : "Sélectionnez un patient"}
            </h3>
            {!selectedPatient && (
              <p className="muted">
                Cliquez sur un patient pour consulter son dossier complet.
              </p>
            )}
            {selectedPatient && (
              <>
                <dl className="dossier-dl">
                  <dt>Email</dt>
                  <dd>{selectedPatient.email}</dd>
                  <dt>Groupe sanguin</dt>
                  <dd>
                    {selectedPatient.bloodType || (
                      <span className="muted">—</span>
                    )}
                  </dd>
                  <dt>Allergies</dt>
                  <dd className="pre-wrap allergies-alert">
                    {selectedPatient.allergies || (
                      <span className="muted">Aucune allergie connue</span>
                    )}
                  </dd>
                  <dt>Pathologies chroniques</dt>
                  <dd className="pre-wrap">
                    {selectedPatient.chronicConditions || (
                      <span className="muted">—</span>
                    )}
                  </dd>
                  <dt>Contact d'urgence</dt>
                  <dd>
                    {selectedPatient.emergencyContact || (
                      <span className="muted">—</span>
                    )}
                  </dd>
                </dl>
                <h4 style={{ marginTop: "1rem" }}>Historique</h4>
                <ul className="timeline-list">
                  {selectedPatientAppointments.slice(0, 8).map((a) => (
                    <li key={a.id}>
                      <span className={STATUS_CLASS[a.status] || "badge"}>
                        {STATUS_LABEL[a.status] || a.status}
                      </span>{" "}
                      {dateTimeLabel(a.appointmentAt)}
                    </li>
                  ))}
                  {!selectedPatientAppointments.length && (
                    <li className="muted">Aucune consultation enregistrée.</li>
                  )}
                </ul>
              </>
            )}
          </div>
        </div>
      )}

      {/* ─── MESSAGERIE ─── */}
      {tab === "messages" && (
        <div className="card-grid-two">
          <form className="profile-card form-grid" onSubmit={onSendMessage}>
            <h3>Envoyer un message à un patient</h3>
            <label>Patient destinataire</label>
            <select
              value={msgForm.recipientUserId}
              onChange={(e) =>
                setMsgForm((p) => ({ ...p, recipientUserId: e.target.value }))
              }
              required
            >
              <option value="">Selectionner...</option>
              {filteredPatients.map((p) => (
                <option
                  key={p.id}
                  value={p.userAccountId || ""}
                  disabled={!p.userAccountId}
                >
                  {`${p.firstName} ${p.lastName}`}
                </option>
              ))}
            </select>
            <label>Objet</label>
            <input
              value={msgForm.title}
              onChange={(e) =>
                setMsgForm((p) => ({ ...p, title: e.target.value }))
              }
              placeholder="Résultats d'analyse, prescription…"
              required
            />
            <label>Message</label>
            <textarea
              value={msgForm.message}
              onChange={(e) =>
                setMsgForm((p) => ({ ...p, message: e.target.value }))
              }
              rows={5}
              placeholder="Rédigez votre message médical…"
              required
            />
            <button type="submit" disabled={submitting}>
              {submitting ? "Envoi…" : "Envoyer au patient"}
            </button>
          </form>

          <div className="profile-card">
            <h3>Historique de contact</h3>
            {!messages.length && <p className="muted">Aucun message reçu.</p>}
            <ul className="msg-list">
              {messages.map((msg) => {
                const recipient = patientByUserAccountId[msg.recipientUserId];
                return (
                  <li key={msg.id} className="msg-item">
                    <div className="msg-header">
                      <strong>{msg.title}</strong>
                      <span className="muted">
                        {dateTimeLabel(msg.createdAt)}
                      </span>
                    </div>
                    {recipient && (
                      <span className="muted" style={{ fontSize: "0.8rem" }}>
                        Patient: {recipient.firstName} {recipient.lastName}
                      </span>
                    )}
                    <p className="msg-body">{msg.message}</p>
                  </li>
                );
              })}
            </ul>
          </div>
        </div>
      )}
    </section>
  );
}
