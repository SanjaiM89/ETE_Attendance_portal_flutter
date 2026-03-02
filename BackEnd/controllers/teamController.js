// teamController.js
const Team = require("../models/Team");
const jwt = require("jsonwebtoken");
const speakeasy = require("speakeasy");

// Team Login
exports.teamLogin = async (req, res) => {
  const { teamId, otp } = req.body;

  const team = await Team.findOne({ teamId });
  if (!team) return res.status(400).json({ message: "Team not found" });

  const verified = speakeasy.totp.verify({
    secret: team.totpSecret,
    encoding: "base32",
    token: otp,
    window: 1
  });

  if (!verified) return res.status(400).json({ message: "Invalid OTP" });

  const token = jwt.sign(
    { id: team._id, role: team.role },
    process.env.JWT_SECRET,
    { expiresIn: "6h" }
  );

  res.json({ token });
};

// Team Dashboard
exports.dashboard = async (req, res) => {
  const team = await Team.findById(req.user.id).select("-totpSecret");

  res.json({
    teamName: team.teamName,
    teamId: team.teamId,
    members: team.members.map(m => ({
      name: m.name,
      email: m.email,
      attendance: m.attendance
    })),
    judgingStatus: team.judgingStatus
  });
};