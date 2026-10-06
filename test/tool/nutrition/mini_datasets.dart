import 'dart:io';

/// Mini-dataset sintetici nel formato delle fonti vere (FoodData Central CSV,
/// CIQUAL XML), scritti in una cartella temporanea: niente download nei test.
class MiniDatasets {
  MiniDatasets._(this.root);

  final Directory root;

  Directory get sr => Directory('${root.path}/sr');
  Directory get foundation => Directory('${root.path}/foundation');
  Directory get ciqual => Directory('${root.path}/ciqual');

  static Future<MiniDatasets> create() async {
    final root = await Directory.systemTemp.createTemp('irenefy_food_db_');
    final d = MiniDatasets._(root);
    d._writeSr();
    d._writeFoundation();
    d._writeCiqual();
    return d;
  }

  void dispose() => root.deleteSync(recursive: true);

  static void _write(Directory dir, String name, String text) {
    dir.createSync(recursive: true);
    File('${dir.path}/$name').writeAsStringSync(text);
  }

  static String _csv(List<List<Object>> rows) =>
      '${rows.map((r) => r.map((c) => '"${'$c'.replaceAll('"', '""')}"').join(',')).join('\n')}\n';

  static const _categories = [
    ['id', 'code', 'description'],
    [1, '0100', 'Dairy and Egg Products'],
    [4, '0400', 'Fats and Oils'],
    [11, '1100', 'Vegetables and Vegetable Products'],
    [18, '1800', 'Baked Products'],
    [21, '2100', 'Fast Foods'],
  ];

  static const _units = [
    ['id', 'name'],
    [1000, 'cup'],
    [1001, 'tablespoon'],
    [1029, 'large'],
    [9999, 'undetermined'],
  ];

  /// `[fdc_id, nutrient_id, amount]`.
  static List<List<Object>> _nutrients(List<List<Object>> rows) => [
    ['id', 'fdc_id', 'nutrient_id', 'amount', 'data_points'],
    for (var i = 0; i < rows.length; i++) [i + 1, ...rows[i], ''],
  ];

  /// Gli 8 nutrienti "normali" di un alimento.
  static List<List<Object>> _full(
    int id, {
    required double kcal,
    double protein = 1,
    double carbs = 2,
    double fat = 3,
  }) => [
    [id, 1008, kcal],
    [id, 1003, protein],
    [id, 1005, carbs],
    [id, 1004, fat],
    [id, 2000, 0.5],
    [id, 1258, 0.25],
    [id, 1079, 1.5],
    [id, 1093, 10],
  ];

  void _writeSr() {
    _write(sr, 'food_category.csv', _csv(_categories));
    _write(sr, 'measure_unit.csv', _csv(_units));
    const type = 'sr_legacy_food';
    _write(
      sr,
      'food.csv',
      _csv([
        ['fdc_id', 'data_type', 'description', 'food_category_id', 'pub'],
        [100001, type, 'Egg, whole, raw, fresh', 1, ''],
        [100002, type, 'Fast foods, egg sandwich', 21, ''],
        [100003, type, 'Oil, olive, salad or cooking', 4, ''],
        [100004, type, 'Garlic, raw', 11, ''],
        [100005, type, 'Bread, white, KRAFT, sliced', 18, ''],
        [100006, type, 'Mystery food, without fat', 11, ''],
        [100007, type, 'Onions, raw', 11, ''],
        [100008, type, "Pears, raw (Includes USDA's Program)", 11, ''],
        [100009, type, 'Butter, salted', 1, ''],
      ]),
    );
    _write(
      sr,
      'food_nutrient.csv',
      _csv(
        _nutrients([
          ..._full(100001, kcal: 143, protein: 12.56),
          ..._full(100002, kcal: 250),
          ..._full(100003, kcal: 884, fat: 100),
          ..._full(100004, kcal: 149),
          ..._full(100005, kcal: 266),
          // Senza grassi: escluso.
          [100006, 1008, 10],
          [100006, 1003, 1],
          [100006, 1005, 1],
          // Solo i quattro obbligatori: incluso, gli altri NULL.
          [100007, 1008, 40],
          [100007, 1003, 1.1],
          [100007, 1005, 9.34],
          [100007, 1004, 0.1],
          ..._full(100008, kcal: 57),
          ..._full(100009, kcal: 717),
          // Nutriente non usato: ignorato.
          [100001, 1087, 56],
        ]),
      ),
    );
    _write(
      sr,
      'food_portion.csv',
      _csv([
        [
          'id',
          'fdc_id',
          'seq_num',
          'amount',
          'measure_unit_id',
          'portion_description',
          'modifier',
          'gram_weight',
        ],
        // Uovo: "large" prima di "medium"; "extra large" mai.
        [1, 100001, 1, 1, 9999, '', 'extra large', 56],
        [2, 100001, 2, 1, 9999, '', 'medium', 44],
        [3, 100001, 3, 1, 9999, '', 'large', 50],
        [4, 100001, 5, 1, 9999, '', 'cup (4.86 large eggs)', 243],
        // Olio: cucchiaio da 2 unità (grammi divisi), tazza, oncia ignorata.
        [5, 100003, 1, 2, 9999, '', 'tbsp', 27],
        [6, 100003, 2, 1, 9999, '', 'cup', 216],
        [7, 100003, 3, 1, 9999, '', 'oz', 28.35],
        // Aglio: spicchio (porzione unitaria), "3 cloves" ignorato.
        [8, 100004, 1, 1, 9999, '', 'cup', 136],
        [9, 100004, 2, 1, 9999, '', 'tsp', 2.8],
        [10, 100004, 3, 3, 9999, '', 'cloves', 9],
        [11, 100004, 4, 1, 9999, '', 'clove', 3],
        // Cipolla: "medium" prima di "large" e "small"; tazza: seq_num più
        // basso.
        [12, 100007, 1, 1, 9999, '', 'small', 70],
        [13, 100007, 2, 1, 9999, '', 'large', 150],
        [14, 100007, 3, 1, 9999, '', 'medium (2-1/2" dia)', 110],
        [15, 100007, 5, 1, 9999, '', 'cup, sliced', 115],
        [16, 100007, 4, 1, 9999, '', 'cup, chopped', 160],
        // Burro: un panetto ("stick") o una confezione non sono un pezzo.
        [17, 100009, 1, 1, 9999, '', 'stick', 113],
        [18, 100009, 2, 1, 9999, '', 'package', 227],
        [19, 100009, 3, 1, 9999, '', 'tbsp', 14.2],
      ]),
    );
  }

  void _writeFoundation() {
    _write(foundation, 'food_category.csv', _csv(_categories));
    _write(foundation, 'measure_unit.csv', _csv(_units));
    _write(
      foundation,
      'food.csv',
      _csv([
        ['fdc_id', 'data_type', 'description', 'food_category_id', 'pub'],
        [200001, 'foundation_food', 'Broccoli, raw', 11, ''],
        [200002, 'foundation_food', 'Carrots, raw', 11, ''],
        [200003, 'sample_food', 'BROCCOLI, SAMPLE', 11, ''],
        [200004, 'foundation_food', 'Eggs, Grade A, Large, egg whole', 1, ''],
      ]),
    );
    _write(
      foundation,
      'food_nutrient.csv',
      _csv(
        _nutrients([
          // kcal solo Atwater generale (2047), zuccheri solo 1063.
          [200001, 2047, 31],
          [200001, 2048, 39],
          [200001, 1003, 2.57],
          [200001, 1005, 6.27],
          [200001, 1004, 0.34],
          [200001, 1063, 1.4],
          [200001, 1258, 0.039],
          [200001, 1079, 2.4],
          [200001, 1093, 36],
          // Senza fibre: escluso da Foundation.
          [200002, 1008, 41],
          [200002, 1003, 0.9],
          [200002, 1005, 9.6],
          [200002, 1004, 0.2],
          [200002, 2000, 4.7],
          [200002, 1258, 0.03],
          [200002, 1093, 69],
          ..._full(200003, kcal: 30),
          ..._full(200004, kcal: 148),
        ]),
      ),
    );
    _write(
      foundation,
      'food_portion.csv',
      _csv([
        [
          'id',
          'fdc_id',
          'seq_num',
          'amount',
          'measure_unit_id',
          'portion_description',
          'modifier',
          'gram_weight',
        ],
        [1, 200001, '', 1, 1000, '', 'chopped', 91],
        // Porzione senza alimento (succede in Foundation): ignorata.
        [2, '', '', 1, 1000, '', '', 50],
        // Uovo: unità "large" nella colonna dell'unità di misura.
        [3, 200004, '', 1, 1029, '', '', 50.3],
      ]),
    );
  }

  void _writeCiqual() {
    const bom = '﻿';
    String alim(int code, String fr, String eng, String grp, String ssgrp) =>
        '   <ALIM>\r\n'
        '      <alim_code> $code </alim_code>\r\n'
        '      <alim_nom_fr> $fr </alim_nom_fr>\r\n'
        '      <alim_nom_eng> $eng </alim_nom_eng>\r\n'
        '      <alim_nom_sci missing=" " />\r\n'
        '      <alim_grp_code> $grp </alim_grp_code>\r\n'
        '      <alim_ssgrp_code> $ssgrp </alim_ssgrp_code>\r\n'
        '   </ALIM>\r\n';
    _write(
      ciqual,
      'alim_2025_11_03.xml',
      '$bom<?xml version="1.0" encoding="utf-8" ?>\r\n<TABLE>\r\n'
          '${alim(12122, 'Pecorino', 'Pecorino cheese, from ewe&apos;s milk', '05', '0502')}'
          '${alim(28503, 'Bresaola', 'Bresaola', '04', '0499')}'
          '${alim(1000, 'Pastis', 'Pastis', '06', '0603')}'
          '</TABLE>\r\n',
    );
    _write(
      ciqual,
      'alim_grp_2025_11_03.xml',
      '$bom<?xml version="1.0" encoding="utf-8" ?>\r\n<TABLE>\r\n'
          '   <ALIM_GRP>\r\n'
          '      <alim_grp_code> 05 </alim_grp_code>\r\n'
          '      <alim_grp_nom_eng> milk and milk products </alim_grp_nom_eng>\r\n'
          '      <alim_ssgrp_code> 0502 </alim_ssgrp_code>\r\n'
          '      <alim_ssgrp_nom_eng> cheese and similar </alim_ssgrp_nom_eng>\r\n'
          '   </ALIM_GRP>\r\n'
          '   <ALIM_GRP>\r\n'
          '      <alim_grp_code> 04 </alim_grp_code>\r\n'
          '      <alim_grp_nom_eng> meat, egg and fish </alim_grp_nom_eng>\r\n'
          '      <alim_ssgrp_code> 0499 </alim_ssgrp_code>\r\n'
          '      <alim_ssgrp_nom_eng> - </alim_ssgrp_nom_eng>\r\n'
          '   </ALIM_GRP>\r\n'
          '</TABLE>\r\n',
    );
    String compo(int code, int constant, String value) =>
        '   <COMPO>\r\n'
        '      <alim_code> $code </alim_code>\r\n'
        '      <const_code> $constant </const_code>\r\n'
        '      <teneur> $value </teneur>\r\n'
        '      <min missing=" " />\r\n'
        '   </COMPO>\r\n';
    _write(
      ciqual,
      'compo_2025_11_03.xml',
      '$bom<?xml version="1.0" encoding="utf-8" ?>\r\n<TABLE>\r\n'
          // Pecorino: sale e sodio, tracce di zuccheri, fibre "< 0,5".
          '${compo(12122, 328, '383')}'
          '${compo(12122, 25000, '25,5')}'
          '${compo(12122, 31000, '1')}'
          '${compo(12122, 32000, 'traces')}'
          '${compo(12122, 40000, '31')}'
          '${compo(12122, 40302, '22')}'
          '${compo(12122, 34100, '&lt; 0,5')}'
          '${compo(12122, 10004, '4,8')}'
          '${compo(12122, 10110, '1890')}'
          // Bresaola: solo il sale (sodio dal sale), saturi non misurati.
          '${compo(28503, 328, '172')}'
          '${compo(28503, 25000, '32,8')}'
          '${compo(28503, 31000, '0,49')}'
          '${compo(28503, 40000, '4,3')}'
          '${compo(28503, 40302, '-')}'
          '${compo(28503, 10004, '5,15')}'
          // Costituente non usato e alimento non citato: ignorati.
          '${compo(28503, 51330, '12')}'
          '${compo(1000, 328, '274')}'
          '</TABLE>\r\n',
    );
  }
}

