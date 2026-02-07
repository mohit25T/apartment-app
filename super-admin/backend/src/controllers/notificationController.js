import { sendPushNotification } from "../services/notificationService.js";

export async function sendNotification(req, res) {
  try {
    const { token, title, body, data } = req.body;

    if (!token || !title || !body) {
      return res.status(400).json({
        success: false,
        message: "token, title, and body are required",
      });
    }

    await sendPushNotification(token, title, body, data);

    res.status(200).json({
      success: true,
      message: "Notification sent successfully",
    });
  } catch (error) {
    console.error("Notification Error:", error);

    res.status(500).json({
      success: false,
      message: "Failed to send notification",
      error: error.message,
    });
  }
}
