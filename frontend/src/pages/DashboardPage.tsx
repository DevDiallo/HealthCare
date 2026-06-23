import { useEffect, useMemo, useState } from "react";
import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
} from "recharts";
import PageHeader from "../components/PageHeader";
import StatCard from "../components/StatCard";
import { domainApi } from "../services/domainApi";
import type {
  ApiEnvelope,
  Appointment,
  Doctor,
  Hospital,
  Notification,
  PageResponse,
  Patient,
} from "../types/domain";

export default function DashboardPage() {
  const [counts, setCounts] = useState({
    hospitals: 0,
    patients: 0,
    doctors: 0,
    appointments: 0,
    notifications: 0,
  });

  useEffect(() => {
    Promise.all([
      domainApi.hospitals({ page: 0, size: 1 }),
      domainApi.patients({ page: 0, size: 1 }),
      domainApi.doctors({ page: 0, size: 1 }),
      domainApi.appointments({ page: 0, size: 1 }),
      domainApi.notifications({ page: 0, size: 1 }),
    ])
      .then(([h, p, d, a, n]) => {
        const hData = (h.data as ApiEnvelope<PageResponse<Hospital>>)?.data;
        const pData = (p.data as ApiEnvelope<PageResponse<Patient>>)?.data;
        const dData = (d.data as ApiEnvelope<PageResponse<Doctor>>)?.data;
        const aData = (a.data as ApiEnvelope<PageResponse<Appointment>>)?.data;
        const nData = (n.data as ApiEnvelope<PageResponse<Notification>>)?.data;
        setCounts({
          hospitals: hData?.totalElements || 0,
          patients: pData?.totalElements || 0,
          doctors: dData?.totalElements || 0,
          appointments: aData?.totalElements || 0,
          notifications: nData?.totalElements || 0,
        });
      })
      .catch(() => {
        setCounts({
          hospitals: 0,
          patients: 0,
          doctors: 0,
          appointments: 0,
          notifications: 0,
        });
      });
  }, []);

  const chartData = useMemo(
    () => [
      { name: "Hopitaux", value: counts.hospitals },
      { name: "Patients", value: counts.patients },
      { name: "Medecins", value: counts.doctors },
      { name: "Rdv", value: counts.appointments },
      { name: "Messages", value: counts.notifications },
    ],
    [counts],
  );

  return (
    <section>
      <PageHeader
        title="Dashboard"
        subtitle="Vue globale de la plateforme hospitaliere"
      />
      <div className="stats-grid">
        <StatCard label="Hopitaux" value={String(counts.hospitals)} />
        <StatCard label="Patients" value={String(counts.patients)} />
        <StatCard label="Medecins" value={String(counts.doctors)} />
        <StatCard label="Rendez-vous" value={String(counts.appointments)} />
      </div>
      <div className="chart-card">
        <h3>Activite clinique</h3>
        <ResponsiveContainer width="100%" height={260}>
          <BarChart data={chartData}>
            <CartesianGrid strokeDasharray="3 3" />
            <XAxis dataKey="name" />
            <YAxis />
            <Tooltip />
            <Bar dataKey="value" fill="#0f766e" />
          </BarChart>
        </ResponsiveContainer>
      </div>
    </section>
  );
}
