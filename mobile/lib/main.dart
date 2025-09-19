import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/create_post_screen.dart';
import 'screens/feed_screen.dart';
import 'screens/leaderboard_screen.dart';
import 'screens/login_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/rewards_screen.dart';
import 'services/app_state.dart';

void main() {
  runApp(const SoloJourneyApp());
}

class SoloJourneyApp extends StatelessWidget {
  const SoloJourneyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState(),
      child: MaterialApp(
        title: 'Solo Journey',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
          useMaterial3: true,
        ),
        home: const AuthGate(),
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        if (state.currentUser == null) {
          return const LoginScreen();
        }
        return const HomeShell();
      },
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static final pages = [
    const FeedScreen(),
    const CreatePostScreen(),
    const LeaderboardScreen(),
    const RewardsScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final user = state.profile?.user ?? state.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('你好，${user?.username ?? '旅行者'}'),
            Text('积分 ${user?.points ?? 0} · 等级 ${user?.level ?? 0}',
                style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
        actions: [
          IconButton(
            onPressed: state.syncing ? null : () => context.read<AppState>().refreshAll(),
            icon: state.syncing
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(child: pages[_index]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.map), label: '旅程'),
          NavigationDestination(icon: Icon(Icons.add_a_photo), label: '发布'),
          NavigationDestination(icon: Icon(Icons.emoji_events), label: '排行榜'),
          NavigationDestination(icon: Icon(Icons.card_giftcard), label: '兑换'),
          NavigationDestination(icon: Icon(Icons.person), label: '我的'),
        ],
      ),
    );
  }
}
