import mongoose from "mongoose";

const userSchema = new mongoose.Schema(
  {
    name: String,

    mobile: {
      type: String,
      unique: true,
      required: true
    },

    email: {
      type: String,
      required: true,
      unique: true,
      lowercase: true,
      trim: true
    },

    roles: {
      type: [String],
      enum: [
        "SUPER_ADMIN",
        "ADMIN",
        "OWNER",
        "TENANT",
        "GUARD"
      ],
      required: true
    },

    societyId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Society"
    },

    invitedBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User"
    },

    status: {
      type: String,
      enum: ["ACTIVE", "BLOCKED", "PENDING_VERIFICATION"],
      default: "ACTIVE"
    },

    profileImage: {
      type: String,
      default: null
    },

    isProfileComplete: {
      type: Boolean,
      default: false
    },

    flatNo: {
      type: String,
      required: function () {
        return (
          this.roles?.includes("OWNER") ||
          this.roles?.includes("TENANT")
        );
      }
    },

    fcmTokens: {
      type: [String],
      default: []
    },

    fcmUpdatedAt: {
      type: Date,
      default: null
    }
  },
  { timestamps: true }
);

/* =====================================================
   🔥 PRODUCTION OPTIMIZED INDEXES
===================================================== */

// For society-based queries
userSchema.index({ societyId: 1 });

// For role filtering inside society
userSchema.index({ societyId: 1, roles: 1 });

// For flat owner lookup
userSchema.index({ societyId: 1, flatNo: 1 });

// For invited user tracking
userSchema.index({ invitedBy: 1 });

// For status filtering
userSchema.index({ societyId: 1, status: 1 });

// For role-only filtering (admin dashboard)
userSchema.index({ roles: 1 });

export default mongoose.model("User", userSchema);