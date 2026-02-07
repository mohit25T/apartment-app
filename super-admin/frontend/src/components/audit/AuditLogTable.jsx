const AuditLogTable = ({ logs }) => {
  return (
    <div className="bg-white rounded-xl shadow overflow-x-auto">
      <table className="w-full text-left text-sm">
        <thead className="bg-gray-100">
          <tr>
            <th className="p-4">Action</th>
            <th className="p-4">Performed By</th>
            {/* <th className="p-4">Description</th> */}
            <th className="p-4">Time</th>
          </tr>
        </thead>

        <tbody>
          {logs.map((log) => (
            <tr key={log._id} className="border-t">
              <td className="p-4 font-semibold text-blue-700">
                {log.action}
              </td>

              <td className="p-4">
                <div className="font-medium">
                  {log.performedBy?.name || "System"}
                </div>
                <div className="text-xs text-gray-500">
                  {log.performedByRole}
                </div>
              </td>

              {/* <td className="p-4 text-gray-700">
                {log.description}
              </td> */}

              <td className="p-4 text-xs text-gray-500">
                {new Date(log.createdAt).toLocaleString()}
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
};

export default AuditLogTable;
