import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/enhancements/online_policy.dart';
import '../data/enhancements/enhancement_client.dart';
import 'preferences_providers.dart';

final onlinePolicyProvider = ChangeNotifierProvider<OnlinePolicy>((ref) {
  final policy = OnlinePolicy(ref.watch(userPreferencesProvider));
  policy.load().catchError((Object _) {}); // A read failure stays offline.
  return policy;
});
final enhancementClientProvider = Provider(
  (ref) => EnhancementClient(ref.read(onlinePolicyProvider)),
);
