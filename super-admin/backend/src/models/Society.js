import mongoose from "mongoose";

const societySchema = new mongoose.Schema({
  name: { type: String, required: true },
  city: { type: String },
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
}, { timestamps: true });

export default mongoose.model("Society", societySchema);
