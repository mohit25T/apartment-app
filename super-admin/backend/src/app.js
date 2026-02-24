import express from "express";
import cors from "cors";
import helmet from "helmet";
import morgan from "morgan";
import rateLimit from "express-rate-limit";

import authRoutes from "./routes/auth.routes.js";
import societyRoutes from "./routes/society.routes.js";
import inviteRoutes from "./routes/invite.routes.js";
import analyticsRoutes from "./routes/analytics.routes.js";
import userRoutes from "./routes/user.routes.js";
import blockRoutes from "./routes/block.routes.js";
import searchRoutes from "./routes/search.routes.js";
import exportRoutes from "./routes/export.routes.js";
import adminRoutes from "./routes/admin.routes.js";
import adminReplacementRoutes from "./routes/adminReplacement.routes.js";
import auditLogRoutes from "./routes/auditLog.routes.js";
import visitorRoutes from "./routes/visitor.routes.js";
import updateUserRoutes from "./routes/superAdmin.routes.js";
import notificationRoutes from "./routes/notificationRoutes.js";
import maintenanceRoutes from "./routes/maintenance.routes.js";
import { errorHandler } from "./middlewares/errorHandler.js";

const app = express();
/* =========================================
   REQUIRED ENV VALIDATION
========================================= */
const requiredEnv = [
  "MONGO_URI",
  "JWT_SECRET",
  "BREVO_API_KEY",
  "FIREBASE_SERVICE_ACCOUNT"
];

requiredEnv.forEach((key) => {
  if (!process.env[key]) {
    console.error(`❌ Missing environment variable: ${key}`);
    process.exit(1);
  }
});

/* =========================================
   ENVIRONMENT CHECK
========================================= */
const isProduction = process.env.NODE_ENV === "production";

if (isProduction) {
  app.set("trust proxy", 1); // Required for Render
}

/* =========================================
   SECURITY HEADERS
========================================= */
app.use(helmet());

/* =========================================
   BODY SIZE LIMIT (Prevents payload abuse)
========================================= */
app.use(express.json({ limit: "10kb" }));
app.use(express.urlencoded({ extended: true, limit: "10kb" }));

/* =========================================
   CORS CONFIGURATION
========================================= */
app.use(
  cors({
    origin: [
      "https://web-deploy-j4qo.onrender.com",
      "https://apexitworld.com",
      "http://localhost:3000"
    ],
    methods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
    credentials: true
  })
);

/* =========================================
   RATE LIMITING (GLOBAL)
========================================= */
const globalLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 300,
  standardHeaders: true,
  legacyHeaders: false
});

app.use(globalLimiter);

/* =========================================
   OTP RATE LIMITER (STRICT)
========================================= */
const otpLimiter = rateLimit({
  windowMs: 10 * 60 * 1000,
  max: 10
});

app.use("/api/auth/send-user-otp", otpLimiter);
app.use("/api/auth/verify-user-otp", otpLimiter);

/* =========================================
   LOGGING
========================================= */
if (isProduction) {
  app.use(morgan("combined"));
} else {
  app.use(morgan("dev"));
}

/* =========================================
   HEALTH CHECK ENDPOINT
========================================= */
app.get("/health", (req, res) => {
  res.status(200).json({
    status: "OK",
    uptime: process.uptime(),
    timestamp: Date.now()
  });
});

/* =========================================
   ROUTES (UNCHANGED)
========================================= */
app.use("/api/admin", adminRoutes);
app.use("/api/adminR", adminReplacementRoutes);
app.use("/api/users", userRoutes);
app.use("/api/auth", authRoutes);
app.use("/api/societies", societyRoutes);
app.use("/api/invites", inviteRoutes);
app.use("/api/visitors", visitorRoutes);
app.use("/api/analytics", analyticsRoutes);
app.use("/api/block", blockRoutes);
app.use("/api/search", searchRoutes);
app.use("/api/export", exportRoutes);
app.use("/api/audit-logs", auditLogRoutes);
app.use("/api/user", updateUserRoutes);
app.use("/api/notifications", notificationRoutes);
app.use("/api/maintenance", maintenanceRoutes);

/* =========================================
   GLOBAL ERROR HANDLER
========================================= */
app.use(errorHandler);

export default app;