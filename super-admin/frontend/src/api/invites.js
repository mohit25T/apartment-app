import api from "./axios";

export const fetchInvites = () => api.get("/invites");
export const resendInvite = (id) => api.post(`/invites/${id}/resend`);
export const cancelInvite = (id) => api.post(`/invites/${id}/cancel`);
