import nodemailer from "nodemailer";
import "dotenv/config";

const transporter = nodemailer.createTransport({
  host: process.env.EMAIL_HOST,
  port: Number(process.env.EMAIL_PORT),
  secure: false, // MUST be false for 587
  auth: {
    user: process.env.EMAIL_USER,
    pass: process.env.EMAIL_PASS
  }
});

const sendTestEmail = async () => {
  try {
    const info = await transporter.sendMail({
      from: `"Apex IT Solutions" <${process.env.EMAIL_USER}>`,
      to: process.env.EMAIL_USER, // send to yourself
      subject: "✅ Nodemailer Test Successful",
      text: "If you received this email, Nodemailer is working perfectly."
    });

    console.log("✅ Email sent successfully");
    console.log("Message ID:", info.messageId);
  } catch (err) {
    console.error("❌ Email failed");
    console.error(err);
  }
};

sendTestEmail();
