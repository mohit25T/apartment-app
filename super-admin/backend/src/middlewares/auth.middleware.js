import { verifyToken } from "../utils/jwt.js";
import User from "../models/User.js";
import Society from "../models/Society.js";

export const requireAuth = async (req, res, next) => {
  console.log(".......")
  const token = req.headers.authorization?.split(" ")[1];
  if (!token) {
    return res.status(401).json({ message: "No token" });
  }
  
  try {
    // 1️⃣ Verify JWT
    const decoded = verifyToken(token);
    req.user = decoded;

    // 2️⃣ Check user status (BLOCKED / ACTIVE)
    const user = await User.findById(decoded.userId);
    if (!user || user.status === "BLOCKED") {
      return res.status(403).json({
        message: "User account is blocked"
      });
    }

    // 3️⃣ Check society status (if user belongs to a society)
    if (user.societyId) {
      const society = await Society.findById(user.societyId);
      if (society?.status === "BLOCKED") {
        return res.status(403).json({
          message: "Society is blocked"
        });
      }
    }
   
    // ✅ Everything ok
    next();
  } catch (err) {
    return res.status(401).json({ message: "Invalid token" });
  }
};
