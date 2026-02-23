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
      enum: ["SUPER_ADMIN", "ADMIN", "RESIDENT", "GUARD"],
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

    flatNo: {
      type: String,
      required: function () {
        return this.roles?.includes("RESIDENT");
      }
    },

    /**
     * 🔔 FCM TOKENS (NEW – MULTI DEVICE SUPPORT)
     * Each login device adds its token here
     */
    fcmTokens: {
      type: [String],
      default: []
    },

    /**
     * 🕒 Last time FCM token was updated
     */
    fcmUpdatedAt: {
      type: Date,
      default: null
    }
  },
  { timestamps: true }
);

export default mongoose.model("User", userSchema);
