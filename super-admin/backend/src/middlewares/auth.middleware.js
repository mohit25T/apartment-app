import { verifyToken } from "../utils/jwt.js";
import User from "../models/User.js";
import Society from "../models/Society.js";

export const requireAuth = async (req, res, next) => {
  const token = req.headers.authorization?.split(" ")[1];

  if (!token) {
    return res.status(401).json({ message: "No token" });
  }

  try {
    // 1️⃣ Verify JWT
    const decoded = verifyToken(token);

    // 2️⃣ Fetch latest user from DB
    const user = await User.findById(decoded.userId);

    if (!user) {
      return res.status(401).json({ message: "User not found" });
    }

    if (user.status === "BLOCKED") {
      return res.status(403).json({
        message: "User account is blocked"
      });
    }

    // 3️⃣ Check society status
    if (user.societyId) {
      const society = await Society.findById(user.societyId);
      if (society?.status === "BLOCKED") {
        return res.status(403).json({
          message: "Society is blocked"
        });
      }
    }

    // 4️⃣ Attach fresh user data to request
    req.user = {
      userId: user._id,
      roles: user.roles,
      societyId: user.societyId
    };

    next();

  } catch (err) {
    return res.status(401).json({ message: "Invalid token" });
  }
};