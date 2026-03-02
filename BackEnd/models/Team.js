const mongoose = require("mongoose");

const memberSchema = new mongoose.Schema({
  name: String,
  email: String,
  attendance: {
    round1: { type: Boolean, default: false },
    round2: { type: Boolean, default: false },
    round3: { type: Boolean, default: false }
  },
  signatures: {
    round1: String, // base64 image
    round2: String,
    round3: String
  }
});

const teamSchema = new mongoose.Schema(
  {
    teamId: { type: String, unique: true },
    teamName: { type: String, required: true, unique: true },
    members: [memberSchema],

    judgingStatus: {
      round1: { type: String, default: "Pending" },
      round2: { type: String, default: "Pending" },
      round3: { type: String, default: "Pending" }
    },

    totpSecret: String,
    role: { type: String, default: "team" }
  },
  { timestamps: true }
);

module.exports = mongoose.model("Team", teamSchema);