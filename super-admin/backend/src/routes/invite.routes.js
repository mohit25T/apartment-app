import express from "express";
import {
  inviteAdmin,
  getAllInvites,
  resendInvite,
  cancelInvite,
  inviteResident,
  inviteGuard
} from "../controllers/invite.controller.js";

import { requireAuth } from "../middlewares/auth.middleware.js";
import { requireSuperAdmin, requireAdmin } from "../middlewares/role.middleware.js";

const router = express.Router();

// router.use(requireAuth, requireSuperAdmin);

router.get("/", requireAuth, requireSuperAdmin, getAllInvites);
router.post("/admin", requireAuth, requireSuperAdmin, inviteAdmin);
router.post("/:id/resend", requireAuth, requireSuperAdmin, resendInvite);
router.post("/:id/cancel", requireAuth, requireSuperAdmin, cancelInvite);
router.post("/invite-resident", requireAuth, requireAdmin, inviteResident);
router.post("/invite-guard", requireAuth, requireAdmin, inviteGuard);

export default router;
