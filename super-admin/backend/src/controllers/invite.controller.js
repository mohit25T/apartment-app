import Invite from "../models/Invite.js";
import Society from "../models/Society.js";
import User from "../models/User.js";
import { auditLogger } from "../utils/auditLogger.js";

const INVITE_EXPIRY_HOURS = 24;

/**
 * CREATE ADMIN INVITE
 */
export const inviteAdmin = async (req, res) => {
  const { name, mobile, email, societyId, flatNo } = req.body;

  if (!name || !mobile || !email || !societyId || !flatNo) {
    return res.status(400).json({
      message: "Name, mobile, email, societyId and flat number are required"
    });
  }

  const society = await Society.findById(societyId);
  if (!society) {
    return res.status(404).json({ message: "Society not found" });
  }

  const flatExists = await Invite.findOne({
    societyId,
    flatNo,
    status: { $in: ["PENDING", "USED"] }
  });

  if (flatExists) {
    return res.status(409).json({
      message: `Flat ${flatNo} already assigned`
    });
  }

  const expiresAt = new Date(
    Date.now() + INVITE_EXPIRY_HOURS * 60 * 60 * 1000
  );

  let invite = await Invite.findOne({
    mobile,
    role: "ADMIN",
    societyId
  });

  if (invite && invite.status === "USED") {
    return res.status(409).json({
      message: "Admin already onboarded with this number"
    });
  }

  if (invite) {
    invite.name = name;
    invite.email = email;
    invite.flatNo = flatNo;
    invite.status = "PENDING";
    invite.expiresAt = expiresAt;
    invite.invitedBy = req.user.userId;
    await invite.save();

    await auditLogger({
      req,
      action: "UPDATE_ADMIN_INVITE",
      targetType: "INVITE",
      targetId: invite._id,
      societyId,
      description: `Admin invite updated | Flat ${flatNo}`
    });

    return res.json({
      message: "Existing admin invite updated",
      invite
    });
  }

  invite = await Invite.create({
    name,
    mobile,
    email,
    flatNo,
    role: "ADMIN",
    societyId,
    invitedBy: req.user.userId,
    expiresAt
  });

  await auditLogger({
    req,
    action: "CREATE_ADMIN_INVITE",
    targetType: "INVITE",
    targetId: invite._id,
    societyId,
    description: `Admin invited | Flat ${flatNo}`
  });

  res.status(201).json({
    message: "Admin invite created",
    invite
  });
};

/**
 * GET ALL INVITES
 */
export const getAllInvites = async (req, res) => {
  const invites = await Invite.find()
    .populate("societyId", "name city")
    .sort({ createdAt: -1 });

  res.json(invites);
};

/**
 * RESEND INVITE
 */
export const resendInvite = async (req, res) => {
  const { id } = req.params;

  const invite = await Invite.findById(id);
  if (!invite || invite.status !== "PENDING") {
    return res.status(400).json({ message: "Invite not valid" });
  }

  invite.expiresAt = new Date(
    Date.now() + INVITE_EXPIRY_HOURS * 60 * 60 * 1000
  );
  await invite.save();

  await auditLogger({
    req,
    action: "RESEND_ADMIN_INVITE",
    targetType: "INVITE",
    targetId: invite._id,
    societyId: invite.societyId,
    description: `Invite resent for ${invite.name} (${invite.mobile})`
  });

  res.json({ message: "Invite resent" });
};

/**
 * CANCEL INVITE
 */
export const cancelInvite = async (req, res) => {
  const { id } = req.params;

  const invite = await Invite.findById(id);
  if (!invite || invite.status !== "PENDING") {
    return res.status(400).json({ message: "Invite not valid" });
  }

  invite.status = "EXPIRED";
  await invite.save();

  await auditLogger({
    req,
    action: "CANCEL_ADMIN_INVITE",
    targetType: "INVITE",
    targetId: invite._id,
    societyId: invite.societyId,
    description: `Invite cancelled for ${invite.name} (${invite.mobile})`
  });

  res.json({ message: "Invite cancelled" });
};

