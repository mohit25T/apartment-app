import { useEffect, useState } from "react";
import AppLayout from "../components/layout/AppLayout";
import PageWrapper from "../components/layout/PageWrapper";
import InviteTable from "../components/invites/InviteTable";
import {
  fetchInvites,
  resendInvite,
  cancelInvite
} from "../api/invites";

const Invites = () => {
  const [invites, setInvites] = useState([]);
  const [loading, setLoading] = useState(false);

  const loadInvites = async () => {
    const res = await fetchInvites();
    setInvites(res.data);
  };

  useEffect(() => {
    loadInvites();
  }, []);

  const handleResend = async (id) => {
    setLoading(true);
    await resendInvite(id);
    await loadInvites();
    setLoading(false);
  };

  const handleCancel = async (id) => {
    setLoading(true);
    await cancelInvite(id);
    await loadInvites();
    setLoading(false);
  };

  return (
    <AppLayout>
      <PageWrapper>
        <h1 className="text-2xl font-bold mb-6">Admin Invites</h1>

        {loading && (
          <p className="text-sm text-gray-500 mb-2">
            Updating...
          </p>
        )}

        <InviteTable
          invites={invites}
          onResend={handleResend}
          onCancel={handleCancel}
        />
      </PageWrapper>
    </AppLayout>
  );
};

export default Invites;