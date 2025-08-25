import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:statushub/router/route_names.dart';
import 'package:statushub/screens/gif_maker_screen.dart';
import 'package:statushub/screens/settings_screen.dart';
import 'package:statushub/screens/sticker_maker_screen.dart';

import '../screens/home_screen.dart';
import '../widgets/direct_message.dart';

class AppRouter {
  late final GoRouter router = GoRouter(
    initialLocation: '/home',
    routes: [
      GoRoute(
        path: '/home',
        name: RouteNames.home,
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: HomeScreen(),
        ),
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
        path: '/sticker',
        name: RouteNames.sticker,
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: StickerMakerScreen(),
        ),
      ),
      GoRoute(
        path: '/gif',
        name: RouteNames.gif,
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: GifMakerScreen(),
        ),
      ),
    ],
  );
}