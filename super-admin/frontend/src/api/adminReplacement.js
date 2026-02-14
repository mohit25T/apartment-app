import api from "./axios";

export const replaceAdmin = (oldAdminId, payload) => {
  return api.post(`/adminR/replace/${oldAdminId}`, payload);
};
