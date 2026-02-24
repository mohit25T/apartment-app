import { useEffect, useState } from "react";
import AppLayout from "../components/layout/AppLayout";
import PageWrapper from "../components/layout/PageWrapper";
import api from "../api/axios";

const AddAdminWithSociety = () => {
  const [societies, setSocieties] = useState([]);
  const [societyId, setSocietyId] = useState("");
  const [isNewSociety, setIsNewSociety] = useState(false);

  // admin fields
  const [name, setName] = useState("");
  const [mobile, setMobile] = useState("");
  const [email, setEmail] = useState("");
  const [flatNo, setFlatNo] = useState("");

  // new society fields
  const [societyName, setSocietyName] = useState("");
  const [city, setCity] = useState("");

  const [loading, setLoading] = useState(false);
  const [msg, setMsg] = useState("");

  useEffect(() => {
    api.get("/societies").then((res) => setSocieties(res.data));
  }, []);

  const handleSocietyChange = (e) => {
    const value = e.target.value;
    setSocietyId(value);
    setIsNewSociety(value === "OTHER");
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setMsg("");
    setLoading(true);

    try {
      let finalSocietyId = societyId;

      // 1️⃣ Create society if "Other"
      if (isNewSociety) {
        const res = await api.post("/societies", {
          name: societyName,
          city,
        });
        finalSocietyId = res.data._id;
      }

      // 2️⃣ Invite admin
      await api.post("/invites/admin", {
        name,
        mobile,
        email,
        flatNo,
        societyId: finalSocietyId,
      });

      setMsg("Admin invited successfully");

      // reset
      setName("");
      setMobile("");
      setEmail("");
      setFlatNo("");
      setSocietyId("");
      setSocietyName("");
      setCity("");
      setIsNewSociety(false);
    } catch (err) {
      setMsg(err.response?.data?.message || "Operation failed");
    } finally {
      setLoading(false);
    }
  };

  return (
    <AppLayout>
      <PageWrapper>
         <div className="min-h-screen flex items-center justify-center">
          <div className="w-full max-w-md">
        <h1 className="text-2xl font-bold mb-6">Add Admin</h1>

        <form
          onSubmit={handleSubmit}
          className="bg-white p-6 rounded-xl shadow max-w-md space-y-4"
        >
          {/* Admin Info */}
          <input
            type="text"
            placeholder="Admin Name"
            value={name}
            onChange={(e) => setName(e.target.value)}
            required
            className="w-full border p-2 rounded"
          />

          <input
            type="email"
            placeholder="Admin Email"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            required
            className="w-full border p-2 rounded"
          />

          <input
            type="text"
            placeholder="Admin Mobile"
            value={mobile}
            onChange={(e) => setMobile(e.target.value)}
            required
            className="w-full border p-2 rounded"
          />

          <input
            type="text"
            placeholder="Flat Number (A-101)"
            value={flatNo}
            onChange={(e) => setFlatNo(e.target.value.toUpperCase())}
            required
            className="w-full border p-2 rounded"
          />

          {/* Society Dropdown */}
          <select
            value={societyId}
            onChange={handleSocietyChange}
            required
            className="w-full border p-2 rounded"
          >
            <option value="">Select Society</option>

            {societies.map((s) => (
              <option key={s._id} value={s._id}>
                {s.name} ({s.city})
              </option>
            ))}

            <option value="OTHER">➕ Other (Create New Society)</option>
          </select>

          {/* New Society Fields */}
          {isNewSociety && (
            <>
              <input
                type="text"
                placeholder="New Society Name"
                value={societyName}
                onChange={(e) => setSocietyName(e.target.value)}
                required
                className="w-full border p-2 rounded"
              />

              <input
                type="text"
                placeholder="City"
                value={city}
                onChange={(e) => setCity(e.target.value)}
                required
                className="w-full border p-2 rounded"
              />
            </>
          )}

          <button
            type="submit"
            disabled={loading}
            className="w-full bg-black text-white py-2 rounded"
          >
            {loading ? "Processing..." : "Invite Admin"}
          </button>

          {msg && (
            <p className="text-sm text-center text-blue-600">{msg}</p>
          )}
        </form>
           </div>
           </div>
            
      </PageWrapper>
    </AppLayout>
  );
};

export default AddAdminWithSociety;
