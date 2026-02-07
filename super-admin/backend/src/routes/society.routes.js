import express from "express";
import {
  createSociety,
  getAllSocieties,
  getSocietySummary
} from "../controllers/society.controller.js";

import { requireAuth } from "../middlewares/auth.middleware.js";
import { requireSuperAdmin } from "../middlewares/role.middleware.js";

const router = express.Router();

router.use(requireAuth, requireSuperAdmin);

router.post("/", createSociety);
router.get("/", getAllSocieties);
router.get("/:id/summary", getSocietySummary);

export default router;
