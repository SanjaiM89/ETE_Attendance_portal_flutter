// adminController.js

const Admin = require("../models/Admin");
const Team = require("../models/Team");
const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");
const speakeasy = require("speakeasy");
const QRCode = require("qrcode");
const { nanoid } = require("nanoid");



// Admin Login
exports.adminLogin = async (req, res) => {
  console.log("Body received:",req.body);
  const { email, password } = req.body;

  const admin = await Admin.findOne({ email });
  if (!admin) return res.status(400).json({ message: "Admin not found" });

  const isMatch = await bcrypt.compare(password, admin.password);
  if (!isMatch) return res.status(400).json({ message: "Invalid password" });

  const token = jwt.sign(
    { id: admin._id, role: admin.role },
    process.env.JWT_SECRET,
    { expiresIn: "6h" }
  );

  res.json({ token });
};

// Create Team
exports.createTeam = async (req, res) => {
  try {
    const { teamName, members } = req.body;

    if (!teamName || !members || members.length === 0) {
      return res.status(400).json({ message: "Team name and members required" });
    }

    // ✅ CHECK IF TEAM ALREADY EXISTS
    const existingTeam = await Team.findOne({ teamName });

    if (existingTeam) {
      return res.status(400).json({
        message: "Team with this name already exists"
      });
    }

    const { nanoid } = await import("nanoid");
    const teamId = "ETE-" + nanoid(6);

    const secret = speakeasy.generateSecret({
      length: 20,
      name: `Hackathon-${teamId}`
    });

    const qrCode = await QRCode.toDataURL(secret.otpauth_url);

    const newTeam = await Team.create({
      teamId,
      teamName,
      members,
      totpSecret: secret.base32
    });

    res.json({
      message: "Team created successfully",
      teamId,
      qrCode
    });

  } catch (error) {
    console.error(error);
    res.status(500).json({ message: "Server error" });
  }
};

exports.getAllTeams = async (req, res) => {
  const teams = await Team.find().select("-totpSecret");
  res.json(teams);
};

exports.updateAttendance = async (req, res) => {
  const { teamId } = req.params;
  const { round, members } = req.body;

  const team = await Team.findOne({ teamId });
  if (!team) return res.status(404).json({ message: "Team not found" });

  members.forEach(update => {
    const member = team.members.id(update.memberId);
    if (member) {
      member.attendance[round] = true;
      member.signatures[round] = update.signature;
    }
  });

  await team.save();

  res.json({ message: "Attendance updated successfully" });
};

exports.updateJudging = async (req, res) => {
  const { teamId } = req.params;
  const { round, status } = req.body;

  const team = await Team.findOne({ teamId });
  team.judgingStatus[round] = status;

  await team.save();

  res.json({ message: "Judging updated" });
};