import User from "../models/User.js";
import Society from "../models/Society.js";
import { auditLogger } from "../utils/auditLogger.js"; // ✅ ADDED

/* -------- ADMIN -------- */
export const blockUnblockUser = async (req, res) => {
  try {
    const { userId } = req.params;

    const user = await User.findById(userId);

    if (!user) {
      return res.status(404).json({
        message: "User not found"
      });
    }

    // ❌ Protect super admin
    if (user.roles.includes("SUPER_ADMIN")) {
      return res.status(403).json({
        message: "Super admin cannot be blocked"
      });
    }

    const oldStatus = user.status;

    user.status =
      user.status === "ACTIVE" ? "BLOCKED" : "ACTIVE";

    await user.save();

    // ✅ AUDIT LOG
    await auditLogger({
      req,
      action:
        user.status === "BLOCKED"
          ? "BLOCK_USER"
          : "UNBLOCK_USER",
      targetType: "USER",
      targetId: user._id,
      societyId: user.societyId,
      description: `User ${user.name} (${user.roles.join(
        ", "
      )}) status changed from ${oldStatus} to ${user.status}`
    });

    return res.json({
      message: `User ${user.status.toLowerCase()} successfully`,
      status: user.status
    });
  } catch (error) {
    console.error("BLOCK / UNBLOCK USER ERROR:", error);
    return res.status(500).json({
      message: "Failed to update user status"
    });
  }
};

/* -------- SOCIETY -------- */
export const toggleSocietyStatus = async (req, res) => {
  const { societyId } = req.params;

  const society = await Society.findById(societyId);

  if (!society) {
    return res.status(404).json({ message: "Society not found" });
  }

  const oldStatus = society.status;

  society.status =
    society.status === "ACTIVE" ? "BLOCKED" : "ACTIVE";

  await society.save();

  // ✅ AUDIT LOG
  await auditLogger({
    req,
    action:
      society.status === "BLOCKED"
        ? "BLOCK_SOCIETY"
        : "UNBLOCK_SOCIETY",
    targetType: "SOCIETY",
    targetId: society._id,
    societyId: society._id,
    description: `Society "${society.name}" status changed from ${oldStatus} to ${society.status}`
  });

  res.json({
    message: `Society ${society.status.toLowerCase()} successfully`,
    status: society.status
  });
};
