import { useEffect, useState } from 'react'
import PageHeader from '../components/PageHeader'
import SimpleTable from '../components/SimpleTable'
import { domainApi } from '../services/domainApi'

type PatientRow = {
  id: number
  firstName: string
  lastName: string
  gender: string
  phone: string
}

export default function PatientsPage() {
  const [rows, setRows] = useState<PatientRow[]>([])

  useEffect(() => {
    domainApi.patients({ page: 0, size: 20 })
      .then((res) => setRows(res.data?.data?.content || []))
      .catch(() => setRows([]))
  }, [])

  return (
    <section>
      <PageHeader title="Patients" subtitle="Dossiers et historique medical" />
      <SimpleTable
        columns={[
          { key: 'id', label: 'ID' },
          { key: 'firstName', label: 'Prenom' },
          { key: 'lastName', label: 'Nom' },
          { key: 'gender', label: 'Genre' },
          { key: 'phone', label: 'Telephone' },
        ]}
        rows={rows}
      />
    </section>
  )
}
