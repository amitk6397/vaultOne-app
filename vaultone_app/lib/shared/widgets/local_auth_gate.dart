import 'package:flutter/material.dart';
import '../../core/localization/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'app_loading_indicator.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../features/profile/providers/profile_provider.dart';

enum VaultSecuritySection {
  files,
  passwords,
  secureNotes,
  digiLocker,
  photos,
  videos,
  scanner,
}

class LocalAuthGate extends ConsumerStatefulWidget {
  const LocalAuthGate({
    super.key,
    required this.child,
    this.title,
    this.reason,
    this.enabled,
    this.section,
  });

  final Widget child;
  final String? title;
  final String? reason;
  final bool? enabled;
  final VaultSecuritySection? section;

  @override
  ConsumerState<LocalAuthGate> createState() => _LocalAuthGateState();
}

class _LocalAuthGateState extends ConsumerState<LocalAuthGate> {
  final LocalAuthentication _auth = LocalAuthentication();
  bool _unlocked = false;
  bool _checking = true;
  bool _hasBiometrics = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _unlock());
  }

  @override
  void didUpdateWidget(covariant LocalAuthGate oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled == oldWidget.enabled) return;
    if (widget.enabled == false) {
      setState(() {
        _unlocked = true;
        _checking = false;
        _error = null;
      });
    } else if (widget.enabled == true) {
      setState(() => _unlocked = false);
      _unlock();
    }
  }

  Future<void> _unlock() async {
    final profile = ref.read(profileProvider);
    final enabled =
        widget.enabled ??
        switch (widget.section) {
          VaultSecuritySection.passwords => profile.passwordSecurityEnabled,
          VaultSecuritySection.secureNotes =>
            profile.secureNotesSecurityEnabled,
          VaultSecuritySection.digiLocker => profile.digiLockerSecurityEnabled,
          VaultSecuritySection.files => profile.filesSecurityEnabled,
          VaultSecuritySection.photos => profile.photosSecurityEnabled,
          VaultSecuritySection.videos => profile.videosSecurityEnabled,
          VaultSecuritySection.scanner => profile.scannerSecurityEnabled,
          null => profile.biometricLockEnabled,
        };
    if (!enabled) {
      if (mounted) {
        setState(() {
          _unlocked = true;
          _checking = false;
          _error = null;
        });
      }
      return;
    }

    setState(() {
      _checking = true;
      _error = null;
    });

    try {
      final supported = await _auth.isDeviceSupported();
      final canCheck = await _auth.canCheckBiometrics;
      final availableBiometrics = await _auth.getAvailableBiometrics();
      if (mounted) {
        setState(() => _hasBiometrics = availableBiometrics.isNotEmpty);
      }
      if (!supported && !canCheck) {
        if (!mounted) return;
        setState(() {
          _unlocked = false;
          _checking = false;
          _error = context.l10n.tr('device_security_required');
        });
        return;
      }

      if (!mounted) return;
      final authenticated = await _auth.authenticate(
        localizedReason: widget.reason ?? context.l10n.tr('unlock_to_continue'),
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );

      if (!mounted) return;
      setState(() {
        _unlocked = authenticated;
        _checking = false;
        _error = authenticated
            ? null
            : context.l10n.tr('authentication_cancelled');
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _unlocked = false;
        _checking = false;
        _error = context.l10n.tr(
          'device_authentication_failed',
          args: {'error': error.toString().replaceFirst('Exception: ', '')},
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_unlocked) return widget.child;

    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: AppColors.blue.withValues(alpha: .12),
                  child: Icon(
                    _hasBiometrics
                        ? Icons.fingerprint_rounded
                        : Icons.lock_rounded,
                    color: AppColors.blue,
                    size: 38,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  widget.title ?? context.l10n.tr('private_vault'),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.heading.copyWith(fontSize: 24),
                ),
                const SizedBox(height: 8),
                Text(
                  _error ??
                      (_hasBiometrics
                          ? context.l10n.tr('biometric_unlock_description')
                          : context.l10n.tr('device_unlock_description')),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body,
                ),
                const SizedBox(height: 22),
                if (_checking)
                  AppLoadingIndicator(color: colors.primary, size: 42)
                else
                  FilledButton.icon(
                    onPressed: _unlock,
                    icon: const Icon(Icons.lock_open_rounded),
                    label: Text(context.l10n.tr('unlock')),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
