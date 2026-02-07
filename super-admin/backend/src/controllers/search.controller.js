import User from "../models/User.js";
import Society from "../models/Society.js";

export const globalSearch = async (req, res) => {
  const { q } = req.query;

  if (!q || q.trim().length < 2) {
    return res.json({ users: [], societies: [] });
  }

  const regex = new RegExp(q, "i");

  const [users, societies] = await Promise.all([
    User.find({
      $or: [
        { name: regex },
        { mobile: regex },
        { email: regex }          // ✅ ADDED
      ]
    })
      .select("name email mobile roles status societyId") // ✅ ADDED
      .populate("societyId", "name city")
      .limit(10),

    Society.find({
      $or: [
        { name: regex },
        { city: regex }
      ]
    })
      .select("name city status")
      .limit(10)
  ]);

  res.json({ users, societies });
};
