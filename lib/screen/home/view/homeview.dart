import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:walleta/screen/home/view/daily_view.dart';
import 'package:walleta/screen/home/view/monthly_view.dart';
import 'package:walleta/screen/home/view/weekly_view.dart';
import 'package:walleta/screen/profile/view/notification_view.dart';
import 'package:walleta/screen/profile/viewmodel/profile_viewmodel.dart';
import 'package:walleta/theme/app_theme_manager.dart';

const Color _accentTeal = Color(0xFF006A60);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeManager = context.watch<AppThemeManager>();
    final colors = themeManager.colors;

    final profileVm = context.watch<ProfileViewModel>();
    final name = profileVm.name;

    return Scaffold(
      backgroundColor: colors.backgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
              child: Row(
                children: [
                  Consumer<ProfileViewModel>(
                    builder: (context, vm, _) {
                      final imageUrl = vm.profileImage;
                      final bool hasValidImage =
                          imageUrl.isNotEmpty &&
                          (imageUrl.startsWith('http') ||
                              imageUrl.startsWith('https'));

                      return CircleAvatar(
                        radius: 24,
                        backgroundColor: colors.containerBG,
                        backgroundImage: hasValidImage
                            ? NetworkImage(imageUrl)
                            : null,
                        child: !hasValidImage
                            ? Icon(Icons.person, color: colors.primaryText)
                            : null,
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Welcome, $name",
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: colors.primaryText,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Have a great day!",
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 14,
                            color: colors.disabledText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const NotificationScreen(),
                        ),
                      );
                    },
                    child: Icon(
                      Icons.notifications_none,
                      color: _accentTeal,
                      size: 26,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: colors.tileBG,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tabController,
                  labelColor: Colors.white,
                  unselectedLabelColor: colors.disabledText,
                  indicator: BoxDecoration(
                    color: _accentTeal,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelStyle: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 14,
                  ),
                  tabs: const [
                    Tab(child: Text("Daily")),
                    Tab(child: Text("Weekly")),
                    Tab(child: Text("Monthly")),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [DailyView(), WeeklyView(), MonthlyView()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
