export type PageResponse<T> = {
  content: T[];
  page: number;
  size: number;
  totalElements: number;
  totalPages: number;
  first: boolean;
  last: boolean;
};

export type ApiEnvelope<T> = {
  success: boolean;
  message: string;
  data: T;
};

export type HospitalStatus = "ACTIVE" | "SUSPENDED";

export type Hospital = {
  id: string;
  name: string;
  address: string;
  status: HospitalStatus;
  createdAt: string;
  updatedAt: string;
};

export type Patient = {
  id: string;
  hospitalId: string;
  firstName: string;
  lastName: string;
  email: string;
  bloodType?: string | null;
  allergies?: string | null;
  chronicConditions?: string | null;
  emergencyContact?: string | null;
  createdAt: string;
  updatedAt: string;
};

export type Doctor = {
  id: string;
  hospitalId: string;
  firstName: string;
  lastName: string;
  speciality: string;
  createdAt: string;
  updatedAt: string;
};

export type AppointmentStatus = "PENDING" | "CONFIRMED" | "CANCELLED";

export type Appointment = {
  id: string;
  hospitalId: string;
  patientId: string;
  doctorId: string;
  appointmentAt: string;
  status: AppointmentStatus;
  createdAt: string;
  updatedAt: string;
};

export type NotificationStatus = "NEW" | "SENT";

export type Notification = {
  id: string;
  hospitalId: string;
  recipientUserId: string;
  title: string;
  message: string;
  status: NotificationStatus;
  sentAt?: string | null;
  createdAt: string;
  updatedAt: string;
};
