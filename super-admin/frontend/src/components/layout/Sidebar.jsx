import { NavLink } from "react-router-dom";
import { motion, AnimatePresence } from "framer-motion";

const navItems = [
  { name: "Dashboard", path: "/" },
  { name: "Add Admin", path: "/admins/add" },
  { name: "Societies", path: "/societies" },
  { name: "Admin Invites", path: "/invites" },
  { name: "Users", path: "/users" },
  { name: "Search", path: "/search" },
  { name: "Audit Logs", path: "/audit-logs" }
];

const Sidebar = ({ open, setOpen }) => {
  return (
    <AnimatePresence>
      {open && (
        <>
          {/* BACKDROP */}
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 0.4 }}
            exit={{ opacity: 0 }}
            className="fixed inset-0 z-40 bg-black"
            onClick={() => setOpen(false)}
          />

          {/* SIDEBAR */}
          <motion.aside
            initial={{ x: -260 }}
            animate={{ x: 0 }}
            exit={{ x: -260 }}
            transition={{ duration: 0.3, ease: "easeOut" }}
            className="fixed top-0 left-0 z-50
                       w-64 min-h-screen
                       bg-black text-white"
          >
            {/* ✖ CLOSE BUTTON */}
            <button
              onClick={() => setOpen(false)}
              className="absolute -right-10 top-4
                         w-8 h-8
                         flex items-center justify-center
                         bg-black text-white
                         rounded-full shadow-lg"
            >
              ✕
            </button>

            <div className="p-6 text-xl font-bold border-b border-gray-700">
              Super Admin
            </div>

            <nav className="mt-4 flex flex-col">
              {navItems.map((item) => (
                <NavLink
                  key={item.path}
                  to={item.path}
                  onClick={() => setOpen(false)}
                  className={({ isActive }) =>
                    `px-6 py-3 transition
                     ${
                       isActive
                         ? "bg-gray-800 text-white"
                         : "text-gray-300 hover:bg-gray-700"
                     }`
                  }
                >
                  {item.name}
                </NavLink>
              ))}
            </nav>
          </motion.aside>
        </>
      )}
    </AnimatePresence>
  );
};

export default Sidebar;
