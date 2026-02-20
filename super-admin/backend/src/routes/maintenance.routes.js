import express from "express";
import {
  generateMonthlyBills,
  getResidentBills,
  markBillAsPaid,
  getAllSocietyBills
} from "../controllers/maintenance.controller.js";

import { requireAuth } from "../middlewares/auth.middleware.js";
import { requireAdmin } from "../middlewares/role.middleware.js";

const router = express.Router();

// 🔹 Admin generates monthly bills
router.post(
  "/generate",
  requireAuth,
  requireAdmin,
  generateMonthlyBills
);

// 🔹 Resident views own bills
router.get(
  "/my-bills",
  requireAuth,
  getResidentBills
);

// 🔹 Resident marks bill as paid
router.put(
  "/pay/:id",
  requireAuth,
  markBillAsPaid
);

// 🔹 Admin views all bills in society
router.get(
  "/all",
  requireAuth,
  requireAdmin,
  getAllSocietyBills
);

export default router;
