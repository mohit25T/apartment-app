import { useEffect, useState } from "react";
import AppLayout from "../components/layout/AppLayout";
import PageWrapper from "../components/layout/PageWrapper";
import { useNavigate } from "react-router-dom";
import { useAuth } from "../context/AuthContext";
import { requestEmailChange, verifyEmailChange } from "../api/changeEmail";
import api from "../api/axios";

const ChangeEmail = () => {
  const [oldEmail, setOldEmail] = useState("");
  const [newEmail, setNewEmail] = useState("");
  const [otp, setOtp] = useState("");
  const [step, setStep] = useState(1);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");
  const [message, setMessage] = useState("");

  const { logout } = useAuth();
  const navigate = useNavigate();

  /* ==========================
     FETCH CURRENT EMAIL
  ========================== */
  useEffect(() => {
    api
      .get("/auth/me")
      .then((res) => {
        setOldEmail(res.data.email);
      })
      .catch(() => {
        setError("Failed to load current email");
      });
  }, []);

  /* ==========================
     STEP 1: REQUEST CHANGE
  ========================== */
  const requestChange = async (e) => {
    e.preventDefault();
    setError("");
    setMessage("");

    if (!newEmail) {
      setError("New email is required");
      return;
    }

    if (newEmail === oldEmail) {
      setError("New email must be different from current email");
      return;
    }

    try {
      setLoading(true);

      await requestEmailChange({
        oldEmail,
        newEmail,
      });

      setMessage("OTP sent to your current email");
      setStep(2);
    } catch (err) {
      setError(err.response?.data?.message || "Request failed");
    } finally {
      setLoading(false);
    }
  };

  /* ==========================
     STEP 2: VERIFY OTP
  ========================== */
  const verifyOtp = async (e) => {
    e.preventDefault();
    setError("");

    if (!otp) {
      setError("OTP is required");
      return;
    }

    try {
      setLoading(true);

      await verifyEmailChange({ otp });

      setMessage("Email updated successfully. Please login again.");

      setTimeout(() => {
        logout();
        navigate("/login");
      }, 1500);
    } catch (err) {
      setError(err.response?.data?.message || "Invalid OTP");
    } finally {
      setLoading(false);
    }
  };

  return (
    <AppLayout>
      <PageWrapper>
        <div className="max-w-md mx-auto mt-12 bg-white p-6 rounded-xl shadow">
          <h2 className="text-xl font-bold mb-4">Change Email Address</h2>

          {/* STEP 1 */}
          {step === 1 && (
            <form onSubmit={requestChange} className="space-y-4">
              {/* OLD EMAIL (READ ONLY) */}
              <div>
                <label className="block text-sm text-gray-600 mb-1">
                  Current Email
                </label>
                <input
                  type="email"
                  value={oldEmail}
                  disabled
                  className="w-full border p-2 rounded bg-gray-100 text-gray-600"
                />
              </div>

              {/* NEW EMAIL */}
              <input
                type="email"
                placeholder="New Email Address"
                value={newEmail}
                onChange={(e) => setNewEmail(e.target.value)}
                className="w-full border p-2 rounded"
              />

              {error && <p className="text-red-600 text-sm">{error}</p>}
              {message && <p className="text-green-600 text-sm">{message}</p>}

              <button
                type="submit"
                disabled={loading}
                className="w-full bg-black text-white py-2 rounded"
              >
                {loading ? "Sending OTP..." : "Send OTP"}
              </button>
            </form>
          )}

          {/* STEP 2 */}
          {step === 2 && (
            <form onSubmit={verifyOtp} className="space-y-4">
              <input
                type="text"
                placeholder="Enter OTP sent to old email"
                value={otp}
                onChange={(e) => setOtp(e.target.value)}
                className="w-full border p-2 rounded"
              />

              {error && <p className="text-red-600 text-sm">{error}</p>}
              {message && <p className="text-green-600 text-sm">{message}</p>}

              <button
                type="submit"
                disabled={loading}
                className="w-full bg-green-600 text-white py-2 rounded"
              >
                {loading ? "Verifying..." : "Verify & Update Email"}
              </button>
            </form>
          )}
        </div>
      </PageWrapper>
    </AppLayout>
  );
};

export default ChangeEmail;
