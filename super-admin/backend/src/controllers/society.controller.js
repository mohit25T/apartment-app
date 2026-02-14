import Society from "../models/Society.js";
import User from "../models/User.js";
import { auditLogger } from "../utils/auditLogger.js"; // ✅ ADDED

/**
 * CREATE SOCIETY
 */
export const createSociety = async (req, res) => {
  const { name, city } = req.body;

  if (!name) {
    return res.status(400).json({ message: "Society name required" });
  }

  const society = await Society.create({
    name,
    city,
    createdBy: req.user.userId
  });

  // ✅ AUDIT LOG — SOCIETY CREATED
  await auditLogger({
    req,
    action: "CREATE_SOCIETY",
    targetType: "SOCIETY",
    targetId: society._id,
    societyId: society._id,
    description: `Society created: "${society.name}"`
  });

  res.status(201).json(society);
};

/**
 * GET ALL SOCIETIES
 */
export const getAllSocieties = async (req, res) => {
  const societies = await Society.find().sort({ createdAt: -1 });
  res.json(societies);
};

/**
 * SOCIETY SUMMARY (FOR DASHBOARD)
 */
export const getSocietySummary = async (req, res) => {
  const { id } = req.params;

  const society = await Society.findById(id);
  if (!society) {
    return res.status(404).json({ message: "Society not found" });
  }

  const admins = await User.countDocuments({
    societyId: id,
    roles: "ADMIN"
  });

  const residents = await User.countDocuments({
    societyId: id,
    roles: "RESIDENT"
  });

  const guards = await User.countDocuments({
    societyId: id,
    roles: "GUARD"
  });

  res.json({
    societyId: id,
    societyName: society.name,
    admins,
    residents,
    guards
  });
};
