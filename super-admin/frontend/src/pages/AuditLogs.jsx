import { useEffect, useMemo, useState } from "react";
import AppLayout from "../components/layout/AppLayout";
import PageWrapper from "../components/layout/PageWrapper";
import AuditLogTable from "../components/audit/AuditLogTable";
import AuditLogFilters from "../components/audit/AuditLogFilters";
import { fetchAuditLogs } from "../api/auditLogs";

const AuditLogs = () => {
  const [logs, setLogs] = useState([]);
  const [action, setAction] = useState("");
  const [dateRange, setDateRange] = useState("ALL");
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchAuditLogs()
      .then((res) => setLogs(res.data))
      .finally(() => setLoading(false));
  }, []);

  const availableActions = useMemo(() => {
    return [...new Set(logs.map((l) => l.action))];
  }, [logs]);

  const filteredLogs = useMemo(() => {
    return logs.filter((log) => {
      const logDate = new Date(log.createdAt);
      const now = new Date();

      if (action && log.action !== action) return false;

      if (dateRange === "TODAY") {
        return logDate.toDateString() === now.toDateString();
      }

      if (dateRange === "7_DAYS") {
        const diff = (now - logDate) / (1000 * 60 * 60 * 24);
        return diff <= 7;
      }

      return true;
    });
  }, [logs, action, dateRange]);

  return (
    <AppLayout>
      <PageWrapper>
        <h1 className="text-2xl font-bold mb-4">
          Audit Logs
        </h1>

        <AuditLogFilters
          action={action}
          setAction={setAction}
          dateRange={dateRange}
          setDateRange={setDateRange}
          availableActions={availableActions}
        />

        {loading ? (
          <p>Loading audit logs...</p>
        ) : filteredLogs.length === 0 ? (
          <p className="text-gray-500">
            No logs found
          </p>
        ) : (
          <AuditLogTable logs={filteredLogs} />
        )}
      </PageWrapper>
    </AppLayout>
  );
};

export default AuditLogs;
