import { useMemo } from 'react'
import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
} from 'recharts'
import PageHeader from '../components/PageHeader'
import StatCard from '../components/StatCard'

export default function DashboardPage() {
  const chartData = useMemo(
    () => [
      { name: 'Hopitaux', value: 8 },
      { name: 'Patients', value: 1250 },
      { name: 'Medecins', value: 180 },
      { name: 'Rdv', value: 430 },
    ],
    [],
  )

  return (
    <section>
      <PageHeader title="Dashboard" subtitle="Vue globale de la plateforme hospitaliere" />
      <div className="stats-grid">
        <StatCard label="Hopitaux" value="8" />
        <StatCard label="Patients" value="1 250" />
        <StatCard label="Medecins" value="180" />
        <StatCard label="Rendez-vous" value="430" />
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
  )
}
