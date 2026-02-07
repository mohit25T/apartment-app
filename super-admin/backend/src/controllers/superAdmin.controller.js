import User from "../models/User.js";

/**
 * ======================================================
 * UPDATE MY MOBILE NUMBER (ALL ROLES)
 * ======================================================
 * - SUPER_ADMIN / ADMIN / RESIDENT / GUARD
 * - Updates only OWN mobile number
 * - JWT protected
 * - Frontend will auto-logout after success
 */
export const updateMyMobile = async (req, res) => {
  try {
    const { mobile } = req.body;
    const userId = req.user.userId;

    // ❌ validation
    if (!mobile) {
      return res.status(400).json({
        message: "Mobile number required"
      });
    }

    if (!/^[6-9]\d{9}$/.test(mobile)) {
      return res.status(400).json({
        message: "Invalid mobile number format"
      });
    }

    // ❌ prevent duplicate (excluding current user)
    const exists = await User.findOne({
      mobile,
      _id: { $ne: userId }
    });

    if (exists) {
      return res.status(409).json({
        message: "Mobile number already in use"
      });
    }

    // ✅ update mobile
    const user = await User.findByIdAndUpdate(
      userId,
      { mobile },
      { new: true }
    );

    if (!user) {
      return res.status(404).json({
        message: "User not found"
      });
    }

    return res.json({
      message: "Mobile number updated successfully. Please login again.",
      forceLogout: true
    });

  } catch (err) {
    console.error("UPDATE MOBILE ERROR:", err);
    return res.status(500).json({
      message: "Failed to update mobile number"
    });
  }
};