/**
 * INVITE RESIDENT
 * (Now supports OWNER or TENANT)
 * API name kept same to avoid breaking frontend
 */
export const inviteResident = async (req, res) => {
  try {
    const { name, mobile, email, flatNo, role } = req.body;

    const userRole = role || "OWNER";

    if (!["OWNER", "TENANT"].includes(userRole)) {
      return res.status(400).json({
        message: "Role must be OWNER or TENANT"
      });
    }

    if (!name || !mobile || !email || !flatNo) {
      return res.status(400).json({
        message: "Name, mobile, email and flat number are required"
      });
    }

    const admin = await User.findById(req.user.userId);
    if (!admin || !admin.societyId) {
      return res.status(403).json({
        message: "Admin society not found"
      });
    }

    const flatExists = await Invite.findOne({
      societyId: admin.societyId,
      flatNo,
      role: { $in: ["OWNER", "TENANT"] },
      status: { $in: ["PENDING", "USED"] }
    });

    if (flatExists) {
      return res.status(409).json({
        message: `Flat ${flatNo} already assigned`
      });
    }

    const expiresAt = new Date(
      Date.now() + INVITE_EXPIRY_HOURS * 60 * 60 * 1000
    );

    let invite = await Invite.findOne({
      mobile,
      role: userRole,
      societyId: admin.societyId
    });

    if (invite?.status === "USED") {
      return res.status(409).json({
        message: `${userRole} already onboarded`
      });
    }

    if (invite) {
      invite.name = name;
      invite.email = email;
      invite.flatNo = flatNo;
      invite.status = "PENDING";
      invite.expiresAt = expiresAt;
      invite.invitedBy = admin._id;
      await invite.save();
    } else {
      invite = await Invite.create({
        name,
        mobile,
        email,
        flatNo,
        role: userRole,
        societyId: admin.societyId,
        invitedBy: admin._id,
        expiresAt
      });
    }

    await auditLogger({
      req,
      action: "INVITE_RESIDENT",
      targetType: "INVITE",
      targetId: invite._id,
      societyId: admin.societyId,
      description: `${userRole} invited: ${name} (${mobile}) | Flat ${flatNo}`
    });

    res.json({
      message: `${userRole} invite sent successfully`,
      invite
    });

  } catch (err) {
    console.error("INVITE RESIDENT ERROR:", err);
    res.status(500).json({
      message: "Failed to invite user"
    });
  }
};

/**
 * INVITE GUARD
 */
export const inviteGuard = async (req, res) => {
  try {
    const { name, mobile, email } = req.body;

    if (!name || !mobile || !email) {
      return res.status(400).json({
        message: "Name, mobile and email are required"
      });
    }

    const admin = await User.findById(req.user.userId);
    if (!admin || !admin.societyId) {
      return res.status(403).json({
        message: "Admin society not found"
      });
    }

    const expiresAt = new Date(
      Date.now() + INVITE_EXPIRY_HOURS * 60 * 60 * 1000
    );

    let invite = await Invite.findOne({
      mobile,
      role: "GUARD",
      societyId: admin.societyId
    });

    if (invite && invite.status === "USED") {
      return res.status(409).json({
        message: "Guard already onboarded"
      });
    }

    if (invite) {
      invite.name = name;
      invite.email = email;
      invite.status = "PENDING";
      invite.expiresAt = expiresAt;
      invite.invitedBy = admin._id;
      await invite.save();
    } else {
      invite = await Invite.create({
        name,
        mobile,
        email,
        role: "GUARD",
        societyId: admin.societyId,
        invitedBy: admin._id,
        expiresAt
      });
    }

    await auditLogger({
      req,
      action: "INVITE_GUARD",
      targetType: "INVITE",
      targetId: invite._id,
      societyId: admin.societyId,
      description: `Guard invited: ${name} (${mobile})`
    });

    res.json({
      message: "Guard invite sent successfully",
      invite
    });
  } catch (err) {
    console.error("INVITE GUARD ERROR:", err);
    res.status(500).json({
      message: "Failed to invite guard"
    });
  }
};