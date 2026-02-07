import api from "./axios";

export const fetchUsersByRole = (role) =>
  api.get(`/users?role=${role}`);