/// Tabella curata dei test.
const curatedHeader =
    'aliases_en,name_it,aliases_it,source,source_id,piece_g,note';

const miniCurated =
    '$curatedHeader\n'
    'egg|Whole  Egg|eggs,Uovo,uova|uovo intero,usda_sr,100001,,\n'
    'olive oil|extra virgin olive oil,Olio extravergine d’oliva,'
    '"Olio d’Oliva|olio evo",usda_sr,100003,,"Olio, generico"\n'
    'garlic,Aglio,spicchio d\'aglio,usda_sr,100004,4,Spicchio grande\n'
    'broccoli,Broccoli,broccolo,usda_foundation,200001,,\n'
    'pecorino,Pecorino,pecorino romano,ciqual,12122,,\n'
    'bresaola,Bresaola,,ciqual,28503,,\n';

const manualHeader =
    'id,key,name_en,name_it,kcal,protein_g,carbs_g,sugars_g,fat_g,'
    'saturated_fat_g,fiber_g,sodium_mg,density_g_per_ml,sources,note';

const miniManual =
    '$manualHeader\n'
    '1,guanciale,Guanciale (cured pork cheek),Guanciale,600,10.5,0.5,0.2,62,'
    '22.5,0,1200,,"Etichette: A, B",grassi variabili\n'
    '2,glassa_balsamica,Balsamic glaze,Glassa di aceto balsamico,220,1,52,,0,'
    '0,,40,1.25,Etichette,\n';
