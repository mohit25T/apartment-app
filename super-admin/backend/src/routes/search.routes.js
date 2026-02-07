import express from "express";
import { globalSearch } from "../controllers/search.controller.js";
import { requireAuth } from "../middlewares/auth.middleware.js";
import { requireSuperAdmin } from "../middlewares/role.middleware.js";

const router = express.Router();

router.get(
  "/",
  requireAuth,
  requireSuperAdmin,
  globalSearch
);

export default router;
