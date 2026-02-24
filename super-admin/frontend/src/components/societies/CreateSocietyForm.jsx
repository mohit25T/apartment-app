import { useState } from "react";

const CreateSocietyForm = ({ onSubmit, loading }) => {
  const [name, setName] = useState("");
  const [city, setCity] = useState("");

  const handleSubmit = (e) => {
    e.preventDefault();
    onSubmit({ name, city });
  };

  return (
    <>
      <h2 className="text-xl font-semibold mb-4">Create Society</h2>

      <form onSubmit={handleSubmit} className="space-y-4">
        <input
          type="text"
          placeholder="Society Name"
          value={name}
          onChange={(e) => setName(e.target.value)}
          required
          className="w-full border p-2 rounded"
        />

        <input
          type="text"
          placeholder="City"
          value={city}
          onChange={(e) => setCity(e.target.value)}
          className="w-full border p-2 rounded"
        />

        <button
          type="submit"
          disabled={loading}
          className="w-full bg-black text-white py-2 rounded hover:bg-gray-800 transition"
        >
          {loading ? "Creating..." : "Create Society"}
        </button>
      </form>
    </>
  );
};

export default CreateSocietyForm;
