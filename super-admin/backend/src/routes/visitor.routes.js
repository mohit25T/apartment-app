import express from "express";
import {
    createVisitorEntry,
    approveVisitor,
    rejectVisitor,
    markVisitorEntered,
    markVisitorExited,
    getVisitors,
    getSocietyFlats,
    createPreApprovedGuest,
    verifyGuestOtp,
    allowOtpGuestEntry
} from "../controllers/visitor.controller.js";

import { requireAuth } from "../middlewares/auth.middleware.js";

import {
    requireGuard,
    requireResident,
} from "../middlewares/role.middleware.js";

const router = express.Router();

/**
 * =========================
 * 👮 GUARD ROUTES
 * =========================
 */

// Guard creates visitor entry
router.post(
    "/create",
    requireAuth,
    requireGuard,
    createVisitorEntry
);

// Guard allows entry
router.put(
    "/enter/:id",
    requireAuth,
    requireGuard,
    markVisitorEntered
);

// Guard marks exit
router.put(
    "/exit/:id",
    requireAuth,
    requireGuard,
    markVisitorExited
);


/**
 * =========================
 * 🧍 RESIDENT ROUTES
 * =========================
 */

// Resident approves visitor
router.put(
    "/approve/:id",
    requireAuth,
    requireResident,
    approveVisitor
);

// Resident rejects visitor
router.put(
    "/reject/:id",
    requireAuth,
    requireResident,
    rejectVisitor
);


/**
 * =========================
 * 🏢 ADMIN / COMMON ROUTES
 * =========================
 */

// Admin / Secretary / Super Admin can view logs
router.get(
    "/",
    requireAuth,
    requireResident, 
    getVisitors
);

// Get flats list (for guard)
router.get(
    "/flats",
    requireAuth,
    requireGuard,
    getSocietyFlats
);

// resident
router.post(
    "/preapprove",
    requireAuth,
    requireResident,
    createPreApprovedGuest
);

// guard
router.post(
    "/verify-otp",
    requireAuth,
    requireGuard,
    verifyGuestOtp
);

router.put(
    "/otp-enter/:id",
    requireAuth,
    requireGuard,
    allowOtpGuestEntry
);



export default router;
