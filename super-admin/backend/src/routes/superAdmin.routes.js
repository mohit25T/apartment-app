import express from "express";
import { updateMyMobile } from "../controllers/superAdmin.controller.js";
import { requireAuth } from "../middlewares/auth.middleware.js";

const router = express.Router();

router.put(
  "/mobile",
  requireAuth,
  updateMyMobile
);

export default router;
