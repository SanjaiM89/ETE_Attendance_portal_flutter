// teamRoutes.js
const express = require("express");
const { teamLogin, dashboard } = require("../controllers/teamController");
const { authenticate } = require("../middleware/authMiddleware");
const { authorize } = require("../middleware/roleMiddleware");

const router = express.Router();

router.post("/login", teamLogin);
router.get("/dashboard", authenticate, authorize(["team"]), dashboard);

module.exports = router;