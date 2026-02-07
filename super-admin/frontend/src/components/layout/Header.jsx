import { motion } from "framer-motion";
import { useAuth } from "../../context/AuthContext";
import { useNavigate } from "react-router-dom";
import { jwtDecode } from "jwt-decode";

const Header = ({ isSidebarOpen, setIsSidebarOpen }) => {
  const { logout } = useAuth();
  const navigate = useNavigate();

  // 🔐 Read token directly
  const token = localStorage.getItem("token");

  // ✅ Determine super admin from JWT
  let isSuperAdmin = false;
  if (token) {
    try {
      const decoded = jwtDecode(token);
      isSuperAdmin = decoded.role === "SUPER_ADMIN";
    } catch (e) {
      console.error("Invalid token");
    }
  }

  const handleLogout = () => {
    logout();
    navigate("/login");
  };

  const handleUpdateSuperAdmin = () => {
    navigate("/super-admin/update");
  };

  return (
    <motion.header
      animate={{
        opacity: isSidebarOpen ? 0.6 : 1,
        y: isSidebarOpen ? -4 : 0,
      }}
      transition={{ duration: 0.25 }}
      className="h-16 bg-white shadow
                 flex items-center justify-between
                 px-4 sticky top-0 z-40"
    >
      {/* LEFT */}
      <div className="flex items-center gap-4">
        <button
          onClick={() => setIsSidebarOpen(true)}
          className="flex flex-col justify-between w-6 h-5"
        >
          <span className="block h-1 bg-black" />
          <span className="block h-1 bg-black" />
          <span className="block h-1 bg-black" />
        </button>

        <h1 className="text-lg font-semibold">Super Admin Dashboard</h1>
      </div>

      {/* RIGHT */}
      <div className="flex items-center gap-3">
        <button
          onClick={() => navigate("/change-email")}
          className="px-4 py-2 rounded border
                       text-sm font-medium
                       hover:bg-gray-100
                       transition"
        >
          Change Email
        </button>
        {isSuperAdmin && (
          <button
            onClick={handleUpdateSuperAdmin}
            className="bg-blue-600 text-white
                       px-4 py-2 rounded
                       hover:bg-blue-700 transition"
          >
            Update Super Admin
          </button>
        )}

        <button
          onClick={handleLogout}
          className="bg-red-500 text-white
                     px-4 py-2 rounded
                     hover:bg-red-600 transition"
        >
          Logout
        </button>
      </div>
    </motion.header>
  );
};

export default Header;
