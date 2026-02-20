import User from "../models/User.js";
import VisitorLog from "../models/VisitorLog.js";

/**
 * ==========================================
 * GET USERS BY ROLE (ADMIN / RESIDENT / GUARD)
 * ==========================================
 * ✅ Email INCLUDED (for admin panels & export)
 */
export const getUsersByRole = async (req, res) => {
  const { role } = req.query;

  if (!role) {
    return res.status(400).json({ message: "Role is required" });
  }

  const users = await User.find({ roles: { $in: [role] } })
    .populate("societyId", "name city _id")
    .select("name email mobile roles status societyId createdAt") // ✅ email added
    .sort({ createdAt: -1 });

  res.json(users);
};

/**
 * ==========================
 * GET MY PROFILE
 * ==========================
 * ✅ Email REQUIRED (profile + change email flow)
 */
export const getMyProfile = async (req, res) => {
  try {
    const userId = req.user.userId;

    const user = await User.findById(userId)
      .populate("societyId", "name")
      .populate("invitedBy", "name mobile")
      .select("-__v");

    if (!user) {
      return res.status(404).json({
        success: false,
        message: "User not found"
      });
    }

    return res.status(200).json({
      success: true,
      user: {
        _id: user._id,
        name: user.name,
        email: user.email,            // ✅ ADDED
        mobile: user.mobile,
        roles: user.roles,
        flatNo: user.flatNo,
        status: user.status,
        society: user.societyId,
        invitedBy: user.invitedBy,
        createdAt: user.createdAt
      }
    });

  } catch (error) {
    console.error("Profile Error:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to fetch profile"
    });
  }
};

/**
 * =================================
 * GET RESIDENT VISITOR HISTORY
 * =================================
 * ❌ Email NOT REQUIRED here
 */
export const getResidentVisitorHistory = async (req, res) => {
  try {
    const { userId, societyId, roles } = req.user;

    // ===============================
    // 🔐 Role check (RESIDENT required)
    // ===============================
    if (!roles || !roles.includes("RESIDENT")) {
      return res.status(403).json({
        success: false,
        message: "Access denied. Residents only."
      });
    }

    if (!userId || !societyId) {
      return res.status(403).json({
        success: false,
        message: "Resident not linked to society"
      });
    }

    // 🔹 Pagination Params
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const skip = (page - 1) * limit;

    // 🔹 Base filter (ONLY resident’s visitors)
    const filter = {
      residentId: userId,
      societyId
    };

    // 🔹 Total count
    const totalVisitors = await VisitorLog.countDocuments(filter);

    // 🔹 Fetch paginated data
    const visitors = await VisitorLog.find(filter)
      .populate("guardId", "name")
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit);

    return res.status(200).json({
      success: true,
      totalVisitors,
      currentPage: page,
      totalPages: Math.ceil(totalVisitors / limit),
      hasMore: page * limit < totalVisitors,
      visitors
    });

  } catch (error) {
    console.error("Resident Visitor History Error:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to fetch visitor history"
    });
  }
};


export const getUsersBySociety = async (req, res) => {
  try {

    const societyId = req.user.societyId;
    const { role } = req.query;
    if (!societyId) {
      return res.status(400).json({
        message: "societyId is required"
      });
    }

    const filter = {
      societyId
    };

    if (role) {
      filter.roles = { $in: [role] };
    }

    const users = await User.find(filter)
      .populate("societyId", "name city _id")
      .select("name email mobile roles status societyId createdAt")
      .sort({ createdAt: -1 });

    return res.json(users);
  } catch (error) {
    console.error("GET USERS BY SOCIETY ERROR:", error);
    return res.status(500).json({
      message: "Failed to fetch users"
    });
  }
};
