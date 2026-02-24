import { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import AppLayout from "../components/layout/AppLayout";
import PageWrapper from "../components/layout/PageWrapper";
import MetricCard from "../components/ui/MetricCard";
import api from "../api/axios";

const Dashboard = () => {
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");

  const navigate = useNavigate();

  useEffect(() => {
    const fetchOverview = async () => {
      try {
        const res = await api.get("/analytics/overview");
        setData(res.data);
      } catch (err) {
        setError("Failed to load dashboard data");
      } finally {
        setLoading(false);
      }
    };

    fetchOverview();
  }, []);

  return (
    <AppLayout>
      <PageWrapper>
        <div className="flex justify-between items-center mb-6">
          <h1 className="text-3xl font-bold">Super Admin Dashboard</h1>
        </div>

        {loading && <p>Loading...</p>}
        {error && <p className="text-red-500">{error}</p>}

        {data && (
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            <MetricCard title="Societies" value={data.societies} />
            <MetricCard title="Admins" value={data.admins} />
            <MetricCard title="Owners" value={data.owners} />
            <MetricCard title="Tenants" value={data.tenants} />
            <MetricCard title="Guards" value={data.guards} />
            <MetricCard title="Invites" value={data.invites} />
          </div>
        )}
      </PageWrapper>
    </AppLayout>
  );
};

export default Dashboard;
