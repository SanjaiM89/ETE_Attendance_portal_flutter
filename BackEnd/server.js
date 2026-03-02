// server.js
require("dotenv").config();
const express = require("express");
const cors = require("cors");
const connectDB = require("./config/db");

const http = require("http");
const { Server } = require("socket.io");
const rateLimit = require("express-rate-limit");

const app = express();
const server = http.createServer(app);
const io = new Server(server, { cors: { origin: "*" } });

// Attach socket io to locals
app.locals.io = io;

connectDB();

app.use(cors());
app.use(express.json());

// Anti Brute-Force Rate Limiting (50 requests per 1 hour)
const apiLimiter = rateLimit({
  windowMs: 60 * 60 * 1000, // 1 hour
  max: 50, // limit each IP to 50 requests per windowMs
  message: { message: "Too many login attempts from this IP, please try again after an hour" },
  standardHeaders: true,
  legacyHeaders: false,
});
app.use("/api/admin/login", apiLimiter);
app.use("/api/team/login", apiLimiter);

app.use("/api/admin", require("./routes/adminRoutes"));
app.use("/api/team", require("./routes/teamRoutes"));

const PORT = process.env.PORT || 5000;
server.listen(PORT, () => console.log(`Server running on port ${PORT}`));

io.on("connection", (socket) => {
  console.log("Client connected via WebSocket");
  socket.on("disconnect", () => console.log("Client disconnected"));
});