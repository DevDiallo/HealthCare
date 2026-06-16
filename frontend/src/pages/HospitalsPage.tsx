import { useEffect, useState } from 'react'
import PageHeader from '../components/PageHeader'
import SimpleTable from '../components/SimpleTable'
import { domainApi } from '../services/domainApi'

type HospitalRow = {
  id: number
  name: string
  city: string
  country: string
  status: string
}

export default function HospitalsPage() {
  const [rows, setRows] = useState<HospitalRow[]>([])

  useEffect(() => {
    domainApi.hospitals({ page: 0, size: 20 })
      .then((res) => {
        const content = res.data?.data?.content || []
        setRows(content)
      })
      .catch(() => setRows([]))
  }, [])

  return (
    <section>
      <PageHeader title="Hopitaux" subtitle="Gestion multi-etablissements" />
      <SimpleTable
        columns={[
          { key: 'id', label: 'ID' },
          { key: 'name', label: 'Nom' },
          { key: 'city', label: 'Ville' },
          { key: 'country', label: 'Pays' },
          { key: 'status', label: 'Statut' },
        ]}
        rows={rows}
      />
    </section>
  )
}
