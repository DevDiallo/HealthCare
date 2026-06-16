import { useEffect, useState } from 'react'
import PageHeader from '../components/PageHeader'
import SimpleTable from '../components/SimpleTable'
import { domainApi } from '../services/domainApi'

type AppointmentRow = {
  id: number
  patientId: number
  doctorId: number
  appointmentDate: string
  status: string
}

export default function AppointmentsPage() {
  const [rows, setRows] = useState<AppointmentRow[]>([])

  useEffect(() => {
    domainApi.appointments({ page: 0, size: 20 })
      .then((res) => setRows(res.data?.data?.content || []))
      .catch(() => setRows([]))
  }, [])

  return (
    <section>
      <PageHeader title="Rendez-vous" subtitle="Agenda, confirmations, annulations" />
      <SimpleTable
        columns={[
          { key: 'id', label: 'ID' },
          { key: 'patientId', label: 'Patient' },
          { key: 'doctorId', label: 'Medecin' },
          { key: 'appointmentDate', label: 'Date' },
          { key: 'status', label: 'Statut' },
        ]}
        rows={rows}
      />
    </section>
  )
}
