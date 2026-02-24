import api from "./axios";

export const toggleAdminBlock = (userId) =>
  api.patch(`/block/user/${userId}`);

export const toggleSocietyBlock = (societyId) =>
  api.patch(`/block/society/${societyId}`);
