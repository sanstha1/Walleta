import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:walleta/screen/home/view/daily_view.dart';
import 'package:walleta/screen/home/view/monthly_view.dart';
import 'package:walleta/screen/home/view/weekly_view.dart';
import 'package:walleta/screen/profile/viewmodel/profile_viewmodel.dart';
import 'package:walleta/theme/app_colors.dart';

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
    final colors = AppColors.of(context);

    final name = Provider.of<ProfileViewModel>(context).name;

    return Scaffold(
      backgroundColor: colors.backgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Welcome, $name",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: colors.primaryText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Have a great day!",
                    style: TextStyle(fontSize: 16, color: colors.disabledText),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: colors.containerBG,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tabController,
                  labelColor: Colors.white,
                  unselectedLabelColor: colors.disabledText,
                  indicator: BoxDecoration(
                    color: colors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  tabs: const [
                    Tab(child: Text("Daily", style: TextStyle(fontSize: 14))),
                    Tab(child: Text("Weekly", style: TextStyle(fontSize: 14))),
                    Tab(child: Text("Monthly", style: TextStyle(fontSize: 14))),
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
