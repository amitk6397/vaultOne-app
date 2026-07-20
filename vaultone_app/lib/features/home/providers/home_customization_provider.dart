import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

enum HomeModuleId { connect, files, passwords, photos, videos, scanner }

enum HomeModuleColumns { auto, two, three }

enum HomeModuleCardStyle { glassGrid, commandDeck, blueprint }

const _homeCustomizationBox = 'home_customization';
const _columnsKey = 'columns';
const _styleKey = 'style';
const _hiddenKey = 'hidden_modules';
const _orderKey = 'module_order';
const _colorsKey = 'module_colors';

final homeCustomizationProvider =
    StateNotifierProvider<HomeCustomizationController, HomeCustomizationState>(
      (ref) => HomeCustomizationController(),
    );

class HomeCustomizationState {
  const HomeCustomizationState({
    this.columns = HomeModuleColumns.auto,
    this.cardStyle = HomeModuleCardStyle.glassGrid,
    this.hiddenModules = const {},
    this.moduleOrder = _defaultOrder,
    this.moduleColors = const {},
    this.isLoading = true,
  });

  final HomeModuleColumns columns;
  final HomeModuleCardStyle cardStyle;
  final Set<HomeModuleId> hiddenModules;
  final List<HomeModuleId> moduleOrder;
  final Map<HomeModuleId, Color> moduleColors;
  final bool isLoading;

  bool isVisible(HomeModuleId id) => !hiddenModules.contains(id);
  Color colorFor(HomeModuleId id, Color fallback) =>
      moduleColors[id] ?? fallback;

  HomeCustomizationState copyWith({
    HomeModuleColumns? columns,
    HomeModuleCardStyle? cardStyle,
    Set<HomeModuleId>? hiddenModules,
    List<HomeModuleId>? moduleOrder,
    Map<HomeModuleId, Color>? moduleColors,
    bool? isLoading,
  }) {
    return HomeCustomizationState(
      columns: columns ?? this.columns,
      cardStyle: cardStyle ?? this.cardStyle,
      hiddenModules: hiddenModules ?? this.hiddenModules,
      moduleOrder: moduleOrder ?? this.moduleOrder,
      moduleColors: moduleColors ?? this.moduleColors,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

const _defaultOrder = [
  HomeModuleId.connect,
  HomeModuleId.files,
  HomeModuleId.passwords,
  HomeModuleId.photos,
  HomeModuleId.videos,
  HomeModuleId.scanner,
];

class HomeCustomizationController
    extends StateNotifier<HomeCustomizationState> {
  HomeCustomizationController() : super(const HomeCustomizationState()) {
    _load();
  }

  Box<dynamic>? _box;

  Future<void> _load() async {
    _box = await Hive.openBox<dynamic>(_homeCustomizationBox);
    state = HomeCustomizationState(
      columns: _enumFromName(
        HomeModuleColumns.values,
        _box?.get(_columnsKey)?.toString(),
        HomeModuleColumns.auto,
      ),
      cardStyle: _enumFromName(
        HomeModuleCardStyle.values,
        _box?.get(_styleKey)?.toString(),
        HomeModuleCardStyle.glassGrid,
      ),
      hiddenModules: _moduleSet(_box?.get(_hiddenKey)),
      moduleOrder: _moduleOrder(_box?.get(_orderKey)),
      moduleColors: _moduleColors(_box?.get(_colorsKey)),
      isLoading: false,
    );
  }

  Future<void> setColumns(HomeModuleColumns columns) async {
    state = state.copyWith(columns: columns);
    await _box?.put(_columnsKey, columns.name);
  }

  Future<void> setCardStyle(HomeModuleCardStyle style) async {
    state = state.copyWith(cardStyle: style);
    await _box?.put(_styleKey, style.name);
  }

  Future<void> setModuleVisible(HomeModuleId id, bool visible) async {
    final hidden = {...state.hiddenModules};
    visible ? hidden.remove(id) : hidden.add(id);
    state = state.copyWith(hiddenModules: hidden);
    await _box?.put(_hiddenKey, hidden.map((item) => item.name).toList());
  }

  Future<void> moveModule(HomeModuleId id, int direction) async {
    final order = [...state.moduleOrder];
    final from = order.indexOf(id);
    if (from == -1) return;
    final to = (from + direction).clamp(0, order.length - 1).toInt();
    if (from == to) return;
    final item = order.removeAt(from);
    order.insert(to, item);
    state = state.copyWith(moduleOrder: order);
    await _box?.put(_orderKey, order.map((item) => item.name).toList());
  }

  Future<void> setModuleColor(HomeModuleId id, Color color) async {
    final colors = {...state.moduleColors, id: color};
    state = state.copyWith(moduleColors: colors);
    await _box?.put(
      _colorsKey,
      colors.map((key, value) => MapEntry(key.name, value.toARGB32())),
    );
  }

  Future<void> reset() async {
    state = const HomeCustomizationState(isLoading: false);
    await _box?.delete(_columnsKey);
    await _box?.delete(_styleKey);
    await _box?.delete(_hiddenKey);
    await _box?.delete(_orderKey);
    await _box?.delete(_colorsKey);
  }

  T _enumFromName<T extends Enum>(List<T> values, String? name, T fallback) {
    return values.firstWhere(
      (item) => item.name == name,
      orElse: () => fallback,
    );
  }

  Set<HomeModuleId> _moduleSet(dynamic value) {
    if (value is! List) return {};
    final modules = <HomeModuleId>{};
    for (final raw in value) {
      final name = raw.toString();
      for (final module in HomeModuleId.values) {
        if (module.name == name) modules.add(module);
      }
    }
    return modules;
  }

  List<HomeModuleId> _moduleOrder(dynamic value) {
    if (value is! List) return _defaultOrder;
    final parsed = <HomeModuleId>[];
    for (final raw in value) {
      final name = raw.toString();
      for (final module in HomeModuleId.values) {
        if (module.name == name && !parsed.contains(module)) {
          parsed.add(module);
        }
      }
    }
    return [
      ...parsed.where(_defaultOrder.contains),
      ..._defaultOrder.where((item) => !parsed.contains(item)),
    ];
  }

  Map<HomeModuleId, Color> _moduleColors(dynamic value) {
    if (value is! Map) return {};
    final colors = <HomeModuleId, Color>{};
    for (final entry in value.entries) {
      final key = entry.key.toString();
      final rawColor = entry.value;
      if (rawColor is! int) continue;
      for (final module in HomeModuleId.values) {
        if (module.name == key) {
          colors[module] = Color(rawColor);
        }
      }
    }
    return colors;
  }
}
