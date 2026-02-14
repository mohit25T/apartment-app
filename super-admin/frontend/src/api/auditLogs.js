import api from "./axios";

export const fetchAuditLogs = () => {
  return api.get("/audit-logs");
};