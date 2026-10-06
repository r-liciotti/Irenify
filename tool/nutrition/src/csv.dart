/// Lettore CSV minimo (RFC 4180): separatore `,`, virgolette doppie per i
/// campi con virgole, a capo o virgolette (raddoppiate). Basta per i CSV di
/// FoodData Central e per la tabella curata.
library;

import 'dart:io';

/// Righe del testo, intestazione compresa. Righe vuote ignorate.
List<List<String>> parseCsv(String text) {
  final rows = <List<String>>[];
  var row = <String>[];
  final field = StringBuffer();
  var quoted = false;
  var i = 0;
  // BOM UTF-8 iniziale.
  if (text.startsWith('﻿')) i = 1;
  void endField() {
    row.add(field.toString());
    field.clear();
  }

  void endRow() {
    endField();
    if (!(row.length == 1 && row.first.isEmpty)) rows.add(row);
    row = <String>[];
  }

  const quote = 0x22, comma = 0x2C, newline = 0x0A, cr = 0x0D;
  final length = text.length;
  while (i < length) {
    final c = text.codeUnitAt(i);
    if (quoted) {
      if (c == quote) {
        if (i + 1 < length && text.codeUnitAt(i + 1) == quote) {
          field.writeCharCode(quote);
          i += 2;
          continue;
        }
        quoted = false;
      } else {
        field.writeCharCode(c);
      }
    } else if (c == quote) {
      quoted = true;
    } else if (c == comma) {
      endField();
    } else if (c == newline) {
      endRow();
    } else if (c != cr) {
      field.writeCharCode(c);
    }
    i++;
  }
  if (field.isNotEmpty || row.isNotEmpty) endRow();
  return rows;
}

/// Un CSV con intestazione: ogni riga come mappa colonna → valore.
class CsvTable {
  CsvTable(this.header, this.rows);

  factory CsvTable.parse(String text) {
    final all = parseCsv(text);
    if (all.isEmpty) return CsvTable(const [], const []);
    return CsvTable(all.first, all.sublist(1));
  }

  static CsvTable read(File file) => CsvTable.parse(file.readAsStringSync());

  final List<String> header;
  final List<List<String>> rows;

  late final Map<String, int> _index = {
    for (var i = 0; i < header.length; i++) header[i]: i,
  };

  int column(String name) {
    final index = _index[name];
    if (index == null) {
      throw FormatException('Colonna "$name" assente: $header');
    }
    return index;
  }

  /// Valore della colonna [index] della riga, vuoto se la riga è corta.
  static String cell(List<String> row, int index) =>
      index < row.length ? row[index] : '';
}
