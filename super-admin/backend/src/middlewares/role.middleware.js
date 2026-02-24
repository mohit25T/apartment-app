export const requireSuperAdmin = (req, res, next) => {
  if (!req.user.roles || !req.user.roles.includes("SUPER_ADMIN")) {
    return res.status(403).json({ message: "Super admin access required" });
  }
  next();
};


export const requireAdmin = (req, res, next) => {
  if (!req.user.roles || !req.user.roles.includes("ADMIN")) {
    return res.status(403).json({ message: "Admin access required" });
  }
  next();
};


/**
 * ⚠️ Name kept same to avoid breaking routes
 * Now allows OWNER + TENANT
 */
export const requireResident = (req, res, next) => {
  if (
    !req.user.roles ||
    (
      !req.user.roles.includes("OWNER") &&
      !req.user.roles.includes("TENANT")
    )
  ) {
    return res.status(403).json({
      message: "Flat member access required"
    });
  }
  next();
};


export const requireGuard = (req, res, next) => {
  if (!req.user.roles || !req.user.roles.includes("GUARD")) {
    return res.status(403).json({ message: "Only guard allowed" });
  }
  next();
};