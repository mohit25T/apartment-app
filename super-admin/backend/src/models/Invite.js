import mongoose from "mongoose";

const inviteSchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: true
    },

    mobile: {
      type: String,
      required: true
    },

    email: {
      type: String,
      required: true,
      lowercase: true,
      trim: true
    },

    role: {
      type: String,
      enum: ["ADMIN", "OWNER", "TENANT", "GUARD"],
      required: true
    },

    societyId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Society",
      required: true
    },

    invitedBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true
    },

    flatNo: {
      type: String,
      required: function () {
        return this.role === "OWNER" || this.role === "TENANT";
      }
    },

    status: {
      type: String,
      enum: ["PENDING", "USED", "EXPIRED"],
      default: "PENDING"
    },

    expiresAt: {
      type: Date,
      required: true
    }
  },
  { timestamps: true }
);

/* =====================================================
   🔥 PRODUCTION INDEXES
===================================================== */

// 🔥 CRITICAL — for OTP verification
inviteSchema.index({
  mobile: 1,
  role: 1,
  status: 1,
  expiresAt: 1
});

// For society admin management
inviteSchema.index({ societyId: 1, createdAt: -1 });

// For tracking invites sent by admin
inviteSchema.index({ invitedBy: 1 });

// For cleanup jobs (optional future cron)
inviteSchema.index({ expiresAt: 1 });

export default mongoose.model("Invite", inviteSchema);