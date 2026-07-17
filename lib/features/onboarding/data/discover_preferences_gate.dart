import 'package:shared_preferences/shared_preferences.dart';

/// First-run gate for the mandatory Discovery preferences flow (style / fit /
/// modesty / size / style-quiz). Mirrors the swipe-tutorial "seen" flag: the
/// flow is shown once, and only marked complete after the profile is updated —
/// so quitting mid-flow re-shows it next time the Discover tab opens.
const String _kDiscoverPrefsDoneKey = 'has_completed_discover_preferences';

Future<bool> shouldShowDiscoverPreferences() async {
  final prefs = await SharedPreferences.getInstance();
  return !(prefs.getBool(_kDiscoverPrefsDoneKey) ?? false);
}

Future<void> markDiscoverPreferencesCompleted() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_kDiscoverPrefsDoneKey, true);
}
