import express from "express";
import AuditLog from "../models/AuditLog.js";
import { requireAuth } from "../middlewares/auth.middleware.js";
import { requireSuperAdmin } from "../middlewares/role.middleware.js";

const router = express.Router();

router.get(
  "/",
  requireAuth,
  requireSuperAdmin,
  async (req, res) => {
    const logs = await AuditLog.find()
      .sort({ createdAt: -1 });

    res.json(logs);
  }
);

export default router;
