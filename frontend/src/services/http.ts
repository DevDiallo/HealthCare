import axios from "axios";

const http = axios.create({
  baseURL: import.meta.env.VITE_API_BASE_URL || "/api",
  timeout: 20000,
});

function normalizePagedPayload(payload: unknown) {
  if (!payload || typeof payload !== "object") return payload;

  const envelope = payload as {
    data?: {
      items?: unknown[];
      content?: unknown[];
    };
  };

  const pageData = envelope.data;
  if (!pageData || typeof pageData !== "object") return payload;

  if (Array.isArray(pageData.items) && !Array.isArray(pageData.content)) {
    pageData.content = pageData.items;
  }

  return payload;
}

http.interceptors.request.use((config) => {
  const token = localStorage.getItem("hc_access_token");
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

http.interceptors.response.use(
  (response) => {
    normalizePagedPayload(response.data);
    return response;
  },
  (error) => {
    if (error.response?.status === 401) {
      localStorage.removeItem("hc_access_token");
      localStorage.removeItem("hc_refresh_token");
      if (!window.location.pathname.includes("/login")) {
        window.location.href = "/login";
      }
    }
    return Promise.reject(error);
  },
);

export default http;
