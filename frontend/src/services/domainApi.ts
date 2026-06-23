import http from "./http";

export const domainApi = {
  hospitals: (params?: Record<string, unknown>) =>
    http.get("/hospitals", { params }),
  createHospital: (payload: Record<string, unknown>) =>
    http.post("/hospitals", payload),
  updateHospital: (id: string, payload: Record<string, unknown>) =>
    http.put(`/hospitals/${id}`, payload),
  activateHospital: (id: string) => http.patch(`/hospitals/${id}/activate`),
  suspendHospital: (id: string) => http.patch(`/hospitals/${id}/suspend`),

  patients: (params?: Record<string, unknown>) =>
    http.get("/patients", { params }),
  getPatientById: (id: string) => http.get(`/patients/${id}`),
  createPatient: (payload: Record<string, unknown>) =>
    http.post("/patients", payload),
  updatePatient: (id: string, payload: Record<string, unknown>) =>
    http.put(`/patients/${id}`, payload),
  deletePatient: (id: string) => http.delete(`/patients/${id}`),

  doctors: (params?: Record<string, unknown>) =>
    http.get("/doctors", { params }),
  createDoctor: (payload: Record<string, unknown>) =>
    http.post("/doctors", payload),
  updateDoctor: (id: string, payload: Record<string, unknown>) =>
    http.put(`/doctors/${id}`, payload),
  deleteDoctor: (id: string) => http.delete(`/doctors/${id}`),

  appointments: (params?: Record<string, unknown>) =>
    http.get("/appointments", { params }),
  createAppointment: (payload: Record<string, unknown>) =>
    http.post("/appointments", payload),
  updateAppointment: (id: string, payload: Record<string, unknown>) =>
    http.put(`/appointments/${id}`, payload),
  confirmAppointment: (id: string) => http.patch(`/appointments/${id}/confirm`),
  cancelAppointment: (id: string) => http.patch(`/appointments/${id}/cancel`),
  deleteAppointment: (id: string) => http.delete(`/appointments/${id}`),

  notifications: (params?: Record<string, unknown>) =>
    http.get("/notifications", { params }),
  createNotification: (payload: Record<string, unknown>) =>
    http.post("/notifications", payload),
  updateNotification: (id: string, payload: Record<string, unknown>) =>
    http.put(`/notifications/${id}`, payload),
  sendNotification: (id: string) => http.patch(`/notifications/${id}/send`),
  deleteNotification: (id: string) => http.delete(`/notifications/${id}`),
};
