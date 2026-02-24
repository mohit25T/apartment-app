import { BrowserRouter, Routes, Route } from "react-router-dom";
import Login from "../pages/Login";
import ChangeEmail from "../pages/ChangeEmail";
import Dashboard from "../pages/Dashboard";
import Societies from "../pages/Societies";
import Invites from "../pages/Invites";
// import Analytics from "../pages/Analytics";
import AuditLogs from "../pages/AuditLogs";
import ProtectedRoute from "./ProtectRoute";
import AddAdmin from "../pages/AddAdmin";
import UsersByRole from "../pages/UsersByRole";
import GlobalSearch from "../pages/GlobalSearch";
import UpdateSuperAdmin from "../pages/UpdateSuperAdminMobile";

const AppRouter = () => {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/login" element={<Login />} />

        <Route
          path="/"
          element={
            <ProtectedRoute>
              <Dashboard />
            </ProtectedRoute>
          }
        />

        <Route
          path="/societies"
          element={
            <ProtectedRoute>
              <Societies />
            </ProtectedRoute>
          }
        />

        <Route
          path="/invites"
          element={
            <ProtectedRoute>
              <Invites />
            </ProtectedRoute>
          }
        />

        <Route
          path="/users"
          element={
            <ProtectedRoute>
              <UsersByRole />
            </ProtectedRoute>
          }
        />

        <Route
          path="/super-admin/update"
          element={
            <ProtectedRoute>
              <UpdateSuperAdmin />
            </ProtectedRoute>
          }
        />

        <Route
          path="/change-email"
          element={
            <ProtectedRoute>
              <ChangeEmail />
            </ProtectedRoute>
          }
        />

        <Route
          path="/search"
          element={
            <ProtectedRoute>
              <GlobalSearch />
            </ProtectedRoute>
          }
        />

        <Route
          path="/admins/add"
          element={
            <ProtectedRoute>
              <AddAdmin />
            </ProtectedRoute>
          }
        />
        <Route
          path="/audit-logs"
          element={
            <ProtectedRoute>
              <AuditLogs />
            </ProtectedRoute>
          }
        />
      </Routes>
    </BrowserRouter>
  );
};

export default AppRouter;
