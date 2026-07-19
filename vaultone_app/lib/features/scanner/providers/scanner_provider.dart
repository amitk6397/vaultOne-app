import 'package:flutter_riverpod/legacy.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/ocr_scan_result.dart';
import '../repositories/ai_ocr_repository.dart';

const _ocrBoxName = 'ocr_scan_history';

final scannerProvider = StateNotifierProvider<ScannerController, ScannerState>(
  (ref) => ScannerController(ref.watch(aiOcrRepositoryProvider)),
);

class ScannerState {
  const ScannerState({
    this.results = const [],
    this.isLoading = true,
    this.isScanning = false,
    this.error,
  });

  final List<OcrScanResult> results;
  final bool isLoading;
  final bool isScanning;
  final String? error;

  OcrScanResult? get latest => results.isEmpty ? null : results.first;

  ScannerState copyWith({
    List<OcrScanResult>? results,
    bool? isLoading,
    bool? isScanning,
    String? error,
  }) {
    return ScannerState(
      results: results ?? this.results,
      isLoading: isLoading ?? this.isLoading,
      isScanning: isScanning ?? this.isScanning,
      error: error,
    );
  }
}

class ScannerController extends StateNotifier<ScannerState> {
  ScannerController(this._aiOcr) : super(const ScannerState()) {
    _load();
  }

  Box<dynamic>? _box;
  final AiOcrRepository _aiOcr;
  AiOcrResult? lastAiResult;

  Future<void> _load() async {
    try {
      _box = await Hive.openBox<dynamic>(_ocrBoxName);
      state = state.copyWith(results: _readResults(), isLoading: false);
    } catch (error) {
      state = state.copyWith(isLoading: false, error: error.toString());
    }
  }

  Future<OcrScanResult?> scanImagePath(
    String path, {
    String target = 'document',
  }) async {
    state = state.copyWith(isScanning: true, error: null);
    try {
      final extracted = await _aiOcr.extract(path, target: target);
      lastAiResult = extracted;
      final rawText = extracted.rawText.trim();
      final lines = rawText
          .split(RegExp(r'[\r\n]+'))
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .toList();
      final now = DateTime.now();
      final result = OcrScanResult(
        id: 'scan-${now.microsecondsSinceEpoch}',
        title: extracted.title.isEmpty
            ? _titleFromText(rawText, now)
            : extracted.title,
        imagePath: path,
        rawText: rawText,
        lines: lines,
        entities: extractEntities(rawText),
        documentType: extracted.documentType,
        createdAt: now,
      );
      await _box?.put(result.id, result.toMap());
      state = state.copyWith(results: _readResults(), isScanning: false);
      return result;
    } catch (error) {
      state = state.copyWith(isScanning: false, error: error.toString());
      return null;
    }
  }

  Future<void> toggleFavorite(String id) async {
    final result = resultById(id);
    if (result == null) return;
    final updated = result.copyWith(isFavorite: !result.isFavorite);
    await _box?.put(id, updated.toMap());
    state = state.copyWith(results: _readResults());
  }

  Future<void> rename(String id, String title) async {
    final result = resultById(id);
    if (result == null) return;
    final updated = result.copyWith(title: title);
    await _box?.put(id, updated.toMap());
    state = state.copyWith(results: _readResults());
  }

  Future<void> delete(String id) async {
    await _box?.delete(id);
    state = state.copyWith(results: _readResults());
  }

  OcrScanResult? resultById(String id) {
    for (final result in state.results) {
      if (result.id == id) return result;
    }
    return null;
  }

  List<OcrScanResult> _readResults() {
    final box = _box;
    if (box == null) return const [];
    final results = box.values
        .whereType<Map>()
        .map(OcrScanResult.fromMap)
        .where((result) => result.id.isNotEmpty)
        .toList();
    results.sort((a, b) {
      if (a.isFavorite != b.isFavorite) return a.isFavorite ? -1 : 1;
      return b.createdAt.compareTo(a.createdAt);
    });
    return results;
  }
}

List<OcrEntity> extractEntities(String text) {
  final entities = <OcrEntity>[];
  void addMatches(OcrEntityType type, RegExp regex) {
    for (final match in regex.allMatches(text)) {
      final value = match.group(0)?.trim();
      if (value != null && value.isNotEmpty) {
        entities.add(OcrEntity(type: type, value: value));
      }
    }
  }

  addMatches(
    OcrEntityType.email,
    RegExp(r'[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}', caseSensitive: false),
  );
  addMatches(OcrEntityType.phone, RegExp(r'(\+91[\s-]?)?[6-9]\d{9}'));
  addMatches(OcrEntityType.pan, RegExp(r'\b[A-Z]{5}[0-9]{4}[A-Z]\b'));
  addMatches(OcrEntityType.aadhaar, RegExp(r'\b\d{4}\s?\d{4}\s?\d{4}\b'));
  addMatches(OcrEntityType.date, RegExp(r'\b\d{1,2}[/-]\d{1,2}[/-]\d{2,4}\b'));
  addMatches(
    OcrEntityType.amount,
    RegExp(r'(₹|Rs\.?\s?)\s?\d+(,\d{3})*(\.\d{1,2})?'),
  );
  addMatches(
    OcrEntityType.url,
    RegExp(
      r'(https?:\/\/)?(www\.)?[a-z0-9-]+\.[a-z]{2,}',
      caseSensitive: false,
    ),
  );

  final seen = <String>{};
  return entities
      .where((entity) => seen.add('${entity.type}-${entity.value}'))
      .toList();
}

String detectDocumentType(String text) {
  final value = text.toLowerCase();
  if (value.contains('aadhaar') || value.contains('uidai')) return 'Aadhaar';
  if (RegExp(r'\b[A-Z]{5}[0-9]{4}[A-Z]\b').hasMatch(text)) return 'PAN';
  if (value.contains('invoice') || value.contains('gst')) return 'Invoice';
  if (value.contains('passport')) return 'Passport';
  if (value.contains('driving') || value.contains('licence')) {
    return 'Driving Licence';
  }
  if (value.contains('insurance') || value.contains('policy')) return 'Policy';
  if (value.contains('medical') || value.contains('lab')) return 'Medical';
  return 'General';
}

String _titleFromText(String text, DateTime now) {
  final firstLine = text
      .split('\n')
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .firstOrNull;
  if (firstLine == null) return 'Scan ${now.day}/${now.month}/${now.year}';
  return firstLine.length > 40 ? firstLine.substring(0, 40) : firstLine;
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
