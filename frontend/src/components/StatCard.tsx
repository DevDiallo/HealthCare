type Props = {
  label: string
  value: string
}

export default function StatCard({ label, value }: Props) {
  return (
    <article className="stat-card">
      <p className="stat-label">{label}</p>
      <h3>{value}</h3>
    </article>
  )
}
