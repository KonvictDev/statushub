import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:statushub/router/route_names.dart';
import 'package:statushub/screens/games_screen.dart';
import 'package:statushub/screens/recover_message_screen.dart';
import 'package:statushub/screens/settings_screen.dart';
import 'package:statushub/screens/secret_message_screen.dart';
import 'package:statushub/screens/splash_screen.dart';

import '../screens/home_screen.dart';
import '../widgets/direct_message.dart';

class AppRouter {
  late final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: RouteNames.splash,
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: SplashScreen(),
        ),
      ),
      GoRoute(
        name: RouteNames.home,
        path: '/home',
        pageBuilder: (context, state) {
          return CustomTransitionPage(
            key: state.pageKey,
            child: const HomeScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
          );
        },
      ),

      GoRoute(
        path: '/direct-message',
        name: RouteNames.directMessage,
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: DirectMessageWidget(),
        ),
      ),
      GoRoute(
        path: '/settings',
        name: RouteNames.settings,
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: SettingsScreen(),
        ),
      ),
      GoRoute(
        path: '/messageEncrypt',
        name: RouteNames.messageEncrypt,
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: SecretMessageEncrypter(),
        ),
      ),
      GoRoute(
        path: '/recoverMessage',
        name: RouteNames.recoverMessage,
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: RecoverMessageScreen(),
        ),
      ),
      GoRoute(
        path: '/games',
        name: RouteNames.games,
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: GamesScreen(),
        ),
      ),
    ],
  );
}