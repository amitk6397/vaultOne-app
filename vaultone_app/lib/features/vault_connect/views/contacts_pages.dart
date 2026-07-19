import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../constants/app_colors.dart';
import '../../../routes/app_routes.dart';
import '../models/connect_models.dart';
import '../providers/connect_provider.dart';
import '../repositories/connect_repository.dart';

class ContactPermissionInfoPage extends StatelessWidget {
  const ContactPermissionInfoPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Find VaultOne contacts')),
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircleAvatar(
              radius: 44,
              backgroundColor: Color(0xFFEDE9FE),
              child: Icon(
                Icons.contacts_rounded,
                size: 42,
                color: AppColors.purple,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Why VaultOne needs contacts',
              style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            const Text(
              'VaultOne reads phone numbers on this device to find people who already use VaultOne. Numbers are normalized locally and checked in limited batches.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'Your complete contact list is never stored on our server. Local contact names stay on this device.',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () =>
                    context.pushReplacementNamed(AppRoutes.connectContactsName),
                icon: const Icon(Icons.shield_outlined),
                label: const Text('Continue securely'),
              ),
            ),
            TextButton(
              onPressed: () => context.pop(),
              child: const Text('Not now'),
            ),
          ],
        ),
      ),
    ),
  );
}

class RegisteredContactsPage extends ConsumerStatefulWidget {
  const RegisteredContactsPage({super.key});
  @override
  ConsumerState<RegisteredContactsPage> createState() =>
      _RegisteredContactsPageState();
}

class _RegisteredContactsPageState
    extends ConsumerState<RegisteredContactsPage> {
  bool loading = true;
  String? error;
  List<ConnectUser> users = const [];
  final search = TextEditingController();
  final countryCode = TextEditingController(text: '+91');

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    search.dispose();
    countryCode.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final allowed = await FlutterContacts.requestPermission(readonly: true);
      if (!allowed) {
        setState(() {
          loading = false;
          error =
              'Contacts permission was denied. Enable it in Settings to find registered contacts.';
        });
        return;
      }
      final contacts = await FlutterContacts.getContacts(withProperties: true);
      final names = <String, String>{};
      for (final contact in contacts) {
        for (final phone in contact.phones) {
          final normalized = _normalize(phone.number, countryCode.text.trim());
          if (normalized != null) names[normalized] = contact.displayName;
        }
      }
      final found = <ConnectUser>[];
      final numbers = names.keys.toList();
      for (var offset = 0; offset < numbers.length; offset += 500) {
        final end = (offset + 500).clamp(0, numbers.length).toInt();
        final batch = await ref
            .read(connectRepositoryProvider)
            .discover(numbers.sublist(offset, end));
        found.addAll(
          batch.map(
            (x) => ConnectUser(
              id: x.id,
              fullName: x.fullName,
              phone: x.phone,
              localName: names[x.phone],
            ),
          ),
        );
      }
      if (mounted) {
        setState(() {
          users = found;
          loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          loading = false;
          error = e.toString();
        });
      }
    }
  }

  String? _normalize(String value, String countryCode) {
    var digits = value.replaceAll(RegExp(r'[^0-9+]'), '');
    if (digits.startsWith('00')) digits = '+${digits.substring(2)}';
    if (!digits.startsWith('+')) {
      digits = digits.replaceFirst(RegExp(r'^0+'), '');
      digits = '$countryCode$digits';
    }
    final onlyDigits = digits.substring(1);
    return onlyDigits.length >= 8 && onlyDigits.length <= 15
        ? '+$onlyDigits'
        : null;
  }

  @override
  Widget build(BuildContext context) {
    final query = search.text.trim().toLowerCase();
    final visible = users
        .where(
          (x) =>
              x.displayName.toLowerCase().contains(query) ||
              x.phone.contains(query),
        )
        .toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registered contacts'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded)),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                TextField(
                  controller: search,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Search contacts',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    SizedBox(
                      width: 100,
                      child: TextField(
                        controller: countryCode,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Country',
                          hintText: '+91',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Used only on this device to normalize local numbers.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Apply country code',
                      onPressed: _load,
                      icon: const Icon(Icons.sync_rounded),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(error!, textAlign: TextAlign.center),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: () => openAppSettings(),
                            child: const Text('Open settings'),
                          ),
                        ],
                      ),
                    ),
                  )
                : visible.isEmpty
                ? const Center(child: Text('No registered contacts found'))
                : ListView.builder(
                    itemCount: visible.length,
                    itemBuilder: (_, index) {
                      final user = visible[index];
                      return ListTile(
                        leading: CircleAvatar(
                          child: Text(user.displayName[0].toUpperCase()),
                        ),
                        title: Text(user.displayName),
                        subtitle: Text(user.phone),
                        trailing: const Icon(Icons.lock_outline),
                        onTap: () async {
                          final item = await ref
                              .read(vaultConnectProvider.notifier)
                              .createDirect(user.id);
                          if (item != null && context.mounted) {
                            context.pushReplacementNamed(
                              AppRoutes.connectChatName,
                              pathParameters: {'conversationId': item.id},
                              extra: item,
                            );
                          }
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
