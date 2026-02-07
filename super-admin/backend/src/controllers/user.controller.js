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
    const residentId = req.user.userId;
    const societyId = req.user.societyId;

    if (!residentId || !societyId) {
      return res.status(403).json({
        success: false,
        message: "Resident not linked to society"
      });
    }

    const visitors = await VisitorLog.find({
      residentId: residentId,
      societyId: societyId
    })
      .populate("guardId", "name")
      .sort({ createdAt: -1 });

    return res.status(200).json({
      success: true,
      totalVisitors: visitors.length,
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
    console.log(societyId)
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

    console.log(users)
    return res.json(users);
  } catch (error) {
    console.error("GET USERS BY SOCIETY ERROR:", error);
    return res.status(500).json({
      message: "Failed to fetch users"
    });
  }
};