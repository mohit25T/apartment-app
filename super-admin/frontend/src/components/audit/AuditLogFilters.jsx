const AuditLogFilters = ({
  action,
  setAction,
  dateRange,
  setDateRange,
  availableActions
}) => {
  return (
    <div className="flex gap-4 mb-6">
      {/* Action Filter */}
      <select
        value={action}
        onChange={(e) => setAction(e.target.value)}
        className="border px-3 py-2 rounded text-sm"
      >
        <option value="">All Actions</option>
        {availableActions.map((a) => (
          <option key={a} value={a}>
            {a}
          </option>
        ))}
      </select>

      {/* Date Filter */}
      <select
        value={dateRange}
        onChange={(e) => setDateRange(e.target.value)}
        className="border px-3 py-2 rounded text-sm"
      >
        <option value="ALL">All Time</option>
        <option value="TODAY">Today</option>
        <option value="7_DAYS">Last 7 Days</option>
      </select>
    </div>
  );
};

export default AuditLogFilters;
