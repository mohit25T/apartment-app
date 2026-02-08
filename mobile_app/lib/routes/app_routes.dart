import 'package:flutter/material.dart';
import '../auth/login_screen.dart';
import '../auth/auth_check_screen.dart';
import '../auth/otp_screen.dart';
import '../admin/admin_dashboard.dart';
import '../admin/invite_residant.dart';
import '../admin/invite_guard.dart';
import '../admin/society_residents_guards_screen.dart';
import '../profile/change_email_screen.dart';
import '../profile/change_mobile_screen.dart';
import '../resident/resident_dashboard.dart';
import '../guard/guard_dashboard.dart';
import '../guard/visitor_screen.dart';
import '../guard/delivery_entry_screen.dart';
import '../guard/new_visitor_screen.dart';
import '../guard/guests_otp_screen.dart';
import '../resident/preapproved_guest_screen.dart';
import '../resident/resident_visitor_history_screen.dart';
import '../resident/pending_visitors_screen.dart';
import '../profile/profile_screen.dart';
import '../admin/society_visitor_log_screen.dart';

final Map<String, WidgetBuilder> appRoutes = {
  '/': (context) => const AuthCheckScreen(),
  '/login': (context) => const LoginScreen(),
  '/otp': (context) => const OtpScreen(),
  '/guard': (context) => const GuardDashboard(),
  '/resident': (context) => const ResidentDashboard(),
  '/admin': (context) => const AdminDashboard(),
  '/invite-resident': (context) => const InviteResidentScreen(),
  '/invite-guard': (context) => const InviteGuardScreen(),
  '/visitor-entry': (context) => const NewVisitorScreen(),
  '/delivery-entry': (context) => const DeliveryEntryScreen(),
  '/visitors': (context) => const ResidentVisitorsScreen(),
  '/resident-visitors': (context) => const ResidentPendingVisitorsScreen(),
  '/preapproved-guest': (context) => const PreApprovedGuestScreen(),
  '/guest-otp': (context) => const GuestOtpScreen(),
  '/profile': (context) => const ProfileScreen(),
  '/society-visitors': (context) => const SocietyVisitorLogsScreen(),
  '/resident-visitor-history': (context) =>
      const ResidentVisitorHistoryScreen(),
  '/change-email': (context) => const ChangeEmailScreen(),
  '/change-mobile': (context) => const ChangeMobileScreen(),
  '/society-users': (context) => const SocietyUsersScreen(),
};
