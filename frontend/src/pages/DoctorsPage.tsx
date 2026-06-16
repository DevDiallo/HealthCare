import { useEffect, useState } from 'react'
import PageHeader from '../components/PageHeader'
import SimpleTable from '../components/SimpleTable'
import { domainApi } from '../services/domainApi'

type DoctorRow = {
  id: number
  firstName: string
  lastName: string
  speciality: string
  department: string
}

export default function DoctorsPage() {
  const [rows, setRows] = useState<DoctorRow[]>([])

  useEffect(() => {
    domainApi.doctors({ page: 0, size: 20 })
      .then((res) => setRows(res.data?.data?.content || []))
      .catch(() => setRows([]))
  }, [])

  return (
    <section>
      <PageHeader title="Medecins" subtitle="Specialites, disponibilites et planning" />
      <SimpleTable
        columns={[
          { key: 'id', label: 'ID' },
          { key: 'firstName', label: 'Prenom' },
          { key: 'lastName', label: 'Nom' },
          { key: 'speciality', label: 'Specialite' },
          { key: 'department', label: 'Service' },
        ]}
        rows={rows}
      />
    </section>
  )
}
