import admin from "../config/firebase.js";

export async function sendPushNotification(
  token,
  title,
  body,
  data = {}
) {
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
