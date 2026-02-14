import express from "express";
import { replaceAdmin } from "../controllers/adminReplacement.controller.js";
import { requireAuth } from "../middlewares/auth.middleware.js";
import { requireSuperAdmin } from "../middlewares/role.middleware.js";

const router = express.Router();

router.post(
  "/replace/:oldAdminId",
  requireAuth,
  requireSuperAdmin,
  replaceAdmin
);

export default router;
