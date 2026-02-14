import mongoose from "mongoose";

const emailChangeRequestSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
      unique: true // one active request per user
    },

    oldEmail: {
      type: String,
      required: true
    },

    newEmail: {
      type: String,
      required: true,
      lowercase: true,
      trim: true
    },

    otp: {
      type: String,
      required: true
    },

    expiresAt: {
      type: Date,
      required: true
    }
  },
  { timestamps: true }
);

export default mongoose.model("EmailChangeRequest", emailChangeRequestSchema);
