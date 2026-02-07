export const requireSuperAdmin = (req, res, next) => {
  if (!req.user.role || req.user.role !== "SUPER_ADMIN") {
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


export const requireResident = (req, res, next) => {
  if (!req.user.roles || !req.user.roles.includes("RESIDENT")) {
    return res.status(403).json({ message: "RESIDENT access required" });
  }
  next();
};

export const requireGuard = (req, res, next) => {
  if (!req.user.roles || !req.user.roles.includes("GUARD")) {
    return res.status(403).json({ message: "Only guard allowed" });
  }
  next();
};
