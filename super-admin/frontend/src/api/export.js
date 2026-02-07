import api from "./axios";

export const downloadUsersCSV = async (role) => {
  const res = await api.get(`/export/users?role=${role}`, {
    responseType: "blob"
  });

  const url = window.URL.createObjectURL(
    new Blob([res.data])
  );

  const link = document.createElement("a");
  link.href = url;
  link.setAttribute("download", `users-${role}.csv`);
  document.body.appendChild(link);
  link.click();
  link.remove();
};

export const downloadSocietiesCSV = async () => {
  const res = await api.get("/export/societies", {
    responseType: "blob"
  });

  const url = window.URL.createObjectURL(
    new Blob([res.data])
  );

  const link = document.createElement("a");
  link.href = url;
  link.setAttribute("download", "societies.csv");
  document.body.appendChild(link);
  link.click();
  link.remove();
};
