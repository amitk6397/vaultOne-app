import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ModuleStorageTarget { local, database }

enum StorageModule { videos, photos, fileVault }

class ModuleStorageState {
  const ModuleStorageState({this.targets = const {}});

  final Map<StorageModule, ModuleStorageTarget> targets;

  ModuleStorageTarget? targetFor(StorageModule module) => targets[module];

  ModuleStorageState setTarget(
    StorageModule module,
    ModuleStorageTarget target,
  ) => ModuleStorageState(targets: {...targets, module: target});
}

class ModuleStorageController extends StateNotifier<ModuleStorageState> {
  ModuleStorageController() : super(const ModuleStorageState()) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final values = <StorageModule, ModuleStorageTarget>{};
    for (final module in StorageModule.values) {
      final raw = prefs.getString(keyFor(module));
      if (raw != null) {
        values[module] = raw == ModuleStorageTarget.database.name
            ? ModuleStorageTarget.database
            : ModuleStorageTarget.local;
      }
    }
    // Preserve the existing video preference for current users.
    final legacyVideo = prefs.getString('private_video_storage');
    if (values[StorageModule.videos] == null && legacyVideo != null) {
      values[StorageModule.videos] = legacyVideo == 'database'
          ? ModuleStorageTarget.database
          : ModuleStorageTarget.local;
    }
    state = ModuleStorageState(targets: values);
  }

  Future<void> setTarget(
    StorageModule module,
    ModuleStorageTarget target,
  ) async {
    state = state.setTarget(module, target);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyFor(module), target.name);
    if (module == StorageModule.videos) {
      await prefs.setString('private_video_storage', target.name);
    }
  }

  static String keyFor(StorageModule module) =>
      'module_storage_${module.name}';
}

final moduleStorageProvider =
    StateNotifierProvider<ModuleStorageController, ModuleStorageState>(
      (ref) => ModuleStorageController(),
    );

Future<ModuleStorageTarget?> savedStorageTarget(StorageModule module) async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString(ModuleStorageController.keyFor(module));
  if (raw == null) return null;
  return raw == ModuleStorageTarget.database.name
      ? ModuleStorageTarget.database
      : ModuleStorageTarget.local;
}
