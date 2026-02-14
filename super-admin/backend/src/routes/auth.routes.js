import express from "express";
import { getMe, sendOtp, sendOtpUser, verifyOtpLogin, verifyUserLogin,logoutUser, requestEmailChange, verifyEmailChange } from "../controllers/auth.controller.js";
import { requireAuth } from "../middlewares/auth.middleware.js"

const router = express.Router();
router.get("/me", requireAuth, getMe);

router.post("/send-otp", sendOtp);
router.post("/send-user-otp", sendOtpUser);
router.post("/verify-otp", verifyOtpLogin);
router.post("/verify-user-otp", verifyUserLogin);
router.post("/logout", requireAuth, logoutUser);


/**
 * 🔐 REQUEST EMAIL CHANGE
 * Sends OTP to OLD email
 * Auth required
 */
router.post("/request-email-change", requireAuth, requestEmailChange);

/**
 * 🔐 VERIFY EMAIL CHANGE
 * Verifies OTP and updates email
 * Auth required
 */
router.post("/verify-email-change", requireAuth, verifyEmailChange);


export default router;
