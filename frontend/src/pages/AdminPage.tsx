import PageHeader from '../components/PageHeader'

export default function AdminPage() {
  return (
    <section>
      <PageHeader title="Administration" subtitle="Audit, rapports, exports et gouvernance" />
      <div className="profile-card">
        <p>Fonctions prevues:</p>
        <ul>
          <li>Export PDF / Excel</li>
          <li>Journal d'audit centralise</li>
          <li>Supervision des tenants</li>
          <li>Politique de roles et permissions</li>
        </ul>
      </div>
    </section>
  )
}
