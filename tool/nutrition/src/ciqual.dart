/// Lettura della tabella CIQUAL 2025 (ANSES) in XML: `alim_*.xml` (alimenti),
/// `alim_grp_*.xml` (gruppi), `compo_*.xml` (composizione).
///
/// I file hanno un elemento per riga (`<alim_code> 1000 </alim_code>`, valori
/// mancanti come `<min missing=" " />`): il lettore va per righe, senza un
/// parser XML completo, e tiene solo i record che servono (la composizione
/// pesa ~70 MB).
library;

import 'dart:convert';
import 'dart:io';

import 'package:irenefy/features/nutrition/data/food_db_schema.dart';

import 'model.dart';

/// Codici dei costituenti CIQUAL (`const_*.xml`), valori per 100 g.
abstract final class CiqualConst {
  /// Energia, Regolamento UE 1169/2011 (kcal/100 g).
  static const energyKcal = 328;
  static const protein = 25000;

  /// Proteine grezze (N × 6,25): ripiego se manca [protein].
  static const proteinCrude = 25003;
  static const carbs = 31000;
  static const sugars = 32000;
  static const fat = 40000;
  static const saturatedFat = 40302;
  static const fiber = 34100;
  static const salt = 10004;
  static const sodium = 10110;

  static const all = {
    energyKcal,
    protein,
    proteinCrude,
    carbs,
    sugars,
    fat,
    saturatedFat,
    fiber,
    salt,
    sodium,
  };
}

final _element = RegExp(r'^\s*<(\w+)>(.*)</\1>\s*$');
final _empty = RegExp(r'^\s*<(\w+)(\s[^>]*)?/>\s*$');

String _decode(String text) => text
    .replaceAll('&lt;', '<')
    .replaceAll('&gt;', '>')
    .replaceAll('&quot;', '"')
    .replaceAll('&apos;', "'")
    .replaceAll('&amp;', '&')
    .trim();

/// Record `<[record]>…</[record]>` delle righe [lines], come mappa
/// elemento → testo (vuoto se `missing`). [keep] scarta subito i record che
/// non servono.
Future<List<Map<String, String>>> readCiqualRecords(
  Stream<String> lines,
  String record, {
  bool Function(Map<String, String>)? keep,
}) async {
  final open = '<$record>';
  final close = '</$record>';
  final out = <Map<String, String>>[];
  Map<String, String>? current;
  await for (var line in lines) {
    if (line.startsWith('﻿')) line = line.substring(1);
    final trimmed = line.trim();
    if (trimmed == open) {
      current = {};
    } else if (trimmed == close) {
      if (current != null && (keep == null || keep(current))) {
        out.add(current);
      }
      current = null;
    } else if (current != null) {
      final m = _element.firstMatch(line);
      if (m != null) {
        current[m.group(1)!] = _decode(m.group(2)!);
      } else if (_empty.firstMatch(line) case final e?) {
        current[e.group(1)!] = '';
      }
    }
  }
  return out;
}

Stream<String> _fileLines(File file) =>
    file.openRead().transform(utf8.decoder).transform(const LineSplitter());

/// Un valore di `teneur`, per 100 g:
/// - "-" o vuoto (non misurato) → `null`;
/// - "traces" → 0;
/// - "< x" (sotto il limite di quantificazione) → x / 2;
/// - numeri con la virgola decimale ("12,5").
double? parseCiqualValue(String raw) {
  final value = raw.trim();
  if (value.isEmpty || value == '-') return null;
  if (value.toLowerCase() == 'traces') return 0;
  if (value.startsWith('<')) {
    final limit = double.parse(value.substring(1).trim().replaceAll(',', '.'));
    return limit / 2;
  }
  return double.parse(value.replaceAll(',', '.'));
}

