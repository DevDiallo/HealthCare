import { useEffect, useState } from "react";
import type { FormEvent } from "react";
import PageHeader from "../components/PageHeader";
import { domainApi } from "../services/domainApi";
import type { ApiEnvelope, Hospital, PageResponse } from "../types/domain";
import { dateTimeLabel } from "../utils/format";

type HospitalForm = {
  id?: string;
  name: string;
  address: string;
};

export default function HospitalsPage() {
  const [rows, setRows] = useState<Hospital[]>([]);
  const [search, setSearch] = useState("");
  const [loading, setLoading] = useState(false);
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [form, setForm] = useState<HospitalForm>({ name: "", address: "" });

  async function loadHospitals() {
    setLoading(true);
    setError(null);
    try {
      const res = await domainApi.hospitals({ page: 0, size: 100, search });
      const data =
        (res.data as ApiEnvelope<PageResponse<Hospital>>)?.data?.content || [];
      setRows(data);
    } catch {
      setError("Chargement des hopitaux impossible.");
      setRows([]);
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    loadHospitals();
  }, [search]);

  function onEdit(hospital: Hospital) {
    setForm({
      id: hospital.id,
      name: hospital.name,
      address: hospital.address,
    });
  }

  function resetForm() {
    setForm({ name: "", address: "" });
  }

  async function onSubmit(event: FormEvent) {
    event.preventDefault();
    setSubmitting(true);
    setError(null);
    try {
      if (form.id) {
        await domainApi.updateHospital(form.id, {
          name: form.name,
          address: form.address,
        });
      } else {
        await domainApi.createHospital({
          name: form.name,
          address: form.address,
        });
      }
      resetForm();
      await loadHospitals();
    } catch {
      setError("Enregistrement de l'hopital impossible.");
    } finally {
      setSubmitting(false);
    }
  }

  async function onSetStatus(id: string, action: "activate" | "suspend") {
    setError(null);
    try {
      if (action === "activate") {
        await domainApi.activateHospital(id);
      } else {
        await domainApi.suspendHospital(id);
      }
      await loadHospitals();
    } catch {
      setError("Mise a jour du statut impossible.");
    }
  }

  return (
    <section>
      <PageHeader
        title="Hopitaux"
        subtitle="Gouvernance multi-etablissements et qualite operationnelle"
      />

      <div className="card-grid-two">
        <form className="profile-card form-grid" onSubmit={onSubmit}>
          <h3>{form.id ? "Editer un hopital" : "Nouvel hopital"}</h3>
          <label>Nom</label>
          <input
            value={form.name}
            onChange={(e) => setForm((p) => ({ ...p, name: e.target.value }))}
            required
          />
          <label>Adresse</label>
          <textarea
            value={form.address}
            onChange={(e) =>
              setForm((p) => ({ ...p, address: e.target.value }))
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

        <div className="profile-card form-grid">
          <h3>Recherche</h3>
          <input
            placeholder="Nom ou adresse"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
          />
          <button
            type="button"
            onClick={() => loadHospitals()}
            disabled={loading}
          >
            {loading ? "Chargement..." : "Rafraichir"}
          </button>
        </div>
      </div>

      {error && <p className="inline-error">{error}</p>}

      <div className="table-wrap">
        <table>
          <thead>
            <tr>
              <th>Nom</th>
              <th>Adresse</th>
              <th>Statut</th>
              <th>Cree le</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            {rows.map((row) => (
              <tr key={row.id}>
                <td>{row.name}</td>
                <td>{row.address}</td>
                <td>{row.status}</td>
                <td>{dateTimeLabel(row.createdAt)}</td>
                <td>
                  <div className="row-actions">
                    <button type="button" onClick={() => onEdit(row)}>
                      Editer
                    </button>
                    <button
                      type="button"
                      onClick={() => onSetStatus(row.id, "activate")}
                    >
                      Activer
                    </button>
                    <button
                      type="button"
                      className="danger"
                      onClick={() => onSetStatus(row.id, "suspend")}
                    >
                      Suspendre
                    </button>
                  </div>
                </td>
              </tr>
            ))}
            {!rows.length && (
              <tr>
                <td colSpan={5}>
                  {loading ? "Chargement..." : "Aucun hopital trouve."}
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
    </section>
  );
}
