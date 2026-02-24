import mongoose from "mongoose";

const visitorLogSchema = new mongoose.Schema(
  {
    societyId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Society",
      required: true
    },

    visitorPhoto: {
      type: String,
      default: null
    },

    // 🔹 Visitor info
    personName: {
      type: String,
      required: true
    },

    personMobile: {
      type: String
    },

    purpose: {
      type: String,
    },

    vehicleNo: {
      type: String
    },

    // 🏠 Flat info
    flatNo: {
      type: String,
      required: true
    },

    // 👮 Guard
    guardId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User"
    },

    // 🧍 Resident
    residentId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true
    },

    approvedBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User"
    },

    // 🔁 Visitor flow
    status: {
      type: String,
      enum: [
        "PENDING",
        "APPROVED",
        "REJECTED",
        "ENTERED",
        "EXITED"
      ],
      default: "PENDING"
    },

    checkInAt: Date,
    checkOutAt: Date,

    entryType: {
      type: String,
      enum: ["VISITOR", "DELIVERY", "EMERGENCY", "GUEST"],
      default: "VISITOR"
    },

    deliveryCompany: String,
    parcelType: String,

    otp: String,

    otpStatus: {
      type: String,
      enum: ["ACTIVE", "USED", "EXPIRED"],
      default: "ACTIVE"
    },

    otpExpiresAt: Date,

    createdByResident: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User"
    }

  },
  { timestamps: true }
);

/* =====================================================
   🔥 PRODUCTION OPTIMIZED INDEXES
===================================================== */

// For main society visitor listing (pagination)
visitorLogSchema.index({ societyId: 1, createdAt: -1 });

// For status filtering inside society
visitorLogSchema.index({ societyId: 1, status: 1 });

// For resident-specific history
visitorLogSchema.index({ residentId: 1, createdAt: -1 });

// For guard-specific logs
visitorLogSchema.index({ guardId: 1, createdAt: -1 });

// For flat-based search
visitorLogSchema.index({ societyId: 1, flatNo: 1 });

// For entry type filtering
visitorLogSchema.index({ societyId: 1, entryType: 1 });

// For OTP lookup
visitorLogSchema.index({ otp: 1, otpStatus: 1 });

export default mongoose.model("VisitorLog", visitorLogSchema);