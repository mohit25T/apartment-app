import User from "../models/User.js";
import VisitorLog from "../models/VisitorLog.js";
import cloudinary from "../config/cloudinary.js";

/**
 * ==========================================
 * GET USERS BY ROLE (ADMIN / OWNER / TENANT / GUARD)
 * ==========================================
 */
export const getUsersByRole = async (req, res) => {
  const { role } = req.query;

  if (!role) {
    return res.status(400).json({ message: "Role is required" });
  }

  const users = await User.find({ roles: { $in: [role] } })
    .populate("societyId", "name city _id")
    .select("name email mobile roles status societyId createdAt")
    .sort({ createdAt: -1 });

  res.json(users);
};

/**
 * ==========================
 * GET MY PROFILE
 * ==========================
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

    // ✅ NEW FLAG
    const requiresProfilePhoto = !user.profileImage;

    return res.status(200).json({
      success: true,
      requiresProfilePhoto, // ✅ Added (does not break old frontend)
      user: {
        _id: user._id,
        name: user.name,
        email: user.email,
        mobile: user.mobile,
        roles: user.roles,
        flatNo: user.flatNo,
        status: user.status,
        society: user.societyId,
        invitedBy: user.invitedBy,
        createdAt: user.createdAt,

        // ✅ NEW FIELD
        profileImage: user.profileImage || null
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
 * GET OWNER / TENANT VISITOR HISTORY
 * =================================
 */
export const getResidentVisitorHistory = async (req, res) => {
  try {
    const { userId, societyId, roles } = req.user;

    // ✅ OWNER or TENANT allowed
    if (
      !roles ||
      (!roles.includes("OWNER") && !roles.includes("TENANT"))
    ) {
      return res.status(403).json({
        success: false,
        message: "Access denied. Flat members only."
      });
    }

    if (!userId || !societyId) {
      return res.status(403).json({
        success: false,
        message: "User not linked to society"
      });
    }

    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const skip = (page - 1) * limit;

    const filter = {
      residentId: userId,
      societyId
    };

    const totalVisitors = await VisitorLog.countDocuments(filter);

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
    console.error("Visitor History Error:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to fetch visitor history"
    });
  }
};


/**
 * =================================
 * GET USERS BY SOCIETY
 * =================================
 */
export const getUsersBySociety = async (req, res) => {
  try {
    const societyId = req.user.societyId;
    const { role } = req.query;

    if (!societyId) {
      return res.status(400).json({
        message: "societyId is required"
      });
    }

    const filter = { societyId };

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

/**
 * =================================
 * UPLOAD PROFILE PHOTO
 * =================================
 */
export const uploadProfilePhoto = async (req, res) => {
  try {
    const userId = req.user.userId;

    if (!req.file) {
      return res.status(400).json({
        success: false,
        message: "Image file is required"
      });
    }

    // 🔥 Upload to Cloudinary
    const result = await cloudinary.uploader.upload(req.file.path, {
      folder: "apartment_app/profile_photos",
      width: 500,
      crop: "scale"
    });

    const user = await User.findByIdAndUpdate(
      userId,
      {
        profileImage: result.secure_url,
        isProfileComplete: true
      },
      { new: true }
    );

    return res.status(200).json({
      success: true,
      message: "Profile photo uploaded successfully",
      profileImage: user.profileImage
    });

  } catch (error) {
    console.error("UPLOAD PROFILE PHOTO ERROR:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to upload profile photo"
    });
  }
};