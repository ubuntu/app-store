import 'dart:ui';

import 'package:app_center/deb/deb.dart';
import 'package:app_center/error/error.dart';
import 'package:app_center/games/games.dart';
import 'package:app_center/l10n.dart';
import 'package:app_center/layout.dart';
import 'package:app_center/manage/manage_page.dart';
import 'package:app_center/providers/error_stream_provider.dart';
import 'package:app_center/search/search.dart';
import 'package:app_center/snapd/snapd.dart';
import 'package:app_center/store/store_navigator.dart';
import 'package:app_center/store/store_observer.dart';
import 'package:app_center/store/store_pages.dart';
import 'package:app_center/store/store_providers.dart';
import 'package:app_center/store/store_routes.dart';
import 'package:app_center/widgets/widgets.dart';
import 'package:flutter/material.dart' hide AboutDialog, showAboutDialog;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snapd/snapd.dart';
import 'package:yaru/yaru.dart';

// Making a provider to provide navigatorKeyTwo
final materialAppNavigatorKeyProvider =
    Provider((ref) => GlobalKey<NavigatorState>());

final yaruPageControllerProvider =
    Provider((ref) => YaruPageController(length: pages.length));

final routeNameProvider = StateProvider<String?>((ref) => null);

class StoreApp extends ConsumerStatefulWidget {
  const StoreApp({super.key});

  @override
  ConsumerState<StoreApp> createState() => _StoreAppState();
}

class _StoreAppState extends ConsumerState<StoreApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  final searchFocus = FocusNode();
  final keyboardListenerFocus = FocusNode();

  NavigatorState get _navigator => _navigatorKey.currentState!;

  @override
  Widget build(BuildContext context) {
    ref.listen(routeStreamProvider, (prev, next) {
      next.whenData((route) => _navigator.pushNamed(route));
    });

    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyF): () {
          searchFocus.requestFocus();
          searchFocus.nextFocus();
        },
      },
      child: KeyboardListener(
        onKeyEvent: (event) {
          if (event is KeyDownEvent && (event.character?.isNotEmpty ?? false)) {
            final currentFocus = FocusManager.instance.primaryFocus;
            if (currentFocus?.context?.widget is FocusScope) {
              searchFocus.requestFocus();
              searchFocus.nextFocus();
            }
          }
        },
        focusNode: keyboardListenerFocus,
        child: YaruTheme(
          builder: (context, yaru, child) => MaterialApp(
            theme: yaru.theme,
            darkTheme: yaru.darkTheme,
            highContrastTheme: yaruHighContrastLight,
            highContrastDarkTheme: yaruHighContrastDark,
            debugShowCheckedModeBanner: false,
            localizationsDelegates: localizationsDelegates,
            navigatorKey: ref.watch(materialAppNavigatorKeyProvider),
            supportedLocales: supportedLocales,
            scrollBehavior: const MaterialScrollBehavior().copyWith(
              dragDevices: {
                PointerDeviceKind.mouse,
                PointerDeviceKind.touch,
                PointerDeviceKind.stylus,
                PointerDeviceKind.unknown,
                PointerDeviceKind.trackpad,
              },
            ),
            home: _StoreAppHome(
              navigatorKey: _navigatorKey,
              searchFocus: searchFocus,
            ),
          ),
        ),
      ),
    );
  }
}

class _StoreAppHome extends ConsumerWidget {
  const _StoreAppHome({
    required this.navigatorKey,
    required this.searchFocus,
  });

  final GlobalKey<NavigatorState> navigatorKey;
  final FocusNode searchFocus;

  NavigatorState get navigator => navigatorKey.currentState!;

