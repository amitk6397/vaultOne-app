import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../files_vault/providers/files_vault_provider.dart';
import '../home/providers/banner_provider.dart';
import '../media/providers/media_provider.dart';
import '../notifications/providers/notification_provider.dart';
import '../passwords/providers/password_vault_provider.dart';
import '../profile/providers/profile_provider.dart';
import '../profile/providers/policy_provider.dart';
import '../profile/providers/support_provider.dart';
import '../scanner/providers/scanner_provider.dart';
import '../subscriptions/providers/subscription_provider.dart';
import '../vault_connect/providers/connect_provider.dart';

void refreshAuthenticatedData(WidgetRef ref) {
  ref.invalidate(profileProvider);
  ref.invalidate(subscriptionProvider);
  ref.invalidate(notificationProvider);
  ref.invalidate(passwordVaultProvider);
  ref.invalidate(filesVaultProvider);
  ref.invalidate(mediaLibraryProvider);
  ref.invalidate(scannerProvider);
  ref.invalidate(homeBannersProvider);
  ref.invalidate(privacyPolicyProvider);
  ref.invalidate(termsPolicyProvider);
  ref.invalidate(helpContentProvider);
  ref.invalidate(aboutContentProvider);
  ref.invalidate(supportChatProvider);
  ref.invalidate(vaultConnectProvider);
}
