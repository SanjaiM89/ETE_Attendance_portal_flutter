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
  console.log("Body received:", req.body);
  const { email, password } = req.body;

  const admin = await Admin.findOne({ email });
  if (!admin) return res.status(400).json({ message: "Admin not found" });

  const isMatch = await bcrypt.compare(password, admin.password);
  if (!isMatch) return res.status(400).json({ message: "Invalid password" });

  if (!admin.mfaEnabled) {
    const secret = speakeasy.generateSecret({
      length: 20,
      name: `FODSE-Admin-${admin.email}`
    });

    admin.mfaSecret = secret.base32;
    await admin.save();

    const qrCode = await QRCode.toDataURL(secret.otpauth_url);

    return res.json({
      mfaRequired: true,
      isSetup: true,
      qrCode,
      message: "Please scan the QR code with your Authenticator app and enter the code to verify."
    });
  }

  // If MFA is already enabled, just tell them it's required.
  return res.json({
    mfaRequired: true,
    isSetup: false,
    message: "Authenticator code required"
  });
};

// Verify Admin MFA
exports.verifyAdminMfa = async (req, res) => {
  console.log("Verify MFA received body:", req.body);
  const { password, otp } = req.body;
  const email = (req.body.email || "").trim();

  const admin = await Admin.findOne({ email });
  if (!admin) {
    console.log(`Admin not found for email: "${email}"`);
    return res.status(400).json({ message: "Admin not found" });
  }

  const isMatch = await bcrypt.compare(password, admin.password);
  if (!isMatch) return res.status(400).json({ message: "Invalid credentials" });

  const verified = speakeasy.totp.verify({
    secret: admin.mfaSecret,
    encoding: "base32",
    token: otp,
    window: 1
  });

  if (!verified) {
    return res.status(400).json({ message: "Invalid Authenticator Code" });
  }

  if (!admin.mfaEnabled) {
    admin.mfaEnabled = true;
    await admin.save();
  }

  const token = jwt.sign(
    { id: admin._id, role: admin.role },
    process.env.JWT_SECRET,
    { expiresIn: "6h" }
  );

  res.json({ token, message: "Login successful" });
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

    // Broadcast team created event
    if (req.app.locals.io) {
      req.app.locals.io.emit('team_created');
    }

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

  // Broadcast the update
  if (req.app.locals.io) {
    req.app.locals.io.emit('team_updated', {
      teamId: team.teamId,
      type: 'attendance'
    });
  }

  res.json({ message: "Attendance updated successfully" });
};

exports.updateJudging = async (req, res) => {
  const { teamId } = req.params;
  const { round, status } = req.body;

  const team = await Team.findOne({ teamId });
  team.judgingStatus[round] = status;

  await team.save();

  // Broadcast the update
  if (req.app.locals.io) {
    req.app.locals.io.emit('team_updated', {
      teamId: team.teamId,
      type: 'judging'
    });
  }

  res.json({ message: "Judging updated" });
};