/// Gli alimenti CIQUAL [codes] dai file XML nella cartella [dir]. Kcal,
/// proteine, carboidrati e grassi sono obbligatori; sodio dal costituente
/// "Sodium" o, se manca, dal sale (sale / 2,5 × 1000 mg).
Future<List<FoodRecord>> loadCiqualFoods(Directory dir, Set<int> codes) async {
  if (codes.isEmpty) return const [];
  File find(String prefix) {
    final matches =
        dir
            .listSync()
            .whereType<File>()
            .where(
              (f) =>
                  f.uri.pathSegments.last.startsWith(prefix) &&
                  f.path.endsWith('.xml'),
            )
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path));
    if (matches.isEmpty) {
      throw FoodDbBuildException([
        'CIQUAL: file ${prefix}AAAA_MM_GG.xml assente in ${dir.path}',
      ]);
    }
    return matches.last;
  }

  int code(Map<String, String> r) => int.parse(r['alim_code']!);

  final alims = await readCiqualRecords(
    _fileLines(find('alim_2')),
    'ALIM',
    keep: (r) => codes.contains(code(r)),
  );
  final groups = await readCiqualRecords(
    _fileLines(find('alim_grp_')),
    'ALIM_GRP',
  );
  final subgroupNames = <String, String>{};
  final groupNames = <String, String>{};
  for (final g in groups) {
    final sub = g['alim_ssgrp_nom_eng'] ?? '';
    if (sub.isNotEmpty && sub != '-') {
      subgroupNames[g['alim_ssgrp_code'] ?? ''] = sub;
    }
    groupNames[g['alim_grp_code'] ?? ''] = g['alim_grp_nom_eng'] ?? '';
  }

  final compo = await readCiqualRecords(
    _fileLines(find('compo_')),
    'COMPO',
    keep: (r) =>
        codes.contains(code(r)) &&
        CiqualConst.all.contains(int.parse(r['const_code']!)),
  );
  final values = <int, Map<int, double?>>{};
  for (final c in compo) {
    values.putIfAbsent(code(c), () => {})[int.parse(c['const_code']!)] =
        parseCiqualValue(c['teneur'] ?? '');
  }

  final problems = <String>[];
  final foods = <FoodRecord>[];
  final found = {for (final a in alims) code(a): a};
  for (final alimCode in codes.toList()..sort()) {
    final alim = found[alimCode];
    if (alim == null) {
      problems.add('CIQUAL: alimento $alimCode inesistente');
      continue;
    }
    final v = values[alimCode] ?? const <int, double?>{};
    final kcal = v[CiqualConst.energyKcal];
    final protein = v[CiqualConst.protein] ?? v[CiqualConst.proteinCrude];
    final carbs = v[CiqualConst.carbs];
    final fat = v[CiqualConst.fat];
    if (kcal == null || protein == null || carbs == null || fat == null) {
      problems.add(
        'CIQUAL: alimento $alimCode senza kcal, proteine, carboidrati o '
        'grassi',
      );
      continue;
    }
    final salt = v[CiqualConst.salt];
    final category =
        subgroupNames[alim['alim_ssgrp_code'] ?? ''] ??
        groupNames[alim['alim_grp_code'] ?? ''];
    foods.add(
      FoodRecord(
        id: FoodDb.ciqualIdOffset + alimCode,
        source: FoodDb.sourceCiqual,
        sourceId: '$alimCode',
        nameEn: alim['alim_nom_eng'] ?? alim['alim_nom_fr'] ?? '$alimCode',
        category: category == null || category.isEmpty ? null : category,
        kcal: kcal,
        proteinG: protein,
        carbsG: carbs,
        fatG: fat,
        sugarsG: v[CiqualConst.sugars],
        saturatedFatG: v[CiqualConst.saturatedFat],
        fiberG: v[CiqualConst.fiber],
        sodiumMg:
            v[CiqualConst.sodium] ?? (salt == null ? null : salt / 2.5 * 1000),
      ),
    );
  }
  if (problems.isNotEmpty) throw FoodDbBuildException(problems);
  return foods;
}
