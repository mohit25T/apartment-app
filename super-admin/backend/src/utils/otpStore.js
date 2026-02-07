const store = new Map();

/**
 * Save OTP
 * Supports BOTH:
 * 1. Mobile-based OTP (existing)
 * 2. Email-based OTP (new)
 */
export const saveOtp = ({ mobile, email, otp }) => {
  // Store OTP against mobile (existing behavior)
  if (mobile) {
    store.set(`mobile:${mobile}`, {
      otp,
      expiresAt: Date.now() + 5 * 60 * 1000 // 5 min
    });
  }

  // Store OTP against email (new behavior)
  if (email) {
    store.set(`email:${email}`, {
      otp,
      expiresAt: Date.now() + 5 * 60 * 1000 // 5 min
    });
  }
};

/**
 * Verify OTP
 * Tries:
 * 1. Email OTP (preferred)
 * 2. Mobile OTP (fallback / future SMS)
 */
export const verifyOtp = ({ mobile, email, otp }) => {
  // Check email OTP first
  if (email) {
    const emailData = store.get(`email:${email}`);
    if (emailData) {
      if (Date.now() > emailData.expiresAt) return false;
      return emailData.otp === otp;
    }
  }

  // Check mobile OTP (existing behavior)
  if (mobile) {
    const mobileData = store.get(`mobile:${mobile}`);
    if (!mobileData) return false;
    if (Date.now() > mobileData.expiresAt) return false;
    return mobileData.otp === otp;
  }

  return false;
};
