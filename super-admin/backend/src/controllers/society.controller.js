import Society from "../models/Society.js";
import User from "../models/User.js";
import { auditLogger } from "../utils/auditLogger.js";

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
 * SOCIETY SUMMARY (UPDATED FOR OWNER / TENANT)
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

  const owners = await User.countDocuments({
    societyId: id,
    roles: "OWNER"
  });

  const tenants = await User.countDocuments({
    societyId: id,
    roles: "TENANT"
  });

  const guards = await User.countDocuments({
    societyId: id,
    roles: "GUARD"
  });

  res.json({
    societyId: id,
    societyName: society.name,
    admins,
    owners,
    tenants,
    guards
  });
};