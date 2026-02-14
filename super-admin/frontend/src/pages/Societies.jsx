import { useEffect, useState } from "react";
import AppLayout from "../components/layout/AppLayout";
import PageWrapper from "../components/layout/PageWrapper";
import Modal from "../components/ui/Modal";
import CreateSocietyForm from "../components/societies/CreateSocietyForm";
import SocietyTable from "../components/societies/SocietyTable";
import { fetchSocieties, createSociety } from "../api/societies";

const Societies = () => {
  const [societies, setSocieties] = useState([]);
  const [open, setOpen] = useState(false);
  const [loading, setLoading] = useState(false);

  const loadSocieties = async () => {
    const res = await fetchSocieties();
    setSocieties(res.data);
  };

  useEffect(() => {
    loadSocieties();
  }, []);

  const handleCreate = async (data) => {
    try {
      setLoading(true);
      await createSociety(data);
      setOpen(false);
      loadSocieties();
    } finally {
      setLoading(false);
    }
  };

  return (
    <AppLayout>
      <PageWrapper>
        <div className="flex justify-between items-center mb-6">
          <h1 className="text-2xl font-bold">Societies</h1>
          <button
            onClick={() => setOpen(true)}
            className="bg-black text-white px-4 py-2 rounded hover:bg-gray-800 transition"
          >
            + Create Society
          </button>
        </div>

        <SocietyTable societies={societies} reloadSocieties={loadSocieties} />

        <Modal open={open} onClose={() => setOpen(false)}>
          <CreateSocietyForm onSubmit={handleCreate} loading={loading} />
        </Modal>
      </PageWrapper>
    </AppLayout>
  );
};

export default Societies;