  Future<void> _showError(BuildContext context, SnapdException e) {
    final errorMessage = ErrorMessage.fromObject(e);
    final title = errorMessage.title(AppLocalizations.of(context));
    final body = errorMessage.body(AppLocalizations.of(context));

    return showErrorDialog(
      context: context,
      title: title,
      message: body,
      type: errorMessage.type,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    YaruWindow.of(context).setTitle(l10n.appCenterLabel);

    ref.listen(errorStreamProvider, (_, error) {
      if (error.hasValue && error.value is SnapdException) {
        final snapdError = error.value as SnapdException;
        // Don't show an error if the user cancelled the auth dialog.
        if (snapdError.kind == 'auth-cancelled') {
          return;
        }
        _showError(context, snapdError);
      }
    });

    return Scaffold(
      appBar: _TitleBar(
        leading: _MaybeBackButton(navigatorKey),
        title: SizedBox(
          width: kSearchBarWidth,
          child: SearchField(
            onSearch: (query) => navigator.pushAndRemoveSearch(query: query),
            onSnapSelected: (name) => navigator.pushSnap(name: name),
            onDebSelected: (id) => navigator.pushDeb(id: id),
            searchFocus: searchFocus,
          ),
        ),
      ),
      body: YaruMasterDetailPage(
        navigatorKey: navigatorKey,
        navigatorObservers: [StoreObserver(ref)],
        initialRoute: ref.watch(initialRouteProvider),
        controller: ref.watch(yaruPageControllerProvider),
        tileBuilder: (context, index, selected, availableWidth) =>
            pages[index].tileBuilder(context, selected),
        pageBuilder: (context, index) => pages[index].pageBuilder(context),
        paneLayoutDelegate: const YaruFixedPaneDelegate(paneSize: kPaneWidth),
        breakpoint: 0, // always landscape
        onGenerateRoute: (settings) => switch (StoreRoutes.routeOf(settings)) {
          StoreRoutes.deb => MaterialPageRoute(
              settings: settings,
              builder: (_) => DebPage(
                id: StoreRoutes.debOf(settings)!,
              ),
            ),
          StoreRoutes.localDeb => MaterialPageRoute(
              settings: settings,
              builder: (_) => LocalDebPage(
                path: StoreRoutes.localDebOf(settings)!,
              ),
            ),
          StoreRoutes.snap => MaterialPageRoute(
              settings: settings,
              builder: (_) => SnapPage(
                snapName: StoreRoutes.snapOf(settings)!,
              ),
            ),
          StoreRoutes.search => MaterialPageRoute(
              settings: settings,
              builder: (_) => SearchPage(
                query: StoreRoutes.queryOf(settings),
                category: StoreRoutes.categoryOf(settings),
              ),
            ),
          StoreRoutes.externalTools => MaterialPageRoute(
              settings: settings,
              builder: (_) => const ExternalTools(),
            ),
          StoreRoutes.manage => MaterialPageRoute(
              settings: settings,
              builder: (_) => const ManagePage(),
            ),
          _ => null,
        },
      ),
    );
  }
}

class _TitleBar extends StatelessWidget implements PreferredSizeWidget {
  const _TitleBar({required this.title, required this.leading});

  final Widget title;
  final Widget leading;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: kPaneWidth,
          child: YaruWindowTitleBar(
            style: YaruTitleBarStyle.undecorated,
            border: BorderSide.none,
            backgroundColor: YaruMasterDetailTheme.of(context).sideBarColor,
          ),
        ),
        const SizedBox(
          height: kYaruTitleBarHeight,
          child: VerticalDivider(),
        ),
        Expanded(
          child: YaruWindowTitleBar(
            border: BorderSide.none,
            backgroundColor: Colors.transparent,
            title: title,
            leading: leading,
          ),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size(0, kYaruTitleBarHeight);
}

class _MaybeBackButton extends ConsumerWidget {
  const _MaybeBackButton(this.navigatorKey);

  final GlobalKey<NavigatorState> navigatorKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routeName = ref.watch(routeNameProvider);
    final canPop = routeName != null && routeName != '/';
    return canPop
        ? YaruBackButton(
            style: YaruBackButtonStyle.rounded,
            onPressed: navigatorKey.currentState?.pop,
          )
        : const SizedBox();
  }
}
