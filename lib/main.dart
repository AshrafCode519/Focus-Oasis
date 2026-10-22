import 'package:flutter/material.dart';
import 'screens/main_navigation_screen.dart';
import 'services/community_service.dart';
import 'services/desktop_service.dart';
import 'services/locale_service.dart';
import 'services/supabase_service.dart';
import 'services/storage_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storage = await StorageService.init();
  LocaleService.instance.init(storage);
  final supabase = SupabaseService();
  await supabase.init(storage.prefs);
  CommunityService().init(storage, supabase);
  await DesktopService().init();
  runApp(FocusOasisApp(storage: storage));
}

class FocusOasisApp extends StatelessWidget {
  final StorageService storage;

  const FocusOasisApp({super.key, required this.storage});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LocaleService.instance,
      builder: (context, _) {
        final localeService = LocaleService.instance;
        return MaterialApp(
          title: '${localeService.t('app_title')} • Focus Oasis',
          debugShowCheckedModeBanner: false,
          locale: localeService.locale,
          theme: OasisTheme.darkTheme,
          home: Directionality(
            textDirection: localeService.isRtl ? TextDirection.rtl : TextDirection.ltr,
            child: MainNavigationScreen(storage: storage),
          ),
        );
      },
    );
  }
}
