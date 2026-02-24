import { motion } from "framer-motion";
import StatusBadge from "../ui/StatusBadge";

const InviteTable = ({ invites, onResend, onCancel }) => {
  return (
    <div className="bg-white rounded-xl shadow overflow-hidden">
      <table className="w-full text-left">
        <thead className="bg-gray-100">
          <tr>
            <th className="p-4">Mobile</th>
            <th className="p-4">Email</th> {/* ✅ ADDED */}
            <th className="p-4">Role</th>
            <th className="p-4">Society</th>
            <th className="p-4">Status</th>
            <th className="p-4">Expires</th>
            <th className="p-4">Actions</th>
          </tr>
        </thead>
        <tbody>
          {invites.map((inv, i) => (
            <motion.tr
              key={inv._id}
              initial={{ opacity: 0, y: 5 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: i * 0.03 }}
              className="border-t"
            >
              <td className="p-4 font-medium">
                {inv.mobile}
              </td>

              <td className="p-4 text-sm text-gray-600">
                {inv.email || "-"} {/* ✅ ADDED */}
              </td>
              <td className="p-4 font-medium">{inv.role}</td>
              <td className="p-4">
                {inv.societyId?.name || "-"}
              </td>

              <td className="p-4">
                <StatusBadge status={inv.status} />
              </td>

              <td className="p-4 text-sm text-gray-500">
                {new Date(inv.expiresAt).toLocaleString()}
              </td>

              <td className="p-4 space-x-2">
                {inv.status === "PENDING" && (
                  <>
                    <button
                      onClick={() => onResend(inv._id)}
                      className="px-3 py-1 text-sm rounded bg-blue-500 text-white hover:bg-blue-600 transition"
                    >
                      Resend
                    </button>
                    <button
                      onClick={() => onCancel(inv._id)}
                      className="px-3 py-1 text-sm rounded bg-red-500 text-white hover:bg-red-600 transition"
                    >
                      Cancel
                    </button>
                  </>
                )}
              </td>
            </motion.tr>
          ))}
        </tbody>
      </table>
    </div>
  );
};

export default InviteTable;
