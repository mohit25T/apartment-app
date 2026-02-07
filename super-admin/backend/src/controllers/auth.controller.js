import Invite from "../models/Invite.js";
import User from "../models/User.js";
import EmailChangeRequest from "../models/EmailChangeRequest.js";
import { signToken } from "../utils/jwt.js";
import { saveOtp, verifyOtp } from "../utils/otpStore.js";
import { generateOtp } from "../utils/generateOtp.js";
import { auditLogger } from "../utils/auditLogger.js";
import { sendOtpEmail } from "../utils/sendOtpEmail.js"; // ✅ NEW

/**
 * SEND OTP
 * Allowed only for:
 * 1. Super Admin
 * 2. Valid Admin Invite
 */
export const sendOtp = async (req, res) => {
  try {
    const { mobile } = req.body;

    if (!mobile) {
      return res.status(400).json({ message: "Mobile number required" });
    }

    const superAdmin = await User.findOne({
      mobile,
      roles: "SUPER_ADMIN"
    });

    const adminInvite = await Invite.findOne({
      mobile,
      role: "ADMIN",
      expiresAt: { $gt: new Date() }
    });

    if (!superAdmin && !adminInvite) {
      return res.status(403).json({
        message: "Not allowed to request OTP"
      });
    }

    const email = superAdmin?.email || adminInvite?.email;
    if (!email) {
      return res.status(400).json({
        message: "Email not found for OTP"
      });
    }

    const otp = generateOtp();

    saveOtp({
      mobile,
      email,
      otp
    });

    // ✅ SEND OTP TO EMAIL
    await sendOtpEmail(email, otp);

    console.log(`OTP sent to ${email} (mobile: ${mobile})`);

    res.json({ message: "OTP sent successfully to email" });
  } catch (err) {
    console.error("SEND OTP ERROR:", err);
    res.status(500).json({ message: "Failed to send OTP" });
  }
};

export const sendOtpUser = async (req, res) => {
  try {
    const { mobile } = req.body;

    if (!mobile) {
      return res.status(400).json({
        message: "Mobile number required"
      });
    }

    const user = await User.findOne({ mobile });

    // ❌ block super admin here
    if (user?.roles.includes("SUPER_ADMIN")) {
      return res.status(403).json({
        message: "Super admin login not allowed in mobile app"
      });
    }

    const invite = await Invite.findOne({
      mobile,
      role: { $in: ["ADMIN", "RESIDENT", "GUARD"] },
      status: "PENDING",
      expiresAt: { $gt: new Date() }
    });

    if (!user && !invite) {
      return res.status(403).json({
        message: "You are not invited to any society"
      });
    }

    const email = user?.email || invite?.email;
    if (!email) {
      return res.status(400).json({
        message: "Email not found for OTP"
      });
    }

    const otp = generateOtp();

    saveOtp({
      mobile,
      email,
      otp
    });

    // ✅ SEND OTP TO EMAIL
    await sendOtpEmail(email, otp);

    console.log(`USER OTP sent to ${email} (mobile: ${mobile})`);

    res.json({
      message: "OTP sent successfully to email",
      role: invite?.role || user.roles[0]
    });
  } catch (err) {
    console.error("SEND USER OTP ERROR:", err);
    res.status(500).json({
      message: "Failed to send OTP"
    });
  }
};

/**
 * VERIFY OTP — SUPER ADMIN LOGIN
 */
export const verifyOtpLogin = async (req, res) => {
  try {
    const { mobile, otp } = req.body;

    const user = await User.findOne({
      mobile,
      roles: "SUPER_ADMIN"
    });

    if (!user) {
      return res.status(404).json({ message: "Super Admin not found" });
    }

    if (user.status === "BLOCKED") {
      return res.status(403).json({
        message: "Account is blocked"
      });
    }

    const isValid = verifyOtp({
      mobile,
      email: user.email,
      otp
    });

    if (!isValid) {
      return res.status(401).json({ message: "Invalid OTP" });
    }

    const token = signToken({
      userId: user._id,
      role: "SUPER_ADMIN"
    });

    res.json({ token });
  } catch (err) {
    console.error("VERIFY SUPER ADMIN ERROR:", err);
    res.status(500).json({ message: "Login failed" });
  }
};

/**
 * VERIFY OTP — ADMIN / RESIDENT / GUARD
 * 🔐 AUDIT LOG ENABLED
 */
