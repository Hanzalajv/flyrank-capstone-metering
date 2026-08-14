
const express = require("express");
const cors = require("cors");
const pool = require("./db/database");

const app = express();

app.use(cors());
app.use(express.json());

app.get("/", (req, res) => {
  res.json({
    message: "FlyRank Usage Metering & Billing API",
    status: "running"
  });
});

app.get("/health/db", async (req, res) => {
  try {
    const result = await pool.query("SELECT NOW()");

    res.json({
      database: "connected",
      time: result.rows[0].now
    });
  } catch (error) {
    console.error(error);

    res.status(500).json({
      database: "disconnected"
    });
  }
});

module.exports = app;