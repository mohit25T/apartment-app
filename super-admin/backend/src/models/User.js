import mongoose from "mongoose";

const userSchema = new mongoose.Schema({
  name: String,
  mobile: { type: String, unique: true, required: true },
  email: {
    type: String,
    required: true,
    unique: true,
    lowercase: true,
    trim: true
  },

  roles: {
    type: [String],
    enum: ["SUPER_ADMIN", "ADMIN", "RESIDENT", "GUARD"],
    required: true
  },
  societyId: { type: mongoose.Schema.Types.ObjectId, ref: "Society" },
  invitedBy: { type: mongoose.Schema.Types.ObjectId, ref: "User" },
  status: {
    type: String,
    enum: ["ACTIVE", "BLOCKED", "PENDING_VERIFICATION"],
    default: "ACTIVE"
  },
  flatNo: {
    type: String,
    required: function () { return this.roles?.includes("RESIDENT") }
  }
}, { timestamps: true });

export default mongoose.model("User", userSchema);
