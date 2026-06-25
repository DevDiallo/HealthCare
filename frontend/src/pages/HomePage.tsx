import { Link } from "react-router-dom";

const highlights = [
  {
    value: "24/7",
    label: "Coordination continue",
    detail:
      "Pilotage des admissions, rendez-vous et communications critiques en temps reel.",
  },
  {
    value: "6",
    label: "Domaines orchestrés",
    detail:
      "Patients, medecins, hopitaux, rendez-vous, auth et notifications centralises.",
  },
  {
    value: "RBAC",
    label: "Securite par role",
    detail:
      "Acces controles pour super admin, etablissements, medecins et patients.",
  },
];

const pillars = [
  {
    title: "Exploitation multi-etablissements",
    text: "Chaque hopital conserve son perimetre operationnel tout en partageant un socle de gouvernance unique.",
  },
  {
    title: "Parcours patient fluide",
    text: "Du premier contact a la notification finale, les equipes disposent d un fil operationnel lisible et traçable.",
  },
  {
    title: "Socle pret pour la croissance",
    text: "Architecture microservices, gateway unique et separation des contextes pour absorber de nouveaux usages.",
  },
];

const journeys = [
  "Centraliser les operations quotidiennes de plusieurs etablissements sans perdre la segregation metier.",
  "Reduire les frictions entre secretariat, soignants et administration avec des flux simples et auditables.",
  "Donner une interface claire aux patients et praticiens pour suivre rendez-vous, profils et communications.",
];

export default function HomePage() {
  return (
    <main className="landing-page">
      <section className="landing-hero">
        <div className="landing-copy">
          <span className="landing-kicker">
            Plateforme hospitaliere unifiee
          </span>
          <h1>
            Le cockpit operationnel pour piloter un reseau de soins moderne.
          </h1>
          <p className="landing-lead">
            HealthCare relie administration, parcours patient, rendez-vous et
            communications dans une experience professionnelle, securisee et
            exploitable a grande echelle.
          </p>
          <div className="landing-actions">
            <Link to="/login" className="landing-primary">
              Acceder a la plateforme
            </Link>
            <Link to="/register" className="landing-secondary">
              Creer un compte etablissement
            </Link>
          </div>
          <div className="landing-trust">
            <span>JWT et controle d acces par role</span>
            <span>Flux multi-tenant securises</span>
            <span>Microservices supervisables</span>
          </div>
        </div>

        <div className="landing-panel">
          <div className="landing-panel-card accent-card">
            <p className="eyebrow">Vue direction</p>
            <strong>
              Operations, soins et gouvernance dans le meme tableau de bord.
            </strong>
            <p>
              Priorisez les capacites, suivez les activites critiques et
              diffusez les informations utiles aux bonnes equipes.
            </p>
          </div>
          <div className="landing-panel-grid">
            {highlights.map((item) => (
              <article key={item.label} className="landing-metric-card">
                <span>{item.value}</span>
                <h2>{item.label}</h2>
                <p>{item.detail}</p>
              </article>
            ))}
          </div>
        </div>
      </section>

      <section className="landing-section">
        <div className="landing-section-head">
          <span>Pourquoi cette plateforme</span>
          <h2>
            Une base serieuse pour operer, collaborer et monter en charge.
          </h2>
        </div>
        <div className="landing-pillars">
          {pillars.map((pillar) => (
            <article key={pillar.title} className="landing-info-card">
              <h3>{pillar.title}</h3>
              <p>{pillar.text}</p>
            </article>
          ))}
        </div>
      </section>

      <section className="landing-section landing-split">
        <article className="landing-story-card">
          <span>Parcours terrain</span>
          <h2>Des equipes qui voient la meme information, au bon moment.</h2>
          <p>
            La page d accueil n est plus un simple sas d authentification. Elle
            pose le cadre, met en avant les promesses du produit et donne une
            vision claire des usages couverts.
          </p>
        </article>
        <div className="landing-journey-list">
          {journeys.map((item) => (
            <div key={item} className="landing-journey-item">
              <strong>01</strong>
              <p>{item}</p>
            </div>
          ))}
        </div>
      </section>

      <section className="landing-cta-band">
        <div>
          <span>Prete pour les equipes de direction et les operations</span>
          <h2>
            Connectez vos etablissements a une interface plus claire et plus
            credible.
          </h2>
        </div>
        <Link to="/login" className="landing-primary">
          Ouvrir la console
        </Link>
      </section>
    </main>
  );
}
