import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:foodpilot/app/shell.dart';
import 'package:foodpilot/data/providers.dart';
import 'package:foodpilot/features/analisis/ai_screen.dart';
import 'package:foodpilot/features/analisis/analisis_screen.dart';
import 'package:foodpilot/features/analisis/simulasi_screen.dart';
import 'package:foodpilot/features/beranda/beranda_screen.dart';
import 'package:foodpilot/features/menu/menu_form_screen.dart';
import 'package:foodpilot/features/menu/menu_list_screen.dart';
import 'package:foodpilot/features/onboarding/onboarding_screen.dart';
import 'package:foodpilot/features/profil/akun_screen.dart';
import 'package:foodpilot/features/profil/biaya_screen.dart';
import 'package:foodpilot/features/profil/laporan_screen.dart';
import 'package:foodpilot/features/profil/pengaturan_screen.dart';
import 'package:foodpilot/features/profil/profil_screen.dart';
import 'package:foodpilot/features/profil/usaha_screen.dart';

/// Router aplikasi.
///
/// Padanannya di React Router: `createBrowserRouter` dengan layout route.
/// `StatefulShellRoute.indexedStack` adalah layout berisi tab bar yang
/// menjaga state tiap tab, seperti `<Outlet />` yang tidak di-unmount saat
/// pindah tab.
///
/// Rute level 2 memakai `parentNavigatorKey: rootNavigatorKey`, jadi tampil
/// di navigator paling atas dan menutupi tab bar (CONTEXT.md bagian 7).
final routerProvider = Provider<GoRouter>((ref) {
  final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

  final router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: ref.watch(initialLocationProvider),
    redirect: (context, state) => state.uri.path == '/' ? '/beranda' : null,
    routes: <RouteBase>[
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/beranda',
                builder: (context, state) => const BerandaScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/menu',
                builder: (context, state) => const MenuListScreen(),
                routes: <RouteBase>[
                  GoRoute(
                    path: ':id',
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (context, state) =>
                        MenuFormScreen(menuId: state.pathParameters['id']!),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/analisis',
                builder: (context, state) => const AnalisisScreen(),
                routes: <RouteBase>[
                  GoRoute(
                    path: 'ai',
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (context, state) => const AiScreen(),
                  ),
                  GoRoute(
                    path: 'simulasi',
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (context, state) => const SimulasiScreen(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/profil',
                builder: (context, state) => const ProfilScreen(),
                routes: <RouteBase>[
                  GoRoute(
                    path: 'usaha',
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (context, state) => const UsahaScreen(),
                  ),
                  GoRoute(
                    path: 'biaya',
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (context, state) => const BiayaScreen(),
                  ),
                  GoRoute(
                    path: 'laporan',
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (context, state) => const LaporanScreen(),
                  ),
                  GoRoute(
                    path: 'akun',
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (context, state) => const AkunScreen(),
                  ),
                  GoRoute(
                    path: 'pengaturan',
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (context, state) => const PengaturanScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
    ],
  );

  ref.onDispose(router.dispose);
  return router;
});
