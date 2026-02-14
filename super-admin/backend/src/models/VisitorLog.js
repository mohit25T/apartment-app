import mongoose from "mongoose";

const visitorLogSchema = new mongoose.Schema(
  {
    societyId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Society",
      required: true,
      index: true
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

    // 🏠 Flat info (VERY IMPORTANT)
    flatNo: {
      type: String,
      required: true,
      index: true
    },

    // 👮 Guard who created entry
    guardId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: false
    },

    // 🧍 Resident of that flat
    residentId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true
    },

    // ✅ Who approved/rejected
    approvedBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User"
    },

    // 🔁 Visitor flow
    status: {
      type: String,
      enum: [
        "PENDING",     // waiting for resident
        "APPROVED",    // approved by resident
        "REJECTED",    // rejected by resident
        "ENTERED",     // guard allowed entry
        "EXITED"       // visitor left
      ],
      default: "PENDING",
      index: true
    },

    checkInAt: {
      type: Date
    },

    checkOutAt: {
      type: Date
    },

    entryType: {
      type: String,
      enum: ["VISITOR", "DELIVERY", "EMERGENCY", "GUEST"],
      default: "VISITOR",
      index: true
    },

    deliveryCompany: {
      type: String
    },

    parcelType: {
      type: String // Box / Food / Document
    },

    otp: {
      type: String
    },

    otpStatus: {
      type: String,
      enum: ["ACTIVE", "USED", "EXPIRED"],
      default: "ACTIVE"
    },

    otpExpiresAt: {
      type: Date
    },

    createdByResident: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User"
    }

  },
  { timestamps: true }
);

/* 🔥 Indexes for performance */
visitorLogSchema.index({ societyId: 1, createdAt: -1 });
visitorLogSchema.index({ flatNo: 1 });
visitorLogSchema.index({ guardId: 1 });
visitorLogSchema.index({ residentId: 1 });
visitorLogSchema.index({ status: 1 });

export default mongoose.model("VisitorLog", visitorLogSchema);
