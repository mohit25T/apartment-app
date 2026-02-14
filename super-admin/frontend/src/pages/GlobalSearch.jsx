import { useEffect, useState } from "react";
import AppLayout from "../components/layout/AppLayout";
import PageWrapper from "../components/layout/PageWrapper";
import { globalSearch } from "../api/search";

const GlobalSearch = () => {
  const [q, setQ] = useState("");
  const [result, setResult] = useState({
    users: [],
    societies: []
  });

  useEffect(() => {
    if (q.length < 2) {
      setResult({ users: [], societies: [] });
      return;
    }

    const timer = setTimeout(() => {
      globalSearch(q).then((res) => setResult(res.data));
    }, 300);

    return () => clearTimeout(timer);
  }, [q]);

  return (
    <AppLayout>
      <PageWrapper>
        <h1 className="text-2xl font-bold mb-4">
          Global Search
        </h1>

        <input
          type="text"
          placeholder="Search users or societies..."
          value={q}
          onChange={(e) => setQ(e.target.value)}
          className="w-full border p-3 rounded mb-6"
        />

        {/* USERS */}
        {result.users.length > 0 && (
          <div className="mb-6">
            <h2 className="font-semibold mb-2">Users</h2>
            <ul className="bg-white rounded shadow divide-y">
              {result.users.map((u) => (
                <li key={u._id} className="p-3">
                  <p className="font-medium">
                    {u.name || "—"} ({u.roles.join(", ")})
                  </p>
                  <p className="text-sm text-gray-500">
                    {u.email} • {u.mobile} • {u.societyId?.name || "-"}
                  </p>
                </li>
              ))}
            </ul>
          </div>
        )}

        {/* SOCIETIES */}
        {result.societies.length > 0 && (
          <div>
            <h2 className="font-semibold mb-2">Societies</h2>
            <ul className="bg-white rounded shadow divide-y">
              {result.societies.map((s) => (
                <li key={s._id} className="p-3">
                  <p className="font-medium">{s.name}</p>
                  <p className="text-sm text-gray-500">
                    {s.city} • {s.status}
                  </p>
                </li>
              ))}
            </ul>
          </div>
        )}
      </PageWrapper>
    </AppLayout>
  );
};

export default GlobalSearch;
