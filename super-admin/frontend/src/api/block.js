import api from "./axios";

export const toggleAdminBlock = (adminId) =>
  api.patch(`/block/admin/${adminId}`);

export const toggleSocietyBlock = (societyId) =>
  api.patch(`/block/society/${societyId}`);
