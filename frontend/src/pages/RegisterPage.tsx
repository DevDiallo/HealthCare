import { Formik, Form, Field } from "formik";
import * as Yup from "yup";
import { Link, useNavigate } from "react-router-dom";
import { authApi } from "../services/authApi";
import { domainApi } from "../services/domainApi";
import { decodeAccessIdentity } from "../utils/authIdentity";

const schema = Yup.object({
  firstName: Yup.string().required(),
  lastName: Yup.string().required(),
  email: Yup.string().email().required(),
  phone: Yup.string().required(),
  password: Yup.string().min(8).required(),
  hospitalId: Yup.number().required(),
  role: Yup.string().required(),
  speciality: Yup.string().when("role", {
    is: "DOCTOR",
    then: (schema) => schema.required(),
    otherwise: (schema) => schema.optional(),
  }),
});

export default function RegisterPage() {
  const navigate = useNavigate();

  return (
    <section className="auth-shell">
      <div className="auth-card">
        <h1>Inscription</h1>
        <Formik
          initialValues={{
            firstName: "",
            lastName: "",
            email: "",
            phone: "",
            password: "",
            hospitalId: 1,
            role: "PATIENT",
            speciality: "",
          }}
          validationSchema={schema}
          onSubmit={async (values, helpers) => {
            try {
              const { speciality, ...registerPayload } = values;
              const session = await authApi.register(registerPayload as never);
              const identity = decodeAccessIdentity(session.accessToken);

              localStorage.setItem("hc_access_token", session.accessToken);
              localStorage.setItem("hc_refresh_token", session.refreshToken);

              if (values.role === "PATIENT" && identity.userAccountId) {
                await domainApi.createPatient({
                  userAccountId: identity.userAccountId,
                  firstName: values.firstName,
                  lastName: values.lastName,
                  email: values.email,
                  bloodType: null,
                  allergies: null,
                  chronicConditions: null,
                  emergencyContact: values.phone,
                });
              }

              if (values.role === "DOCTOR" && identity.userAccountId) {
                await domainApi.createDoctor({
                  userAccountId: identity.userAccountId,
                  firstName: values.firstName,
                  lastName: values.lastName,
                  speciality: speciality || "Generaliste",
                });
              }

              localStorage.removeItem("hc_access_token");
              localStorage.removeItem("hc_refresh_token");
              navigate("/login");
            } catch {
              localStorage.removeItem("hc_access_token");
              localStorage.removeItem("hc_refresh_token");
              helpers.setStatus("Inscription impossible");
            }
          }}
        >
          {({ status, values, isSubmitting }) => (
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

              {values.role === "DOCTOR" ? (
                <>
                  <label htmlFor="speciality">Specialite</label>
                  <Field id="speciality" name="speciality" />
                </>
              ) : null}

              {status ? <small>{status}</small> : null}
              <button type="submit" disabled={isSubmitting}>
                Creer le compte
              </button>
              <Link to="/" className="auth-return-link">
                Retour a l'accueil
              </Link>
            </Form>
          )}
        </Formik>
      </div>
    </section>
  );
}
