import api from "./axios";

/**
 * 🔐 STEP 1
 * Request email change
 * Sends OTP to OLD email
 */
export const requestEmailChange = ({ oldEmail, newEmail }) => {
    return api.post("/auth/request-email-change", {
        oldEmail,
        newEmail,
    });
};

/**
 * 🔐 STEP 2
 * Verify OTP and update email
 */
export const verifyEmailChange = ({ otp }) => {
    return api.post("/auth/verify-email-change", {
        otp,
    });
};
