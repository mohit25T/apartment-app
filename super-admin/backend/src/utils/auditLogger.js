import AuditLog from "../models/AuditLog.js";

/**
 * SAFE AUDIT LOGGER
 * - Works with and without auth middleware
 * - Never crashes login
 */
export const auditLogger = async ({
  req,
  action,
  targetType,
  targetId = null,
  societyId = null,
  description = ""
}) => {
  try {
    // 🛑 Never log audit-log routes
    if (req?.originalUrl?.startsWith("/api/audit-logs")) {
      return;
    }

    const performedBy = req?.user?.userId || null;
    const performedByRole = req?.user?.role || "SELF";

    await AuditLog.create({
      action,
      performedBy,
      performedByRole,
      targetType,
      targetId,
      societyId,
      description,
      ip: req.ip,
      userAgent: req.headers["user-agent"]
    });
  } catch (err) {
    console.error("Audit log error:", err.message);
  }
};
