import { motion } from "framer-motion";
import { toggleSocietyBlock } from "../../api/block";

const SocietyTable = ({ societies, reloadSocieties }) => {
  return (
    <div className="bg-white rounded-xl shadow overflow-hidden">
      <table className="w-full text-left">
        <thead className="bg-gray-100">
          <tr>
            <th className="p-4">Name</th>
            <th className="p-4">City</th>
            <th className="p-4">Status</th>
            <th className="p-4">Created</th>
            <th className="p-4">Action</th>
          </tr>
        </thead>

        <tbody>
          {societies.map((s, i) => (
            <motion.tr
              key={s._id}
              initial={{ opacity: 0, y: 5 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: i * 0.03 }}
              className="border-t"
            >
              <td className="p-4 font-medium">{s.name}</td>

              <td className="p-4">{s.city || "-"}</td>

              <td className="p-4">
                <span
                  className={`px-2 py-1 rounded text-sm ${
                    s.status === "ACTIVE"
                      ? "bg-green-100 text-green-700"
                      : "bg-red-100 text-red-700"
                  }`}
                >
                  {s.status}
                </span>
              </td>

              <td className="p-4 text-sm text-gray-500">
                {new Date(s.createdAt).toLocaleDateString()}
              </td>

              <td className="p-4">
                <button
                  onClick={async () => {
                    await toggleSocietyBlock(s._id);
                    await reloadSocieties(); // ✅ state refresh
                  }}
                  className={`px-3 py-1 rounded text-sm ${
                    s.status === "ACTIVE"
                      ? "bg-red-500 text-white"
                      : "bg-green-500 text-white"
                  }`}
                >
                  {s.status === "ACTIVE" ? "Block" : "Unblock"}
                </button>
              </td>
            </motion.tr>
          ))}
        </tbody>
      </table>
    </div>
  );
};

export default SocietyTable;
