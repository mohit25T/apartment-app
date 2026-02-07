import api from "./axios";

export const fetchSocieties = () => api.get("/societies");
export const createSociety = (data) => api.post("/societies", data);
