import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:walleta/screen/profile/viewmodel/notification_viewmodel.dart';
import 'package:walleta/theme/app_colors.dart';
import 'package:walleta/theme/app_theme_manager.dart';
import 'package:firebase_auth/firebase_auth.dart';

const Color _accentTeal = Color(0xFF006A60);
const Color _expenseDeep = Color(0xFFBA1A1A);

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  late NotificationViewModel _viewModel;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _viewModel = context.read<NotificationViewModel>();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          _viewModel.startListening();
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) {
              _viewModel.markAllRead();
            }
          });
        } else {
          debugPrint('⚠️ No authenticated user found');
        }
      }
    });
  }

  @override
  void dispose() {
    _viewModel.stopListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<NotificationViewModel>();
    final themeManager = context.watch<AppThemeManager>();
    final colors = themeManager.colors;
    final isDark = themeManager.isDark;
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        backgroundColor: colors.backgroundColor,
        appBar: AppBar(
          backgroundColor: colors.backgroundColor,
          elevation: 0,
          title: Text(
            'Notifications',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              fontFamily: 'monospace',
              color: colors.primaryText,
            ),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_outline_rounded,
                size: 80,
                color: colors.disabledText.withOpacity(0.3),
              ),
              const SizedBox(height: 16),
              Text(
                'Authentication Required',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: colors.primaryText,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please log in to view notifications',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 14,
                  color: colors.disabledText,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: colors.backgroundColor,
      appBar: AppBar(
        backgroundColor: colors.backgroundColor,
        elevation: 0,
        title: Text(
          'Notifications',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            fontFamily: 'monospace',
            color: colors.primaryText,
          ),
        ),
        centerTitle: false,
        iconTheme: IconThemeData(color: colors.primaryText),
        actions: [
          if (vm.unreadCount > 0)
            TextButton(
              onPressed: vm.markAllRead,
              child: Text(
                'Mark all read',
                style: TextStyle(
                  color: _accentTeal,
                  fontSize: 12,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
      body: vm.isLoading
          ? Center(child: CircularProgressIndicator(color: _accentTeal))
          : vm.items.isEmpty
          ? _buildEmpty(colors, isDark)
          : RefreshIndicator(
              color: _accentTeal,
              onRefresh: () async {
                vm.restartListening();
                await Future.delayed(const Duration(milliseconds: 800));
              },
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (vm.todayItems.isNotEmpty) ...[
                    _sectionLabel('Today', vm.todayItems.length, colors),
                    ...vm.todayItems.map(
                      (n) => _tile(context, n, colors, isDark),
                    ),
                  ],
                  if (vm.earlierItems.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _sectionLabel('Earlier', vm.earlierItems.length, colors),
                    ...vm.earlierItems.map(
                      (n) => _tile(context, n, colors, isDark),
                    ),
                  ],
                  const SizedBox(height: 100),
                ],
              ),
            ),
    );
  }

  Widget _buildEmpty(AppColors colors, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none_rounded,
            size: 80,
            color: colors.disabledText.withOpacity(0.2),
          ),
          const SizedBox(height: 16),
          Text(
            'No notifications yet',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colors.disabledText,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Transactions and updates\nwill appear here',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 13,
              color: colors.disabledText.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text, int count, AppColors colors) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Text(
            text,
            style: TextStyle(
              fontFamily: 'monospace',
              color: colors.disabledText,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _accentTeal.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontFamily: 'monospace',
                color: _accentTeal,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tile(
    BuildContext context,
    NotificationItem n,
    AppColors colors,
    bool isDark,
  ) {
    final (icon, color) = switch (n.type) {
      'transaction' => (Icons.receipt_long_rounded, _expenseDeep),
      'payment' => (Icons.account_balance_wallet_rounded, _accentTeal),
      'system' => (Icons.campaign_rounded, Colors.purple),
      _ => (Icons.notifications_rounded, Colors.grey),
    };

    return Dismissible(
      key: Key(n.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: _expenseDeep,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      onDismissed: (_) => _viewModel.deleteNotification(n.id),
      child: GestureDetector(
        onTap: () => _viewModel.markRead(n.id),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.containerBG,
            borderRadius: BorderRadius.circular(18),
            border: n.isRead
                ? null
                : Border.all(color: _accentTeal.withOpacity(0.4), width: 1.5),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      n.title,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: colors.primaryText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      n.body,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: colors.disabledText,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    timeago.format(n.createdAt),
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 10,
                      color: colors.disabledText,
                    ),
                  ),
                  if (!n.isRead) ...[
                    const SizedBox(height: 6),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: _accentTeal,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
