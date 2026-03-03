// adminController.js

const Admin = require("../models/Admin");
const Team = require("../models/Team");
const speakeasy = require("speakeasy");
const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");
const { sendTeamCredentialsEmail } = require("../utils/mail");
const { generateQRWithLogo } = require("../utils/qrUtils");



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

    const qrCode = await generateQRWithLogo(secret.otpauth_url);

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

    // ✅ CHECK IF TEAM NAME ALREADY EXISTS
    const existingTeam = await Team.findOne({ teamName });

    if (existingTeam) {
      return res.status(400).json({
        message: "Team with this name already exists"
      });
    }

    // ✅ ENFORCE EMAIL UNIQUENESS
    const emails = members.map(m => m.email).filter(e => e && e.trim() !== "");
    if (emails.length > 0) {
      const existingEmailTeam = await Team.findOne({ "members.email": { $in: emails } });
      if (existingEmailTeam) {
        return res.status(400).json({ message: "One or more email addresses are already registered to a team." });
      }
    }

    const { nanoid } = await import("nanoid");
    const teamId = "ETE-" + nanoid(6);

    const secret = speakeasy.generateSecret({
      length: 20,
      name: `Hackathon-${teamId}`
    });

    const qrCode = await generateQRWithLogo(secret.otpauth_url);

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

    // Send emails asynchronously only to leaders (or all if none marked)
    const leaders = members.filter(m => m.isLeader);
    const recipients = leaders.length > 0 ? leaders : members;
    sendTeamCredentialsEmail(teamName, teamId, qrCode, recipients);

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

// Edit Team Base info
exports.editTeam = async (req, res) => {
  try {
    const { teamId } = req.params;
    const { teamName, members } = req.body;

    if (!teamName || !members || members.length === 0) {
      return res.status(400).json({ message: "Team name and members required" });
    }

    const team = await Team.findOne({ teamId });
    if (!team) return res.status(404).json({ message: "Team not found" });

    // Check name collision
    if (teamName !== team.teamName) {
      const existingTeam = await Team.findOne({ teamName });
      if (existingTeam) {
        return res.status(400).json({ message: "Team with this name already exists" });
      }
    }

    // Check email collision
    const emails = members.map(m => m.email).filter(e => e && e.trim() !== "");
    if (emails.length > 0) {
      const existingEmailTeam = await Team.findOne({
        "members.email": { $in: emails },
        teamId: { $ne: teamId }
      });
      if (existingEmailTeam) {
        return res.status(400).json({ message: "One or more email addresses are already registered to another team." });
      }
    }

    team.teamName = teamName;
    team.members = members;
    await team.save();

    if (req.app.locals.io) {
      req.app.locals.io.emit('team_updated', {
        teamId: team.teamId,
        type: 'members'
      });
    }

    res.json({ message: "Team updated successfully", team });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: "Server error" });
  }
};

// Delete Team
exports.deleteTeam = async (req, res) => {
  try {
    const { teamId } = req.params;

    const team = await Team.findOneAndDelete({ teamId });
    if (!team) return res.status(404).json({ message: "Team not found" });

    if (req.app.locals.io) {
      req.app.locals.io.emit('team_deleted', teamId);
    }

    res.json({ message: "Team deleted successfully" });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: "Server error" });
  }
};