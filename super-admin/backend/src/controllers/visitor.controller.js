import VisitorLog from "../models/VisitorLog.js";
import User from "../models/User.js";
import { sendPushNotification } from "../services/notificationService.js";

/**
 * ===============================
 * 1️⃣ Guard creates visitor entry
 * ===============================
 */
export const createVisitorEntry = async (req, res) => {
  try {
    const {
      personName,
      personMobile,
      purpose,
      vehicleNo,
      flatNo,
      entryType,
      deliveryCompany,
      parcelType
    } = req.body;

    const societyId = req.user.societyId;
    const guardId = req.user.userId;

    const resident = await User.findOne({
      societyId,
      flatNo,
      roles: { $in: ["RESIDENT"] }
    });

    if (!resident) {
      return res.status(404).json({
        message: "Resident not found for this flat"
      });
    }

    const visitor = await VisitorLog.create({
      societyId,
      personName,
      personMobile,
      purpose,
      vehicleNo,
      flatNo,
      entryType,
      deliveryCompany,
      parcelType,
      guardId,
      residentId: resident._id,
      status: "PENDING"
    });

    // 🔔 Visitor Arrived → Resident
    if (resident.fcmToken) {
      await sendPushNotification(
        resident.fcmToken,
        "Visitor Arrived 🚪",
        `${personName} is waiting at the gate for Flat ${flatNo}`,
        { type: "VISITOR_ARRIVED", visitorId: visitor._id.toString() }
      );
    }

    res.status(201).json({
      message: "Visitor entry created successfully",
      visitor
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: "Server error" });
  }
};



/**
 * =================================
 * 2️⃣ Resident approves visitor
 * =================================
 */
export const approveVisitor = async (req, res) => {
  try {
    const { id } = req.params;

    const visitor = await VisitorLog.findById(id);

    if (!visitor)
      return res.status(404).json({ message: "Visitor not found" });

    if (visitor.status !== "PENDING") {
      return res.status(400).json({
        message: "Visitor already processed"
      });
    }

    if (visitor.residentId.toString() !== req.user.userId.toString()) {
      return res.status(403).json({ message: "Unauthorized" });
    }

    visitor.status = "APPROVED";
    visitor.approvedBy = req.user.userId;

    await visitor.save();

    res.json({
      message: "Visitor approved",
      visitor
    });
  } catch (error) {
    res.status(500).json({ message: "Server error" });
  }
};



/**
 * =================================
 * 3️⃣ Resident rejects visitor
 * =================================
 */
export const rejectVisitor = async (req, res) => {
  try {
    const { id } = req.params;

    const visitor = await VisitorLog.findById(id);

    if (!visitor)
      return res.status(404).json({ message: "Visitor not found" });

    if (visitor.status !== "PENDING") {
      return res.status(400).json({
        message: "Visitor already processed"
      });
    }

    if (visitor.residentId.toString() !== req.user.userId.toString()) {
      return res.status(403).json({ message: "Unauthorized" });
    }

    visitor.status = "REJECTED";
    visitor.approvedBy = req.user.userId;

    await visitor.save();

    res.json({
      message: "Visitor rejected",
      visitor
    });
  } catch (error) {
    res.status(500).json({ message: "Server error" });
  }
};



/**
 * ===============================
 * 4️⃣ Guard allows entry
 * ===============================
 */
export const markVisitorEntered = async (req, res) => {
  try {
    const { id } = req.params;

    const visitor = await VisitorLog.findById(id).populate("residentId");

    if (!visitor)
      return res.status(404).json({ message: "Visitor not found" });

    if (visitor.status !== "APPROVED") {
      return res.status(400).json({
        message: "Visitor not approved yet"
      });
    }

    visitor.status = "ENTERED";
    visitor.checkInAt = new Date();

    await visitor.save();

    // 🔔 Visitor Entered → Resident
    if (visitor.residentId?.fcmToken) {
      await sendPushNotification(
        visitor.residentId.fcmToken,
        "Visitor Entered ✅",
        `${visitor.personName} has entered the society`,
        { type: "VISITOR_ENTERED", visitorId: visitor._id.toString() }
      );
    }

    res.json({
      message: "Visitor entered successfully",
      visitor
    });
  } catch (error) {
    res.status(500).json({ message: "Server error" });
  }
};



/**
 * ===============================
 * 5️⃣ Guard marks exit
 * ===============================
 */
export const markVisitorExited = async (req, res) => {
  try {
    const { id } = req.params;

    const visitor = await VisitorLog.findById(id).populate("residentId");

    if (!visitor)
      return res.status(404).json({ message: "Visitor not found" });

    if (visitor.status !== "ENTERED") {
      return res.status(400).json({
        message: "Visitor has not entered yet"
      });
    }

    visitor.status = "EXITED";
    visitor.checkOutAt = new Date();

    await visitor.save();

    // 🔔 Visitor Exited → Resident
    if (visitor.residentId?.fcmToken) {
      await sendPushNotification(
        visitor.residentId.fcmToken,
        "Visitor Exited 🚶",
        `${visitor.personName} has exited the society`,
        { type: "VISITOR_EXITED", visitorId: visitor._id.toString() }
      );
    }

    res.json({
      message: "Visitor exited successfully",
      visitor
    });
  } catch (error) {
    res.status(500).json({ message: "Server error" });
  }
};



