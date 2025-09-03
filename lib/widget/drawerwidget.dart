import 'package:hpu_eduhust/providers/auth.dart';
import 'package:flutter/material.dart';
import 'package:hpu_eduhust/screens/admincoursescreen.dart';
import 'package:hpu_eduhust/screens/admincreatecoursescreen.dart';
import 'package:hpu_eduhust/screens/giangvienscreens.dart';
import 'package:hpu_eduhust/screens/chatbotscreen.dart';
import 'package:hpu_eduhust/screens/coursescreen.dart';
import 'package:hpu_eduhust/screens/lichgiangdayscreen.dart';
import 'package:hpu_eduhust/screens/profilescreens.dart';
import 'package:hpu_eduhust/screens/schedulescreen.dart';
import 'package:hpu_eduhust/screens/settingscreens.dart';
import 'package:hpu_eduhust/screens/sinhvienscreens.dart';
import 'package:hpu_eduhust/screens/userchatlistscreen.dart';
import 'package:hpu_eduhust/screens/userpostscreens.dart';
import 'package:ionicons/ionicons.dart';
import 'package:hpu_eduhust/components/list_tile.dart';

class Mydrawer extends StatelessWidget {
  final void Function()? onSignoutTap;
  final void Function()? onCreateTap;
  final AppUser user;

  const Mydrawer({
    super.key,
    required this.onSignoutTap,
    required this.onCreateTap,
    required this.user,
  });

  void _navigateToHome(BuildContext context) {
    Navigator.pop(context);
    if (user.isAdmin) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => GVScreenHome(
            giangvien: user,
          ),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => HSScreenHome(
            hocsinh: user,
          ),
        ),
      );
    }
  }

  void _navigateToMyPosts(BuildContext context) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserPostsScreen(
          authorId: user.id!,
          currentUserId: user.id!,
          user: user,
        ),
      ),
    );
  }

  void _navigateToCourseScreen(BuildContext context) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CourseScreen(
          user: user,
        ),
      ),
    );
  }

  void _navigateToScheduleScreens(BuildContext context) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ThoiKhoaBieuScreen(
          sinhVienId: user.id!,
          user: user,
        ),
      ),
    );
  }

  void _navigateToLichGiangDayScreens(BuildContext context) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LichGiangDayScreen(
          giangVienId: user.id!,
          user: user,
        ),
      ),
    );
  }

  void _navigateToProfile(BuildContext context) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Profilescreens(
          user: user,
        ),
      ),
    );
  }

  void _navigateToAdmin(BuildContext context) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminCourseScreen(
          user: user,
        ),
      ),
    );
  }

  void _navigateToSetting(BuildContext context) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Settingscreens(
          user: user,
        ),
      ),
    );
  }

  void _navigateToChatBotScreen(BuildContext context) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatBotScreen(
          user: user,
        ),
      ),
    );
  }

  void _navigateToChatScreen(BuildContext context) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatListScreen(
          user: user,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xff354154),
      child: Column(
        children: [
          // const DrawerHeader(
          //   child: Icon(
          //     Ionicons.apps_outline,
          //     color: Colors.white,
          //     size: 20,
          //   ),
          // ),
          SizedBox(
            height: 50,
          ),
          Icon(
            Ionicons.apps_outline,
            color: Colors.white,
            size: 60,
          ),
          SizedBox(
            height: 20,
          ),
          MyListTile(
            icon: Icons.home,
            onTap: () => _navigateToHome(context),
            title: 'H O M E',
          ),
          if (user.isAdmin)
            MyListTile(
                icon: Icons.create, title: 'C R E A T E', onTap: onCreateTap),
          if (user.isAdmin)
            MyListTile(
              icon: Icons.post_add,
              title: 'M Y  P O S T S',
              onTap: () => _navigateToMyPosts(context),
            ),
          if (user.isAdmin)
            MyListTile(
              icon: Icons.book,
              title: 'C O U R S E',
              onTap: () => _navigateToCourseScreen(context),
            ),
          if (user.isAdmin == false)
            MyListTile(
              icon: Icons.book,
              title: 'C O U R S E',
              onTap: () => _navigateToCourseScreen(context),
            ),
          if (user.isAdmin == false)
            MyListTile(
              icon: Icons.schedule,
              title: 'S C H E D U L E',
              onTap: () => _navigateToScheduleScreens(context),
            ),
          if (user.isAdmin == true)
            MyListTile(
              icon: Icons.schedule,
              title: 'S C H E D U L E',
              onTap: () => _navigateToLichGiangDayScreens(context),
            ),
          MyListTile(
            icon: Icons.person,
            title: 'P R O F I L E',
            onTap: () => _navigateToProfile(context),
          ),
          MyListTile(
            icon: Icons.settings,
            title: 'S E T T I N G',
            onTap: () => _navigateToSetting(context),
          ),
          MyListTile(
            icon: Icons.android,
            title: 'C H A T B O T',
            onTap: () => _navigateToChatBotScreen(context),
          ),
          MyListTile(
            icon: Icons.chat,
            title: 'C H A T',
            onTap: () => _navigateToChatScreen(context),
          ),
          if (user.role == 'admin')
            MyListTile(
              icon: Icons.admin_panel_settings,
              title: 'A D M I N',
              onTap: () => _navigateToAdmin(context),
            ),
          MyListTile(
            icon: Icons.close_rounded,
            onTap: () => Navigator.pop(context),
            title: 'C L O S E',
          ),
          const Spacer(),
          MyListTile(
            icon: Icons.logout,
            title: 'L O G O U T',
            onTap: onSignoutTap,
          ),
          const SizedBox(
            height: 20,
          ),
        ],
      ),
    );
  }
}
