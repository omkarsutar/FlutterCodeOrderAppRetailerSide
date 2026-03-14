import 'package:flutter/foundation.dart';
import 'package:flutter_supabase_order_app_mobile/features/postLogin/products/product_barrel.dart';
import 'package:flutter_supabase_order_app_mobile/features/postLogin/purchase_orders/ui/purchase_order_list_byShopID.dart';
import 'package:flutter_supabase_order_app_mobile/router/app_routes.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/providers/core_providers.dart';
import '../core/providers/user_profile_state_provider.dart';
import '../core/providers/app_config_provider.dart';
import '../core/models/entity_meta.dart';

import '../features/postLogin/loading_page/loading_page.dart';
import '../features/preLogin/welcome_page.dart';
import '../features/auth/auth_page.dart';
import '../features/postLogin/cart/cart_barrel.dart';
import '../shared/widgets/shared_widget_barrel.dart';
import '../features/postLogin/vacation_mode/vacation_mode_screen.dart';
import '../core/routing/module_route_generator.dart';
import '../core/services/rbac_service.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    routes: [
      ...authRoutes,
      ...ProductsRoutesJson.routes,
      GoRoute(
        path: '/purchase-orders-by-shop',
        name: 'purchase-orders-by-shop',
        builder: (context, state) {
          return PurchaseOrderListByShopID(
            entityMeta: EntityMeta(
              entityName: 'Purchase Order',
              entityNamePlural: 'Purchase Orders',
              entityNameLower: 'purchase order',
              entityNamePluralLower: 'purchase orders',
            ),
            idField: 'po_id',
            fieldConfigs: [],
            timestampField: 'created_at',
            viewRouteName: 'purchase-order-view',
            newRouteName: 'purchase-order-new',
            rbacModule: 'purchase_order',
            searchFields: ['po_shop_id', 'status'],
          );
        },
      ),
    ],
    initialLocation: AppRoute.welcome,
    redirect: (context, state) async {
      // --- Vacation Mode Check (Highest Priority) ---
      final appConfig = ref.read(appConfigProvider).valueOrNull;
      if (appConfig != null && appConfig.vacationMode) {
        if (state.uri.path != AppRoute.vacation) {
          debugPrint('AppRouter: Vacation Mode active -> Redirecting to Vacation Screen');
          return AppRoute.vacation;
        }
        return null; // Stay on vacation screen
      } else if (state.uri.path == AppRoute.vacation) {
        // If not in vacation mode but at vacation path, redirect to welcome/home
        return AppRoute.welcome;
      }

      final session = Supabase.instance.client.auth.currentSession;
      final isLoggedIn = session != null;

      final isAtRoot = state.uri.path == AppRoute.welcome;
      final isAuthPage =
          state.uri.path == AppRoute.login || state.uri.path == AppRoute.signup;

      final profile = ref.read(userProfileStateProvider).profile;
      final rbacService = ref.read(rbacServiceProvider);

      // Check role first if possible
      final roleName = rbacService.roleName?.toLowerCase();
      final isGuest = roleName == 'guest';

      debugPrint(
        'AppRouter: Redirect Check | LoggedIn: $isLoggedIn | Role: $roleName | Path: ${state.uri.path}',
      );

      // Profile is "ready" if RBAC is initialized AND (is Guest OR has preferred route)
      final isProfileReady =
          rbacService.isInitialized &&
          (isGuest || profile?.preferredRouteId != null);

      final isPublicRoute =
          state.uri.path.startsWith('/products') ||
          state.uri.path.startsWith('/cart');

      // --- Pending Order Redirect (High Priority) ---
      if (isLoggedIn && (isAuthPage || isAtRoot)) {
        final prefs = await SharedPreferences.getInstance();
        final hasPendingOrder = prefs.containsKey('pending_order');
        debugPrint(
          '[AppRouter] Checking for pending order in router: $hasPendingOrder',
        );
        if (hasPendingOrder) {
          debugPrint('AppRouter: Pending order found -> Redirecting to Cart');
          return state.namedLocation(AppRoute.cartName);
        }
      }

      // Redirect to products page if not logged in and trying to access protected routes
      if (!isLoggedIn && !isAuthPage && !isAtRoot && !isPublicRoute) {
        return state.namedLocation(ProductsRoutesJson.listRouteName);
      }

      // Redirect to products page if at root and not logged in
      if (!isLoggedIn && isAtRoot) {
        return state.namedLocation(ProductsRoutesJson.listRouteName);
      }
      if (isLoggedIn && (isAuthPage || isAtRoot)) {
        debugPrint(
          'AppRouter: Handling Root/Auth Page Redirect for LoggedIn User',
        );

        if (!isProfileReady && !rbacService.isInitialized) {
          debugPrint('AppRouter: Profile/RBAC not ready -> Loading');
          return AppRoute.loading; // Wait for RBAC at minimum
        }

        // If RBAC is ready but preferredRouteId is null, and NOT guest, still show loading
        // (This preserves existing behavior for other roles while fixing it for guests)
        if (rbacService.isInitialized &&
            !isGuest &&
            profile?.preferredRouteId == null) {
          debugPrint('AppRouter: Profile missing preferredRouteId -> Loading');
          return AppRoute.loading;
        }

        debugPrint('AppRouter: User role is $roleName');

        // Redirect guest to Products
        if (roleName == 'guest') {
          debugPrint('AppRouter: Guest user -> Redirecting to Products');
          return state.namedLocation(ProductsRoutesJson.listRouteName);
        }

        return state.namedLocation(ProductsRoutesJson.listRouteName);
      }

      // --- RBAC Route Protection ---
      // Check if the current route has a permission requirement
      final routeName = state.name ?? state.topRoute?.name;

      debugPrint(
        'AppRouter: RBAC Permission Check | Path: ${state.uri.path} | RouteName: $routeName',
      );

      if (isLoggedIn && routeName != null) {
        final permission = ModuleRouteRegistry.getRoutePermission(routeName);

        if (permission != null) {
          final hasAccess = rbacService.hasPermission(
            permission.moduleId,
            permission.action,
          );

          debugPrint(
            'AppRouter: RBAC Check | Route: $routeName | Module: ${permission.moduleId} | Action: ${permission.action.name} | Role: $roleName | Allowed: $hasAccess',
          );

          if (!hasAccess) {
            debugPrint(
              'AppRouter: Access denied for route $routeName -> Redirecting to unauthorized',
            );
            return AppRoute.unauthorized;
          }
        } else {
          // Verbose logging of unprotected routes
          debugPrint(
            'AppRouter: No RBAC permission found for route $routeName',
          );
        }
      }

      return null;
    },
  );
});

final authRoutes = [
  GoRoute(
    path: AppRoute.loading,
    builder: (context, state) => const LoadingPage(),
  ),
  GoRoute(
    name: AppRoute.welcomeName,
    path: AppRoute.welcome,
    builder: (context, state) => const WelcomePage(),
  ),
  GoRoute(
    name: AppRoute.loginName,
    path: AppRoute.login,
    builder: (context, state) => const AuthPage(),
  ),
  GoRoute(
    name: AppRoute.signupName,
    path: AppRoute.signup,
    builder: (context, state) => const AuthPage(),
  ),
  GoRoute(
    name: AppRoute.profileName,
    path: AppRoute.profile,
    builder: (context, state) => const UserProfilePage(),
  ),
  GoRoute(
    name: AppRoute.cartName,
    path: AppRoute.cart,
    builder: (context, state) => const CartPage(),
  ),
  GoRoute(
    name: AppRoute.unauthorizedName,
    path: AppRoute.unauthorized,
    builder: (context, state) => const UnauthorizedPage(),
  ),
  GoRoute(
    name: AppRoute.vacationName,
    path: AppRoute.vacation,
    builder: (context, state) => const VacationModeScreen(),
  ),
];
