import 'package:get/get.dart';
import 'app_routes.dart';

// Import bindings and views as you create them
import '../../modules/admin/books/bindings/books_binding.dart';
import '../../modules/admin/books/views/books_view.dart';
import '../../modules/admin/attendance/bindings/attendance_binding.dart';
import '../../modules/admin/attendance/views/attendance_view.dart';
import '../../modules/admin/logout/bindings/logout_binding.dart';
import '../../modules/admin/logout/views/logout_view.dart';
import '../../modules/admin/routine/bindings/routine_binding.dart';
import '../../modules/admin/routine/views/routine_view.dart';
import '../../modules/admin/splash_content/bindings/splash_content_binding.dart';
import '../../modules/admin/splash_content/views/splash_content_view.dart';
import '../../modules/admin/groups/bindings/groups_binding.dart';
import '../../modules/admin/groups/views/groups_view.dart';
import '../../modules/admin/dashboard/bindings/dashboard_binding.dart' as admin_dashboard;
import '../../modules/admin/dashboard/views/dashboard_view.dart' as admin_dashboard;
import '../../modules/admin/reports/bindings/reports_binding.dart';
import '../../modules/admin/reports/views/reports_view.dart';
import '../../modules/superadmin/users/bindings/users_binding.dart' as superadmin_users;
import '../../modules/superadmin/users/views/users_view.dart' as superadmin_users;
import '../../modules/superadmin/meetings/bindings/meetings_binding.dart' as superadmin_meetings;
import '../../modules/superadmin/meetings/views/meetings_view.dart' as superadmin_meetings;
import '../../modules/superadmin/profile/bindings/profile_binding.dart' as superadmin_profile;
import '../../modules/superadmin/profile/views/profile_view.dart' as superadmin_profile;
import '../../modules/member/books/bindings/books_binding.dart' as member_books;
import '../../modules/member/books/views/books_view.dart' as member_books;
import '../../modules/member/routine/bindings/routine_binding.dart' as member_routine;
import '../../modules/member/routine/views/routine_view.dart' as member_routine;
import '../../modules/member/groups/bindings/groups_binding.dart' as member_groups;
import '../../modules/member/groups/views/groups_view.dart' as member_groups;
import '../../modules/member/prayer/bindings/prayer_binding.dart';
import '../../modules/member/prayer/views/prayer_view.dart';
import '../../modules/member/activity/bindings/activity_binding.dart';
import '../../modules/member/activity/views/activity_view.dart';
import '../../modules/member/profile/bindings/profile_binding.dart';
import '../../modules/member/profile/views/profile_view.dart';
import '../../modules/member/tasks/bindings/tasks_binding.dart';
import '../../modules/member/tasks/views/tasks_view.dart';
import '../../modules/member/dashboard/bindings/dashboard_binding.dart' as member_dashboard;
import '../../modules/member/dashboard/views/dashboard_view.dart' as member_dashboard;
import '../../modules/member/donations/bindings/donations_binding.dart';
import '../../modules/member/donations/views/donations_view.dart';

// TODO: Import other module bindings and views as you migrate them

class AppPages {
  static final routes = [
    // Admin Books Module (Example - WORKING!)
    GetPage(
      name: Routes.adminBooks,
      page: () => const BooksView(),
      binding: BooksBinding(),
    ),
    
    // Admin Attendance Module (WORKING!)
    GetPage(
      name: Routes.adminAttendance,
      page: () => const AttendanceView(),
      binding: AttendanceBinding(),
    ),
    
    // Admin Logout Module (WORKING!)
    GetPage(
      name: Routes.adminLogout,
      page: () => const LogoutView(),
      binding: LogoutBinding(),
    ),
    
    // Admin Routine Module (WORKING!)
    GetPage(
      name: Routes.adminRoutine,
      page: () => const RoutineView(),
      binding: RoutineBinding(),
    ),
    
    // Admin Splash Content Module (WORKING!)
    GetPage(
      name: Routes.adminSplashContent,
      page: () => const SplashContentView(),
      binding: SplashContentBinding(),
    ),
    
    // Admin Groups Module (WORKING!)
    GetPage(
      name: Routes.adminGroups,
      page: () => const GroupsView(),
      binding: GroupsBinding(),
    ),
    
    // Admin Dashboard Module (WORKING!)
    GetPage(
      name: Routes.adminDashboard,
      page: () => const admin_dashboard.DashboardView(),
      binding: admin_dashboard.DashboardBinding(),
    ),
    
    // Admin Reports Module (WORKING! - FINAL ADMIN MODULE!)
    GetPage(
      name: Routes.adminReports,
      page: () => const ReportsView(),
      binding: ReportsBinding(),
    ),
    
    // Superadmin Users Module (WORKING!)
    GetPage(
      name: Routes.superadminUsers,
      page: () => const superadmin_users.UsersView(),
      binding: superadmin_users.UsersBinding(),
    ),
    
    // Superadmin Meetings Module (WORKING!)
    GetPage(
      name: Routes.superadminMeetings,
      page: () => const superadmin_meetings.MeetingsView(),
      binding: superadmin_meetings.MeetingsBinding(),
    ),
    
    // Superadmin Profile Module (WORKING! - FINAL MODULE! 100% COMPLETE!)
    GetPage(
      name: Routes.superadminProfile,
      page: () => const superadmin_profile.ProfileView(),
      binding: superadmin_profile.ProfileBinding(),
    ),
    
    // Member Books Module (WORKING! - Reuses admin repository)
    GetPage(
      name: Routes.memberBooks,
      page: () => const member_books.BooksView(),
      binding: member_books.BooksBinding(),
    ),
    
    // Member Routine Module (WORKING! - Reuses admin repository)
    GetPage(
      name: Routes.memberRoutine,
      page: () => const member_routine.RoutineView(),
      binding: member_routine.RoutineBinding(),
    ),
    
    // Member Groups Module (WORKING! - Reuses admin repository)
    GetPage(
      name: Routes.memberGroups,
      page: () => const member_groups.GroupsView(),
      binding: member_groups.GroupsBinding(),
    ),
    
    // Member Prayer Module (WORKING!)
    GetPage(
      name: Routes.memberPrayer,
      page: () => const PrayerView(),
      binding: PrayerBinding(),
    ),
    
    // Member Activity Module (WORKING!)
    GetPage(
      name: Routes.memberActivities,
      page: () => const ActivityView(),
      binding: ActivityBinding(),
    ),
    
    // Member Profile Module (WORKING!)
    GetPage(
      name: Routes.memberProfile,
      page: () => const ProfileView(),
      binding: ProfileBinding(),
    ),
    
    // Member Tasks Module (WORKING!)
    GetPage(
      name: Routes.memberTasks,
      page: () => const TasksView(),
      binding: TasksBinding(),
    ),
    
    // Member Dashboard Module (WORKING!)
    GetPage(
      name: Routes.memberDashboard,
      page: () => const member_dashboard.DashboardView(),
      binding: member_dashboard.DashboardBinding(),
    ),
    
    // Member Donations Module (WORKING! - FINAL MEMBER MODULE!)
    GetPage(
      name: Routes.memberDonations,
      page: () => const DonationsView(),
      binding: DonationsBinding(),
    ),
    
    // TODO: Add other routes as you create modules
    // Example:
    // GetPage(
    //   name: Routes.adminAttendance,
    //   page: () => const AttendanceView(),
    //   binding: AttendanceBinding(),
    // ),
  ];
}
