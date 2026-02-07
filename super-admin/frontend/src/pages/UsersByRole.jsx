import api from "../api/axios";
import { useEffect, useState } from "react";
import AppLayout from "../components/layout/AppLayout";
import PageWrapper from "../components/layout/PageWrapper";
import UserTable from "../components/users/UserTable";
import { downloadUsersCSV } from "../api/export";
import EditAdminModal from "../components/admin/EditAdminModal";
import ReplaceAdminModal from "../components/admin/ReplaceAdminModal";

const UsersByRole = () => {
  const [admins, setAdmins] = useState([]);
  const [users, setUsers] = useState([]);
  const [selectedAdmin, setSelectedAdmin] = useState(null);

  const [editingAdmin, setEditingAdmin] = useState(null);
  const [replacingAdmin, setReplacingAdmin] = useState(null);
  const [replaceLoading, setReplaceLoading] = useState(false);

  const [view, setView] = useState("ADMINS");

  const [counts, setCounts] = useState({
    admins: 0,
    residents: 0,
    guards: 0,
  });

  /* =============================
     LOAD ADMINS INITIALLY
  ============================= */
  useEffect(() => {
    api.get("/users?role=ADMIN").then((res) => {
      setAdmins(res.data);
      setCounts((p) => ({
        ...p,
        admins: res.data.length,
      }));
    });
  }, []);

  /* =============================
     LOAD USERS BY ADMIN SOCIETY
  ============================= */
  const loadUsersByAdmin = async (role) => {
    const res = await api.get(`/users?role=${role}`);

    const filtered = res.data.filter(
      (u) => u.societyId?._id === selectedAdmin?.societyId?._id,
    );

    setUsers(filtered);

    setCounts((p) => ({
      ...p,
      residents: role === "RESIDENT" ? filtered.length : p.residents,
      guards: role === "GUARD" ? filtered.length : p.guards,
    }));

    setView(role);
  };

  /* =============================
     GO BACK
  ============================= */
  const goBack = () => {
    setSelectedAdmin(null);
    setUsers([]);
    setView("ADMINS");

    // reset sub-counts
    setCounts((p) => ({
      ...p,
      residents: 0,
      guards: 0,
    }));
  };

  return (
    <AppLayout>
      <PageWrapper>
        {/* ================= HEADER ================= */}
        <div className="flex justify-between items-center mb-6">
          <h1 className="text-2xl font-bold flex items-center gap-3">
            {view === "ADMINS" && (
              <>
                Admins
                <span className="px-2 py-1 text-sm bg-blue-100 text-blue-700 rounded">
                  {counts.admins}
                </span>
              </>
            )}
            {view === "OPTIONS" && selectedAdmin && (
              <div className="space-y-4">
                {/* 🔹 OPTIONS HEADING */}
                <h1 className="text-lg font-bold text-gray-800">
                  Options for{" "}
                  <span className="text-blue-600">{selectedAdmin.name}</span>
                </h1>
              </div>
            )}
            {view === "RESIDENT" && (
              <>
                Residents of {selectedAdmin?.name}
                <span className="px-2 py-1 text-sm bg-green-100 text-green-700 rounded">
                  {counts.residents}
                </span>
              </>
            )}

            {view === "GUARD" && (
              <>
                Guards of {selectedAdmin?.name}
                <span className="px-2 py-1 text-sm bg-purple-100 text-purple-700 rounded">
                  {counts.guards}
                </span>
              </>
            )}
          </h1>

          <div className="flex gap-2">
            {view === "ADMINS" && (
              <button
                onClick={() => downloadUsersCSV("ADMIN")}
                className="px-3 py-1 bg-black text-white rounded text-sm"
              >
                Export Admins CSV
              </button>
            )}

            {view === "RESIDENT" && (
              <>
                <button
                  onClick={() => setReplacingAdmin(selectedAdmin)}
                  className="px-4 py-1.5 rounded-full bg-red-600 text-white text-sm hover:bg-red-700"
                >
                  🔁 Replace Admin
                </button>

                <button
                  onClick={() => downloadUsersCSV("RESIDENT")}
                  className="px-3 py-1 bg-black text-white rounded text-sm"
                >
                  Export Residents CSV
                </button>
              </>
            )}

            {view === "GUARD" && (
              <button
                onClick={() => downloadUsersCSV("GUARD")}
                className="px-3 py-1 bg-black text-white rounded text-sm"
              >
                Export Guards CSV
              </button>
            )}

            {view !== "ADMINS" && (
              <button
                onClick={goBack}
                className="px-3 py-1 border rounded text-sm"
              >
                ← Back
              </button>
            )}
          </div>
        </div>

        {/* ================= ADMINS ================= */}
        {view === "ADMINS" && (
          <UserTable
            users={admins}
            view={view}
            onEdit={(a) => setEditingAdmin(a)}
            onRowClick={(a) => {
              setSelectedAdmin(a);
              setView("OPTIONS");
            }}
            onStatusChange={() => {
              api.get("/users?role=ADMIN").then((res) => {
                setAdmins(res.data);
                setCounts((p) => ({
                  ...p,
                  admins: res.data.length,
                }));
              });
            }}
          />
        )}

        {/* ================= OPTIONS ================= */}
        {view === "OPTIONS" && selectedAdmin && (
          <div className="space-y-4">
            {/* 🔹 BUTTONS */}
            <div className="flex gap-4">
              <button
                onClick={() => loadUsersByAdmin("RESIDENT")}
                className="bg-black text-white px-4 py-2 rounded"
              >
                Residents
              </button>

              <button
                onClick={() => loadUsersByAdmin("GUARD")}
                className="bg-black text-white px-4 py-2 rounded"
              >
                Guards
              </button>
            </div>
          </div>
        )}

        {/* ================= USERS ================= */}
        {(view === "RESIDENT" || view === "GUARD") && (
          <UserTable users={users} view={view} />
        )}

        {/* ================= MODALS ================= */}
        {editingAdmin && (
          <EditAdminModal
            admin={editingAdmin}
            onClose={() => setEditingAdmin(null)}
            onUpdated={() => {
              setEditingAdmin(null);
              api.get("/users?role=ADMIN").then((res) => {
                setAdmins(res.data);
                setCounts((p) => ({
                  ...p,
                  admins: res.data.length,
                }));
              });
            }}
          />
        )}

        {replacingAdmin && (
          <ReplaceAdminModal
            admin={replacingAdmin}
            loading={replaceLoading}
            setLoading={setReplaceLoading}
            onClose={() => !replaceLoading && setReplacingAdmin(null)}
            onReplaced={() => {
              setReplaceLoading(true);

              api.get("/users?role=ADMIN").then((res) => {
                setAdmins(res.data);
                setCounts((p) => ({
                  ...p,
                  admins: res.data.length,
                }));

                setReplaceLoading(false);
                setReplacingAdmin(null);
                setView("ADMINS");
              });
            }}
          />
        )}
      </PageWrapper>
    </AppLayout>
  );
};

export default UsersByRole;
