import { Parser } from "json2csv";
import User from "../models/User.js";
import Society from "../models/Society.js";

export const exportUsersCSV = async (req, res) => {
  const { role } = req.query;

  if (!role) {
    return res.status(400).json({ message: "Role is required" });
  }

  const users = await User.find({ roles: role })
    .populate("societyId", "name city")
    .select("name mobile roles status societyId createdAt");

  const data = users.map((u) => ({
    Name: u.name || "",
    Mobile: u.mobile,
    Email:u.email,
    Role: u.roles.join(", "),
    Status: u.status,
    Society: u.societyId?.name || "",
    City: u.societyId?.city || "",
    CreatedAt: u.createdAt
  }));

  const parser = new Parser();
  const csv = parser.parse(data);

  res.header("Content-Type", "text/csv");
  res.attachment(`users-${role}.csv`);
  res.send(csv);
};

export const exportSocietiesCSV = async (req, res) => {
  const societies = await Society.find()
    .select("name city status createdAt");

  const data = societies.map((s) => ({
    Name: s.name,
    City: s.city || "",
    Status: s.status,
    CreatedAt: s.createdAt
  }));

  const parser = new Parser();
  const csv = parser.parse(data);

  res.header("Content-Type", "text/csv");
  res.attachment("societies.csv");
  res.send(csv);
};
