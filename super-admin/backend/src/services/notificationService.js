import admin from "../config/firebase.js";

/**
 * =====================================================
 * 🔔 Send notification to a SINGLE device (OLD - KEEP)
 * =====================================================
 * Used for backward compatibility
 */
export async function sendPushNotification(
  token,
  title,
  body,
  data = {}
) {
  if (!token) return;

  const message = {
    token,
    notification: {
      title,
      body,
    },
    data,
  };

  await admin.messaging().send(message);
}

/**
 * =====================================================
 * 🔔 Send notification to MULTIPLE devices (NEW)
 * =====================================================
 * - Supports resident + guard
 * - Supports multiple devices per user
 * - Filters invalid tokens automatically
 */
export async function sendPushNotificationToMany(
  tokens = [],
  title,
  body,
  data = {}
) {
  const uniqueTokens = [...new Set(tokens)].filter(Boolean);

  if (uniqueTokens.length === 0) {
    console.log("⚠️ No valid FCM tokens found");
    return null;
  }

  const message = {
    tokens: uniqueTokens,
    notification: {
      title,
      body,
    },
    data,
  };

  try {
    const response = await admin.messaging().sendEachForMulticast(message);

    console.log("✅ FCM multicast response:", {
      successCount: response.successCount,
      failureCount: response.failureCount,
    });

    // Log failed tokens (very important for debugging)
    if (response.failureCount > 0) {
      response.responses.forEach((resp, idx) => {
        if (!resp.success) {
          console.error(
            "❌ Failed token:",
            uniqueTokens[idx],
            resp.error?.message
          );
        }
      });
    }

    // 🔥 THIS IS THE FIX
    return response;

  } catch (error) {
    console.error("🔥 FCM MULTICAST ERROR:", error);
    throw error;
  }
}