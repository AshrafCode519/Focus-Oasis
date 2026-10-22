import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:focus_oasis/main.dart';
import 'package:focus_oasis/services/storage_service.dart';
import 'package:focus_oasis/services/locale_service.dart';
import 'package:focus_oasis/services/community_service.dart';
import 'package:focus_oasis/services/supabase_service.dart';

void main() {
  testWidgets('Focus Oasis smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'oasis_custom_supabase_url': 'https://xyzcompany.supabase.co',
      'oasis_custom_supabase_key': 'placeholder',
    });
    final storage = await StorageService.init();
    LocaleService.instance.init(storage);
    CommunityService().init(storage);
    await SupabaseService().init(storage.prefs);

    await tester.pumpWidget(FocusOasisApp(storage: storage));
    await tester.pump();

    // Verify app title and main elements render
    expect(find.text('واحة التركيز'), findsOneWidget);
    expect(find.text('ابدأ التركيز 🌿'), findsOneWidget);
  });
}
