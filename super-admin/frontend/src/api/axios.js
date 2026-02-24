import axios from "axios";

const api = axios.create({
  baseURL: "https://b.apexitworld.com/api",
  headers: {
    "Content-Type": "application/json"
  }
});

// 🔐 Attach token automatically
api.interceptors.request.use((config) => {
  const token = window.__AUTH_TOKEN__;
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

export default api;
