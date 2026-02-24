import api from "./axios";

export const updateAdminDetails = (adminId, payload) => {
  console.log("ADMIN UPDATE API CALLED");
  return api.patch(`/admin/${adminId}`, payload);
};
