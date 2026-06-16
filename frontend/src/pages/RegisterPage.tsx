import { Formik, Form, Field } from 'formik'
import * as Yup from 'yup'
import { useNavigate } from 'react-router-dom'
import { authApi } from '../services/authApi'

const schema = Yup.object({
  firstName: Yup.string().required(),
  lastName: Yup.string().required(),
  email: Yup.string().email().required(),
  phone: Yup.string().required(),
  password: Yup.string().min(8).required(),
  hospitalId: Yup.number().required(),
  role: Yup.string().required(),
})

export default function RegisterPage() {
  const navigate = useNavigate()

  return (
    <section className="auth-shell">
      <div className="auth-card">
        <h1>Inscription</h1>
        <Formik
          initialValues={{
            firstName: '',
            lastName: '',
            email: '',
            phone: '',
            password: '',
            hospitalId: 1,
            role: 'PATIENT',
          }}
          validationSchema={schema}
          onSubmit={async (values, helpers) => {
            try {
              await authApi.register(values as never)
              navigate('/login')
            } catch {
              helpers.setStatus('Inscription impossible')
            }
          }}
        >
          {({ status, isSubmitting }) => (
            <Form className="form-grid">
              <label htmlFor="firstName">Prenom</label>
              <Field id="firstName" name="firstName" />

              <label htmlFor="lastName">Nom</label>
              <Field id="lastName" name="lastName" />

              <label htmlFor="email">Email</label>
              <Field id="email" name="email" type="email" />

              <label htmlFor="phone">Telephone</label>
              <Field id="phone" name="phone" />

              <label htmlFor="password">Mot de passe</label>
              <Field id="password" name="password" type="password" />

              <label htmlFor="hospitalId">Hospital ID</label>
              <Field id="hospitalId" name="hospitalId" type="number" />

              <label htmlFor="role">Role</label>
              <Field as="select" id="role" name="role">
                <option value="PATIENT">PATIENT</option>
                <option value="DOCTOR">DOCTOR</option>
                <option value="NURSE">NURSE</option>
                <option value="RECEPTIONIST">RECEPTIONIST</option>
                <option value="HOSPITAL_ADMIN">HOSPITAL_ADMIN</option>
              </Field>

              {status ? <small>{status}</small> : null}
              <button type="submit" disabled={isSubmitting}>Creer le compte</button>
            </Form>
          )}
        </Formik>
      </div>
    </section>
  )
}