/**
 * ===============================
 * 6️⃣ Get visitors (common)
 * ===============================
 */
export const getVisitors = async (req, res) => {
  try {
    const { status } = req.query;
    const societyId = req.user.societyId;

    const filter = { societyId };
    if (status) filter.status = status;

    const visitors = await VisitorLog.find(filter)
      .populate("guardId", "name mobile")
      .populate("residentId", "name flatNo")
      .sort({ createdAt: -1 });

    res.json(visitors);
  } catch (error) {
    res.status(500).json({ message: "Server error" });
  }
};



/**
 * ===============================
 * 7️⃣ Get society flats
 * ===============================
 */
export const getSocietyFlats = async (req, res) => {
  try {
    const societyId = req.user.societyId;

    const residents = await User.find(
      {
        societyId,
        roles: { $in: ["RESIDENT"] }
      },
      {
        flatNo: 1,
        name: 1
      }
    ).sort({ flatNo: 1 });

    const flats = residents
      .filter((r) => r.flatNo)
      .map((r) => ({
        flatNo: r.flatNo,
        residentName: r.name
      }));

    res.json(flats);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: "Failed to fetch flats" });
  }
};



/**
 * =================================
 * 8️⃣ Resident creates pre-approved guest
 * =================================
 */
export const createPreApprovedGuest = async (req, res) => {
  try {
    const { guestName, guestMobile } = req.body;

    if (!guestName || !guestMobile) {
      return res.status(400).json({
        message: "Guest name and mobile required"
      });
    }

    const resident = await User.findById(req.user.userId);

    const otp = Math.floor(100000 + Math.random() * 900000).toString();

    const visitor = await VisitorLog.create({
      societyId: resident.societyId,
      residentId: resident._id,
      flatNo: resident.flatNo,
      personName: guestName,
      personMobile: guestMobile,
      entryType: "GUEST",
      otp,
      otpStatus: "ACTIVE",
      otpExpiresAt: new Date(Date.now() + 12 * 60 * 60 * 1000),
      createdByResident: resident._id,
      status: "APPROVED"
    });

    res.status(201).json({
      message: "Guest pre-approved successfully",
      otp,
      visitorId: visitor._id
    });
  } catch (error) {
    res.status(500).json({ message: "Server error" });
  }
};



/**
 * ===============================
 * 9️⃣ Verify guest OTP
 * ===============================
 */
export const verifyGuestOtp = async (req, res) => {
  try {
    const { otp } = req.body;

    const visitor = await VisitorLog.findOne({
      otp,
      otpStatus: "ACTIVE",
      status: "APPROVED"
    }).populate("residentId");

    if (!visitor) {
      return res.status(400).json({
        message: "Invalid or expired OTP"
      });
    }

    if (visitor.otpExpiresAt < new Date()) {
      visitor.otpStatus = "EXPIRED";
      await visitor.save();
      return res.status(400).json({
        message: "OTP expired"
      });
    }

    // 🔔 OTP verified → Resident
    if (visitor.residentId?.fcmToken) {
      await sendPushNotification(
        visitor.residentId.fcmToken,
        "Guest Arrived 🚪",
        `${visitor.personName} has verified OTP at the gate`,
        { type: "OTP_VERIFIED", visitorId: visitor._id.toString() }
      );
    }

    res.json({
      message: "OTP verified",
      visitor: {
        id: visitor._id,
        guestName: visitor.personName,
        flatNo: visitor.flatNo,
        residentName: visitor.residentId.name
      }
    });
  } catch (error) {
    res.status(500).json({ message: "Server error" });
  }
};



/**
 * ===============================
 * 🔟 Guard allows OTP guest entry
 * ===============================
 */
export const allowOtpGuestEntry = async (req, res) => {
  try {
    const { id } = req.params;

    const visitor = await VisitorLog.findById(id).populate("residentId");

    if (!visitor) {
      return res.status(404).json({ message: "Guest not found" });
    }

    if (visitor.otpStatus !== "ACTIVE" || visitor.status !== "APPROVED") {
      return res.status(400).json({
        message: "Guest OTP not verified or already entered"
      });
    }

    visitor.status = "ENTERED";
    visitor.otpStatus = "USED";
    visitor.checkInAt = new Date();

    await visitor.save();

    // 🔔 OTP Guest Entered → Resident
    if (visitor.residentId?.fcmToken) {
      await sendPushNotification(
        visitor.residentId.fcmToken,
        "Guest Entered 🚪",
        `${visitor.personName} has entered the society`,
        { type: "OTP_GUEST_ENTERED", visitorId: visitor._id.toString() }
      );
    }

    res.json({
      message: "Guest entered successfully"
    });
  } catch (error) {
    res.status(500).json({ message: "Server error" });
  }
};
