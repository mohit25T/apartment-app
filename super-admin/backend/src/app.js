import express from "express";
import cors from "cors";
import authRoutes from "./routes/auth.routes.js";
import societyRoutes from "./routes/society.routes.js";
import inviteRoutes from "./routes/invite.routes.js";
import analyticsRoutes from "./routes/analytics.routes.js";
import userRoutes from "./routes/user.routes.js";
import blockRoutes from "./routes/block.routes.js"
import searchRoutes from "./routes/search.routes.js";
import exportRoutes from "./routes/export.routes.js";
import adminRoutes from "./routes/admin.routes.js";
import adminReplacementRoutes from "./routes/adminReplacement.routes.js";
import auditLogRoutes from "./routes/auditLog.routes.js";
import visitorRoutes from "./routes/visitor.routes.js"
import updateUserRoutes from "./routes/superAdmin.routes.js"
import notificationRoutes from "./routes/notificationRoutes.js";

const app = express();

app.use((req, res, next) => {
  console.log("REQ:", req.method, req.url);
  next();
});

app.use(cors());
app.use(express.json());

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



export default app;