import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router/app_router.dart';
import 'theme/app_theme.dart';
import '../core/localization/generated/app_localizations.dart';

/// Root widget for the HomeDoc application.
class HomeDocApp extends ConsumerWidget {
  const HomeDocApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'HomeDoc AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,

      // Localization
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}
