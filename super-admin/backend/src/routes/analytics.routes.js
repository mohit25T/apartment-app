import express from "express";
import {
  getOverviewAnalytics,
  getSocietyAnalytics,
  getAdminAnalytics
} from "../controllers/analytics.controller.js";

import { requireAuth } from "../middlewares/auth.middleware.js";
import { requireSuperAdmin } from "../middlewares/role.middleware.js";

const router = express.Router();

router.use(requireAuth, requireSuperAdmin);

router.get("/overview", getOverviewAnalytics);
router.get("/society/:societyId", getSocietyAnalytics);
router.get("/admin/:adminId", getAdminAnalytics);

export default router;