export const verifyUserLogin = async (req, res) => {
  try {
    const { mobile, otp } = req.body;

    let user = await User.findOne({ mobile });
    let invite = null;

    if (!user) {
      invite = await Invite.findOne({
        mobile,
        role: { $in: ["ADMIN", "RESIDENT", "GUARD"] },
        status: "PENDING",
        expiresAt: { $gt: new Date() }
      });
    }

    const email = user?.email || invite?.email;
    if (!email) {
      return res.status(400).json({
        message: "Email not found for OTP verification"
      });
    }

    const isValid = verifyOtp({
      mobile,
      email,
      otp
    });

    if (!isValid) {
      return res.status(401).json({ message: "Invalid OTP" });
    }

    // Existing user
    if (user) {
      const token = signToken({
        userId: user._id,
        roles: user.roles,
        societyId: user.societyId
      });

      return res.json({
        token,
        roles: user.roles,
        societyId: user.societyId
      });
    }

    // Create user from invite
    if (!invite) {
      return res.status(403).json({
        message: "You are not invited to any society"
      });
    }

    const roles = [invite.role];
    if (invite.role === "ADMIN") {
      roles.push("RESIDENT");
    }

    user = await User.create({
      name: invite.name,
      mobile,
      email,
      roles,
      flatNo: invite.flatNo,
      societyId: invite.societyId,
      invitedBy: invite.invitedBy,
      status: "ACTIVE"
    });

    invite.status = "USED";
    await invite.save();

    await auditLogger({
      req,
      action: "USER_VERIFIED",
      targetType: "USER",
      targetId: user._id,
      societyId: user.societyId,
      description: `${invite.role} verified via OTP: ${user.name} (${user.mobile})`
    });

    const token = signToken({
      userId: user._id,
      roles: user.roles,
      societyId: user.societyId
    });

    return res.json({
      token,
      roles: user.roles,
      societyId: user.societyId
    });

  } catch (err) {
    console.error("VERIFY USER LOGIN ERROR:", err);
    res.status(500).json({ message: "Login failed" });
  }
};


export const requestEmailChange = async (req, res) => {
  try {
    const userId = req.user.userId;
    const { newEmail } = req.body;

    if (!newEmail) {
      return res.status(400).json({ message: "New email is required" });
    }

    const user = await User.findById(userId);
    if (!user || !user.email) {
      return res.status(404).json({ message: "User not found" });
    }

    // ❌ same email
    if (user.email === newEmail.toLowerCase()) {
      return res.status(400).json({ message: "New email must be different" });
    }

    // ❌ email already in use
    const emailExists = await User.findOne({ email: newEmail.toLowerCase() });
    if (emailExists) {
      return res.status(409).json({ message: "Email already in use" });
    }

    // 🔁 remove old request if exists
    await EmailChangeRequest.deleteOne({ userId });

    const otp = generateOtp();

    const expiresAt = new Date(Date.now() + 5 * 60 * 1000); // 5 min

    await EmailChangeRequest.create({
      userId,
      oldEmail: user.email,
      newEmail,
      otp,
      expiresAt
    });

    // 🔐 SEND OTP TO OLD EMAIL
    await sendOtpEmail(user.email, otp);

    res.json({
      message: "OTP sent to your current email for verification"
    });

  } catch (err) {
    console.error("REQUEST EMAIL CHANGE ERROR:", err);
    res.status(500).json({ message: "Failed to request email change" });
  }
};


export const verifyEmailChange = async (req, res) => {
  try {
    const userId = req.user.userId;
    const { otp } = req.body;

    if (!otp) {
      return res.status(400).json({ message: "OTP is required" });
    }

    const request = await EmailChangeRequest.findOne({ userId });

    if (!request) {
      return res.status(404).json({ message: "No email change request found" });
    }

    if (Date.now() > request.expiresAt) {
      await request.deleteOne();
      return res.status(400).json({ message: "OTP expired" });
    }

    if (request.otp !== otp) {
      return res.status(401).json({ message: "Invalid OTP" });
    }

    // ✅ UPDATE EMAIL
    const user = await User.findById(userId);
    user.email = request.newEmail;
    await user.save();

    await request.deleteOne();

    await auditLogger({
      req,
      action: "CHANGE_EMAIL",
      targetType: "USER",
      targetId: userId,
      // description: "Admin email changed after OTP verification"
    });


    res.json({
      message: "Email updated successfully"
    });

  } catch (err) {
    console.error("VERIFY EMAIL CHANGE ERROR:", err);
    res.status(500).json({ message: "Failed to verify email change" });
  }
};


export const getMe = async (req, res) => {
  try {
    const user = await User.findById(req.user.userId)
      .select("name email mobile roles");

    if (!user) {
      return res.status(404).json({ message: "User not found" });
    }

    res.json(user);
  } catch (err) {
    res.status(500).json({ message: "Failed to fetch profile" });
  }
};
