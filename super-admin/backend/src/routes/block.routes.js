import express from "express";
import {
    blockUnblockUser,
    toggleSocietyStatus
} from "../controllers/block.controller.js";
import { requireAuth } from "../middlewares/auth.middleware.js";
import { requireSuperAdmin } from "../middlewares/role.middleware.js";

const router = express.Router();

router.patch(
    "/user/:userId",
    requireAuth,
   blockUnblockUser
);

router.patch(
    "/society/:societyId",
    requireAuth,
    requireSuperAdmin,
    toggleSocietyStatus
);

export default router;
