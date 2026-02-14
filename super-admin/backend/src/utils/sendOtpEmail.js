import axios from "axios";
import "dotenv/config";

export const sendOtpEmail = async (toEmail, otp) => {
  if (!toEmail) {
    throw new Error("Email is required to send OTP");
  }

  try {
    await axios.post(
      "https://api.brevo.com/v3/smtp/email",
      {
        sender: {
          name: "Apartment App",
          email: process.env.EMAIL_USER
        },
        to: [
          {
            email: toEmail
          }
        ],
        subject: "Your OTP Code",
        htmlContent: `
          <div style="font-family: Arial; padding: 20px;">
            <h2>OTP Verification</h2>
            <p>Your OTP is:</p>
            <h1 style="letter-spacing: 3px;">${otp}</h1>
            <p>This OTP is valid for <b>5 minutes</b>.</p>
            <p>If you did not request this, please ignore.</p>
          </div>
        `
      },
      {
        headers: {
          "api-key": process.env.BREVO_API_KEY,
          "Content-Type": "application/json"
        }
      }
    );
  } catch (error) {
    console.error(
      "Brevo email error:",
      error?.response?.data || error.message
    );
    throw new Error("Failed to send OTP email");
  }
};
