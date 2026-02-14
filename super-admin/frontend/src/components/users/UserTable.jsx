import { toggleAdminBlock } from "../../api/block";

const UserTable = ({
  users,
  view,
  onRowClick,
  onEdit,
  onReplace,
  onStatusChange,
}) => {
  return (
    <div className="bg-white rounded-xl shadow overflow-x-auto">
      <table className="w-full text-left">
        <thead className="bg-gray-100">
          <tr align="center">
            <th className="p-4">Name</th>
            <th className="p-4">Email</th> {/* ✅ ADDED */}
            <th className="p-4">Mobile</th>
            <th className="p-4">Role</th>
            <th className="p-4">Society</th>
            <th className="p-4">Status</th>
            {view === "ADMINS" && <th className="p-4">Actions</th>}
          </tr>
        </thead>

        <tbody align="center">
          {users.map((u) => (
            <tr
              key={u._id}
              onClick={() => {
                if (view === "ADMINS") onRowClick?.(u);
              }}
              className="border-t hover:bg-gray-50 cursor-pointer"
            >
              <td className="p-4 font-medium">{u.name || "-"}</td>

              <td className="p-4 text-sm text-gray-600">
                {u.email || "-"} {/* ✅ ADDED */}
              </td>

              <td className="p-4">{u.mobile}</td>
              <td className="p-4">{u.roles.join(", ")}</td>
              <td className="p-4">{u.societyId?.name || "-"}</td>

              <td className="p-4">
                <span
                  className={`px-2 py-1 rounded text-sm ${
                    u.status === "ACTIVE"
                      ? "bg-green-100 text-green-700"
                      : "bg-red-100 text-red-700"
                  }`}
                >
                  {u.status}
                </span>
              </td>

              {view === "ADMINS" && (
                <td className="p-4">
                  <div className="flex justify-center items-center gap-2">
                    {/* EDIT */}
                    {u.roles.includes("ADMIN") && onEdit && (
                      <button
                        onClick={(e) => {
                          e.stopPropagation();
                          onEdit(u);
                        }}
                        className="inline-flex items-center gap-2
                          px-3 py-1.5 rounded-full
                          bg-blue-600 text-white text-sm
                          hover:bg-blue-700 active:scale-95
                          transition"
                      >
                        ✏️ Edit
                      </button>
                    )}

                    {/* BLOCK / UNBLOCK */}
                    {u.roles.includes("ADMIN") && onStatusChange && (
                      <button
                        onClick={async (e) => {
                          e.stopPropagation();
                          await toggleAdminBlock(u._id);
                          onStatusChange();
                        }}
                        className={`inline-flex items-center gap-2
                          px-3 py-1.5 rounded-full text-sm
                          ${
                            u.status === "ACTIVE"
                              ? "bg-red-100 text-red-700 hover:bg-red-200"
                              : "bg-green-100 text-green-700 hover:bg-green-200"
                          }`}
                      >
                        {u.status === "ACTIVE" ? "🚫 Block" : "✅ Unblock"}
                      </button>
                    )}
                  </div>
                </td>
              )}
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
};

export default UserTable;