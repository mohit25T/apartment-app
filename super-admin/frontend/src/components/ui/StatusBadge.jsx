const colors = {
  PENDING: "bg-yellow-100 text-yellow-700",
  USED: "bg-green-100 text-green-700",
  EXPIRED: "bg-gray-200 text-gray-600"
};

const StatusBadge = ({ status }) => {
  return (
    <span
      className={`px-2 py-1 rounded text-sm font-medium ${colors[status]}`}
    >
      {status}
    </span>
  );
};

export default StatusBadge;
