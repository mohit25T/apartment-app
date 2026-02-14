import express from "express";
import {
  exportUsersCSV,
  exportSocietiesCSV
} from "../controllers/export.controller.js";
import { requireAuth } from "../middlewares/auth.middleware.js";
import { requireSuperAdmin } from "../middlewares/role.middleware.js";

const router = express.Router();

router.get(
  "/users",
  requireAuth,
  requireSuperAdmin,
  exportUsersCSV
);

router.get(
  "/societies",
  requireAuth,
  requireSuperAdmin,
  exportSocietiesCSV
);

export default router;
