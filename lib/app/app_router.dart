import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../presentation/home/home_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: '/home',
    routes: [
      GoRoute(
        name: 'home',
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(path: '/qibla', redirect: (context, state) => '/home'),
      GoRoute(path: '/settings', redirect: (context, state) => '/home'),
    ],
  );

  ref.onDispose(router.dispose);
  return router;
});
