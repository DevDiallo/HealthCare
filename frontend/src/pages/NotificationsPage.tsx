import { useEffect, useState } from 'react'
import PageHeader from '../components/PageHeader'
import SimpleTable from '../components/SimpleTable'
import { domainApi } from '../services/domainApi'

type NotificationRow = {
  id: number
  channel: string
  type: string
  status: string
  recipient: string
}

export default function NotificationsPage() {
  const [rows, setRows] = useState<NotificationRow[]>([])

  useEffect(() => {
    domainApi.notifications({ page: 0, size: 20 })
      .then((res) => setRows(res.data?.data?.content || []))
      .catch(() => setRows([]))
  }, [])

  return (
    <section>
      <PageHeader title="Notifications" subtitle="Email, SMS, push et alertes internes" />
      <SimpleTable
        columns={[
          { key: 'id', label: 'ID' },
          { key: 'channel', label: 'Canal' },
          { key: 'type', label: 'Type' },
          { key: 'recipient', label: 'Destinataire' },
          { key: 'status', label: 'Statut' },
        ]}
        rows={rows}
      />
    </section>
  )
}
