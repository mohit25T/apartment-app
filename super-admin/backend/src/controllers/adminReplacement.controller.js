import User from "../models/User.js";
import { auditLogger } from "../utils/auditLogger.js";

/**
 * REPLACE ADMIN (PROMOTE EXISTING RESIDENT)
 * Only Super Admin
 *
 * Logic:
 * - Admin and Secretary are same person
 * - Admin lives in a flat
 * - Flat number is already stored in DB
 * - We fetch resident using mobile number
 * - FlatNo is NOT taken from request
 */
export const replaceAdmin = async (req, res) => {
  try {
    const { oldAdminId } = req.params;
    const { mobile } = req.body;

    if (!mobile) {
      return res.status(400).json({
        message: "Resident mobile number is required"
      });
    }

    // 1️⃣ Find old admin
    const oldAdmin = await User.findOne({
      _id: oldAdminId,
      roles: "ADMIN"
    });

    if (!oldAdmin) {
      return res.status(404).json({
        message: "Old admin not found"
      });
    }

    // 2️⃣ Find resident using mobile number
    const resident = await User.findOne({
      mobile,
      societyId: oldAdmin.societyId,
      roles: "RESIDENT",
      status: "ACTIVE"
    });

    if (!resident) {
      return res.status(400).json({
        message: "Resident not found in this society"
      });
    }

    // 🔒 Safety check
    if (!resident.flatNo) {
      return res.status(400).json({
        message: "Resident flat number not found"
      });
    }

    /* ====================================================
       🔁 ROLE SWITCH LOGIC
    ==================================================== */

    // ⛔ Remove ADMIN role from old admin
    oldAdmin.roles = oldAdmin.roles.filter(
      role => role !== "ADMIN"
    );

    // Ensure RESIDENT role still exists
    if (!oldAdmin.roles.includes("RESIDENT")) {
      oldAdmin.roles.push("RESIDENT");
    }

    await oldAdmin.save();

    // ✅ Promote resident → ADMIN + RESIDENT
    resident.roles = Array.from(
      new Set([...resident.roles, "ADMIN"])
    );

    await resident.save();

    /* ====================================================
       ✅ AUDIT LOG
    ==================================================== */
    await auditLogger({
      req,
      action: "REPLACE_ADMIN",
      targetType: "USER",
      targetId: resident._id,
      societyId: oldAdmin.societyId,
      description: `Admin replaced: ${oldAdmin.name} → ${resident.name} | Flat ${resident.flatNo}`
    });

    res.json({
      message: "Admin replaced successfully",
      oldAdmin: {
        id: oldAdmin._id,
        roles: oldAdmin.roles
      },
      newAdmin: {
        id: resident._id,
        roles: resident.roles,
        flatNo: resident.flatNo
      }
    });

  } catch (err) {
    console.error("REPLACE ADMIN ERROR:", err);
    res.status(500).json({
      message: "Failed to replace admin"
    });
  }
};
