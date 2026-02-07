import { useState } from "react";
import { useNavigate } from "react-router-dom";
import AppLayout from "../components/layout/AppLayout";
import PageWrapper from "../components/layout/PageWrapper";
import { useAuth } from "../context/AuthContext";
import { updateSuperAdminMobile } from "../api/updateSuperadminnumber";

const UpdateSuperAdmin = () => {
  const [mobile, setMobile] = useState("");
  const [loading, setLoading] = useState(false);
  const [message, setMessage] = useState("");
  const [error, setError] = useState("");

  const navigate = useNavigate();
  const { logout } = useAuth();

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError("");
    setMessage("");

    if (!/^[6-9]\d{9}$/.test(mobile)) {
      setError("Enter valid 10-digit mobile number");
      return;
    }

    try {
      setLoading(true);
      const res = await updateSuperAdminMobile({ mobile });

      setMessage(res.data.message);

      // 🔐 AUTO LOGOUT AFTER MOBILE CHANGE
      setTimeout(() => {
        logout();
        navigate("/login");
      }, 1500);
    } catch (err) {
      setError(err.response?.data?.message || "Update failed");
    } finally {
      setLoading(false);
    }
  };

  return (
    <AppLayout>
      <PageWrapper>
        <div className="max-w-md mx-auto mt-10 bg-white p-6 rounded shadow">
          <h2 className="text-xl font-semibold mb-4">
            Update Super Admin Mobile
          </h2>

          <form onSubmit={handleSubmit} className="flex flex-col gap-3">
            <input
              type="tel"
              value={mobile}
              onChange={(e) => setMobile(e.target.value)}
              placeholder="New mobile number"
              maxLength={10}
              className="border px-3 py-2 rounded"
            />

            <button
              disabled={loading}
              className="bg-blue-600 text-white py-2 rounded hover:bg-blue-700"
            >
              {loading ? "Updating..." : "Update"}
            </button>
          </form>

          {message && <p className="text-green-600 mt-3">{message}</p>}
          {error && <p className="text-red-600 mt-3">{error}</p>}
        </div>
      </PageWrapper>
    </AppLayout>
  );
};

export default UpdateSuperAdmin;
