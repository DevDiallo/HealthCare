import { Formik, Form, Field } from 'formik'
import * as Yup from 'yup'
import { Link, useNavigate } from 'react-router-dom'
import { authApi } from '../services/authApi'
import { useAppDispatch } from '../app/hooks'
import { setSession } from '../features/auth/authSlice'

const schema = Yup.object({
  email: Yup.string().email().required(),
  password: Yup.string().min(8).required(),
})

export default function LoginPage() {
  const navigate = useNavigate()
  const dispatch = useAppDispatch()

  return (
    <section className="auth-shell">
      <div className="auth-card">
        <h1>Connexion</h1>
        <Formik
          initialValues={{ email: '', password: '' }}
          validationSchema={schema}
          onSubmit={async (values, helpers) => {
            try {
              const payload = await authApi.login(values)
              dispatch(setSession(payload))
              navigate('/home')
            } catch {
              helpers.setStatus('Identifiants invalides')
            }
          }}
        >
          {({ errors, touched, status, isSubmitting }) => (
            <Form className="form-grid">
              <label htmlFor="email">Email</label>
              <Field id="email" name="email" type="email" />
              {errors.email && touched.email ? <small>{errors.email}</small> : null}

              <label htmlFor="password">Mot de passe</label>
              <Field id="password" name="password" type="password" />
              {errors.password && touched.password ? <small>{errors.password}</small> : null}

              {status ? <small>{status}</small> : null}
              <button type="submit" disabled={isSubmitting}>Se connecter</button>
              <Link to="/" className="auth-return-link">Retour a l'accueil</Link>
            </Form>
          )}
        </Formik>
      </div>
    </section>
  )
}
