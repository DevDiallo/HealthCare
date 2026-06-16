import { useAppSelector } from '../app/hooks'
import PageHeader from '../components/PageHeader'

export default function ProfilePage() {
  const auth = useAppSelector((state) => state.auth)

  return (
    <section>
      <PageHeader title="Profil" subtitle="Identite et securite du compte" />
      <div className="profile-card">
        <p><strong>User ID:</strong> {auth.userId ?? '-'}</p>
        <p><strong>Hospital ID:</strong> {auth.hospitalId ?? '-'}</p>
        <p><strong>Role:</strong> {auth.role ?? '-'}</p>
      </div>
    </section>
  )
}
