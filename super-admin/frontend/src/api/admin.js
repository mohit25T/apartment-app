import api from "./axios";

export const updateAdminDetails = (adminId, payload) => {
  return api.patch(`/admin/${adminId}`, payload);
};

