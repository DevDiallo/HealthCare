import { Link } from 'react-router-dom'

export default function HomePage() {
  return (
    <section className="auth-shell">
      <div className="auth-card">
        <h1>Plateforme HealthCare Multi-Tenant</h1>
        <p>Gestion hospitaliere unifiee, securisee et scalable.</p>
        <div className="actions">
          <Link to="/login">Connexion</Link>
          <Link to="/register">Inscription</Link>
        </div>
      </div>
    </section>
  )
}
