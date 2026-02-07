import mongoose from "mongoose";

const auditLogSchema = new mongoose.Schema({
  actorId: { type: mongoose.Schema.Types.ObjectId, ref: "User" },
  actorRole: String,
  action: String,
  targetType: String,
  targetId: mongoose.Schema.Types.ObjectId,
  societyId: mongoose.Schema.Types.ObjectId,
  metadata: Object,
  createdAt: { type: Date, default: Date.now }
});

export default mongoose.model("AuditLog", auditLogSchema);
