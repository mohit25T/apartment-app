import { motion } from "framer-motion";

const MetricCard = ({ title, value }) => {
  return (
    <motion.div
      initial={{ opacity: 0, scale: 0.95 }}
      animate={{ opacity: 1, scale: 1 }}
      transition={{ duration: 0.25 }}
      className="bg-white rounded-xl shadow p-6"
    >
      <p className="text-gray-500 text-sm">{title}</p>
      <h2 className="text-3xl font-bold mt-2">{value}</h2>
    </motion.div>
  );
};

export default MetricCard;
