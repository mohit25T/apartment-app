import { motion } from "framer-motion";
import { pageTransition } from "../../animation/motionVariants";

const PageWrapper = ({ children }) => {
  return (
    <motion.div {...pageTransition}>
      {children}
    </motion.div>
  );
};

export default PageWrapper;
