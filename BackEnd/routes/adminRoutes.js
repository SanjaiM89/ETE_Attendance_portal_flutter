// adminRoutes.js
const express = require("express");
const {
  adminLogin,
  verifyAdminMfa,
  createTeam,
  getAllTeams,
  updateAttendance,
  updateJudging,
  editTeam,
  deleteTeam
} = require("../controllers/adminController");
const { authenticate } = require("../middleware/authMiddleware");
const { authorize } = require("../middleware/roleMiddleware");

const router = express.Router();

router.post("/login", adminLogin);
router.post("/verify-mfa", verifyAdminMfa);
router.post("/create-team", authenticate, authorize(["admin"]), createTeam);
router.get("/teams", authenticate, authorize(["admin"]), getAllTeams);
router.put("/update-attendance/:teamId", authenticate, authorize(["admin"]), updateAttendance);
router.put("/update-judging/:teamId", authenticate, authorize(["admin"]), updateJudging);
router.put("/edit-team/:teamId", authenticate, authorize(["admin"]), editTeam);
router.delete("/delete-team/:teamId", authenticate, authorize(["admin"]), deleteTeam);

module.exports = router;