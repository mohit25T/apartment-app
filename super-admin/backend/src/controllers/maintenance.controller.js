import Maintenance from "../models/maintenance.js";
import User from "../models/User.js";
import {
    sendPushNotification,
    sendPushNotificationToMany
} from "../services/notificationService.js";

// 🔹 Admin generates bills for all residents
export const generateMonthlyBills = async (req, res) => {
    try {
        const { month, amount, dueDate } = req.body;

        if (!month || !amount || !dueDate) {
            return res.status(400).json({
                message: "Month, amount and dueDate are required",
            });
        }

        const residents = await User.find({
            societyId: req.user.societyId,
            roles: "RESIDENT",
        });

        if (!residents.length) {
            return res.status(400).json({
                message: "No residents found",
            });
        }

        const existingBills = await Maintenance.findOne({
            societyId: req.user.societyId,
            month,
        });

        if (existingBills) {
            return res.status(400).json({
                message: "Maintenance already generated for this month",
            });
        }

        const bills = residents
            .filter((r) => r.flatNo)
            .map((resident) => ({
                societyId: req.user.societyId,
                residentId: resident._id,
                flatNumber: resident.flatNo,
                month,
                amount,
                dueDate,
                status: "Pending",
            }));

        if (!bills.length) {
            return res.status(400).json({
                message: "Residents missing flat numbers",
            });
        }

        await Maintenance.insertMany(bills);

        // 🔔 Notify all residents
        for (const resident of residents) {
            if (resident.fcmToken) {
                await sendPushNotification(
                    resident.fcmToken,
                    "New Maintenance Bill 🧾",
                    `Maintenance for ${month} has been generated`,
                    {
                        type: "MAINTENANCE_GENERATED",
                        month,
                    }
                );
            }
        }

        return res.status(201).json({
            message: "Maintenance bills generated successfully",
        });

    } catch (error) {
        console.error("Generate Maintenance Error:", error);
        return res.status(500).json({
            message: "Something went wrong while generating bills",
        });
    }
};


// 🔹 Resident gets own bills (Paginated)
export const getResidentBills = async (req, res) => {
    try {
        const page = parseInt(req.query.page) || 1;
        const limit = parseInt(req.query.limit) || 20;
        const skip = (page - 1) * limit;

        const query = {
            residentId: req.user.userId,
        };

        const total = await Maintenance.countDocuments(query);

        const bills = await Maintenance.find(query)
            .sort({ createdAt: -1 })
            .skip(skip)
            .limit(limit);

        res.json({
            data: bills,
            currentPage: page,
            totalPages: Math.ceil(total / limit),
            hasMore: page * limit < total,
        });

    } catch (error) {
        console.error("Get Resident Bills Error:", error);
        res.status(500).json({ message: error.message });
    }
};


// 🔹 Resident/Admin marks bill as paid
export const markBillAsPaid = async (req, res) => {
    try {
        const bill = await Maintenance.findById(req.params.id)
            .populate("residentId");

        if (!bill) {
            return res.status(404).json({ message: "Bill not found" });
        }

        bill.status = "Paid";
        await bill.save();

        // 🔔 Notify resident
        if (bill.residentId?.fcmToken) {
            await sendPushNotification(
                bill.residentId.fcmToken,
                "Payment Confirmed ✅",
                `Your maintenance payment for ${bill.month} has been confirmed`,
                {
                    type: "MAINTENANCE_PAID",
                    billId: bill._id.toString(),
                }
            );
        }

        res.json({
            message: "Bill marked as paid successfully",
        });

    } catch (error) {
        console.error("Mark Bill Paid Error:", error);
        res.status(500).json({ message: error.message });
    }
};


// 🔹 Admin views all society bills (Paginated)
export const getAllSocietyBills = async (req, res) => {
    try {
        const page = parseInt(req.query.page) || 1;
        const limit = parseInt(req.query.limit) || 20;
        const skip = (page - 1) * limit;

        const query = {
            societyId: req.user.societyId,
        };
        const total = await Maintenance.countDocuments(query);

        const bills = await Maintenance.find(query)
            .populate("residentId", "name flatNo")
            .sort({ createdAt: -1 })
            .skip(skip)
            .limit(limit);

        console.log("Fetched society bills:", bills);
        res.json({
            data: bills,
            currentPage: page,
            totalPages: Math.ceil(total / limit),
            hasMore: page * limit < total,
        });

    } catch (error) {
        console.error("Error fetching society bills:", error);
        res.status(500).json({ message: error.message });
    }
};
