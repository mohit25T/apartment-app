import { useState } from "react";
import { motion } from "framer-motion";
import api from "../api/axios";
import { useAuth } from "../context/AuthContext";
import { useNavigate } from "react-router-dom";

const Login = () => {
  const [mobile, setMobile] = useState("");
  const [email, setEmail] = useState(""); // ✅ ADDED
  const [otp, setOtp] = useState("");
  const [otpSent, setOtpSent] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");

  const { login } = useAuth();
  const navigate = useNavigate();

  const sendOtp = async () => {
    try {
      setLoading(true);
      setError("");

      await api.post("/auth/send-otp", {
        mobile,
        email       // ✅ ADDED
      });

      setOtpSent(true);
    } catch (err) {
      setError(err.response?.data?.message || "Failed to send OTP");
    } finally {
      setLoading(false);
    }
  };

  const verifyOtp = async () => {
    try {
      setLoading(true);
      setError("");

      const res = await api.post("/auth/verify-otp", {
        mobile,
        email,      // ✅ ADDED
        otp
      });

      login(res.data.token);
      navigate("/");
    } catch (err) {
      setError("Invalid OTP");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-100">
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        className="bg-white p-8 rounded-xl shadow-lg w-96"
      >
        <h2 className="text-2xl font-semibold mb-4 text-center">
          Super Admin Login
        </h2>

        <input
          type="text"
          placeholder="Mobile Number"
          value={mobile}
          onChange={(e) => setMobile(e.target.value)}
          required
          className="w-full border p-2 rounded mb-3"
        />

        <input
          type="email"
          placeholder="Email Address"
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          required
          className="w-full border p-2 rounded mb-3"
        />

        {otpSent && (
          <input
            type="text"
            placeholder="Enter OTP"
            value={otp}
            onChange={(e) => setOtp(e.target.value)}
            className="w-full border p-2 rounded mb-3"
          />
        )}

        {error && (
          <p className="text-red-500 text-sm mb-3">{error}</p>
        )}

        {!otpSent ? (
          <button
            onClick={sendOtp}
            disabled={loading}
            className="w-full bg-black text-white py-2 rounded"
          >
            {loading ? "Sending OTP..." : "Send OTP"}
          </button>
        ) : (
          <button
            onClick={verifyOtp}
            disabled={loading}
            className="w-full bg-green-600 text-white py-2 rounded"
          >
            {loading ? "Verifying..." : "Verify OTP"}
          </button>
        )}
      </motion.div>
    </div>
  );
};

export default Login;
