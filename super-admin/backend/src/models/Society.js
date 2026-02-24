import mongoose from "mongoose";

const societySchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: true
    },

    city: {
      type: String
    },

    createdBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true
    },

    status: {
      type: String,
      enum: ["ACTIVE", "BLOCKED"],
      default: "ACTIVE"
    }
  },
  { timestamps: true }
);

/* =====================================================
   🔥 PRODUCTION INDEXES
===================================================== */

// 🔥 For dashboard active societies count
societySchema.index({ status: 1 });

// 🔥 For filtering societies created by Super Admin
societySchema.index({ createdBy: 1 });

// 🔥 Optional (if future search by city)
societySchema.index({ city: 1 });

// 🔥 Optional (if you add society name search later)
societySchema.index({ name: 1 });

export default mongoose.model("Society", societySchema);