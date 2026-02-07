import api from "./axios";

/**
 * Update Super Admin mobile number
 * PUT /api/super-admin/mobile
 */
export const updateSuperAdminMobile = (data) =>
  api.put("/user/mobile", data);
