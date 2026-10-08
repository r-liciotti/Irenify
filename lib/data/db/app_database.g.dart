// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class RecipeSearch extends Table
    with
        TableInfo<RecipeSearch, RecipeSearchData>,
        VirtualTableInfo<RecipeSearch, RecipeSearchData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  RecipeSearch(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _recipeIdMeta = const VerificationMeta(
    'recipeId',
  );
  late final GeneratedColumn<String> recipeId = GeneratedColumn<String>(
    'recipe_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: '',
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: '',
  );
  static const VerificationMeta _ingredientsMeta = const VerificationMeta(
    'ingredients',
  );
  late final GeneratedColumn<String> ingredients = GeneratedColumn<String>(
    'ingredients',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: '',
  );
  static const VerificationMeta _tagsMeta = const VerificationMeta('tags');
  late final GeneratedColumn<String> tags = GeneratedColumn<String>(
    'tags',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: '',
  );
  static const VerificationMeta _authorMeta = const VerificationMeta('author');
  late final GeneratedColumn<String> author = GeneratedColumn<String>(
    'author',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: '',
  );
  @override
  List<GeneratedColumn> get $columns => [
    recipeId,
    title,
    ingredients,
    tags,
    author,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'recipe_search';
  @override
  VerificationContext validateIntegrity(
    Insertable<RecipeSearchData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('recipe_id')) {
      context.handle(
        _recipeIdMeta,
        recipeId.isAcceptableOrUnknown(data['recipe_id']!, _recipeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_recipeIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('ingredients')) {
      context.handle(
        _ingredientsMeta,
        ingredients.isAcceptableOrUnknown(
          data['ingredients']!,
          _ingredientsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_ingredientsMeta);
    }
    if (data.containsKey('tags')) {
      context.handle(
        _tagsMeta,
        tags.isAcceptableOrUnknown(data['tags']!, _tagsMeta),
      );
    } else if (isInserting) {
      context.missing(_tagsMeta);
    }
    if (data.containsKey('author')) {
      context.handle(
        _authorMeta,
        author.isAcceptableOrUnknown(data['author']!, _authorMeta),
      );
    } else if (isInserting) {
      context.missing(_authorMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => const {};
  @override
  RecipeSearchData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RecipeSearchData(
      recipeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recipe_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      ingredients: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ingredients'],
      )!,
      tags: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tags'],
      )!,
      author: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}author'],
      )!,
    );
  }

  @override
  RecipeSearch createAlias(String alias) {
    return RecipeSearch(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
  @override
  String get moduleAndArgs =>
      'fts5(recipe_id UNINDEXED, title, ingredients, tags, author, tokenize = \'unicode61 remove_diacritics 2\')';
}

class RecipeSearchData extends DataClass
    implements Insertable<RecipeSearchData> {
  final String recipeId;
  final String title;
  final String ingredients;
  final String tags;
  final String author;
  const RecipeSearchData({
    required this.recipeId,
    required this.title,
    required this.ingredients,
    required this.tags,
    required this.author,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['recipe_id'] = Variable<String>(recipeId);
    map['title'] = Variable<String>(title);
    map['ingredients'] = Variable<String>(ingredients);
    map['tags'] = Variable<String>(tags);
    map['author'] = Variable<String>(author);
    return map;
  }

  RecipeSearchCompanion toCompanion(bool nullToAbsent) {
    return RecipeSearchCompanion(
      recipeId: Value(recipeId),
      title: Value(title),
      ingredients: Value(ingredients),
      tags: Value(tags),
      author: Value(author),
    );
  }

  factory RecipeSearchData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RecipeSearchData(
      recipeId: serializer.fromJson<String>(json['recipe_id']),
      title: serializer.fromJson<String>(json['title']),
      ingredients: serializer.fromJson<String>(json['ingredients']),
      tags: serializer.fromJson<String>(json['tags']),
      author: serializer.fromJson<String>(json['author']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'recipe_id': serializer.toJson<String>(recipeId),
      'title': serializer.toJson<String>(title),
      'ingredients': serializer.toJson<String>(ingredients),
      'tags': serializer.toJson<String>(tags),
      'author': serializer.toJson<String>(author),
    };
  }

  RecipeSearchData copyWith({
    String? recipeId,
    String? title,
    String? ingredients,
    String? tags,
    String? author,
  }) => RecipeSearchData(
    recipeId: recipeId ?? this.recipeId,
    title: title ?? this.title,
    ingredients: ingredients ?? this.ingredients,
    tags: tags ?? this.tags,
    author: author ?? this.author,
  );
  RecipeSearchData copyWithCompanion(RecipeSearchCompanion data) {
    return RecipeSearchData(
      recipeId: data.recipeId.present ? data.recipeId.value : this.recipeId,
      title: data.title.present ? data.title.value : this.title,
      ingredients: data.ingredients.present
          ? data.ingredients.value
          : this.ingredients,
      tags: data.tags.present ? data.tags.value : this.tags,
      author: data.author.present ? data.author.value : this.author,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RecipeSearchData(')
          ..write('recipeId: $recipeId, ')
          ..write('title: $title, ')
          ..write('ingredients: $ingredients, ')
          ..write('tags: $tags, ')
          ..write('author: $author')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(recipeId, title, ingredients, tags, author);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RecipeSearchData &&
          other.recipeId == this.recipeId &&
          other.title == this.title &&
          other.ingredients == this.ingredients &&
          other.tags == this.tags &&
          other.author == this.author);
}

class RecipeSearchCompanion extends UpdateCompanion<RecipeSearchData> {
  final Value<String> recipeId;
  final Value<String> title;
  final Value<String> ingredients;
  final Value<String> tags;
  final Value<String> author;
  final Value<int> rowid;
  const RecipeSearchCompanion({
    this.recipeId = const Value.absent(),
    this.title = const Value.absent(),
    this.ingredients = const Value.absent(),
    this.tags = const Value.absent(),
    this.author = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RecipeSearchCompanion.insert({
    required String recipeId,
    required String title,
    required String ingredients,
    required String tags,
    required String author,
    this.rowid = const Value.absent(),
  }) : recipeId = Value(recipeId),
       title = Value(title),
       ingredients = Value(ingredients),
       tags = Value(tags),
       author = Value(author);
  static Insertable<RecipeSearchData> custom({
    Expression<String>? recipeId,
    Expression<String>? title,
    Expression<String>? ingredients,
    Expression<String>? tags,
    Expression<String>? author,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (recipeId != null) 'recipe_id': recipeId,
      if (title != null) 'title': title,
      if (ingredients != null) 'ingredients': ingredients,
      if (tags != null) 'tags': tags,
      if (author != null) 'author': author,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RecipeSearchCompanion copyWith({
    Value<String>? recipeId,
    Value<String>? title,
    Value<String>? ingredients,
    Value<String>? tags,
    Value<String>? author,
    Value<int>? rowid,
  }) {
    return RecipeSearchCompanion(
      recipeId: recipeId ?? this.recipeId,
      title: title ?? this.title,
      ingredients: ingredients ?? this.ingredients,
      tags: tags ?? this.tags,
      author: author ?? this.author,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (recipeId.present) {
      map['recipe_id'] = Variable<String>(recipeId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (ingredients.present) {
      map['ingredients'] = Variable<String>(ingredients.value);
    }
    if (tags.present) {
      map['tags'] = Variable<String>(tags.value);
    }
    if (author.present) {
      map['author'] = Variable<String>(author.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RecipeSearchCompanion(')
          ..write('recipeId: $recipeId, ')
          ..write('title: $title, ')
          ..write('ingredients: $ingredients, ')
          ..write('tags: $tags, ')
          ..write('author: $author, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RecipesTable extends Recipes with TableInfo<$RecipesTable, RecipeRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RecipesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _baseServingsMeta = const VerificationMeta(
    'baseServings',
  );
  @override
  late final GeneratedColumn<double> baseServings = GeneratedColumn<double>(
    'base_servings',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _servingsUnitMeta = const VerificationMeta(
    'servingsUnit',
  );
  @override
  late final GeneratedColumn<String> servingsUnit = GeneratedColumn<String>(
    'servings_unit',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('persone'),
  );
  static const VerificationMeta _prepMinutesMeta = const VerificationMeta(
    'prepMinutes',
  );
  @override
  late final GeneratedColumn<int> prepMinutes = GeneratedColumn<int>(
    'prep_minutes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cookMinutesMeta = const VerificationMeta(
    'cookMinutes',
  );
  @override
  late final GeneratedColumn<int> cookMinutes = GeneratedColumn<int>(
    'cook_minutes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _restMinutesMeta = const VerificationMeta(
    'restMinutes',
  );
  @override
  late final GeneratedColumn<int> restMinutes = GeneratedColumn<int>(
    'rest_minutes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<Difficulty?, String> difficulty =
      GeneratedColumn<String>(
        'difficulty',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<Difficulty?>($RecipesTable.$converterdifficultyn);
  static const VerificationMeta _thumbnailPathMeta = const VerificationMeta(
    'thumbnailPath',
  );
  @override
  late final GeneratedColumn<String> thumbnailPath = GeneratedColumn<String>(
    'thumbnail_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isFavoriteMeta = const VerificationMeta(
    'isFavorite',
  );
  @override
  late final GeneratedColumn<bool> isFavorite = GeneratedColumn<bool>(
    'is_favorite',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_favorite" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _extractionModelMeta = const VerificationMeta(
    'extractionModel',
  );
  @override
  late final GeneratedColumn<String> extractionModel = GeneratedColumn<String>(
    'extraction_model',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _needsReviewMeta = const VerificationMeta(
    'needsReview',
  );
  @override
  late final GeneratedColumn<bool> needsReview = GeneratedColumn<bool>(
    'needs_review',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("needs_review" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isDraftMeta = const VerificationMeta(
    'isDraft',
  );
  @override
  late final GeneratedColumn<bool> isDraft = GeneratedColumn<bool>(
    'is_draft',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_draft" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    description,
    baseServings,
    servingsUnit,
    prepMinutes,
    cookMinutes,
    restMinutes,
    difficulty,
    thumbnailPath,
    isFavorite,
    extractionModel,
    needsReview,
    isDraft,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'recipes';
  @override
  VerificationContext validateIntegrity(
    Insertable<RecipeRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('base_servings')) {
      context.handle(
        _baseServingsMeta,
        baseServings.isAcceptableOrUnknown(
          data['base_servings']!,
          _baseServingsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_baseServingsMeta);
    }
    if (data.containsKey('servings_unit')) {
      context.handle(
        _servingsUnitMeta,
        servingsUnit.isAcceptableOrUnknown(
          data['servings_unit']!,
          _servingsUnitMeta,
        ),
      );
    }
    if (data.containsKey('prep_minutes')) {
      context.handle(
        _prepMinutesMeta,
        prepMinutes.isAcceptableOrUnknown(
          data['prep_minutes']!,
          _prepMinutesMeta,
        ),
      );
    }
    if (data.containsKey('cook_minutes')) {
      context.handle(
        _cookMinutesMeta,
        cookMinutes.isAcceptableOrUnknown(
          data['cook_minutes']!,
          _cookMinutesMeta,
        ),
      );
    }
    if (data.containsKey('rest_minutes')) {
      context.handle(
        _restMinutesMeta,
        restMinutes.isAcceptableOrUnknown(
          data['rest_minutes']!,
          _restMinutesMeta,
        ),
      );
    }
    if (data.containsKey('thumbnail_path')) {
      context.handle(
        _thumbnailPathMeta,
        thumbnailPath.isAcceptableOrUnknown(
          data['thumbnail_path']!,
          _thumbnailPathMeta,
        ),
      );
    }
    if (data.containsKey('is_favorite')) {
      context.handle(
        _isFavoriteMeta,
        isFavorite.isAcceptableOrUnknown(data['is_favorite']!, _isFavoriteMeta),
      );
    }
    if (data.containsKey('extraction_model')) {
      context.handle(
        _extractionModelMeta,
        extractionModel.isAcceptableOrUnknown(
          data['extraction_model']!,
          _extractionModelMeta,
        ),
      );
    }
    if (data.containsKey('needs_review')) {
      context.handle(
        _needsReviewMeta,
        needsReview.isAcceptableOrUnknown(
          data['needs_review']!,
          _needsReviewMeta,
        ),
      );
    }
    if (data.containsKey('is_draft')) {
      context.handle(
        _isDraftMeta,
        isDraft.isAcceptableOrUnknown(data['is_draft']!, _isDraftMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RecipeRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RecipeRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      baseServings: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}base_servings'],
      )!,
      servingsUnit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}servings_unit'],
      )!,
      prepMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}prep_minutes'],
      ),
      cookMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cook_minutes'],
      ),
      restMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rest_minutes'],
      ),
      difficulty: $RecipesTable.$converterdifficultyn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}difficulty'],
        ),
      ),
      thumbnailPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}thumbnail_path'],
      ),
      isFavorite: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_favorite'],
      )!,
      extractionModel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}extraction_model'],
      ),
      needsReview: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}needs_review'],
      )!,
      isDraft: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_draft'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $RecipesTable createAlias(String alias) {
    return $RecipesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<Difficulty, String, String> $converterdifficulty =
      const EnumNameConverter<Difficulty>(Difficulty.values);
  static JsonTypeConverter2<Difficulty?, String?, String?>
  $converterdifficultyn = JsonTypeConverter2.asNullable($converterdifficulty);
}

class RecipeRow extends DataClass implements Insertable<RecipeRow> {
  final String id;
  final String title;
  final String? description;
  final double baseServings;
  final String servingsUnit;
  final int? prepMinutes;
  final int? cookMinutes;
  final int? restMinutes;
  final Difficulty? difficulty;
  final String? thumbnailPath;
  final bool isFavorite;
  final String? extractionModel;
  final bool needsReview;

  /// Ricetta in bozza (D-62, schema v3): Gemini non era disponibile, ci sono
  /// solo titolo provvisorio, fonte (didascalia e trascrizione) e miniatura.
  final bool isDraft;
  final DateTime createdAt;
  final DateTime updatedAt;
  const RecipeRow({
    required this.id,
    required this.title,
    this.description,
    required this.baseServings,
    required this.servingsUnit,
    this.prepMinutes,
    this.cookMinutes,
    this.restMinutes,
    this.difficulty,
    this.thumbnailPath,
    required this.isFavorite,
    this.extractionModel,
    required this.needsReview,
    required this.isDraft,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['base_servings'] = Variable<double>(baseServings);
    map['servings_unit'] = Variable<String>(servingsUnit);
    if (!nullToAbsent || prepMinutes != null) {
      map['prep_minutes'] = Variable<int>(prepMinutes);
    }
    if (!nullToAbsent || cookMinutes != null) {
      map['cook_minutes'] = Variable<int>(cookMinutes);
    }
    if (!nullToAbsent || restMinutes != null) {
      map['rest_minutes'] = Variable<int>(restMinutes);
    }
    if (!nullToAbsent || difficulty != null) {
      map['difficulty'] = Variable<String>(
        $RecipesTable.$converterdifficultyn.toSql(difficulty),
      );
    }
    if (!nullToAbsent || thumbnailPath != null) {
      map['thumbnail_path'] = Variable<String>(thumbnailPath);
    }
    map['is_favorite'] = Variable<bool>(isFavorite);
    if (!nullToAbsent || extractionModel != null) {
      map['extraction_model'] = Variable<String>(extractionModel);
    }
    map['needs_review'] = Variable<bool>(needsReview);
    map['is_draft'] = Variable<bool>(isDraft);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  RecipesCompanion toCompanion(bool nullToAbsent) {
    return RecipesCompanion(
      id: Value(id),
      title: Value(title),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      baseServings: Value(baseServings),
      servingsUnit: Value(servingsUnit),
      prepMinutes: prepMinutes == null && nullToAbsent
          ? const Value.absent()
          : Value(prepMinutes),
      cookMinutes: cookMinutes == null && nullToAbsent
          ? const Value.absent()
          : Value(cookMinutes),
      restMinutes: restMinutes == null && nullToAbsent
          ? const Value.absent()
          : Value(restMinutes),
      difficulty: difficulty == null && nullToAbsent
          ? const Value.absent()
          : Value(difficulty),
      thumbnailPath: thumbnailPath == null && nullToAbsent
          ? const Value.absent()
          : Value(thumbnailPath),
      isFavorite: Value(isFavorite),
      extractionModel: extractionModel == null && nullToAbsent
          ? const Value.absent()
          : Value(extractionModel),
      needsReview: Value(needsReview),
      isDraft: Value(isDraft),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory RecipeRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RecipeRow(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String?>(json['description']),
      baseServings: serializer.fromJson<double>(json['baseServings']),
      servingsUnit: serializer.fromJson<String>(json['servingsUnit']),
      prepMinutes: serializer.fromJson<int?>(json['prepMinutes']),
      cookMinutes: serializer.fromJson<int?>(json['cookMinutes']),
      restMinutes: serializer.fromJson<int?>(json['restMinutes']),
      difficulty: $RecipesTable.$converterdifficultyn.fromJson(
        serializer.fromJson<String?>(json['difficulty']),
      ),
      thumbnailPath: serializer.fromJson<String?>(json['thumbnailPath']),
      isFavorite: serializer.fromJson<bool>(json['isFavorite']),
      extractionModel: serializer.fromJson<String?>(json['extractionModel']),
      needsReview: serializer.fromJson<bool>(json['needsReview']),
      isDraft: serializer.fromJson<bool>(json['isDraft']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String?>(description),
      'baseServings': serializer.toJson<double>(baseServings),
      'servingsUnit': serializer.toJson<String>(servingsUnit),
      'prepMinutes': serializer.toJson<int?>(prepMinutes),
      'cookMinutes': serializer.toJson<int?>(cookMinutes),
      'restMinutes': serializer.toJson<int?>(restMinutes),
      'difficulty': serializer.toJson<String?>(
        $RecipesTable.$converterdifficultyn.toJson(difficulty),
      ),
      'thumbnailPath': serializer.toJson<String?>(thumbnailPath),
      'isFavorite': serializer.toJson<bool>(isFavorite),
      'extractionModel': serializer.toJson<String?>(extractionModel),
      'needsReview': serializer.toJson<bool>(needsReview),
      'isDraft': serializer.toJson<bool>(isDraft),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  RecipeRow copyWith({
    String? id,
    String? title,
    Value<String?> description = const Value.absent(),
    double? baseServings,
    String? servingsUnit,
    Value<int?> prepMinutes = const Value.absent(),
    Value<int?> cookMinutes = const Value.absent(),
    Value<int?> restMinutes = const Value.absent(),
    Value<Difficulty?> difficulty = const Value.absent(),
    Value<String?> thumbnailPath = const Value.absent(),
    bool? isFavorite,
    Value<String?> extractionModel = const Value.absent(),
    bool? needsReview,
    bool? isDraft,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => RecipeRow(
    id: id ?? this.id,
    title: title ?? this.title,
    description: description.present ? description.value : this.description,
    baseServings: baseServings ?? this.baseServings,
    servingsUnit: servingsUnit ?? this.servingsUnit,
    prepMinutes: prepMinutes.present ? prepMinutes.value : this.prepMinutes,
    cookMinutes: cookMinutes.present ? cookMinutes.value : this.cookMinutes,
    restMinutes: restMinutes.present ? restMinutes.value : this.restMinutes,
    difficulty: difficulty.present ? difficulty.value : this.difficulty,
    thumbnailPath: thumbnailPath.present
        ? thumbnailPath.value
        : this.thumbnailPath,
    isFavorite: isFavorite ?? this.isFavorite,
    extractionModel: extractionModel.present
        ? extractionModel.value
        : this.extractionModel,
    needsReview: needsReview ?? this.needsReview,
    isDraft: isDraft ?? this.isDraft,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  RecipeRow copyWithCompanion(RecipesCompanion data) {
    return RecipeRow(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      description: data.description.present
          ? data.description.value
          : this.description,
      baseServings: data.baseServings.present
          ? data.baseServings.value
          : this.baseServings,
      servingsUnit: data.servingsUnit.present
          ? data.servingsUnit.value
          : this.servingsUnit,
      prepMinutes: data.prepMinutes.present
          ? data.prepMinutes.value
          : this.prepMinutes,
      cookMinutes: data.cookMinutes.present
          ? data.cookMinutes.value
          : this.cookMinutes,
      restMinutes: data.restMinutes.present
          ? data.restMinutes.value
          : this.restMinutes,
      difficulty: data.difficulty.present
          ? data.difficulty.value
          : this.difficulty,
      thumbnailPath: data.thumbnailPath.present
          ? data.thumbnailPath.value
          : this.thumbnailPath,
      isFavorite: data.isFavorite.present
          ? data.isFavorite.value
          : this.isFavorite,
      extractionModel: data.extractionModel.present
          ? data.extractionModel.value
          : this.extractionModel,
      needsReview: data.needsReview.present
          ? data.needsReview.value
          : this.needsReview,
      isDraft: data.isDraft.present ? data.isDraft.value : this.isDraft,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RecipeRow(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('baseServings: $baseServings, ')
          ..write('servingsUnit: $servingsUnit, ')
          ..write('prepMinutes: $prepMinutes, ')
          ..write('cookMinutes: $cookMinutes, ')
          ..write('restMinutes: $restMinutes, ')
          ..write('difficulty: $difficulty, ')
          ..write('thumbnailPath: $thumbnailPath, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('extractionModel: $extractionModel, ')
          ..write('needsReview: $needsReview, ')
          ..write('isDraft: $isDraft, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    description,
    baseServings,
    servingsUnit,
    prepMinutes,
    cookMinutes,
    restMinutes,
    difficulty,
    thumbnailPath,
    isFavorite,
    extractionModel,
    needsReview,
    isDraft,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RecipeRow &&
          other.id == this.id &&
          other.title == this.title &&
          other.description == this.description &&
          other.baseServings == this.baseServings &&
          other.servingsUnit == this.servingsUnit &&
          other.prepMinutes == this.prepMinutes &&
          other.cookMinutes == this.cookMinutes &&
          other.restMinutes == this.restMinutes &&
          other.difficulty == this.difficulty &&
          other.thumbnailPath == this.thumbnailPath &&
          other.isFavorite == this.isFavorite &&
          other.extractionModel == this.extractionModel &&
          other.needsReview == this.needsReview &&
          other.isDraft == this.isDraft &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class RecipesCompanion extends UpdateCompanion<RecipeRow> {
  final Value<String> id;
  final Value<String> title;
  final Value<String?> description;
  final Value<double> baseServings;
  final Value<String> servingsUnit;
  final Value<int?> prepMinutes;
  final Value<int?> cookMinutes;
  final Value<int?> restMinutes;
  final Value<Difficulty?> difficulty;
  final Value<String?> thumbnailPath;
  final Value<bool> isFavorite;
  final Value<String?> extractionModel;
  final Value<bool> needsReview;
  final Value<bool> isDraft;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const RecipesCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.baseServings = const Value.absent(),
    this.servingsUnit = const Value.absent(),
    this.prepMinutes = const Value.absent(),
    this.cookMinutes = const Value.absent(),
    this.restMinutes = const Value.absent(),
    this.difficulty = const Value.absent(),
    this.thumbnailPath = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.extractionModel = const Value.absent(),
    this.needsReview = const Value.absent(),
    this.isDraft = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RecipesCompanion.insert({
    required String id,
    required String title,
    this.description = const Value.absent(),
    required double baseServings,
    this.servingsUnit = const Value.absent(),
    this.prepMinutes = const Value.absent(),
    this.cookMinutes = const Value.absent(),
    this.restMinutes = const Value.absent(),
    this.difficulty = const Value.absent(),
    this.thumbnailPath = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.extractionModel = const Value.absent(),
    this.needsReview = const Value.absent(),
    this.isDraft = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       baseServings = Value(baseServings),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<RecipeRow> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? description,
    Expression<double>? baseServings,
    Expression<String>? servingsUnit,
    Expression<int>? prepMinutes,
    Expression<int>? cookMinutes,
    Expression<int>? restMinutes,
    Expression<String>? difficulty,
    Expression<String>? thumbnailPath,
    Expression<bool>? isFavorite,
    Expression<String>? extractionModel,
    Expression<bool>? needsReview,
    Expression<bool>? isDraft,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (baseServings != null) 'base_servings': baseServings,
      if (servingsUnit != null) 'servings_unit': servingsUnit,
      if (prepMinutes != null) 'prep_minutes': prepMinutes,
      if (cookMinutes != null) 'cook_minutes': cookMinutes,
      if (restMinutes != null) 'rest_minutes': restMinutes,
      if (difficulty != null) 'difficulty': difficulty,
      if (thumbnailPath != null) 'thumbnail_path': thumbnailPath,
      if (isFavorite != null) 'is_favorite': isFavorite,
      if (extractionModel != null) 'extraction_model': extractionModel,
      if (needsReview != null) 'needs_review': needsReview,
      if (isDraft != null) 'is_draft': isDraft,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RecipesCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<String?>? description,
    Value<double>? baseServings,
    Value<String>? servingsUnit,
    Value<int?>? prepMinutes,
    Value<int?>? cookMinutes,
    Value<int?>? restMinutes,
    Value<Difficulty?>? difficulty,
    Value<String?>? thumbnailPath,
    Value<bool>? isFavorite,
    Value<String?>? extractionModel,
    Value<bool>? needsReview,
    Value<bool>? isDraft,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return RecipesCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      baseServings: baseServings ?? this.baseServings,
      servingsUnit: servingsUnit ?? this.servingsUnit,
      prepMinutes: prepMinutes ?? this.prepMinutes,
      cookMinutes: cookMinutes ?? this.cookMinutes,
      restMinutes: restMinutes ?? this.restMinutes,
      difficulty: difficulty ?? this.difficulty,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      isFavorite: isFavorite ?? this.isFavorite,
      extractionModel: extractionModel ?? this.extractionModel,
      needsReview: needsReview ?? this.needsReview,
      isDraft: isDraft ?? this.isDraft,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (baseServings.present) {
      map['base_servings'] = Variable<double>(baseServings.value);
    }
    if (servingsUnit.present) {
      map['servings_unit'] = Variable<String>(servingsUnit.value);
    }
    if (prepMinutes.present) {
      map['prep_minutes'] = Variable<int>(prepMinutes.value);
    }
    if (cookMinutes.present) {
      map['cook_minutes'] = Variable<int>(cookMinutes.value);
    }
    if (restMinutes.present) {
      map['rest_minutes'] = Variable<int>(restMinutes.value);
    }
    if (difficulty.present) {
      map['difficulty'] = Variable<String>(
        $RecipesTable.$converterdifficultyn.toSql(difficulty.value),
      );
    }
    if (thumbnailPath.present) {
      map['thumbnail_path'] = Variable<String>(thumbnailPath.value);
    }
    if (isFavorite.present) {
      map['is_favorite'] = Variable<bool>(isFavorite.value);
    }
    if (extractionModel.present) {
      map['extraction_model'] = Variable<String>(extractionModel.value);
    }
    if (needsReview.present) {
      map['needs_review'] = Variable<bool>(needsReview.value);
    }
    if (isDraft.present) {
      map['is_draft'] = Variable<bool>(isDraft.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RecipesCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('baseServings: $baseServings, ')
          ..write('servingsUnit: $servingsUnit, ')
          ..write('prepMinutes: $prepMinutes, ')
          ..write('cookMinutes: $cookMinutes, ')
          ..write('restMinutes: $restMinutes, ')
          ..write('difficulty: $difficulty, ')
          ..write('thumbnailPath: $thumbnailPath, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('extractionModel: $extractionModel, ')
          ..write('needsReview: $needsReview, ')
          ..write('isDraft: $isDraft, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RecipeSourcesTable extends RecipeSources
    with TableInfo<$RecipeSourcesTable, RecipeSourceRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RecipeSourcesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _recipeIdMeta = const VerificationMeta(
    'recipeId',
  );
  @override
  late final GeneratedColumn<String> recipeId = GeneratedColumn<String>(
    'recipe_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES recipes (id) ON DELETE CASCADE',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<SourcePlatform, String> platform =
      GeneratedColumn<String>(
        'platform',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<SourcePlatform>($RecipeSourcesTable.$converterplatform);
  static const VerificationMeta _urlMeta = const VerificationMeta('url');
  @override
  late final GeneratedColumn<String> url = GeneratedColumn<String>(
    'url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceKeyMeta = const VerificationMeta(
    'sourceKey',
  );
  @override
  late final GeneratedColumn<String> sourceKey = GeneratedColumn<String>(
    'source_key',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _authorNameMeta = const VerificationMeta(
    'authorName',
  );
  @override
  late final GeneratedColumn<String> authorName = GeneratedColumn<String>(
    'author_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _captionMeta = const VerificationMeta(
    'caption',
  );
  @override
  late final GeneratedColumn<String> caption = GeneratedColumn<String>(
    'caption',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _transcriptMeta = const VerificationMeta(
    'transcript',
  );
  @override
  late final GeneratedColumn<String> transcript = GeneratedColumn<String>(
    'transcript',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<TranscriptQuality, String>
  transcriptQuality =
      GeneratedColumn<String>(
        'transcript_quality',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<TranscriptQuality>(
        $RecipeSourcesTable.$convertertranscriptQuality,
      );
  @override
  List<GeneratedColumn> get $columns => [
    recipeId,
    platform,
    url,
    sourceKey,
    authorName,
    caption,
    transcript,
    transcriptQuality,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'recipe_sources';
  @override
  VerificationContext validateIntegrity(
    Insertable<RecipeSourceRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('recipe_id')) {
      context.handle(
        _recipeIdMeta,
        recipeId.isAcceptableOrUnknown(data['recipe_id']!, _recipeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_recipeIdMeta);
    }
    if (data.containsKey('url')) {
      context.handle(
        _urlMeta,
        url.isAcceptableOrUnknown(data['url']!, _urlMeta),
      );
    }
    if (data.containsKey('source_key')) {
      context.handle(
        _sourceKeyMeta,
        sourceKey.isAcceptableOrUnknown(data['source_key']!, _sourceKeyMeta),
      );
    }
    if (data.containsKey('author_name')) {
      context.handle(
        _authorNameMeta,
        authorName.isAcceptableOrUnknown(data['author_name']!, _authorNameMeta),
      );
    }
    if (data.containsKey('caption')) {
      context.handle(
        _captionMeta,
        caption.isAcceptableOrUnknown(data['caption']!, _captionMeta),
      );
    }
    if (data.containsKey('transcript')) {
      context.handle(
        _transcriptMeta,
        transcript.isAcceptableOrUnknown(data['transcript']!, _transcriptMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {recipeId};
  @override
  RecipeSourceRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RecipeSourceRow(
      recipeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recipe_id'],
      )!,
      platform: $RecipeSourcesTable.$converterplatform.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}platform'],
        )!,
      ),
      url: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}url'],
      ),
      sourceKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_key'],
      ),
      authorName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}author_name'],
      ),
      caption: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}caption'],
      ),
      transcript: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}transcript'],
      ),
      transcriptQuality: $RecipeSourcesTable.$convertertranscriptQuality
          .fromSql(
            attachedDatabase.typeMapping.read(
              DriftSqlType.string,
              data['${effectivePrefix}transcript_quality'],
            )!,
          ),
    );
  }

  @override
  $RecipeSourcesTable createAlias(String alias) {
    return $RecipeSourcesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<SourcePlatform, String, String> $converterplatform =
      const EnumNameConverter<SourcePlatform>(SourcePlatform.values);
  static JsonTypeConverter2<TranscriptQuality, String, String>
  $convertertranscriptQuality = const EnumNameConverter<TranscriptQuality>(
    TranscriptQuality.values,
  );
}

class RecipeSourceRow extends DataClass implements Insertable<RecipeSourceRow> {
  final String recipeId;
  final SourcePlatform platform;
  final String? url;

  /// `piattaforma:id` (D-17). Unica; più ricette possono averla `null`.
  final String? sourceKey;
  final String? authorName;
  final String? caption;
  final String? transcript;
  final TranscriptQuality transcriptQuality;
  const RecipeSourceRow({
    required this.recipeId,
    required this.platform,
    this.url,
    this.sourceKey,
    this.authorName,
    this.caption,
    this.transcript,
    required this.transcriptQuality,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['recipe_id'] = Variable<String>(recipeId);
    {
      map['platform'] = Variable<String>(
        $RecipeSourcesTable.$converterplatform.toSql(platform),
      );
    }
    if (!nullToAbsent || url != null) {
      map['url'] = Variable<String>(url);
    }
    if (!nullToAbsent || sourceKey != null) {
      map['source_key'] = Variable<String>(sourceKey);
    }
    if (!nullToAbsent || authorName != null) {
      map['author_name'] = Variable<String>(authorName);
    }
    if (!nullToAbsent || caption != null) {
      map['caption'] = Variable<String>(caption);
    }
    if (!nullToAbsent || transcript != null) {
      map['transcript'] = Variable<String>(transcript);
    }
    {
      map['transcript_quality'] = Variable<String>(
        $RecipeSourcesTable.$convertertranscriptQuality.toSql(
          transcriptQuality,
        ),
      );
    }
    return map;
  }

  RecipeSourcesCompanion toCompanion(bool nullToAbsent) {
    return RecipeSourcesCompanion(
      recipeId: Value(recipeId),
      platform: Value(platform),
      url: url == null && nullToAbsent ? const Value.absent() : Value(url),
      sourceKey: sourceKey == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceKey),
      authorName: authorName == null && nullToAbsent
          ? const Value.absent()
          : Value(authorName),
      caption: caption == null && nullToAbsent
          ? const Value.absent()
          : Value(caption),
      transcript: transcript == null && nullToAbsent
          ? const Value.absent()
          : Value(transcript),
      transcriptQuality: Value(transcriptQuality),
    );
  }

  factory RecipeSourceRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RecipeSourceRow(
      recipeId: serializer.fromJson<String>(json['recipeId']),
      platform: $RecipeSourcesTable.$converterplatform.fromJson(
        serializer.fromJson<String>(json['platform']),
      ),
      url: serializer.fromJson<String?>(json['url']),
      sourceKey: serializer.fromJson<String?>(json['sourceKey']),
      authorName: serializer.fromJson<String?>(json['authorName']),
      caption: serializer.fromJson<String?>(json['caption']),
      transcript: serializer.fromJson<String?>(json['transcript']),
      transcriptQuality: $RecipeSourcesTable.$convertertranscriptQuality
          .fromJson(serializer.fromJson<String>(json['transcriptQuality'])),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'recipeId': serializer.toJson<String>(recipeId),
      'platform': serializer.toJson<String>(
        $RecipeSourcesTable.$converterplatform.toJson(platform),
      ),
      'url': serializer.toJson<String?>(url),
      'sourceKey': serializer.toJson<String?>(sourceKey),
      'authorName': serializer.toJson<String?>(authorName),
      'caption': serializer.toJson<String?>(caption),
      'transcript': serializer.toJson<String?>(transcript),
      'transcriptQuality': serializer.toJson<String>(
        $RecipeSourcesTable.$convertertranscriptQuality.toJson(
          transcriptQuality,
        ),
      ),
    };
  }

  RecipeSourceRow copyWith({
    String? recipeId,
    SourcePlatform? platform,
    Value<String?> url = const Value.absent(),
    Value<String?> sourceKey = const Value.absent(),
    Value<String?> authorName = const Value.absent(),
    Value<String?> caption = const Value.absent(),
    Value<String?> transcript = const Value.absent(),
    TranscriptQuality? transcriptQuality,
  }) => RecipeSourceRow(
    recipeId: recipeId ?? this.recipeId,
    platform: platform ?? this.platform,
    url: url.present ? url.value : this.url,
    sourceKey: sourceKey.present ? sourceKey.value : this.sourceKey,
    authorName: authorName.present ? authorName.value : this.authorName,
    caption: caption.present ? caption.value : this.caption,
    transcript: transcript.present ? transcript.value : this.transcript,
    transcriptQuality: transcriptQuality ?? this.transcriptQuality,
  );
  RecipeSourceRow copyWithCompanion(RecipeSourcesCompanion data) {
    return RecipeSourceRow(
      recipeId: data.recipeId.present ? data.recipeId.value : this.recipeId,
      platform: data.platform.present ? data.platform.value : this.platform,
      url: data.url.present ? data.url.value : this.url,
      sourceKey: data.sourceKey.present ? data.sourceKey.value : this.sourceKey,
      authorName: data.authorName.present
          ? data.authorName.value
          : this.authorName,
      caption: data.caption.present ? data.caption.value : this.caption,
      transcript: data.transcript.present
          ? data.transcript.value
          : this.transcript,
      transcriptQuality: data.transcriptQuality.present
          ? data.transcriptQuality.value
          : this.transcriptQuality,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RecipeSourceRow(')
          ..write('recipeId: $recipeId, ')
          ..write('platform: $platform, ')
          ..write('url: $url, ')
          ..write('sourceKey: $sourceKey, ')
          ..write('authorName: $authorName, ')
          ..write('caption: $caption, ')
          ..write('transcript: $transcript, ')
          ..write('transcriptQuality: $transcriptQuality')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    recipeId,
    platform,
    url,
    sourceKey,
    authorName,
    caption,
    transcript,
    transcriptQuality,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RecipeSourceRow &&
          other.recipeId == this.recipeId &&
          other.platform == this.platform &&
          other.url == this.url &&
          other.sourceKey == this.sourceKey &&
          other.authorName == this.authorName &&
          other.caption == this.caption &&
          other.transcript == this.transcript &&
          other.transcriptQuality == this.transcriptQuality);
}

class RecipeSourcesCompanion extends UpdateCompanion<RecipeSourceRow> {
  final Value<String> recipeId;
  final Value<SourcePlatform> platform;
  final Value<String?> url;
  final Value<String?> sourceKey;
  final Value<String?> authorName;
  final Value<String?> caption;
  final Value<String?> transcript;
  final Value<TranscriptQuality> transcriptQuality;
  final Value<int> rowid;
  const RecipeSourcesCompanion({
    this.recipeId = const Value.absent(),
    this.platform = const Value.absent(),
    this.url = const Value.absent(),
    this.sourceKey = const Value.absent(),
    this.authorName = const Value.absent(),
    this.caption = const Value.absent(),
    this.transcript = const Value.absent(),
    this.transcriptQuality = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RecipeSourcesCompanion.insert({
    required String recipeId,
    required SourcePlatform platform,
    this.url = const Value.absent(),
    this.sourceKey = const Value.absent(),
    this.authorName = const Value.absent(),
    this.caption = const Value.absent(),
    this.transcript = const Value.absent(),
    required TranscriptQuality transcriptQuality,
    this.rowid = const Value.absent(),
  }) : recipeId = Value(recipeId),
       platform = Value(platform),
       transcriptQuality = Value(transcriptQuality);
  static Insertable<RecipeSourceRow> custom({
    Expression<String>? recipeId,
    Expression<String>? platform,
    Expression<String>? url,
    Expression<String>? sourceKey,
    Expression<String>? authorName,
    Expression<String>? caption,
    Expression<String>? transcript,
    Expression<String>? transcriptQuality,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (recipeId != null) 'recipe_id': recipeId,
      if (platform != null) 'platform': platform,
      if (url != null) 'url': url,
      if (sourceKey != null) 'source_key': sourceKey,
      if (authorName != null) 'author_name': authorName,
      if (caption != null) 'caption': caption,
      if (transcript != null) 'transcript': transcript,
      if (transcriptQuality != null) 'transcript_quality': transcriptQuality,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RecipeSourcesCompanion copyWith({
    Value<String>? recipeId,
    Value<SourcePlatform>? platform,
    Value<String?>? url,
    Value<String?>? sourceKey,
    Value<String?>? authorName,
    Value<String?>? caption,
    Value<String?>? transcript,
    Value<TranscriptQuality>? transcriptQuality,
    Value<int>? rowid,
  }) {
    return RecipeSourcesCompanion(
      recipeId: recipeId ?? this.recipeId,
      platform: platform ?? this.platform,
      url: url ?? this.url,
      sourceKey: sourceKey ?? this.sourceKey,
      authorName: authorName ?? this.authorName,
      caption: caption ?? this.caption,
      transcript: transcript ?? this.transcript,
      transcriptQuality: transcriptQuality ?? this.transcriptQuality,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (recipeId.present) {
      map['recipe_id'] = Variable<String>(recipeId.value);
    }
    if (platform.present) {
      map['platform'] = Variable<String>(
        $RecipeSourcesTable.$converterplatform.toSql(platform.value),
      );
    }
    if (url.present) {
      map['url'] = Variable<String>(url.value);
    }
    if (sourceKey.present) {
      map['source_key'] = Variable<String>(sourceKey.value);
    }
    if (authorName.present) {
      map['author_name'] = Variable<String>(authorName.value);
    }
    if (caption.present) {
      map['caption'] = Variable<String>(caption.value);
    }
    if (transcript.present) {
      map['transcript'] = Variable<String>(transcript.value);
    }
    if (transcriptQuality.present) {
      map['transcript_quality'] = Variable<String>(
        $RecipeSourcesTable.$convertertranscriptQuality.toSql(
          transcriptQuality.value,
        ),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RecipeSourcesCompanion(')
          ..write('recipeId: $recipeId, ')
          ..write('platform: $platform, ')
          ..write('url: $url, ')
          ..write('sourceKey: $sourceKey, ')
          ..write('authorName: $authorName, ')
          ..write('caption: $caption, ')
          ..write('transcript: $transcript, ')
          ..write('transcriptQuality: $transcriptQuality, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $IngredientGroupsTable extends IngredientGroups
    with TableInfo<$IngredientGroupsTable, IngredientGroupRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $IngredientGroupsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recipeIdMeta = const VerificationMeta(
    'recipeId',
  );
  @override
  late final GeneratedColumn<String> recipeId = GeneratedColumn<String>(
    'recipe_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES recipes (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, recipeId, name, position];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ingredient_groups';
  @override
  VerificationContext validateIntegrity(
    Insertable<IngredientGroupRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('recipe_id')) {
      context.handle(
        _recipeIdMeta,
        recipeId.isAcceptableOrUnknown(data['recipe_id']!, _recipeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_recipeIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  IngredientGroupRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return IngredientGroupRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      recipeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recipe_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      ),
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
    );
  }

  @override
  $IngredientGroupsTable createAlias(String alias) {
    return $IngredientGroupsTable(attachedDatabase, alias);
  }
}

class IngredientGroupRow extends DataClass
    implements Insertable<IngredientGroupRow> {
  final String id;
  final String recipeId;
  final String? name;
  final int position;
  const IngredientGroupRow({
    required this.id,
    required this.recipeId,
    this.name,
    required this.position,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['recipe_id'] = Variable<String>(recipeId);
    if (!nullToAbsent || name != null) {
      map['name'] = Variable<String>(name);
    }
    map['position'] = Variable<int>(position);
    return map;
  }

  IngredientGroupsCompanion toCompanion(bool nullToAbsent) {
    return IngredientGroupsCompanion(
      id: Value(id),
      recipeId: Value(recipeId),
      name: name == null && nullToAbsent ? const Value.absent() : Value(name),
      position: Value(position),
    );
  }

  factory IngredientGroupRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return IngredientGroupRow(
      id: serializer.fromJson<String>(json['id']),
      recipeId: serializer.fromJson<String>(json['recipeId']),
      name: serializer.fromJson<String?>(json['name']),
      position: serializer.fromJson<int>(json['position']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'recipeId': serializer.toJson<String>(recipeId),
      'name': serializer.toJson<String?>(name),
      'position': serializer.toJson<int>(position),
    };
  }

  IngredientGroupRow copyWith({
    String? id,
    String? recipeId,
    Value<String?> name = const Value.absent(),
    int? position,
  }) => IngredientGroupRow(
    id: id ?? this.id,
    recipeId: recipeId ?? this.recipeId,
    name: name.present ? name.value : this.name,
    position: position ?? this.position,
  );
  IngredientGroupRow copyWithCompanion(IngredientGroupsCompanion data) {
    return IngredientGroupRow(
      id: data.id.present ? data.id.value : this.id,
      recipeId: data.recipeId.present ? data.recipeId.value : this.recipeId,
      name: data.name.present ? data.name.value : this.name,
      position: data.position.present ? data.position.value : this.position,
    );
  }

  @override
  String toString() {
    return (StringBuffer('IngredientGroupRow(')
          ..write('id: $id, ')
          ..write('recipeId: $recipeId, ')
          ..write('name: $name, ')
          ..write('position: $position')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, recipeId, name, position);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is IngredientGroupRow &&
          other.id == this.id &&
          other.recipeId == this.recipeId &&
          other.name == this.name &&
          other.position == this.position);
}

class IngredientGroupsCompanion extends UpdateCompanion<IngredientGroupRow> {
  final Value<String> id;
  final Value<String> recipeId;
  final Value<String?> name;
  final Value<int> position;
  final Value<int> rowid;
  const IngredientGroupsCompanion({
    this.id = const Value.absent(),
    this.recipeId = const Value.absent(),
    this.name = const Value.absent(),
    this.position = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  IngredientGroupsCompanion.insert({
    required String id,
    required String recipeId,
    this.name = const Value.absent(),
    required int position,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       recipeId = Value(recipeId),
       position = Value(position);
  static Insertable<IngredientGroupRow> custom({
    Expression<String>? id,
    Expression<String>? recipeId,
    Expression<String>? name,
    Expression<int>? position,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (recipeId != null) 'recipe_id': recipeId,
      if (name != null) 'name': name,
      if (position != null) 'position': position,
      if (rowid != null) 'rowid': rowid,
    });
  }

  IngredientGroupsCompanion copyWith({
    Value<String>? id,
    Value<String>? recipeId,
    Value<String?>? name,
    Value<int>? position,
    Value<int>? rowid,
  }) {
    return IngredientGroupsCompanion(
      id: id ?? this.id,
      recipeId: recipeId ?? this.recipeId,
      name: name ?? this.name,
      position: position ?? this.position,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (recipeId.present) {
      map['recipe_id'] = Variable<String>(recipeId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('IngredientGroupsCompanion(')
          ..write('id: $id, ')
          ..write('recipeId: $recipeId, ')
          ..write('name: $name, ')
          ..write('position: $position, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $IngredientsTable extends Ingredients
    with TableInfo<$IngredientsTable, IngredientRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $IngredientsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _groupIdMeta = const VerificationMeta(
    'groupId',
  );
  @override
  late final GeneratedColumn<String> groupId = GeneratedColumn<String>(
    'group_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES ingredient_groups (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _quantityMeta = const VerificationMeta(
    'quantity',
  );
  @override
  late final GeneratedColumn<double> quantity = GeneratedColumn<double>(
    'quantity',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _quantityMaxMeta = const VerificationMeta(
    'quantityMax',
  );
  @override
  late final GeneratedColumn<double> quantityMax = GeneratedColumn<double>(
    'quantity_max',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<IngredientUnit, String> unit =
      GeneratedColumn<String>(
        'unit',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<IngredientUnit>($IngredientsTable.$converterunit);
  static const VerificationMeta _gramsEstimateMeta = const VerificationMeta(
    'gramsEstimate',
  );
  @override
  late final GeneratedColumn<double> gramsEstimate = GeneratedColumn<double>(
    'grams_estimate',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isEstimatedMeta = const VerificationMeta(
    'isEstimated',
  );
  @override
  late final GeneratedColumn<bool> isEstimated = GeneratedColumn<bool>(
    'is_estimated',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_estimated" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<ScalingRule, String> scalingRule =
      GeneratedColumn<String>(
        'scaling_rule',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<ScalingRule>($IngredientsTable.$converterscalingRule);
  static const VerificationMeta _scalingExponentMeta = const VerificationMeta(
    'scalingExponent',
  );
  @override
  late final GeneratedColumn<double> scalingExponent = GeneratedColumn<double>(
    'scaling_exponent',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _canonicalNameEnMeta = const VerificationMeta(
    'canonicalNameEn',
  );
  @override
  late final GeneratedColumn<String> canonicalNameEn = GeneratedColumn<String>(
    'canonical_name_en',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _foodIdMeta = const VerificationMeta('foodId');
  @override
  late final GeneratedColumn<int> foodId = GeneratedColumn<int>(
    'food_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _matchConfidenceMeta = const VerificationMeta(
    'matchConfidence',
  );
  @override
  late final GeneratedColumn<double> matchConfidence = GeneratedColumn<double>(
    'match_confidence',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    groupId,
    position,
    name,
    quantity,
    quantityMax,
    unit,
    gramsEstimate,
    isEstimated,
    note,
    scalingRule,
    scalingExponent,
    canonicalNameEn,
    foodId,
    matchConfidence,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ingredients';
  @override
  VerificationContext validateIntegrity(
    Insertable<IngredientRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('group_id')) {
      context.handle(
        _groupIdMeta,
        groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta),
      );
    } else if (isInserting) {
      context.missing(_groupIdMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('quantity')) {
      context.handle(
        _quantityMeta,
        quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta),
      );
    }
    if (data.containsKey('quantity_max')) {
      context.handle(
        _quantityMaxMeta,
        quantityMax.isAcceptableOrUnknown(
          data['quantity_max']!,
          _quantityMaxMeta,
        ),
      );
    }
    if (data.containsKey('grams_estimate')) {
      context.handle(
        _gramsEstimateMeta,
        gramsEstimate.isAcceptableOrUnknown(
          data['grams_estimate']!,
          _gramsEstimateMeta,
        ),
      );
    }
    if (data.containsKey('is_estimated')) {
      context.handle(
        _isEstimatedMeta,
        isEstimated.isAcceptableOrUnknown(
          data['is_estimated']!,
          _isEstimatedMeta,
        ),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('scaling_exponent')) {
      context.handle(
        _scalingExponentMeta,
        scalingExponent.isAcceptableOrUnknown(
          data['scaling_exponent']!,
          _scalingExponentMeta,
        ),
      );
    }
    if (data.containsKey('canonical_name_en')) {
      context.handle(
        _canonicalNameEnMeta,
        canonicalNameEn.isAcceptableOrUnknown(
          data['canonical_name_en']!,
          _canonicalNameEnMeta,
        ),
      );
    }
    if (data.containsKey('food_id')) {
      context.handle(
        _foodIdMeta,
        foodId.isAcceptableOrUnknown(data['food_id']!, _foodIdMeta),
      );
    }
    if (data.containsKey('match_confidence')) {
      context.handle(
        _matchConfidenceMeta,
        matchConfidence.isAcceptableOrUnknown(
          data['match_confidence']!,
          _matchConfidenceMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  IngredientRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return IngredientRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      groupId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}group_id'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      quantity: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}quantity'],
      ),
      quantityMax: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}quantity_max'],
      ),
      unit: $IngredientsTable.$converterunit.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}unit'],
        )!,
      ),
      gramsEstimate: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}grams_estimate'],
      ),
      isEstimated: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_estimated'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      scalingRule: $IngredientsTable.$converterscalingRule.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}scaling_rule'],
        )!,
      ),
      scalingExponent: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}scaling_exponent'],
      ),
      canonicalNameEn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}canonical_name_en'],
      ),
      foodId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}food_id'],
      ),
      matchConfidence: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}match_confidence'],
      ),
    );
  }

  @override
  $IngredientsTable createAlias(String alias) {
    return $IngredientsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<IngredientUnit, String, String> $converterunit =
      const EnumNameConverter<IngredientUnit>(IngredientUnit.values);
  static JsonTypeConverter2<ScalingRule, String, String> $converterscalingRule =
      const EnumNameConverter<ScalingRule>(ScalingRule.values);
}

class IngredientRow extends DataClass implements Insertable<IngredientRow> {
  final String id;
  final String groupId;
  final int position;
  final String name;
  final double? quantity;
  final double? quantityMax;
  final IngredientUnit unit;
  final double? gramsEstimate;
  final bool isEstimated;
  final String? note;
  final ScalingRule scalingRule;
  final double? scalingExponent;
  final String? canonicalNameEn;

  /// Id nel database nutrizionale incluso nell'app (F4): è un file separato,
  /// quindi niente vincolo di chiave esterna.
  final int? foodId;
  final double? matchConfidence;
  const IngredientRow({
    required this.id,
    required this.groupId,
    required this.position,
    required this.name,
    this.quantity,
    this.quantityMax,
    required this.unit,
    this.gramsEstimate,
    required this.isEstimated,
    this.note,
    required this.scalingRule,
    this.scalingExponent,
    this.canonicalNameEn,
    this.foodId,
    this.matchConfidence,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['group_id'] = Variable<String>(groupId);
    map['position'] = Variable<int>(position);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || quantity != null) {
      map['quantity'] = Variable<double>(quantity);
    }
    if (!nullToAbsent || quantityMax != null) {
      map['quantity_max'] = Variable<double>(quantityMax);
    }
    {
      map['unit'] = Variable<String>(
        $IngredientsTable.$converterunit.toSql(unit),
      );
    }
    if (!nullToAbsent || gramsEstimate != null) {
      map['grams_estimate'] = Variable<double>(gramsEstimate);
    }
    map['is_estimated'] = Variable<bool>(isEstimated);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    {
      map['scaling_rule'] = Variable<String>(
        $IngredientsTable.$converterscalingRule.toSql(scalingRule),
      );
    }
    if (!nullToAbsent || scalingExponent != null) {
      map['scaling_exponent'] = Variable<double>(scalingExponent);
    }
    if (!nullToAbsent || canonicalNameEn != null) {
      map['canonical_name_en'] = Variable<String>(canonicalNameEn);
    }
    if (!nullToAbsent || foodId != null) {
      map['food_id'] = Variable<int>(foodId);
    }
    if (!nullToAbsent || matchConfidence != null) {
      map['match_confidence'] = Variable<double>(matchConfidence);
    }
    return map;
  }

  IngredientsCompanion toCompanion(bool nullToAbsent) {
    return IngredientsCompanion(
      id: Value(id),
      groupId: Value(groupId),
      position: Value(position),
      name: Value(name),
      quantity: quantity == null && nullToAbsent
          ? const Value.absent()
          : Value(quantity),
      quantityMax: quantityMax == null && nullToAbsent
          ? const Value.absent()
          : Value(quantityMax),
      unit: Value(unit),
      gramsEstimate: gramsEstimate == null && nullToAbsent
          ? const Value.absent()
          : Value(gramsEstimate),
      isEstimated: Value(isEstimated),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      scalingRule: Value(scalingRule),
      scalingExponent: scalingExponent == null && nullToAbsent
          ? const Value.absent()
          : Value(scalingExponent),
      canonicalNameEn: canonicalNameEn == null && nullToAbsent
          ? const Value.absent()
          : Value(canonicalNameEn),
      foodId: foodId == null && nullToAbsent
          ? const Value.absent()
          : Value(foodId),
      matchConfidence: matchConfidence == null && nullToAbsent
          ? const Value.absent()
          : Value(matchConfidence),
    );
  }

  factory IngredientRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return IngredientRow(
      id: serializer.fromJson<String>(json['id']),
      groupId: serializer.fromJson<String>(json['groupId']),
      position: serializer.fromJson<int>(json['position']),
      name: serializer.fromJson<String>(json['name']),
      quantity: serializer.fromJson<double?>(json['quantity']),
      quantityMax: serializer.fromJson<double?>(json['quantityMax']),
      unit: $IngredientsTable.$converterunit.fromJson(
        serializer.fromJson<String>(json['unit']),
      ),
      gramsEstimate: serializer.fromJson<double?>(json['gramsEstimate']),
      isEstimated: serializer.fromJson<bool>(json['isEstimated']),
      note: serializer.fromJson<String?>(json['note']),
      scalingRule: $IngredientsTable.$converterscalingRule.fromJson(
        serializer.fromJson<String>(json['scalingRule']),
      ),
      scalingExponent: serializer.fromJson<double?>(json['scalingExponent']),
      canonicalNameEn: serializer.fromJson<String?>(json['canonicalNameEn']),
      foodId: serializer.fromJson<int?>(json['foodId']),
      matchConfidence: serializer.fromJson<double?>(json['matchConfidence']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'groupId': serializer.toJson<String>(groupId),
      'position': serializer.toJson<int>(position),
      'name': serializer.toJson<String>(name),
      'quantity': serializer.toJson<double?>(quantity),
      'quantityMax': serializer.toJson<double?>(quantityMax),
      'unit': serializer.toJson<String>(
        $IngredientsTable.$converterunit.toJson(unit),
      ),
      'gramsEstimate': serializer.toJson<double?>(gramsEstimate),
      'isEstimated': serializer.toJson<bool>(isEstimated),
      'note': serializer.toJson<String?>(note),
      'scalingRule': serializer.toJson<String>(
        $IngredientsTable.$converterscalingRule.toJson(scalingRule),
      ),
      'scalingExponent': serializer.toJson<double?>(scalingExponent),
      'canonicalNameEn': serializer.toJson<String?>(canonicalNameEn),
      'foodId': serializer.toJson<int?>(foodId),
      'matchConfidence': serializer.toJson<double?>(matchConfidence),
    };
  }

  IngredientRow copyWith({
    String? id,
    String? groupId,
    int? position,
    String? name,
    Value<double?> quantity = const Value.absent(),
    Value<double?> quantityMax = const Value.absent(),
    IngredientUnit? unit,
    Value<double?> gramsEstimate = const Value.absent(),
    bool? isEstimated,
    Value<String?> note = const Value.absent(),
    ScalingRule? scalingRule,
    Value<double?> scalingExponent = const Value.absent(),
    Value<String?> canonicalNameEn = const Value.absent(),
    Value<int?> foodId = const Value.absent(),
    Value<double?> matchConfidence = const Value.absent(),
  }) => IngredientRow(
    id: id ?? this.id,
    groupId: groupId ?? this.groupId,
    position: position ?? this.position,
    name: name ?? this.name,
    quantity: quantity.present ? quantity.value : this.quantity,
    quantityMax: quantityMax.present ? quantityMax.value : this.quantityMax,
    unit: unit ?? this.unit,
    gramsEstimate: gramsEstimate.present
        ? gramsEstimate.value
        : this.gramsEstimate,
    isEstimated: isEstimated ?? this.isEstimated,
    note: note.present ? note.value : this.note,
    scalingRule: scalingRule ?? this.scalingRule,
    scalingExponent: scalingExponent.present
        ? scalingExponent.value
        : this.scalingExponent,
    canonicalNameEn: canonicalNameEn.present
        ? canonicalNameEn.value
        : this.canonicalNameEn,
    foodId: foodId.present ? foodId.value : this.foodId,
    matchConfidence: matchConfidence.present
        ? matchConfidence.value
        : this.matchConfidence,
  );
  IngredientRow copyWithCompanion(IngredientsCompanion data) {
    return IngredientRow(
      id: data.id.present ? data.id.value : this.id,
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
      position: data.position.present ? data.position.value : this.position,
      name: data.name.present ? data.name.value : this.name,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      quantityMax: data.quantityMax.present
          ? data.quantityMax.value
          : this.quantityMax,
      unit: data.unit.present ? data.unit.value : this.unit,
      gramsEstimate: data.gramsEstimate.present
          ? data.gramsEstimate.value
          : this.gramsEstimate,
      isEstimated: data.isEstimated.present
          ? data.isEstimated.value
          : this.isEstimated,
      note: data.note.present ? data.note.value : this.note,
      scalingRule: data.scalingRule.present
          ? data.scalingRule.value
          : this.scalingRule,
      scalingExponent: data.scalingExponent.present
          ? data.scalingExponent.value
          : this.scalingExponent,
      canonicalNameEn: data.canonicalNameEn.present
          ? data.canonicalNameEn.value
          : this.canonicalNameEn,
      foodId: data.foodId.present ? data.foodId.value : this.foodId,
      matchConfidence: data.matchConfidence.present
          ? data.matchConfidence.value
          : this.matchConfidence,
    );
  }

  @override
  String toString() {
    return (StringBuffer('IngredientRow(')
          ..write('id: $id, ')
          ..write('groupId: $groupId, ')
          ..write('position: $position, ')
          ..write('name: $name, ')
          ..write('quantity: $quantity, ')
          ..write('quantityMax: $quantityMax, ')
          ..write('unit: $unit, ')
          ..write('gramsEstimate: $gramsEstimate, ')
          ..write('isEstimated: $isEstimated, ')
          ..write('note: $note, ')
          ..write('scalingRule: $scalingRule, ')
          ..write('scalingExponent: $scalingExponent, ')
          ..write('canonicalNameEn: $canonicalNameEn, ')
          ..write('foodId: $foodId, ')
          ..write('matchConfidence: $matchConfidence')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    groupId,
    position,
    name,
    quantity,
    quantityMax,
    unit,
    gramsEstimate,
    isEstimated,
    note,
    scalingRule,
    scalingExponent,
    canonicalNameEn,
    foodId,
    matchConfidence,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is IngredientRow &&
          other.id == this.id &&
          other.groupId == this.groupId &&
          other.position == this.position &&
          other.name == this.name &&
          other.quantity == this.quantity &&
          other.quantityMax == this.quantityMax &&
          other.unit == this.unit &&
          other.gramsEstimate == this.gramsEstimate &&
          other.isEstimated == this.isEstimated &&
          other.note == this.note &&
          other.scalingRule == this.scalingRule &&
          other.scalingExponent == this.scalingExponent &&
          other.canonicalNameEn == this.canonicalNameEn &&
          other.foodId == this.foodId &&
          other.matchConfidence == this.matchConfidence);
}

class IngredientsCompanion extends UpdateCompanion<IngredientRow> {
  final Value<String> id;
  final Value<String> groupId;
  final Value<int> position;
  final Value<String> name;
  final Value<double?> quantity;
  final Value<double?> quantityMax;
  final Value<IngredientUnit> unit;
  final Value<double?> gramsEstimate;
  final Value<bool> isEstimated;
  final Value<String?> note;
  final Value<ScalingRule> scalingRule;
  final Value<double?> scalingExponent;
  final Value<String?> canonicalNameEn;
  final Value<int?> foodId;
  final Value<double?> matchConfidence;
  final Value<int> rowid;
  const IngredientsCompanion({
    this.id = const Value.absent(),
    this.groupId = const Value.absent(),
    this.position = const Value.absent(),
    this.name = const Value.absent(),
    this.quantity = const Value.absent(),
    this.quantityMax = const Value.absent(),
    this.unit = const Value.absent(),
    this.gramsEstimate = const Value.absent(),
    this.isEstimated = const Value.absent(),
    this.note = const Value.absent(),
    this.scalingRule = const Value.absent(),
    this.scalingExponent = const Value.absent(),
    this.canonicalNameEn = const Value.absent(),
    this.foodId = const Value.absent(),
    this.matchConfidence = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  IngredientsCompanion.insert({
    required String id,
    required String groupId,
    required int position,
    required String name,
    this.quantity = const Value.absent(),
    this.quantityMax = const Value.absent(),
    required IngredientUnit unit,
    this.gramsEstimate = const Value.absent(),
    this.isEstimated = const Value.absent(),
    this.note = const Value.absent(),
    required ScalingRule scalingRule,
    this.scalingExponent = const Value.absent(),
    this.canonicalNameEn = const Value.absent(),
    this.foodId = const Value.absent(),
    this.matchConfidence = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       groupId = Value(groupId),
       position = Value(position),
       name = Value(name),
       unit = Value(unit),
       scalingRule = Value(scalingRule);
  static Insertable<IngredientRow> custom({
    Expression<String>? id,
    Expression<String>? groupId,
    Expression<int>? position,
    Expression<String>? name,
    Expression<double>? quantity,
    Expression<double>? quantityMax,
    Expression<String>? unit,
    Expression<double>? gramsEstimate,
    Expression<bool>? isEstimated,
    Expression<String>? note,
    Expression<String>? scalingRule,
    Expression<double>? scalingExponent,
    Expression<String>? canonicalNameEn,
    Expression<int>? foodId,
    Expression<double>? matchConfidence,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (groupId != null) 'group_id': groupId,
      if (position != null) 'position': position,
      if (name != null) 'name': name,
      if (quantity != null) 'quantity': quantity,
      if (quantityMax != null) 'quantity_max': quantityMax,
      if (unit != null) 'unit': unit,
      if (gramsEstimate != null) 'grams_estimate': gramsEstimate,
      if (isEstimated != null) 'is_estimated': isEstimated,
      if (note != null) 'note': note,
      if (scalingRule != null) 'scaling_rule': scalingRule,
      if (scalingExponent != null) 'scaling_exponent': scalingExponent,
      if (canonicalNameEn != null) 'canonical_name_en': canonicalNameEn,
      if (foodId != null) 'food_id': foodId,
      if (matchConfidence != null) 'match_confidence': matchConfidence,
      if (rowid != null) 'rowid': rowid,
    });
  }

  IngredientsCompanion copyWith({
    Value<String>? id,
    Value<String>? groupId,
    Value<int>? position,
    Value<String>? name,
    Value<double?>? quantity,
    Value<double?>? quantityMax,
    Value<IngredientUnit>? unit,
    Value<double?>? gramsEstimate,
    Value<bool>? isEstimated,
    Value<String?>? note,
    Value<ScalingRule>? scalingRule,
    Value<double?>? scalingExponent,
    Value<String?>? canonicalNameEn,
    Value<int?>? foodId,
    Value<double?>? matchConfidence,
    Value<int>? rowid,
  }) {
    return IngredientsCompanion(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      position: position ?? this.position,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      quantityMax: quantityMax ?? this.quantityMax,
      unit: unit ?? this.unit,
      gramsEstimate: gramsEstimate ?? this.gramsEstimate,
      isEstimated: isEstimated ?? this.isEstimated,
      note: note ?? this.note,
      scalingRule: scalingRule ?? this.scalingRule,
      scalingExponent: scalingExponent ?? this.scalingExponent,
      canonicalNameEn: canonicalNameEn ?? this.canonicalNameEn,
      foodId: foodId ?? this.foodId,
      matchConfidence: matchConfidence ?? this.matchConfidence,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (groupId.present) {
      map['group_id'] = Variable<String>(groupId.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<double>(quantity.value);
    }
    if (quantityMax.present) {
      map['quantity_max'] = Variable<double>(quantityMax.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(
        $IngredientsTable.$converterunit.toSql(unit.value),
      );
    }
    if (gramsEstimate.present) {
      map['grams_estimate'] = Variable<double>(gramsEstimate.value);
    }
    if (isEstimated.present) {
      map['is_estimated'] = Variable<bool>(isEstimated.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (scalingRule.present) {
      map['scaling_rule'] = Variable<String>(
        $IngredientsTable.$converterscalingRule.toSql(scalingRule.value),
      );
    }
    if (scalingExponent.present) {
      map['scaling_exponent'] = Variable<double>(scalingExponent.value);
    }
    if (canonicalNameEn.present) {
      map['canonical_name_en'] = Variable<String>(canonicalNameEn.value);
    }
    if (foodId.present) {
      map['food_id'] = Variable<int>(foodId.value);
    }
    if (matchConfidence.present) {
      map['match_confidence'] = Variable<double>(matchConfidence.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('IngredientsCompanion(')
          ..write('id: $id, ')
          ..write('groupId: $groupId, ')
          ..write('position: $position, ')
          ..write('name: $name, ')
          ..write('quantity: $quantity, ')
          ..write('quantityMax: $quantityMax, ')
          ..write('unit: $unit, ')
          ..write('gramsEstimate: $gramsEstimate, ')
          ..write('isEstimated: $isEstimated, ')
          ..write('note: $note, ')
          ..write('scalingRule: $scalingRule, ')
          ..write('scalingExponent: $scalingExponent, ')
          ..write('canonicalNameEn: $canonicalNameEn, ')
          ..write('foodId: $foodId, ')
          ..write('matchConfidence: $matchConfidence, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RecipeStepsTable extends RecipeSteps
    with TableInfo<$RecipeStepsTable, RecipeStepRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RecipeStepsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recipeIdMeta = const VerificationMeta(
    'recipeId',
  );
  @override
  late final GeneratedColumn<String> recipeId = GeneratedColumn<String>(
    'recipe_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES recipes (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _numberMeta = const VerificationMeta('number');
  @override
  late final GeneratedColumn<int> number = GeneratedColumn<int>(
    'number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'body',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _durationMinutesMeta = const VerificationMeta(
    'durationMinutes',
  );
  @override
  late final GeneratedColumn<int> durationMinutes = GeneratedColumn<int>(
    'duration_minutes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _temperatureCMeta = const VerificationMeta(
    'temperatureC',
  );
  @override
  late final GeneratedColumn<int> temperatureC = GeneratedColumn<int>(
    'temperature_c',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    recipeId,
    number,
    body,
    durationMinutes,
    temperatureC,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'recipe_steps';
  @override
  VerificationContext validateIntegrity(
    Insertable<RecipeStepRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('recipe_id')) {
      context.handle(
        _recipeIdMeta,
        recipeId.isAcceptableOrUnknown(data['recipe_id']!, _recipeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_recipeIdMeta);
    }
    if (data.containsKey('number')) {
      context.handle(
        _numberMeta,
        number.isAcceptableOrUnknown(data['number']!, _numberMeta),
      );
    } else if (isInserting) {
      context.missing(_numberMeta);
    }
    if (data.containsKey('body')) {
      context.handle(
        _bodyMeta,
        body.isAcceptableOrUnknown(data['body']!, _bodyMeta),
      );
    } else if (isInserting) {
      context.missing(_bodyMeta);
    }
    if (data.containsKey('duration_minutes')) {
      context.handle(
        _durationMinutesMeta,
        durationMinutes.isAcceptableOrUnknown(
          data['duration_minutes']!,
          _durationMinutesMeta,
        ),
      );
    }
    if (data.containsKey('temperature_c')) {
      context.handle(
        _temperatureCMeta,
        temperatureC.isAcceptableOrUnknown(
          data['temperature_c']!,
          _temperatureCMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RecipeStepRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RecipeStepRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      recipeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recipe_id'],
      )!,
      number: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}number'],
      )!,
      body: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body'],
      )!,
      durationMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_minutes'],
      ),
      temperatureC: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}temperature_c'],
      ),
    );
  }

  @override
  $RecipeStepsTable createAlias(String alias) {
    return $RecipeStepsTable(attachedDatabase, alias);
  }
}

class RecipeStepRow extends DataClass implements Insertable<RecipeStepRow> {
  final String id;
  final String recipeId;
  final int number;
  final String body;
  final int? durationMinutes;
  final int? temperatureC;
  const RecipeStepRow({
    required this.id,
    required this.recipeId,
    required this.number,
    required this.body,
    this.durationMinutes,
    this.temperatureC,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['recipe_id'] = Variable<String>(recipeId);
    map['number'] = Variable<int>(number);
    map['body'] = Variable<String>(body);
    if (!nullToAbsent || durationMinutes != null) {
      map['duration_minutes'] = Variable<int>(durationMinutes);
    }
    if (!nullToAbsent || temperatureC != null) {
      map['temperature_c'] = Variable<int>(temperatureC);
    }
    return map;
  }

  RecipeStepsCompanion toCompanion(bool nullToAbsent) {
    return RecipeStepsCompanion(
      id: Value(id),
      recipeId: Value(recipeId),
      number: Value(number),
      body: Value(body),
      durationMinutes: durationMinutes == null && nullToAbsent
          ? const Value.absent()
          : Value(durationMinutes),
      temperatureC: temperatureC == null && nullToAbsent
          ? const Value.absent()
          : Value(temperatureC),
    );
  }

  factory RecipeStepRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RecipeStepRow(
      id: serializer.fromJson<String>(json['id']),
      recipeId: serializer.fromJson<String>(json['recipeId']),
      number: serializer.fromJson<int>(json['number']),
      body: serializer.fromJson<String>(json['body']),
      durationMinutes: serializer.fromJson<int?>(json['durationMinutes']),
      temperatureC: serializer.fromJson<int?>(json['temperatureC']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'recipeId': serializer.toJson<String>(recipeId),
      'number': serializer.toJson<int>(number),
      'body': serializer.toJson<String>(body),
      'durationMinutes': serializer.toJson<int?>(durationMinutes),
      'temperatureC': serializer.toJson<int?>(temperatureC),
    };
  }

  RecipeStepRow copyWith({
    String? id,
    String? recipeId,
    int? number,
    String? body,
    Value<int?> durationMinutes = const Value.absent(),
    Value<int?> temperatureC = const Value.absent(),
  }) => RecipeStepRow(
    id: id ?? this.id,
    recipeId: recipeId ?? this.recipeId,
    number: number ?? this.number,
    body: body ?? this.body,
    durationMinutes: durationMinutes.present
        ? durationMinutes.value
        : this.durationMinutes,
    temperatureC: temperatureC.present ? temperatureC.value : this.temperatureC,
  );
  RecipeStepRow copyWithCompanion(RecipeStepsCompanion data) {
    return RecipeStepRow(
      id: data.id.present ? data.id.value : this.id,
      recipeId: data.recipeId.present ? data.recipeId.value : this.recipeId,
      number: data.number.present ? data.number.value : this.number,
      body: data.body.present ? data.body.value : this.body,
      durationMinutes: data.durationMinutes.present
          ? data.durationMinutes.value
          : this.durationMinutes,
      temperatureC: data.temperatureC.present
          ? data.temperatureC.value
          : this.temperatureC,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RecipeStepRow(')
          ..write('id: $id, ')
          ..write('recipeId: $recipeId, ')
          ..write('number: $number, ')
          ..write('body: $body, ')
          ..write('durationMinutes: $durationMinutes, ')
          ..write('temperatureC: $temperatureC')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, recipeId, number, body, durationMinutes, temperatureC);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RecipeStepRow &&
          other.id == this.id &&
          other.recipeId == this.recipeId &&
          other.number == this.number &&
          other.body == this.body &&
          other.durationMinutes == this.durationMinutes &&
          other.temperatureC == this.temperatureC);
}

class RecipeStepsCompanion extends UpdateCompanion<RecipeStepRow> {
  final Value<String> id;
  final Value<String> recipeId;
  final Value<int> number;
  final Value<String> body;
  final Value<int?> durationMinutes;
  final Value<int?> temperatureC;
  final Value<int> rowid;
  const RecipeStepsCompanion({
    this.id = const Value.absent(),
    this.recipeId = const Value.absent(),
    this.number = const Value.absent(),
    this.body = const Value.absent(),
    this.durationMinutes = const Value.absent(),
    this.temperatureC = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RecipeStepsCompanion.insert({
    required String id,
    required String recipeId,
    required int number,
    required String body,
    this.durationMinutes = const Value.absent(),
    this.temperatureC = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       recipeId = Value(recipeId),
       number = Value(number),
       body = Value(body);
  static Insertable<RecipeStepRow> custom({
    Expression<String>? id,
    Expression<String>? recipeId,
    Expression<int>? number,
    Expression<String>? body,
    Expression<int>? durationMinutes,
    Expression<int>? temperatureC,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (recipeId != null) 'recipe_id': recipeId,
      if (number != null) 'number': number,
      if (body != null) 'body': body,
      if (durationMinutes != null) 'duration_minutes': durationMinutes,
      if (temperatureC != null) 'temperature_c': temperatureC,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RecipeStepsCompanion copyWith({
    Value<String>? id,
    Value<String>? recipeId,
    Value<int>? number,
    Value<String>? body,
    Value<int?>? durationMinutes,
    Value<int?>? temperatureC,
    Value<int>? rowid,
  }) {
    return RecipeStepsCompanion(
      id: id ?? this.id,
      recipeId: recipeId ?? this.recipeId,
      number: number ?? this.number,
      body: body ?? this.body,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      temperatureC: temperatureC ?? this.temperatureC,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (recipeId.present) {
      map['recipe_id'] = Variable<String>(recipeId.value);
    }
    if (number.present) {
      map['number'] = Variable<int>(number.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (durationMinutes.present) {
      map['duration_minutes'] = Variable<int>(durationMinutes.value);
    }
    if (temperatureC.present) {
      map['temperature_c'] = Variable<int>(temperatureC.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RecipeStepsCompanion(')
          ..write('id: $id, ')
          ..write('recipeId: $recipeId, ')
          ..write('number: $number, ')
          ..write('body: $body, ')
          ..write('durationMinutes: $durationMinutes, ')
          ..write('temperatureC: $temperatureC, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TagsTable extends Tags with TableInfo<$TagsTable, TagRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TagsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  @override
  List<GeneratedColumn> get $columns => [id, name];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tags';
  @override
  VerificationContext validateIntegrity(
    Insertable<TagRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TagRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TagRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
    );
  }

  @override
  $TagsTable createAlias(String alias) {
    return $TagsTable(attachedDatabase, alias);
  }
}

class TagRow extends DataClass implements Insertable<TagRow> {
  final int id;
  final String name;
  const TagRow({required this.id, required this.name});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    return map;
  }

  TagsCompanion toCompanion(bool nullToAbsent) {
    return TagsCompanion(id: Value(id), name: Value(name));
  }

  factory TagRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TagRow(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
    };
  }

  TagRow copyWith({int? id, String? name}) =>
      TagRow(id: id ?? this.id, name: name ?? this.name);
  TagRow copyWithCompanion(TagsCompanion data) {
    return TagRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TagRow(')
          ..write('id: $id, ')
          ..write('name: $name')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TagRow && other.id == this.id && other.name == this.name);
}

class TagsCompanion extends UpdateCompanion<TagRow> {
  final Value<int> id;
  final Value<String> name;
  const TagsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
  });
  TagsCompanion.insert({this.id = const Value.absent(), required String name})
    : name = Value(name);
  static Insertable<TagRow> custom({
    Expression<int>? id,
    Expression<String>? name,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
    });
  }

  TagsCompanion copyWith({Value<int>? id, Value<String>? name}) {
    return TagsCompanion(id: id ?? this.id, name: name ?? this.name);
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TagsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name')
          ..write(')'))
        .toString();
  }
}

class $RecipeTagsTable extends RecipeTags
    with TableInfo<$RecipeTagsTable, RecipeTagRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RecipeTagsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _recipeIdMeta = const VerificationMeta(
    'recipeId',
  );
  @override
  late final GeneratedColumn<String> recipeId = GeneratedColumn<String>(
    'recipe_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES recipes (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _tagIdMeta = const VerificationMeta('tagId');
  @override
  late final GeneratedColumn<int> tagId = GeneratedColumn<int>(
    'tag_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES tags (id) ON DELETE CASCADE',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [recipeId, tagId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'recipe_tags';
  @override
  VerificationContext validateIntegrity(
    Insertable<RecipeTagRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('recipe_id')) {
      context.handle(
        _recipeIdMeta,
        recipeId.isAcceptableOrUnknown(data['recipe_id']!, _recipeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_recipeIdMeta);
    }
    if (data.containsKey('tag_id')) {
      context.handle(
        _tagIdMeta,
        tagId.isAcceptableOrUnknown(data['tag_id']!, _tagIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tagIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {recipeId, tagId};
  @override
  RecipeTagRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RecipeTagRow(
      recipeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recipe_id'],
      )!,
      tagId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tag_id'],
      )!,
    );
  }

  @override
  $RecipeTagsTable createAlias(String alias) {
    return $RecipeTagsTable(attachedDatabase, alias);
  }
}

class RecipeTagRow extends DataClass implements Insertable<RecipeTagRow> {
  final String recipeId;
  final int tagId;
  const RecipeTagRow({required this.recipeId, required this.tagId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['recipe_id'] = Variable<String>(recipeId);
    map['tag_id'] = Variable<int>(tagId);
    return map;
  }

  RecipeTagsCompanion toCompanion(bool nullToAbsent) {
    return RecipeTagsCompanion(recipeId: Value(recipeId), tagId: Value(tagId));
  }

  factory RecipeTagRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RecipeTagRow(
      recipeId: serializer.fromJson<String>(json['recipeId']),
      tagId: serializer.fromJson<int>(json['tagId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'recipeId': serializer.toJson<String>(recipeId),
      'tagId': serializer.toJson<int>(tagId),
    };
  }

  RecipeTagRow copyWith({String? recipeId, int? tagId}) => RecipeTagRow(
    recipeId: recipeId ?? this.recipeId,
    tagId: tagId ?? this.tagId,
  );
  RecipeTagRow copyWithCompanion(RecipeTagsCompanion data) {
    return RecipeTagRow(
      recipeId: data.recipeId.present ? data.recipeId.value : this.recipeId,
      tagId: data.tagId.present ? data.tagId.value : this.tagId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RecipeTagRow(')
          ..write('recipeId: $recipeId, ')
          ..write('tagId: $tagId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(recipeId, tagId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RecipeTagRow &&
          other.recipeId == this.recipeId &&
          other.tagId == this.tagId);
}

class RecipeTagsCompanion extends UpdateCompanion<RecipeTagRow> {
  final Value<String> recipeId;
  final Value<int> tagId;
  final Value<int> rowid;
  const RecipeTagsCompanion({
    this.recipeId = const Value.absent(),
    this.tagId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RecipeTagsCompanion.insert({
    required String recipeId,
    required int tagId,
    this.rowid = const Value.absent(),
  }) : recipeId = Value(recipeId),
       tagId = Value(tagId);
  static Insertable<RecipeTagRow> custom({
    Expression<String>? recipeId,
    Expression<int>? tagId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (recipeId != null) 'recipe_id': recipeId,
      if (tagId != null) 'tag_id': tagId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RecipeTagsCompanion copyWith({
    Value<String>? recipeId,
    Value<int>? tagId,
    Value<int>? rowid,
  }) {
    return RecipeTagsCompanion(
      recipeId: recipeId ?? this.recipeId,
      tagId: tagId ?? this.tagId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (recipeId.present) {
      map['recipe_id'] = Variable<String>(recipeId.value);
    }
    if (tagId.present) {
      map['tag_id'] = Variable<int>(tagId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RecipeTagsCompanion(')
          ..write('recipeId: $recipeId, ')
          ..write('tagId: $tagId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $NutritionSnapshotsTable extends NutritionSnapshots
    with TableInfo<$NutritionSnapshotsTable, NutritionSnapshotRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NutritionSnapshotsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _recipeIdMeta = const VerificationMeta(
    'recipeId',
  );
  @override
  late final GeneratedColumn<String> recipeId = GeneratedColumn<String>(
    'recipe_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES recipes (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _kcalMeta = const VerificationMeta('kcal');
  @override
  late final GeneratedColumn<double> kcal = GeneratedColumn<double>(
    'kcal',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _proteinGMeta = const VerificationMeta(
    'proteinG',
  );
  @override
  late final GeneratedColumn<double> proteinG = GeneratedColumn<double>(
    'protein_g',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _carbsGMeta = const VerificationMeta('carbsG');
  @override
  late final GeneratedColumn<double> carbsG = GeneratedColumn<double>(
    'carbs_g',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sugarsGMeta = const VerificationMeta(
    'sugarsG',
  );
  @override
  late final GeneratedColumn<double> sugarsG = GeneratedColumn<double>(
    'sugars_g',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fatGMeta = const VerificationMeta('fatG');
  @override
  late final GeneratedColumn<double> fatG = GeneratedColumn<double>(
    'fat_g',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _saturatedFatGMeta = const VerificationMeta(
    'saturatedFatG',
  );
  @override
  late final GeneratedColumn<double> saturatedFatG = GeneratedColumn<double>(
    'saturated_fat_g',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fiberGMeta = const VerificationMeta('fiberG');
  @override
  late final GeneratedColumn<double> fiberG = GeneratedColumn<double>(
    'fiber_g',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _saltGMeta = const VerificationMeta('saltG');
  @override
  late final GeneratedColumn<double> saltG = GeneratedColumn<double>(
    'salt_g',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _coverageMeta = const VerificationMeta(
    'coverage',
  );
  @override
  late final GeneratedColumn<double> coverage = GeneratedColumn<double>(
    'coverage',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _computedAtMeta = const VerificationMeta(
    'computedAt',
  );
  @override
  late final GeneratedColumn<DateTime> computedAt = GeneratedColumn<DateTime>(
    'computed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    recipeId,
    kcal,
    proteinG,
    carbsG,
    sugarsG,
    fatG,
    saturatedFatG,
    fiberG,
    saltG,
    coverage,
    computedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'nutrition_snapshots';
  @override
  VerificationContext validateIntegrity(
    Insertable<NutritionSnapshotRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('recipe_id')) {
      context.handle(
        _recipeIdMeta,
        recipeId.isAcceptableOrUnknown(data['recipe_id']!, _recipeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_recipeIdMeta);
    }
    if (data.containsKey('kcal')) {
      context.handle(
        _kcalMeta,
        kcal.isAcceptableOrUnknown(data['kcal']!, _kcalMeta),
      );
    } else if (isInserting) {
      context.missing(_kcalMeta);
    }
    if (data.containsKey('protein_g')) {
      context.handle(
        _proteinGMeta,
        proteinG.isAcceptableOrUnknown(data['protein_g']!, _proteinGMeta),
      );
    } else if (isInserting) {
      context.missing(_proteinGMeta);
    }
    if (data.containsKey('carbs_g')) {
      context.handle(
        _carbsGMeta,
        carbsG.isAcceptableOrUnknown(data['carbs_g']!, _carbsGMeta),
      );
    } else if (isInserting) {
      context.missing(_carbsGMeta);
    }
    if (data.containsKey('sugars_g')) {
      context.handle(
        _sugarsGMeta,
        sugarsG.isAcceptableOrUnknown(data['sugars_g']!, _sugarsGMeta),
      );
    } else if (isInserting) {
      context.missing(_sugarsGMeta);
    }
    if (data.containsKey('fat_g')) {
      context.handle(
        _fatGMeta,
        fatG.isAcceptableOrUnknown(data['fat_g']!, _fatGMeta),
      );
    } else if (isInserting) {
      context.missing(_fatGMeta);
    }
    if (data.containsKey('saturated_fat_g')) {
      context.handle(
        _saturatedFatGMeta,
        saturatedFatG.isAcceptableOrUnknown(
          data['saturated_fat_g']!,
          _saturatedFatGMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_saturatedFatGMeta);
    }
    if (data.containsKey('fiber_g')) {
      context.handle(
        _fiberGMeta,
        fiberG.isAcceptableOrUnknown(data['fiber_g']!, _fiberGMeta),
      );
    } else if (isInserting) {
      context.missing(_fiberGMeta);
    }
    if (data.containsKey('salt_g')) {
      context.handle(
        _saltGMeta,
        saltG.isAcceptableOrUnknown(data['salt_g']!, _saltGMeta),
      );
    } else if (isInserting) {
      context.missing(_saltGMeta);
    }
    if (data.containsKey('coverage')) {
      context.handle(
        _coverageMeta,
        coverage.isAcceptableOrUnknown(data['coverage']!, _coverageMeta),
      );
    } else if (isInserting) {
      context.missing(_coverageMeta);
    }
    if (data.containsKey('computed_at')) {
      context.handle(
        _computedAtMeta,
        computedAt.isAcceptableOrUnknown(data['computed_at']!, _computedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_computedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {recipeId};
  @override
  NutritionSnapshotRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NutritionSnapshotRow(
      recipeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recipe_id'],
      )!,
      kcal: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}kcal'],
      )!,
      proteinG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}protein_g'],
      )!,
      carbsG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}carbs_g'],
      )!,
      sugarsG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}sugars_g'],
      )!,
      fatG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}fat_g'],
      )!,
      saturatedFatG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}saturated_fat_g'],
      )!,
      fiberG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}fiber_g'],
      )!,
      saltG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}salt_g'],
      )!,
      coverage: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}coverage'],
      )!,
      computedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}computed_at'],
      )!,
    );
  }

  @override
  $NutritionSnapshotsTable createAlias(String alias) {
    return $NutritionSnapshotsTable(attachedDatabase, alias);
  }
}

class NutritionSnapshotRow extends DataClass
    implements Insertable<NutritionSnapshotRow> {
  final String recipeId;
  final double kcal;
  final double proteinG;
  final double carbsG;
  final double sugarsG;
  final double fatG;
  final double saturatedFatG;
  final double fiberG;
  final double saltG;

  /// Quota del peso con un abbinamento nutrizionale valido (0–1).
  final double coverage;
  final DateTime computedAt;
  const NutritionSnapshotRow({
    required this.recipeId,
    required this.kcal,
    required this.proteinG,
    required this.carbsG,
    required this.sugarsG,
    required this.fatG,
    required this.saturatedFatG,
    required this.fiberG,
    required this.saltG,
    required this.coverage,
    required this.computedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['recipe_id'] = Variable<String>(recipeId);
    map['kcal'] = Variable<double>(kcal);
    map['protein_g'] = Variable<double>(proteinG);
    map['carbs_g'] = Variable<double>(carbsG);
    map['sugars_g'] = Variable<double>(sugarsG);
    map['fat_g'] = Variable<double>(fatG);
    map['saturated_fat_g'] = Variable<double>(saturatedFatG);
    map['fiber_g'] = Variable<double>(fiberG);
    map['salt_g'] = Variable<double>(saltG);
    map['coverage'] = Variable<double>(coverage);
    map['computed_at'] = Variable<DateTime>(computedAt);
    return map;
  }

  NutritionSnapshotsCompanion toCompanion(bool nullToAbsent) {
    return NutritionSnapshotsCompanion(
      recipeId: Value(recipeId),
      kcal: Value(kcal),
      proteinG: Value(proteinG),
      carbsG: Value(carbsG),
      sugarsG: Value(sugarsG),
      fatG: Value(fatG),
      saturatedFatG: Value(saturatedFatG),
      fiberG: Value(fiberG),
      saltG: Value(saltG),
      coverage: Value(coverage),
      computedAt: Value(computedAt),
    );
  }

  factory NutritionSnapshotRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NutritionSnapshotRow(
      recipeId: serializer.fromJson<String>(json['recipeId']),
      kcal: serializer.fromJson<double>(json['kcal']),
      proteinG: serializer.fromJson<double>(json['proteinG']),
      carbsG: serializer.fromJson<double>(json['carbsG']),
      sugarsG: serializer.fromJson<double>(json['sugarsG']),
      fatG: serializer.fromJson<double>(json['fatG']),
      saturatedFatG: serializer.fromJson<double>(json['saturatedFatG']),
      fiberG: serializer.fromJson<double>(json['fiberG']),
      saltG: serializer.fromJson<double>(json['saltG']),
      coverage: serializer.fromJson<double>(json['coverage']),
      computedAt: serializer.fromJson<DateTime>(json['computedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'recipeId': serializer.toJson<String>(recipeId),
      'kcal': serializer.toJson<double>(kcal),
      'proteinG': serializer.toJson<double>(proteinG),
      'carbsG': serializer.toJson<double>(carbsG),
      'sugarsG': serializer.toJson<double>(sugarsG),
      'fatG': serializer.toJson<double>(fatG),
      'saturatedFatG': serializer.toJson<double>(saturatedFatG),
      'fiberG': serializer.toJson<double>(fiberG),
      'saltG': serializer.toJson<double>(saltG),
      'coverage': serializer.toJson<double>(coverage),
      'computedAt': serializer.toJson<DateTime>(computedAt),
    };
  }

  NutritionSnapshotRow copyWith({
    String? recipeId,
    double? kcal,
    double? proteinG,
    double? carbsG,
    double? sugarsG,
    double? fatG,
    double? saturatedFatG,
    double? fiberG,
    double? saltG,
    double? coverage,
    DateTime? computedAt,
  }) => NutritionSnapshotRow(
    recipeId: recipeId ?? this.recipeId,
    kcal: kcal ?? this.kcal,
    proteinG: proteinG ?? this.proteinG,
    carbsG: carbsG ?? this.carbsG,
    sugarsG: sugarsG ?? this.sugarsG,
    fatG: fatG ?? this.fatG,
    saturatedFatG: saturatedFatG ?? this.saturatedFatG,
    fiberG: fiberG ?? this.fiberG,
    saltG: saltG ?? this.saltG,
    coverage: coverage ?? this.coverage,
    computedAt: computedAt ?? this.computedAt,
  );
  NutritionSnapshotRow copyWithCompanion(NutritionSnapshotsCompanion data) {
    return NutritionSnapshotRow(
      recipeId: data.recipeId.present ? data.recipeId.value : this.recipeId,
      kcal: data.kcal.present ? data.kcal.value : this.kcal,
      proteinG: data.proteinG.present ? data.proteinG.value : this.proteinG,
      carbsG: data.carbsG.present ? data.carbsG.value : this.carbsG,
      sugarsG: data.sugarsG.present ? data.sugarsG.value : this.sugarsG,
      fatG: data.fatG.present ? data.fatG.value : this.fatG,
      saturatedFatG: data.saturatedFatG.present
          ? data.saturatedFatG.value
          : this.saturatedFatG,
      fiberG: data.fiberG.present ? data.fiberG.value : this.fiberG,
      saltG: data.saltG.present ? data.saltG.value : this.saltG,
      coverage: data.coverage.present ? data.coverage.value : this.coverage,
      computedAt: data.computedAt.present
          ? data.computedAt.value
          : this.computedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NutritionSnapshotRow(')
          ..write('recipeId: $recipeId, ')
          ..write('kcal: $kcal, ')
          ..write('proteinG: $proteinG, ')
          ..write('carbsG: $carbsG, ')
          ..write('sugarsG: $sugarsG, ')
          ..write('fatG: $fatG, ')
          ..write('saturatedFatG: $saturatedFatG, ')
          ..write('fiberG: $fiberG, ')
          ..write('saltG: $saltG, ')
          ..write('coverage: $coverage, ')
          ..write('computedAt: $computedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    recipeId,
    kcal,
    proteinG,
    carbsG,
    sugarsG,
    fatG,
    saturatedFatG,
    fiberG,
    saltG,
    coverage,
    computedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NutritionSnapshotRow &&
          other.recipeId == this.recipeId &&
          other.kcal == this.kcal &&
          other.proteinG == this.proteinG &&
          other.carbsG == this.carbsG &&
          other.sugarsG == this.sugarsG &&
          other.fatG == this.fatG &&
          other.saturatedFatG == this.saturatedFatG &&
          other.fiberG == this.fiberG &&
          other.saltG == this.saltG &&
          other.coverage == this.coverage &&
          other.computedAt == this.computedAt);
}

class NutritionSnapshotsCompanion
    extends UpdateCompanion<NutritionSnapshotRow> {
  final Value<String> recipeId;
  final Value<double> kcal;
  final Value<double> proteinG;
  final Value<double> carbsG;
  final Value<double> sugarsG;
  final Value<double> fatG;
  final Value<double> saturatedFatG;
  final Value<double> fiberG;
  final Value<double> saltG;
  final Value<double> coverage;
  final Value<DateTime> computedAt;
  final Value<int> rowid;
  const NutritionSnapshotsCompanion({
    this.recipeId = const Value.absent(),
    this.kcal = const Value.absent(),
    this.proteinG = const Value.absent(),
    this.carbsG = const Value.absent(),
    this.sugarsG = const Value.absent(),
    this.fatG = const Value.absent(),
    this.saturatedFatG = const Value.absent(),
    this.fiberG = const Value.absent(),
    this.saltG = const Value.absent(),
    this.coverage = const Value.absent(),
    this.computedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  NutritionSnapshotsCompanion.insert({
    required String recipeId,
    required double kcal,
    required double proteinG,
    required double carbsG,
    required double sugarsG,
    required double fatG,
    required double saturatedFatG,
    required double fiberG,
    required double saltG,
    required double coverage,
    required DateTime computedAt,
    this.rowid = const Value.absent(),
  }) : recipeId = Value(recipeId),
       kcal = Value(kcal),
       proteinG = Value(proteinG),
       carbsG = Value(carbsG),
       sugarsG = Value(sugarsG),
       fatG = Value(fatG),
       saturatedFatG = Value(saturatedFatG),
       fiberG = Value(fiberG),
       saltG = Value(saltG),
       coverage = Value(coverage),
       computedAt = Value(computedAt);
  static Insertable<NutritionSnapshotRow> custom({
    Expression<String>? recipeId,
    Expression<double>? kcal,
    Expression<double>? proteinG,
    Expression<double>? carbsG,
    Expression<double>? sugarsG,
    Expression<double>? fatG,
    Expression<double>? saturatedFatG,
    Expression<double>? fiberG,
    Expression<double>? saltG,
    Expression<double>? coverage,
    Expression<DateTime>? computedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (recipeId != null) 'recipe_id': recipeId,
      if (kcal != null) 'kcal': kcal,
      if (proteinG != null) 'protein_g': proteinG,
      if (carbsG != null) 'carbs_g': carbsG,
      if (sugarsG != null) 'sugars_g': sugarsG,
      if (fatG != null) 'fat_g': fatG,
      if (saturatedFatG != null) 'saturated_fat_g': saturatedFatG,
      if (fiberG != null) 'fiber_g': fiberG,
      if (saltG != null) 'salt_g': saltG,
      if (coverage != null) 'coverage': coverage,
      if (computedAt != null) 'computed_at': computedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  NutritionSnapshotsCompanion copyWith({
    Value<String>? recipeId,
    Value<double>? kcal,
    Value<double>? proteinG,
    Value<double>? carbsG,
    Value<double>? sugarsG,
    Value<double>? fatG,
    Value<double>? saturatedFatG,
    Value<double>? fiberG,
    Value<double>? saltG,
    Value<double>? coverage,
    Value<DateTime>? computedAt,
    Value<int>? rowid,
  }) {
    return NutritionSnapshotsCompanion(
      recipeId: recipeId ?? this.recipeId,
      kcal: kcal ?? this.kcal,
      proteinG: proteinG ?? this.proteinG,
      carbsG: carbsG ?? this.carbsG,
      sugarsG: sugarsG ?? this.sugarsG,
      fatG: fatG ?? this.fatG,
      saturatedFatG: saturatedFatG ?? this.saturatedFatG,
      fiberG: fiberG ?? this.fiberG,
      saltG: saltG ?? this.saltG,
      coverage: coverage ?? this.coverage,
      computedAt: computedAt ?? this.computedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (recipeId.present) {
      map['recipe_id'] = Variable<String>(recipeId.value);
    }
    if (kcal.present) {
      map['kcal'] = Variable<double>(kcal.value);
    }
    if (proteinG.present) {
      map['protein_g'] = Variable<double>(proteinG.value);
    }
    if (carbsG.present) {
      map['carbs_g'] = Variable<double>(carbsG.value);
    }
    if (sugarsG.present) {
      map['sugars_g'] = Variable<double>(sugarsG.value);
    }
    if (fatG.present) {
      map['fat_g'] = Variable<double>(fatG.value);
    }
    if (saturatedFatG.present) {
      map['saturated_fat_g'] = Variable<double>(saturatedFatG.value);
    }
    if (fiberG.present) {
      map['fiber_g'] = Variable<double>(fiberG.value);
    }
    if (saltG.present) {
      map['salt_g'] = Variable<double>(saltG.value);
    }
    if (coverage.present) {
      map['coverage'] = Variable<double>(coverage.value);
    }
    if (computedAt.present) {
      map['computed_at'] = Variable<DateTime>(computedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NutritionSnapshotsCompanion(')
          ..write('recipeId: $recipeId, ')
          ..write('kcal: $kcal, ')
          ..write('proteinG: $proteinG, ')
          ..write('carbsG: $carbsG, ')
          ..write('sugarsG: $sugarsG, ')
          ..write('fatG: $fatG, ')
          ..write('saturatedFatG: $saturatedFatG, ')
          ..write('fiberG: $fiberG, ')
          ..write('saltG: $saltG, ')
          ..write('coverage: $coverage, ')
          ..write('computedAt: $computedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ImportJobsTable extends ImportJobs
    with TableInfo<$ImportJobsTable, ImportJobRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ImportJobsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<ImportStatus, String> status =
      GeneratedColumn<String>(
        'status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<ImportStatus>($ImportJobsTable.$converterstatus);
  static const VerificationMeta _sharedTextMeta = const VerificationMeta(
    'sharedText',
  );
  @override
  late final GeneratedColumn<String> sharedText = GeneratedColumn<String>(
    'shared_text',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sharedFilePathMeta = const VerificationMeta(
    'sharedFilePath',
  );
  @override
  late final GeneratedColumn<String> sharedFilePath = GeneratedColumn<String>(
    'shared_file_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<SourcePlatform?, String>
  platform = GeneratedColumn<String>(
    'platform',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  ).withConverter<SourcePlatform?>($ImportJobsTable.$converterplatformn);
  static const VerificationMeta _sourceUrlMeta = const VerificationMeta(
    'sourceUrl',
  );
  @override
  late final GeneratedColumn<String> sourceUrl = GeneratedColumn<String>(
    'source_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceKeyMeta = const VerificationMeta(
    'sourceKey',
  );
  @override
  late final GeneratedColumn<String> sourceKey = GeneratedColumn<String>(
    'source_key',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _attemptsMeta = const VerificationMeta(
    'attempts',
  );
  @override
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
    'attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  late final GeneratedColumnWithTypeConverter<ImportStatus?, String>
  failedStep = GeneratedColumn<String>(
    'failed_step',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  ).withConverter<ImportStatus?>($ImportJobsTable.$converterfailedStepn);
  static const VerificationMeta _errorCodeMeta = const VerificationMeta(
    'errorCode',
  );
  @override
  late final GeneratedColumn<String> errorCode = GeneratedColumn<String>(
    'error_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _errorDetailMeta = const VerificationMeta(
    'errorDetail',
  );
  @override
  late final GeneratedColumn<String> errorDetail = GeneratedColumn<String>(
    'error_detail',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _recipeIdMeta = const VerificationMeta(
    'recipeId',
  );
  @override
  late final GeneratedColumn<String> recipeId = GeneratedColumn<String>(
    'recipe_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES recipes (id) ON DELETE SET NULL',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<ImportJobData, String> data =
      GeneratedColumn<String>(
        'data',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<ImportJobData>($ImportJobsTable.$converterdata);
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    status,
    sharedText,
    sharedFilePath,
    platform,
    sourceUrl,
    sourceKey,
    attempts,
    failedStep,
    errorCode,
    errorDetail,
    recipeId,
    data,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'import_jobs';
  @override
  VerificationContext validateIntegrity(
    Insertable<ImportJobRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('shared_text')) {
      context.handle(
        _sharedTextMeta,
        sharedText.isAcceptableOrUnknown(data['shared_text']!, _sharedTextMeta),
      );
    }
    if (data.containsKey('shared_file_path')) {
      context.handle(
        _sharedFilePathMeta,
        sharedFilePath.isAcceptableOrUnknown(
          data['shared_file_path']!,
          _sharedFilePathMeta,
        ),
      );
    }
    if (data.containsKey('source_url')) {
      context.handle(
        _sourceUrlMeta,
        sourceUrl.isAcceptableOrUnknown(data['source_url']!, _sourceUrlMeta),
      );
    }
    if (data.containsKey('source_key')) {
      context.handle(
        _sourceKeyMeta,
        sourceKey.isAcceptableOrUnknown(data['source_key']!, _sourceKeyMeta),
      );
    }
    if (data.containsKey('attempts')) {
      context.handle(
        _attemptsMeta,
        attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta),
      );
    }
    if (data.containsKey('error_code')) {
      context.handle(
        _errorCodeMeta,
        errorCode.isAcceptableOrUnknown(data['error_code']!, _errorCodeMeta),
      );
    }
    if (data.containsKey('error_detail')) {
      context.handle(
        _errorDetailMeta,
        errorDetail.isAcceptableOrUnknown(
          data['error_detail']!,
          _errorDetailMeta,
        ),
      );
    }
    if (data.containsKey('recipe_id')) {
      context.handle(
        _recipeIdMeta,
        recipeId.isAcceptableOrUnknown(data['recipe_id']!, _recipeIdMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ImportJobRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ImportJobRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      status: $ImportJobsTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}status'],
        )!,
      ),
      sharedText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}shared_text'],
      ),
      sharedFilePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}shared_file_path'],
      ),
      platform: $ImportJobsTable.$converterplatformn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}platform'],
        ),
      ),
      sourceUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_url'],
      ),
      sourceKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_key'],
      ),
      attempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempts'],
      )!,
      failedStep: $ImportJobsTable.$converterfailedStepn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}failed_step'],
        ),
      ),
      errorCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}error_code'],
      ),
      errorDetail: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}error_detail'],
      ),
      recipeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recipe_id'],
      ),
      data: $ImportJobsTable.$converterdata.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}data'],
        )!,
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ImportJobsTable createAlias(String alias) {
    return $ImportJobsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<ImportStatus, String, String> $converterstatus =
      const EnumNameConverter<ImportStatus>(ImportStatus.values);
  static JsonTypeConverter2<SourcePlatform, String, String> $converterplatform =
      const EnumNameConverter<SourcePlatform>(SourcePlatform.values);
  static JsonTypeConverter2<SourcePlatform?, String?, String?>
  $converterplatformn = JsonTypeConverter2.asNullable($converterplatform);
  static JsonTypeConverter2<ImportStatus, String, String> $converterfailedStep =
      const EnumNameConverter<ImportStatus>(ImportStatus.values);
  static JsonTypeConverter2<ImportStatus?, String?, String?>
  $converterfailedStepn = JsonTypeConverter2.asNullable($converterfailedStep);
  static JsonTypeConverter2<ImportJobData, String, Object?> $converterdata =
      importJobDataConverter;
}

class ImportJobRow extends DataClass implements Insertable<ImportJobRow> {
  final String id;
  final ImportStatus status;
  final String? sharedText;
  final String? sharedFilePath;
  final SourcePlatform? platform;
  final String? sourceUrl;
  final String? sourceKey;
  final int attempts;
  final ImportStatus? failedStep;
  final String? errorCode;
  final String? errorDetail;

  /// Se la ricetta viene eliminata il job resta, senza collegamento.
  final String? recipeId;
  final ImportJobData data;
  final DateTime createdAt;
  final DateTime updatedAt;
  const ImportJobRow({
    required this.id,
    required this.status,
    this.sharedText,
    this.sharedFilePath,
    this.platform,
    this.sourceUrl,
    this.sourceKey,
    required this.attempts,
    this.failedStep,
    this.errorCode,
    this.errorDetail,
    this.recipeId,
    required this.data,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    {
      map['status'] = Variable<String>(
        $ImportJobsTable.$converterstatus.toSql(status),
      );
    }
    if (!nullToAbsent || sharedText != null) {
      map['shared_text'] = Variable<String>(sharedText);
    }
    if (!nullToAbsent || sharedFilePath != null) {
      map['shared_file_path'] = Variable<String>(sharedFilePath);
    }
    if (!nullToAbsent || platform != null) {
      map['platform'] = Variable<String>(
        $ImportJobsTable.$converterplatformn.toSql(platform),
      );
    }
    if (!nullToAbsent || sourceUrl != null) {
      map['source_url'] = Variable<String>(sourceUrl);
    }
    if (!nullToAbsent || sourceKey != null) {
      map['source_key'] = Variable<String>(sourceKey);
    }
    map['attempts'] = Variable<int>(attempts);
    if (!nullToAbsent || failedStep != null) {
      map['failed_step'] = Variable<String>(
        $ImportJobsTable.$converterfailedStepn.toSql(failedStep),
      );
    }
    if (!nullToAbsent || errorCode != null) {
      map['error_code'] = Variable<String>(errorCode);
    }
    if (!nullToAbsent || errorDetail != null) {
      map['error_detail'] = Variable<String>(errorDetail);
    }
    if (!nullToAbsent || recipeId != null) {
      map['recipe_id'] = Variable<String>(recipeId);
    }
    {
      map['data'] = Variable<String>(
        $ImportJobsTable.$converterdata.toSql(data),
      );
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ImportJobsCompanion toCompanion(bool nullToAbsent) {
    return ImportJobsCompanion(
      id: Value(id),
      status: Value(status),
      sharedText: sharedText == null && nullToAbsent
          ? const Value.absent()
          : Value(sharedText),
      sharedFilePath: sharedFilePath == null && nullToAbsent
          ? const Value.absent()
          : Value(sharedFilePath),
      platform: platform == null && nullToAbsent
          ? const Value.absent()
          : Value(platform),
      sourceUrl: sourceUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceUrl),
      sourceKey: sourceKey == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceKey),
      attempts: Value(attempts),
      failedStep: failedStep == null && nullToAbsent
          ? const Value.absent()
          : Value(failedStep),
      errorCode: errorCode == null && nullToAbsent
          ? const Value.absent()
          : Value(errorCode),
      errorDetail: errorDetail == null && nullToAbsent
          ? const Value.absent()
          : Value(errorDetail),
      recipeId: recipeId == null && nullToAbsent
          ? const Value.absent()
          : Value(recipeId),
      data: Value(data),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory ImportJobRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ImportJobRow(
      id: serializer.fromJson<String>(json['id']),
      status: $ImportJobsTable.$converterstatus.fromJson(
        serializer.fromJson<String>(json['status']),
      ),
      sharedText: serializer.fromJson<String?>(json['sharedText']),
      sharedFilePath: serializer.fromJson<String?>(json['sharedFilePath']),
      platform: $ImportJobsTable.$converterplatformn.fromJson(
        serializer.fromJson<String?>(json['platform']),
      ),
      sourceUrl: serializer.fromJson<String?>(json['sourceUrl']),
      sourceKey: serializer.fromJson<String?>(json['sourceKey']),
      attempts: serializer.fromJson<int>(json['attempts']),
      failedStep: $ImportJobsTable.$converterfailedStepn.fromJson(
        serializer.fromJson<String?>(json['failedStep']),
      ),
      errorCode: serializer.fromJson<String?>(json['errorCode']),
      errorDetail: serializer.fromJson<String?>(json['errorDetail']),
      recipeId: serializer.fromJson<String?>(json['recipeId']),
      data: $ImportJobsTable.$converterdata.fromJson(
        serializer.fromJson<Object?>(json['data']),
      ),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'status': serializer.toJson<String>(
        $ImportJobsTable.$converterstatus.toJson(status),
      ),
      'sharedText': serializer.toJson<String?>(sharedText),
      'sharedFilePath': serializer.toJson<String?>(sharedFilePath),
      'platform': serializer.toJson<String?>(
        $ImportJobsTable.$converterplatformn.toJson(platform),
      ),
      'sourceUrl': serializer.toJson<String?>(sourceUrl),
      'sourceKey': serializer.toJson<String?>(sourceKey),
      'attempts': serializer.toJson<int>(attempts),
      'failedStep': serializer.toJson<String?>(
        $ImportJobsTable.$converterfailedStepn.toJson(failedStep),
      ),
      'errorCode': serializer.toJson<String?>(errorCode),
      'errorDetail': serializer.toJson<String?>(errorDetail),
      'recipeId': serializer.toJson<String?>(recipeId),
      'data': serializer.toJson<Object?>(
        $ImportJobsTable.$converterdata.toJson(data),
      ),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  ImportJobRow copyWith({
    String? id,
    ImportStatus? status,
    Value<String?> sharedText = const Value.absent(),
    Value<String?> sharedFilePath = const Value.absent(),
    Value<SourcePlatform?> platform = const Value.absent(),
    Value<String?> sourceUrl = const Value.absent(),
    Value<String?> sourceKey = const Value.absent(),
    int? attempts,
    Value<ImportStatus?> failedStep = const Value.absent(),
    Value<String?> errorCode = const Value.absent(),
    Value<String?> errorDetail = const Value.absent(),
    Value<String?> recipeId = const Value.absent(),
    ImportJobData? data,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => ImportJobRow(
    id: id ?? this.id,
    status: status ?? this.status,
    sharedText: sharedText.present ? sharedText.value : this.sharedText,
    sharedFilePath: sharedFilePath.present
        ? sharedFilePath.value
        : this.sharedFilePath,
    platform: platform.present ? platform.value : this.platform,
    sourceUrl: sourceUrl.present ? sourceUrl.value : this.sourceUrl,
    sourceKey: sourceKey.present ? sourceKey.value : this.sourceKey,
    attempts: attempts ?? this.attempts,
    failedStep: failedStep.present ? failedStep.value : this.failedStep,
    errorCode: errorCode.present ? errorCode.value : this.errorCode,
    errorDetail: errorDetail.present ? errorDetail.value : this.errorDetail,
    recipeId: recipeId.present ? recipeId.value : this.recipeId,
    data: data ?? this.data,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ImportJobRow copyWithCompanion(ImportJobsCompanion data) {
    return ImportJobRow(
      id: data.id.present ? data.id.value : this.id,
      status: data.status.present ? data.status.value : this.status,
      sharedText: data.sharedText.present
          ? data.sharedText.value
          : this.sharedText,
      sharedFilePath: data.sharedFilePath.present
          ? data.sharedFilePath.value
          : this.sharedFilePath,
      platform: data.platform.present ? data.platform.value : this.platform,
      sourceUrl: data.sourceUrl.present ? data.sourceUrl.value : this.sourceUrl,
      sourceKey: data.sourceKey.present ? data.sourceKey.value : this.sourceKey,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
      failedStep: data.failedStep.present
          ? data.failedStep.value
          : this.failedStep,
      errorCode: data.errorCode.present ? data.errorCode.value : this.errorCode,
      errorDetail: data.errorDetail.present
          ? data.errorDetail.value
          : this.errorDetail,
      recipeId: data.recipeId.present ? data.recipeId.value : this.recipeId,
      data: data.data.present ? data.data.value : this.data,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ImportJobRow(')
          ..write('id: $id, ')
          ..write('status: $status, ')
          ..write('sharedText: $sharedText, ')
          ..write('sharedFilePath: $sharedFilePath, ')
          ..write('platform: $platform, ')
          ..write('sourceUrl: $sourceUrl, ')
          ..write('sourceKey: $sourceKey, ')
          ..write('attempts: $attempts, ')
          ..write('failedStep: $failedStep, ')
          ..write('errorCode: $errorCode, ')
          ..write('errorDetail: $errorDetail, ')
          ..write('recipeId: $recipeId, ')
          ..write('data: $data, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    status,
    sharedText,
    sharedFilePath,
    platform,
    sourceUrl,
    sourceKey,
    attempts,
    failedStep,
    errorCode,
    errorDetail,
    recipeId,
    data,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ImportJobRow &&
          other.id == this.id &&
          other.status == this.status &&
          other.sharedText == this.sharedText &&
          other.sharedFilePath == this.sharedFilePath &&
          other.platform == this.platform &&
          other.sourceUrl == this.sourceUrl &&
          other.sourceKey == this.sourceKey &&
          other.attempts == this.attempts &&
          other.failedStep == this.failedStep &&
          other.errorCode == this.errorCode &&
          other.errorDetail == this.errorDetail &&
          other.recipeId == this.recipeId &&
          other.data == this.data &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ImportJobsCompanion extends UpdateCompanion<ImportJobRow> {
  final Value<String> id;
  final Value<ImportStatus> status;
  final Value<String?> sharedText;
  final Value<String?> sharedFilePath;
  final Value<SourcePlatform?> platform;
  final Value<String?> sourceUrl;
  final Value<String?> sourceKey;
  final Value<int> attempts;
  final Value<ImportStatus?> failedStep;
  final Value<String?> errorCode;
  final Value<String?> errorDetail;
  final Value<String?> recipeId;
  final Value<ImportJobData> data;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const ImportJobsCompanion({
    this.id = const Value.absent(),
    this.status = const Value.absent(),
    this.sharedText = const Value.absent(),
    this.sharedFilePath = const Value.absent(),
    this.platform = const Value.absent(),
    this.sourceUrl = const Value.absent(),
    this.sourceKey = const Value.absent(),
    this.attempts = const Value.absent(),
    this.failedStep = const Value.absent(),
    this.errorCode = const Value.absent(),
    this.errorDetail = const Value.absent(),
    this.recipeId = const Value.absent(),
    this.data = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ImportJobsCompanion.insert({
    required String id,
    required ImportStatus status,
    this.sharedText = const Value.absent(),
    this.sharedFilePath = const Value.absent(),
    this.platform = const Value.absent(),
    this.sourceUrl = const Value.absent(),
    this.sourceKey = const Value.absent(),
    this.attempts = const Value.absent(),
    this.failedStep = const Value.absent(),
    this.errorCode = const Value.absent(),
    this.errorDetail = const Value.absent(),
    this.recipeId = const Value.absent(),
    required ImportJobData data,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       status = Value(status),
       data = Value(data),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<ImportJobRow> custom({
    Expression<String>? id,
    Expression<String>? status,
    Expression<String>? sharedText,
    Expression<String>? sharedFilePath,
    Expression<String>? platform,
    Expression<String>? sourceUrl,
    Expression<String>? sourceKey,
    Expression<int>? attempts,
    Expression<String>? failedStep,
    Expression<String>? errorCode,
    Expression<String>? errorDetail,
    Expression<String>? recipeId,
    Expression<String>? data,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (status != null) 'status': status,
      if (sharedText != null) 'shared_text': sharedText,
      if (sharedFilePath != null) 'shared_file_path': sharedFilePath,
      if (platform != null) 'platform': platform,
      if (sourceUrl != null) 'source_url': sourceUrl,
      if (sourceKey != null) 'source_key': sourceKey,
      if (attempts != null) 'attempts': attempts,
      if (failedStep != null) 'failed_step': failedStep,
      if (errorCode != null) 'error_code': errorCode,
      if (errorDetail != null) 'error_detail': errorDetail,
      if (recipeId != null) 'recipe_id': recipeId,
      if (data != null) 'data': data,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ImportJobsCompanion copyWith({
    Value<String>? id,
    Value<ImportStatus>? status,
    Value<String?>? sharedText,
    Value<String?>? sharedFilePath,
    Value<SourcePlatform?>? platform,
    Value<String?>? sourceUrl,
    Value<String?>? sourceKey,
    Value<int>? attempts,
    Value<ImportStatus?>? failedStep,
    Value<String?>? errorCode,
    Value<String?>? errorDetail,
    Value<String?>? recipeId,
    Value<ImportJobData>? data,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return ImportJobsCompanion(
      id: id ?? this.id,
      status: status ?? this.status,
      sharedText: sharedText ?? this.sharedText,
      sharedFilePath: sharedFilePath ?? this.sharedFilePath,
      platform: platform ?? this.platform,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      sourceKey: sourceKey ?? this.sourceKey,
      attempts: attempts ?? this.attempts,
      failedStep: failedStep ?? this.failedStep,
      errorCode: errorCode ?? this.errorCode,
      errorDetail: errorDetail ?? this.errorDetail,
      recipeId: recipeId ?? this.recipeId,
      data: data ?? this.data,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(
        $ImportJobsTable.$converterstatus.toSql(status.value),
      );
    }
    if (sharedText.present) {
      map['shared_text'] = Variable<String>(sharedText.value);
    }
    if (sharedFilePath.present) {
      map['shared_file_path'] = Variable<String>(sharedFilePath.value);
    }
    if (platform.present) {
      map['platform'] = Variable<String>(
        $ImportJobsTable.$converterplatformn.toSql(platform.value),
      );
    }
    if (sourceUrl.present) {
      map['source_url'] = Variable<String>(sourceUrl.value);
    }
    if (sourceKey.present) {
      map['source_key'] = Variable<String>(sourceKey.value);
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    if (failedStep.present) {
      map['failed_step'] = Variable<String>(
        $ImportJobsTable.$converterfailedStepn.toSql(failedStep.value),
      );
    }
    if (errorCode.present) {
      map['error_code'] = Variable<String>(errorCode.value);
    }
    if (errorDetail.present) {
      map['error_detail'] = Variable<String>(errorDetail.value);
    }
    if (recipeId.present) {
      map['recipe_id'] = Variable<String>(recipeId.value);
    }
    if (data.present) {
      map['data'] = Variable<String>(
        $ImportJobsTable.$converterdata.toSql(data.value),
      );
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ImportJobsCompanion(')
          ..write('id: $id, ')
          ..write('status: $status, ')
          ..write('sharedText: $sharedText, ')
          ..write('sharedFilePath: $sharedFilePath, ')
          ..write('platform: $platform, ')
          ..write('sourceUrl: $sourceUrl, ')
          ..write('sourceKey: $sourceKey, ')
          ..write('attempts: $attempts, ')
          ..write('failedStep: $failedStep, ')
          ..write('errorCode: $errorCode, ')
          ..write('errorDetail: $errorDetail, ')
          ..write('recipeId: $recipeId, ')
          ..write('data: $data, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final RecipeSearch recipeSearch = RecipeSearch(this);
  late final $RecipesTable recipes = $RecipesTable(this);
  late final Trigger recipeSearchDelete = Trigger(
    'CREATE TRIGGER recipe_search_delete AFTER DELETE ON recipes BEGIN DELETE FROM recipe_search WHERE recipe_id = old.id;END',
    'recipe_search_delete',
  );
  late final $RecipeSourcesTable recipeSources = $RecipeSourcesTable(this);
  late final $IngredientGroupsTable ingredientGroups = $IngredientGroupsTable(
    this,
  );
  late final $IngredientsTable ingredients = $IngredientsTable(this);
  late final $RecipeStepsTable recipeSteps = $RecipeStepsTable(this);
  late final $TagsTable tags = $TagsTable(this);
  late final $RecipeTagsTable recipeTags = $RecipeTagsTable(this);
  late final $NutritionSnapshotsTable nutritionSnapshots =
      $NutritionSnapshotsTable(this);
  late final $ImportJobsTable importJobs = $ImportJobsTable(this);
  late final Index importJobsSourceKey = Index(
    'import_jobs_source_key',
    'CREATE INDEX import_jobs_source_key ON import_jobs (source_key)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    recipeSearch,
    recipes,
    recipeSearchDelete,
    recipeSources,
    ingredientGroups,
    ingredients,
    recipeSteps,
    tags,
    recipeTags,
    nutritionSnapshots,
    importJobs,
    importJobsSourceKey,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'recipes',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('recipe_search', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'recipes',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('recipe_sources', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'recipes',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('ingredient_groups', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'ingredient_groups',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('ingredients', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'recipes',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('recipe_steps', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'recipes',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('recipe_tags', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'tags',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('recipe_tags', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'recipes',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('nutrition_snapshots', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'recipes',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('import_jobs', kind: UpdateKind.update)],
    ),
  ]);
  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);
}

typedef $RecipeSearchCreateCompanionBuilder =
    RecipeSearchCompanion Function({
      required String recipeId,
      required String title,
      required String ingredients,
      required String tags,
      required String author,
      Value<int> rowid,
    });
typedef $RecipeSearchUpdateCompanionBuilder =
    RecipeSearchCompanion Function({
      Value<String> recipeId,
      Value<String> title,
      Value<String> ingredients,
      Value<String> tags,
      Value<String> author,
      Value<int> rowid,
    });

class $RecipeSearchFilterComposer
    extends Composer<_$AppDatabase, RecipeSearch> {
  $RecipeSearchFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get recipeId => $composableBuilder(
    column: $table.recipeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ingredients => $composableBuilder(
    column: $table.ingredients,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tags => $composableBuilder(
    column: $table.tags,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get author => $composableBuilder(
    column: $table.author,
    builder: (column) => ColumnFilters(column),
  );
}

class $RecipeSearchOrderingComposer
    extends Composer<_$AppDatabase, RecipeSearch> {
  $RecipeSearchOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get recipeId => $composableBuilder(
    column: $table.recipeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ingredients => $composableBuilder(
    column: $table.ingredients,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tags => $composableBuilder(
    column: $table.tags,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get author => $composableBuilder(
    column: $table.author,
    builder: (column) => ColumnOrderings(column),
  );
}

class $RecipeSearchAnnotationComposer
    extends Composer<_$AppDatabase, RecipeSearch> {
  $RecipeSearchAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get recipeId =>
      $composableBuilder(column: $table.recipeId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get ingredients => $composableBuilder(
    column: $table.ingredients,
    builder: (column) => column,
  );

  GeneratedColumn<String> get tags =>
      $composableBuilder(column: $table.tags, builder: (column) => column);

  GeneratedColumn<String> get author =>
      $composableBuilder(column: $table.author, builder: (column) => column);
}

class $RecipeSearchTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          RecipeSearch,
          RecipeSearchData,
          $RecipeSearchFilterComposer,
          $RecipeSearchOrderingComposer,
          $RecipeSearchAnnotationComposer,
          $RecipeSearchCreateCompanionBuilder,
          $RecipeSearchUpdateCompanionBuilder,
          (
            RecipeSearchData,
            BaseReferences<_$AppDatabase, RecipeSearch, RecipeSearchData>,
          ),
          RecipeSearchData,
          PrefetchHooks Function()
        > {
  $RecipeSearchTableManager(_$AppDatabase db, RecipeSearch table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $RecipeSearchFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $RecipeSearchOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $RecipeSearchAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> recipeId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> ingredients = const Value.absent(),
                Value<String> tags = const Value.absent(),
                Value<String> author = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RecipeSearchCompanion(
                recipeId: recipeId,
                title: title,
                ingredients: ingredients,
                tags: tags,
                author: author,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String recipeId,
                required String title,
                required String ingredients,
                required String tags,
                required String author,
                Value<int> rowid = const Value.absent(),
              }) => RecipeSearchCompanion.insert(
                recipeId: recipeId,
                title: title,
                ingredients: ingredients,
                tags: tags,
                author: author,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $RecipeSearchProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      RecipeSearch,
      RecipeSearchData,
      $RecipeSearchFilterComposer,
      $RecipeSearchOrderingComposer,
      $RecipeSearchAnnotationComposer,
      $RecipeSearchCreateCompanionBuilder,
      $RecipeSearchUpdateCompanionBuilder,
      (
        RecipeSearchData,
        BaseReferences<_$AppDatabase, RecipeSearch, RecipeSearchData>,
      ),
      RecipeSearchData,
      PrefetchHooks Function()
    >;
typedef $$RecipesTableCreateCompanionBuilder =
    RecipesCompanion Function({
      required String id,
      required String title,
      Value<String?> description,
      required double baseServings,
      Value<String> servingsUnit,
      Value<int?> prepMinutes,
      Value<int?> cookMinutes,
      Value<int?> restMinutes,
      Value<Difficulty?> difficulty,
      Value<String?> thumbnailPath,
      Value<bool> isFavorite,
      Value<String?> extractionModel,
      Value<bool> needsReview,
      Value<bool> isDraft,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$RecipesTableUpdateCompanionBuilder =
    RecipesCompanion Function({
      Value<String> id,
      Value<String> title,
      Value<String?> description,
      Value<double> baseServings,
      Value<String> servingsUnit,
      Value<int?> prepMinutes,
      Value<int?> cookMinutes,
      Value<int?> restMinutes,
      Value<Difficulty?> difficulty,
      Value<String?> thumbnailPath,
      Value<bool> isFavorite,
      Value<String?> extractionModel,
      Value<bool> needsReview,
      Value<bool> isDraft,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$RecipesTableReferences
    extends BaseReferences<_$AppDatabase, $RecipesTable, RecipeRow> {
  $$RecipesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$RecipeSourcesTable, List<RecipeSourceRow>>
  _recipeSourcesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.recipeSources,
    aliasName: 'recipes__id__recipe_sources__recipe_id',
  );

  $$RecipeSourcesTableProcessedTableManager get recipeSourcesRefs {
    final manager = $$RecipeSourcesTableTableManager(
      $_db,
      $_db.recipeSources,
    ).filter((f) => f.recipeId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_recipeSourcesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$IngredientGroupsTable, List<IngredientGroupRow>>
  _ingredientGroupsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.ingredientGroups,
    aliasName: 'recipes__id__ingredient_groups__recipe_id',
  );

  $$IngredientGroupsTableProcessedTableManager get ingredientGroupsRefs {
    final manager = $$IngredientGroupsTableTableManager(
      $_db,
      $_db.ingredientGroups,
    ).filter((f) => f.recipeId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _ingredientGroupsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$RecipeStepsTable, List<RecipeStepRow>>
  _recipeStepsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.recipeSteps,
    aliasName: 'recipes__id__recipe_steps__recipe_id',
  );

  $$RecipeStepsTableProcessedTableManager get recipeStepsRefs {
    final manager = $$RecipeStepsTableTableManager(
      $_db,
      $_db.recipeSteps,
    ).filter((f) => f.recipeId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_recipeStepsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$RecipeTagsTable, List<RecipeTagRow>>
  _recipeTagsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.recipeTags,
    aliasName: 'recipes__id__recipe_tags__recipe_id',
  );

  $$RecipeTagsTableProcessedTableManager get recipeTagsRefs {
    final manager = $$RecipeTagsTableTableManager(
      $_db,
      $_db.recipeTags,
    ).filter((f) => f.recipeId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_recipeTagsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $NutritionSnapshotsTable,
    List<NutritionSnapshotRow>
  >
  _nutritionSnapshotsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.nutritionSnapshots,
        aliasName: 'recipes__id__nutrition_snapshots__recipe_id',
      );

  $$NutritionSnapshotsTableProcessedTableManager get nutritionSnapshotsRefs {
    final manager = $$NutritionSnapshotsTableTableManager(
      $_db,
      $_db.nutritionSnapshots,
    ).filter((f) => f.recipeId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _nutritionSnapshotsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ImportJobsTable, List<ImportJobRow>>
  _importJobsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.importJobs,
    aliasName: 'recipes__id__import_jobs__recipe_id',
  );

  $$ImportJobsTableProcessedTableManager get importJobsRefs {
    final manager = $$ImportJobsTableTableManager(
      $_db,
      $_db.importJobs,
    ).filter((f) => f.recipeId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_importJobsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$RecipesTableFilterComposer
    extends Composer<_$AppDatabase, $RecipesTable> {
  $$RecipesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get baseServings => $composableBuilder(
    column: $table.baseServings,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get servingsUnit => $composableBuilder(
    column: $table.servingsUnit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get prepMinutes => $composableBuilder(
    column: $table.prepMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cookMinutes => $composableBuilder(
    column: $table.cookMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get restMinutes => $composableBuilder(
    column: $table.restMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<Difficulty?, Difficulty, String>
  get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get thumbnailPath => $composableBuilder(
    column: $table.thumbnailPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get extractionModel => $composableBuilder(
    column: $table.extractionModel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get needsReview => $composableBuilder(
    column: $table.needsReview,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDraft => $composableBuilder(
    column: $table.isDraft,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> recipeSourcesRefs(
    Expression<bool> Function($$RecipeSourcesTableFilterComposer f) f,
  ) {
    final $$RecipeSourcesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.recipeSources,
      getReferencedColumn: (t) => t.recipeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecipeSourcesTableFilterComposer(
            $db: $db,
            $table: $db.recipeSources,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> ingredientGroupsRefs(
    Expression<bool> Function($$IngredientGroupsTableFilterComposer f) f,
  ) {
    final $$IngredientGroupsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.ingredientGroups,
      getReferencedColumn: (t) => t.recipeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$IngredientGroupsTableFilterComposer(
            $db: $db,
            $table: $db.ingredientGroups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> recipeStepsRefs(
    Expression<bool> Function($$RecipeStepsTableFilterComposer f) f,
  ) {
    final $$RecipeStepsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.recipeSteps,
      getReferencedColumn: (t) => t.recipeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecipeStepsTableFilterComposer(
            $db: $db,
            $table: $db.recipeSteps,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> recipeTagsRefs(
    Expression<bool> Function($$RecipeTagsTableFilterComposer f) f,
  ) {
    final $$RecipeTagsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.recipeTags,
      getReferencedColumn: (t) => t.recipeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecipeTagsTableFilterComposer(
            $db: $db,
            $table: $db.recipeTags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> nutritionSnapshotsRefs(
    Expression<bool> Function($$NutritionSnapshotsTableFilterComposer f) f,
  ) {
    final $$NutritionSnapshotsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.nutritionSnapshots,
      getReferencedColumn: (t) => t.recipeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NutritionSnapshotsTableFilterComposer(
            $db: $db,
            $table: $db.nutritionSnapshots,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> importJobsRefs(
    Expression<bool> Function($$ImportJobsTableFilterComposer f) f,
  ) {
    final $$ImportJobsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.importJobs,
      getReferencedColumn: (t) => t.recipeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ImportJobsTableFilterComposer(
            $db: $db,
            $table: $db.importJobs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$RecipesTableOrderingComposer
    extends Composer<_$AppDatabase, $RecipesTable> {
  $$RecipesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get baseServings => $composableBuilder(
    column: $table.baseServings,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get servingsUnit => $composableBuilder(
    column: $table.servingsUnit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get prepMinutes => $composableBuilder(
    column: $table.prepMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cookMinutes => $composableBuilder(
    column: $table.cookMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get restMinutes => $composableBuilder(
    column: $table.restMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get thumbnailPath => $composableBuilder(
    column: $table.thumbnailPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get extractionModel => $composableBuilder(
    column: $table.extractionModel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get needsReview => $composableBuilder(
    column: $table.needsReview,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDraft => $composableBuilder(
    column: $table.isDraft,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RecipesTableAnnotationComposer
    extends Composer<_$AppDatabase, $RecipesTable> {
  $$RecipesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<double> get baseServings => $composableBuilder(
    column: $table.baseServings,
    builder: (column) => column,
  );

  GeneratedColumn<String> get servingsUnit => $composableBuilder(
    column: $table.servingsUnit,
    builder: (column) => column,
  );

  GeneratedColumn<int> get prepMinutes => $composableBuilder(
    column: $table.prepMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get cookMinutes => $composableBuilder(
    column: $table.cookMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get restMinutes => $composableBuilder(
    column: $table.restMinutes,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<Difficulty?, String> get difficulty =>
      $composableBuilder(
        column: $table.difficulty,
        builder: (column) => column,
      );

  GeneratedColumn<String> get thumbnailPath => $composableBuilder(
    column: $table.thumbnailPath,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => column,
  );

  GeneratedColumn<String> get extractionModel => $composableBuilder(
    column: $table.extractionModel,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get needsReview => $composableBuilder(
    column: $table.needsReview,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isDraft =>
      $composableBuilder(column: $table.isDraft, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> recipeSourcesRefs<T extends Object>(
    Expression<T> Function($$RecipeSourcesTableAnnotationComposer a) f,
  ) {
    final $$RecipeSourcesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.recipeSources,
      getReferencedColumn: (t) => t.recipeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecipeSourcesTableAnnotationComposer(
            $db: $db,
            $table: $db.recipeSources,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> ingredientGroupsRefs<T extends Object>(
    Expression<T> Function($$IngredientGroupsTableAnnotationComposer a) f,
  ) {
    final $$IngredientGroupsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.ingredientGroups,
      getReferencedColumn: (t) => t.recipeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$IngredientGroupsTableAnnotationComposer(
            $db: $db,
            $table: $db.ingredientGroups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> recipeStepsRefs<T extends Object>(
    Expression<T> Function($$RecipeStepsTableAnnotationComposer a) f,
  ) {
    final $$RecipeStepsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.recipeSteps,
      getReferencedColumn: (t) => t.recipeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecipeStepsTableAnnotationComposer(
            $db: $db,
            $table: $db.recipeSteps,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> recipeTagsRefs<T extends Object>(
    Expression<T> Function($$RecipeTagsTableAnnotationComposer a) f,
  ) {
    final $$RecipeTagsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.recipeTags,
      getReferencedColumn: (t) => t.recipeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecipeTagsTableAnnotationComposer(
            $db: $db,
            $table: $db.recipeTags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> nutritionSnapshotsRefs<T extends Object>(
    Expression<T> Function($$NutritionSnapshotsTableAnnotationComposer a) f,
  ) {
    final $$NutritionSnapshotsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.nutritionSnapshots,
          getReferencedColumn: (t) => t.recipeId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$NutritionSnapshotsTableAnnotationComposer(
                $db: $db,
                $table: $db.nutritionSnapshots,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> importJobsRefs<T extends Object>(
    Expression<T> Function($$ImportJobsTableAnnotationComposer a) f,
  ) {
    final $$ImportJobsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.importJobs,
      getReferencedColumn: (t) => t.recipeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ImportJobsTableAnnotationComposer(
            $db: $db,
            $table: $db.importJobs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$RecipesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RecipesTable,
          RecipeRow,
          $$RecipesTableFilterComposer,
          $$RecipesTableOrderingComposer,
          $$RecipesTableAnnotationComposer,
          $$RecipesTableCreateCompanionBuilder,
          $$RecipesTableUpdateCompanionBuilder,
          (RecipeRow, $$RecipesTableReferences),
          RecipeRow,
          PrefetchHooks Function({
            bool recipeSourcesRefs,
            bool ingredientGroupsRefs,
            bool recipeStepsRefs,
            bool recipeTagsRefs,
            bool nutritionSnapshotsRefs,
            bool importJobsRefs,
          })
        > {
  $$RecipesTableTableManager(_$AppDatabase db, $RecipesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RecipesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RecipesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RecipesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<double> baseServings = const Value.absent(),
                Value<String> servingsUnit = const Value.absent(),
                Value<int?> prepMinutes = const Value.absent(),
                Value<int?> cookMinutes = const Value.absent(),
                Value<int?> restMinutes = const Value.absent(),
                Value<Difficulty?> difficulty = const Value.absent(),
                Value<String?> thumbnailPath = const Value.absent(),
                Value<bool> isFavorite = const Value.absent(),
                Value<String?> extractionModel = const Value.absent(),
                Value<bool> needsReview = const Value.absent(),
                Value<bool> isDraft = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RecipesCompanion(
                id: id,
                title: title,
                description: description,
                baseServings: baseServings,
                servingsUnit: servingsUnit,
                prepMinutes: prepMinutes,
                cookMinutes: cookMinutes,
                restMinutes: restMinutes,
                difficulty: difficulty,
                thumbnailPath: thumbnailPath,
                isFavorite: isFavorite,
                extractionModel: extractionModel,
                needsReview: needsReview,
                isDraft: isDraft,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String title,
                Value<String?> description = const Value.absent(),
                required double baseServings,
                Value<String> servingsUnit = const Value.absent(),
                Value<int?> prepMinutes = const Value.absent(),
                Value<int?> cookMinutes = const Value.absent(),
                Value<int?> restMinutes = const Value.absent(),
                Value<Difficulty?> difficulty = const Value.absent(),
                Value<String?> thumbnailPath = const Value.absent(),
                Value<bool> isFavorite = const Value.absent(),
                Value<String?> extractionModel = const Value.absent(),
                Value<bool> needsReview = const Value.absent(),
                Value<bool> isDraft = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => RecipesCompanion.insert(
                id: id,
                title: title,
                description: description,
                baseServings: baseServings,
                servingsUnit: servingsUnit,
                prepMinutes: prepMinutes,
                cookMinutes: cookMinutes,
                restMinutes: restMinutes,
                difficulty: difficulty,
                thumbnailPath: thumbnailPath,
                isFavorite: isFavorite,
                extractionModel: extractionModel,
                needsReview: needsReview,
                isDraft: isDraft,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$RecipesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                recipeSourcesRefs = false,
                ingredientGroupsRefs = false,
                recipeStepsRefs = false,
                recipeTagsRefs = false,
                nutritionSnapshotsRefs = false,
                importJobsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (recipeSourcesRefs) db.recipeSources,
                    if (ingredientGroupsRefs) db.ingredientGroups,
                    if (recipeStepsRefs) db.recipeSteps,
                    if (recipeTagsRefs) db.recipeTags,
                    if (nutritionSnapshotsRefs) db.nutritionSnapshots,
                    if (importJobsRefs) db.importJobs,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (recipeSourcesRefs)
                        await $_getPrefetchedData<
                          RecipeRow,
                          $RecipesTable,
                          RecipeSourceRow
                        >(
                          currentTable: table,
                          referencedTable: $$RecipesTableReferences
                              ._recipeSourcesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$RecipesTableReferences(
                                db,
                                table,
                                p0,
                              ).recipeSourcesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.recipeId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (ingredientGroupsRefs)
                        await $_getPrefetchedData<
                          RecipeRow,
                          $RecipesTable,
                          IngredientGroupRow
                        >(
                          currentTable: table,
                          referencedTable: $$RecipesTableReferences
                              ._ingredientGroupsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$RecipesTableReferences(
                                db,
                                table,
                                p0,
                              ).ingredientGroupsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.recipeId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (recipeStepsRefs)
                        await $_getPrefetchedData<
                          RecipeRow,
                          $RecipesTable,
                          RecipeStepRow
                        >(
                          currentTable: table,
                          referencedTable: $$RecipesTableReferences
                              ._recipeStepsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$RecipesTableReferences(
                                db,
                                table,
                                p0,
                              ).recipeStepsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.recipeId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (recipeTagsRefs)
                        await $_getPrefetchedData<
                          RecipeRow,
                          $RecipesTable,
                          RecipeTagRow
                        >(
                          currentTable: table,
                          referencedTable: $$RecipesTableReferences
                              ._recipeTagsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$RecipesTableReferences(
                                db,
                                table,
                                p0,
                              ).recipeTagsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.recipeId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (nutritionSnapshotsRefs)
                        await $_getPrefetchedData<
                          RecipeRow,
                          $RecipesTable,
                          NutritionSnapshotRow
                        >(
                          currentTable: table,
                          referencedTable: $$RecipesTableReferences
                              ._nutritionSnapshotsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$RecipesTableReferences(
                                db,
                                table,
                                p0,
                              ).nutritionSnapshotsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.recipeId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (importJobsRefs)
                        await $_getPrefetchedData<
                          RecipeRow,
                          $RecipesTable,
                          ImportJobRow
                        >(
                          currentTable: table,
                          referencedTable: $$RecipesTableReferences
                              ._importJobsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$RecipesTableReferences(
                                db,
                                table,
                                p0,
                              ).importJobsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.recipeId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$RecipesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RecipesTable,
      RecipeRow,
      $$RecipesTableFilterComposer,
      $$RecipesTableOrderingComposer,
      $$RecipesTableAnnotationComposer,
      $$RecipesTableCreateCompanionBuilder,
      $$RecipesTableUpdateCompanionBuilder,
      (RecipeRow, $$RecipesTableReferences),
      RecipeRow,
      PrefetchHooks Function({
        bool recipeSourcesRefs,
        bool ingredientGroupsRefs,
        bool recipeStepsRefs,
        bool recipeTagsRefs,
        bool nutritionSnapshotsRefs,
        bool importJobsRefs,
      })
    >;
typedef $$RecipeSourcesTableCreateCompanionBuilder =
    RecipeSourcesCompanion Function({
      required String recipeId,
      required SourcePlatform platform,
      Value<String?> url,
      Value<String?> sourceKey,
      Value<String?> authorName,
      Value<String?> caption,
      Value<String?> transcript,
      required TranscriptQuality transcriptQuality,
      Value<int> rowid,
    });
typedef $$RecipeSourcesTableUpdateCompanionBuilder =
    RecipeSourcesCompanion Function({
      Value<String> recipeId,
      Value<SourcePlatform> platform,
      Value<String?> url,
      Value<String?> sourceKey,
      Value<String?> authorName,
      Value<String?> caption,
      Value<String?> transcript,
      Value<TranscriptQuality> transcriptQuality,
      Value<int> rowid,
    });

final class $$RecipeSourcesTableReferences
    extends
        BaseReferences<_$AppDatabase, $RecipeSourcesTable, RecipeSourceRow> {
  $$RecipeSourcesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $RecipesTable _recipeIdTable(_$AppDatabase db) =>
      db.recipes.createAlias('recipe_sources__recipe_id__recipes__id');

  $$RecipesTableProcessedTableManager get recipeId {
    final $_column = $_itemColumn<String>('recipe_id')!;

    final manager = $$RecipesTableTableManager(
      $_db,
      $_db.recipes,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_recipeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$RecipeSourcesTableFilterComposer
    extends Composer<_$AppDatabase, $RecipeSourcesTable> {
  $$RecipeSourcesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnWithTypeConverterFilters<SourcePlatform, SourcePlatform, String>
  get platform => $composableBuilder(
    column: $table.platform,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceKey => $composableBuilder(
    column: $table.sourceKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get authorName => $composableBuilder(
    column: $table.authorName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get caption => $composableBuilder(
    column: $table.caption,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get transcript => $composableBuilder(
    column: $table.transcript,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<TranscriptQuality, TranscriptQuality, String>
  get transcriptQuality => $composableBuilder(
    column: $table.transcriptQuality,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  $$RecipesTableFilterComposer get recipeId {
    final $$RecipesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recipeId,
      referencedTable: $db.recipes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecipesTableFilterComposer(
            $db: $db,
            $table: $db.recipes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RecipeSourcesTableOrderingComposer
    extends Composer<_$AppDatabase, $RecipeSourcesTable> {
  $$RecipeSourcesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get platform => $composableBuilder(
    column: $table.platform,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceKey => $composableBuilder(
    column: $table.sourceKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get authorName => $composableBuilder(
    column: $table.authorName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get caption => $composableBuilder(
    column: $table.caption,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get transcript => $composableBuilder(
    column: $table.transcript,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get transcriptQuality => $composableBuilder(
    column: $table.transcriptQuality,
    builder: (column) => ColumnOrderings(column),
  );

  $$RecipesTableOrderingComposer get recipeId {
    final $$RecipesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recipeId,
      referencedTable: $db.recipes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecipesTableOrderingComposer(
            $db: $db,
            $table: $db.recipes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RecipeSourcesTableAnnotationComposer
    extends Composer<_$AppDatabase, $RecipeSourcesTable> {
  $$RecipeSourcesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumnWithTypeConverter<SourcePlatform, String> get platform =>
      $composableBuilder(column: $table.platform, builder: (column) => column);

  GeneratedColumn<String> get url =>
      $composableBuilder(column: $table.url, builder: (column) => column);

  GeneratedColumn<String> get sourceKey =>
      $composableBuilder(column: $table.sourceKey, builder: (column) => column);

  GeneratedColumn<String> get authorName => $composableBuilder(
    column: $table.authorName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get caption =>
      $composableBuilder(column: $table.caption, builder: (column) => column);

  GeneratedColumn<String> get transcript => $composableBuilder(
    column: $table.transcript,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<TranscriptQuality, String>
  get transcriptQuality => $composableBuilder(
    column: $table.transcriptQuality,
    builder: (column) => column,
  );

  $$RecipesTableAnnotationComposer get recipeId {
    final $$RecipesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recipeId,
      referencedTable: $db.recipes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecipesTableAnnotationComposer(
            $db: $db,
            $table: $db.recipes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RecipeSourcesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RecipeSourcesTable,
          RecipeSourceRow,
          $$RecipeSourcesTableFilterComposer,
          $$RecipeSourcesTableOrderingComposer,
          $$RecipeSourcesTableAnnotationComposer,
          $$RecipeSourcesTableCreateCompanionBuilder,
          $$RecipeSourcesTableUpdateCompanionBuilder,
          (RecipeSourceRow, $$RecipeSourcesTableReferences),
          RecipeSourceRow,
          PrefetchHooks Function({bool recipeId})
        > {
  $$RecipeSourcesTableTableManager(_$AppDatabase db, $RecipeSourcesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RecipeSourcesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RecipeSourcesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RecipeSourcesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> recipeId = const Value.absent(),
                Value<SourcePlatform> platform = const Value.absent(),
                Value<String?> url = const Value.absent(),
                Value<String?> sourceKey = const Value.absent(),
                Value<String?> authorName = const Value.absent(),
                Value<String?> caption = const Value.absent(),
                Value<String?> transcript = const Value.absent(),
                Value<TranscriptQuality> transcriptQuality =
                    const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RecipeSourcesCompanion(
                recipeId: recipeId,
                platform: platform,
                url: url,
                sourceKey: sourceKey,
                authorName: authorName,
                caption: caption,
                transcript: transcript,
                transcriptQuality: transcriptQuality,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String recipeId,
                required SourcePlatform platform,
                Value<String?> url = const Value.absent(),
                Value<String?> sourceKey = const Value.absent(),
                Value<String?> authorName = const Value.absent(),
                Value<String?> caption = const Value.absent(),
                Value<String?> transcript = const Value.absent(),
                required TranscriptQuality transcriptQuality,
                Value<int> rowid = const Value.absent(),
              }) => RecipeSourcesCompanion.insert(
                recipeId: recipeId,
                platform: platform,
                url: url,
                sourceKey: sourceKey,
                authorName: authorName,
                caption: caption,
                transcript: transcript,
                transcriptQuality: transcriptQuality,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$RecipeSourcesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({recipeId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (recipeId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.recipeId,
                                referencedTable: $$RecipeSourcesTableReferences
                                    ._recipeIdTable(db),
                                referencedColumn: $$RecipeSourcesTableReferences
                                    ._recipeIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$RecipeSourcesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RecipeSourcesTable,
      RecipeSourceRow,
      $$RecipeSourcesTableFilterComposer,
      $$RecipeSourcesTableOrderingComposer,
      $$RecipeSourcesTableAnnotationComposer,
      $$RecipeSourcesTableCreateCompanionBuilder,
      $$RecipeSourcesTableUpdateCompanionBuilder,
      (RecipeSourceRow, $$RecipeSourcesTableReferences),
      RecipeSourceRow,
      PrefetchHooks Function({bool recipeId})
    >;
typedef $$IngredientGroupsTableCreateCompanionBuilder =
    IngredientGroupsCompanion Function({
      required String id,
      required String recipeId,
      Value<String?> name,
      required int position,
      Value<int> rowid,
    });
typedef $$IngredientGroupsTableUpdateCompanionBuilder =
    IngredientGroupsCompanion Function({
      Value<String> id,
      Value<String> recipeId,
      Value<String?> name,
      Value<int> position,
      Value<int> rowid,
    });

final class $$IngredientGroupsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $IngredientGroupsTable,
          IngredientGroupRow
        > {
  $$IngredientGroupsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $RecipesTable _recipeIdTable(_$AppDatabase db) =>
      db.recipes.createAlias('ingredient_groups__recipe_id__recipes__id');

  $$RecipesTableProcessedTableManager get recipeId {
    final $_column = $_itemColumn<String>('recipe_id')!;

    final manager = $$RecipesTableTableManager(
      $_db,
      $_db.recipes,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_recipeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$IngredientsTable, List<IngredientRow>>
  _ingredientsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.ingredients,
    aliasName: 'ingredient_groups__id__ingredients__group_id',
  );

  $$IngredientsTableProcessedTableManager get ingredientsRefs {
    final manager = $$IngredientsTableTableManager(
      $_db,
      $_db.ingredients,
    ).filter((f) => f.groupId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_ingredientsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$IngredientGroupsTableFilterComposer
    extends Composer<_$AppDatabase, $IngredientGroupsTable> {
  $$IngredientGroupsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  $$RecipesTableFilterComposer get recipeId {
    final $$RecipesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recipeId,
      referencedTable: $db.recipes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecipesTableFilterComposer(
            $db: $db,
            $table: $db.recipes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> ingredientsRefs(
    Expression<bool> Function($$IngredientsTableFilterComposer f) f,
  ) {
    final $$IngredientsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.ingredients,
      getReferencedColumn: (t) => t.groupId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$IngredientsTableFilterComposer(
            $db: $db,
            $table: $db.ingredients,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$IngredientGroupsTableOrderingComposer
    extends Composer<_$AppDatabase, $IngredientGroupsTable> {
  $$IngredientGroupsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  $$RecipesTableOrderingComposer get recipeId {
    final $$RecipesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recipeId,
      referencedTable: $db.recipes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecipesTableOrderingComposer(
            $db: $db,
            $table: $db.recipes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$IngredientGroupsTableAnnotationComposer
    extends Composer<_$AppDatabase, $IngredientGroupsTable> {
  $$IngredientGroupsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  $$RecipesTableAnnotationComposer get recipeId {
    final $$RecipesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recipeId,
      referencedTable: $db.recipes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecipesTableAnnotationComposer(
            $db: $db,
            $table: $db.recipes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> ingredientsRefs<T extends Object>(
    Expression<T> Function($$IngredientsTableAnnotationComposer a) f,
  ) {
    final $$IngredientsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.ingredients,
      getReferencedColumn: (t) => t.groupId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$IngredientsTableAnnotationComposer(
            $db: $db,
            $table: $db.ingredients,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$IngredientGroupsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $IngredientGroupsTable,
          IngredientGroupRow,
          $$IngredientGroupsTableFilterComposer,
          $$IngredientGroupsTableOrderingComposer,
          $$IngredientGroupsTableAnnotationComposer,
          $$IngredientGroupsTableCreateCompanionBuilder,
          $$IngredientGroupsTableUpdateCompanionBuilder,
          (IngredientGroupRow, $$IngredientGroupsTableReferences),
          IngredientGroupRow,
          PrefetchHooks Function({bool recipeId, bool ingredientsRefs})
        > {
  $$IngredientGroupsTableTableManager(
    _$AppDatabase db,
    $IngredientGroupsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$IngredientGroupsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$IngredientGroupsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$IngredientGroupsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> recipeId = const Value.absent(),
                Value<String?> name = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => IngredientGroupsCompanion(
                id: id,
                recipeId: recipeId,
                name: name,
                position: position,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String recipeId,
                Value<String?> name = const Value.absent(),
                required int position,
                Value<int> rowid = const Value.absent(),
              }) => IngredientGroupsCompanion.insert(
                id: id,
                recipeId: recipeId,
                name: name,
                position: position,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$IngredientGroupsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({recipeId = false, ingredientsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (ingredientsRefs) db.ingredients],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (recipeId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.recipeId,
                                referencedTable:
                                    $$IngredientGroupsTableReferences
                                        ._recipeIdTable(db),
                                referencedColumn:
                                    $$IngredientGroupsTableReferences
                                        ._recipeIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (ingredientsRefs)
                    await $_getPrefetchedData<
                      IngredientGroupRow,
                      $IngredientGroupsTable,
                      IngredientRow
                    >(
                      currentTable: table,
                      referencedTable: $$IngredientGroupsTableReferences
                          ._ingredientsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$IngredientGroupsTableReferences(
                            db,
                            table,
                            p0,
                          ).ingredientsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.groupId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$IngredientGroupsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $IngredientGroupsTable,
      IngredientGroupRow,
      $$IngredientGroupsTableFilterComposer,
      $$IngredientGroupsTableOrderingComposer,
      $$IngredientGroupsTableAnnotationComposer,
      $$IngredientGroupsTableCreateCompanionBuilder,
      $$IngredientGroupsTableUpdateCompanionBuilder,
      (IngredientGroupRow, $$IngredientGroupsTableReferences),
      IngredientGroupRow,
      PrefetchHooks Function({bool recipeId, bool ingredientsRefs})
    >;
typedef $$IngredientsTableCreateCompanionBuilder =
    IngredientsCompanion Function({
      required String id,
      required String groupId,
      required int position,
      required String name,
      Value<double?> quantity,
      Value<double?> quantityMax,
      required IngredientUnit unit,
      Value<double?> gramsEstimate,
      Value<bool> isEstimated,
      Value<String?> note,
      required ScalingRule scalingRule,
      Value<double?> scalingExponent,
      Value<String?> canonicalNameEn,
      Value<int?> foodId,
      Value<double?> matchConfidence,
      Value<int> rowid,
    });
typedef $$IngredientsTableUpdateCompanionBuilder =
    IngredientsCompanion Function({
      Value<String> id,
      Value<String> groupId,
      Value<int> position,
      Value<String> name,
      Value<double?> quantity,
      Value<double?> quantityMax,
      Value<IngredientUnit> unit,
      Value<double?> gramsEstimate,
      Value<bool> isEstimated,
      Value<String?> note,
      Value<ScalingRule> scalingRule,
      Value<double?> scalingExponent,
      Value<String?> canonicalNameEn,
      Value<int?> foodId,
      Value<double?> matchConfidence,
      Value<int> rowid,
    });

final class $$IngredientsTableReferences
    extends BaseReferences<_$AppDatabase, $IngredientsTable, IngredientRow> {
  $$IngredientsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $IngredientGroupsTable _groupIdTable(_$AppDatabase db) => db
      .ingredientGroups
      .createAlias('ingredients__group_id__ingredient_groups__id');

  $$IngredientGroupsTableProcessedTableManager get groupId {
    final $_column = $_itemColumn<String>('group_id')!;

    final manager = $$IngredientGroupsTableTableManager(
      $_db,
      $_db.ingredientGroups,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_groupIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$IngredientsTableFilterComposer
    extends Composer<_$AppDatabase, $IngredientsTable> {
  $$IngredientsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get quantityMax => $composableBuilder(
    column: $table.quantityMax,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<IngredientUnit, IngredientUnit, String>
  get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<double> get gramsEstimate => $composableBuilder(
    column: $table.gramsEstimate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isEstimated => $composableBuilder(
    column: $table.isEstimated,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<ScalingRule, ScalingRule, String>
  get scalingRule => $composableBuilder(
    column: $table.scalingRule,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<double> get scalingExponent => $composableBuilder(
    column: $table.scalingExponent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get canonicalNameEn => $composableBuilder(
    column: $table.canonicalNameEn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get foodId => $composableBuilder(
    column: $table.foodId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get matchConfidence => $composableBuilder(
    column: $table.matchConfidence,
    builder: (column) => ColumnFilters(column),
  );

  $$IngredientGroupsTableFilterComposer get groupId {
    final $$IngredientGroupsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.ingredientGroups,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$IngredientGroupsTableFilterComposer(
            $db: $db,
            $table: $db.ingredientGroups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$IngredientsTableOrderingComposer
    extends Composer<_$AppDatabase, $IngredientsTable> {
  $$IngredientsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get quantityMax => $composableBuilder(
    column: $table.quantityMax,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get gramsEstimate => $composableBuilder(
    column: $table.gramsEstimate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isEstimated => $composableBuilder(
    column: $table.isEstimated,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get scalingRule => $composableBuilder(
    column: $table.scalingRule,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get scalingExponent => $composableBuilder(
    column: $table.scalingExponent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get canonicalNameEn => $composableBuilder(
    column: $table.canonicalNameEn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get foodId => $composableBuilder(
    column: $table.foodId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get matchConfidence => $composableBuilder(
    column: $table.matchConfidence,
    builder: (column) => ColumnOrderings(column),
  );

  $$IngredientGroupsTableOrderingComposer get groupId {
    final $$IngredientGroupsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.ingredientGroups,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$IngredientGroupsTableOrderingComposer(
            $db: $db,
            $table: $db.ingredientGroups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$IngredientsTableAnnotationComposer
    extends Composer<_$AppDatabase, $IngredientsTable> {
  $$IngredientsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<double> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<double> get quantityMax => $composableBuilder(
    column: $table.quantityMax,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<IngredientUnit, String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<double> get gramsEstimate => $composableBuilder(
    column: $table.gramsEstimate,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isEstimated => $composableBuilder(
    column: $table.isEstimated,
    builder: (column) => column,
  );

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ScalingRule, String> get scalingRule =>
      $composableBuilder(
        column: $table.scalingRule,
        builder: (column) => column,
      );

  GeneratedColumn<double> get scalingExponent => $composableBuilder(
    column: $table.scalingExponent,
    builder: (column) => column,
  );

  GeneratedColumn<String> get canonicalNameEn => $composableBuilder(
    column: $table.canonicalNameEn,
    builder: (column) => column,
  );

  GeneratedColumn<int> get foodId =>
      $composableBuilder(column: $table.foodId, builder: (column) => column);

  GeneratedColumn<double> get matchConfidence => $composableBuilder(
    column: $table.matchConfidence,
    builder: (column) => column,
  );

  $$IngredientGroupsTableAnnotationComposer get groupId {
    final $$IngredientGroupsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.ingredientGroups,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$IngredientGroupsTableAnnotationComposer(
            $db: $db,
            $table: $db.ingredientGroups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$IngredientsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $IngredientsTable,
          IngredientRow,
          $$IngredientsTableFilterComposer,
          $$IngredientsTableOrderingComposer,
          $$IngredientsTableAnnotationComposer,
          $$IngredientsTableCreateCompanionBuilder,
          $$IngredientsTableUpdateCompanionBuilder,
          (IngredientRow, $$IngredientsTableReferences),
          IngredientRow,
          PrefetchHooks Function({bool groupId})
        > {
  $$IngredientsTableTableManager(_$AppDatabase db, $IngredientsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$IngredientsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$IngredientsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$IngredientsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> groupId = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<double?> quantity = const Value.absent(),
                Value<double?> quantityMax = const Value.absent(),
                Value<IngredientUnit> unit = const Value.absent(),
                Value<double?> gramsEstimate = const Value.absent(),
                Value<bool> isEstimated = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<ScalingRule> scalingRule = const Value.absent(),
                Value<double?> scalingExponent = const Value.absent(),
                Value<String?> canonicalNameEn = const Value.absent(),
                Value<int?> foodId = const Value.absent(),
                Value<double?> matchConfidence = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => IngredientsCompanion(
                id: id,
                groupId: groupId,
                position: position,
                name: name,
                quantity: quantity,
                quantityMax: quantityMax,
                unit: unit,
                gramsEstimate: gramsEstimate,
                isEstimated: isEstimated,
                note: note,
                scalingRule: scalingRule,
                scalingExponent: scalingExponent,
                canonicalNameEn: canonicalNameEn,
                foodId: foodId,
                matchConfidence: matchConfidence,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String groupId,
                required int position,
                required String name,
                Value<double?> quantity = const Value.absent(),
                Value<double?> quantityMax = const Value.absent(),
                required IngredientUnit unit,
                Value<double?> gramsEstimate = const Value.absent(),
                Value<bool> isEstimated = const Value.absent(),
                Value<String?> note = const Value.absent(),
                required ScalingRule scalingRule,
                Value<double?> scalingExponent = const Value.absent(),
                Value<String?> canonicalNameEn = const Value.absent(),
                Value<int?> foodId = const Value.absent(),
                Value<double?> matchConfidence = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => IngredientsCompanion.insert(
                id: id,
                groupId: groupId,
                position: position,
                name: name,
                quantity: quantity,
                quantityMax: quantityMax,
                unit: unit,
                gramsEstimate: gramsEstimate,
                isEstimated: isEstimated,
                note: note,
                scalingRule: scalingRule,
                scalingExponent: scalingExponent,
                canonicalNameEn: canonicalNameEn,
                foodId: foodId,
                matchConfidence: matchConfidence,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$IngredientsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({groupId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (groupId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.groupId,
                                referencedTable: $$IngredientsTableReferences
                                    ._groupIdTable(db),
                                referencedColumn: $$IngredientsTableReferences
                                    ._groupIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$IngredientsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $IngredientsTable,
      IngredientRow,
      $$IngredientsTableFilterComposer,
      $$IngredientsTableOrderingComposer,
      $$IngredientsTableAnnotationComposer,
      $$IngredientsTableCreateCompanionBuilder,
      $$IngredientsTableUpdateCompanionBuilder,
      (IngredientRow, $$IngredientsTableReferences),
      IngredientRow,
      PrefetchHooks Function({bool groupId})
    >;
typedef $$RecipeStepsTableCreateCompanionBuilder =
    RecipeStepsCompanion Function({
      required String id,
      required String recipeId,
      required int number,
      required String body,
      Value<int?> durationMinutes,
      Value<int?> temperatureC,
      Value<int> rowid,
    });
typedef $$RecipeStepsTableUpdateCompanionBuilder =
    RecipeStepsCompanion Function({
      Value<String> id,
      Value<String> recipeId,
      Value<int> number,
      Value<String> body,
      Value<int?> durationMinutes,
      Value<int?> temperatureC,
      Value<int> rowid,
    });

final class $$RecipeStepsTableReferences
    extends BaseReferences<_$AppDatabase, $RecipeStepsTable, RecipeStepRow> {
  $$RecipeStepsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $RecipesTable _recipeIdTable(_$AppDatabase db) =>
      db.recipes.createAlias('recipe_steps__recipe_id__recipes__id');

  $$RecipesTableProcessedTableManager get recipeId {
    final $_column = $_itemColumn<String>('recipe_id')!;

    final manager = $$RecipesTableTableManager(
      $_db,
      $_db.recipes,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_recipeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$RecipeStepsTableFilterComposer
    extends Composer<_$AppDatabase, $RecipeStepsTable> {
  $$RecipeStepsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get number => $composableBuilder(
    column: $table.number,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationMinutes => $composableBuilder(
    column: $table.durationMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get temperatureC => $composableBuilder(
    column: $table.temperatureC,
    builder: (column) => ColumnFilters(column),
  );

  $$RecipesTableFilterComposer get recipeId {
    final $$RecipesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recipeId,
      referencedTable: $db.recipes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecipesTableFilterComposer(
            $db: $db,
            $table: $db.recipes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RecipeStepsTableOrderingComposer
    extends Composer<_$AppDatabase, $RecipeStepsTable> {
  $$RecipeStepsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get number => $composableBuilder(
    column: $table.number,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationMinutes => $composableBuilder(
    column: $table.durationMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get temperatureC => $composableBuilder(
    column: $table.temperatureC,
    builder: (column) => ColumnOrderings(column),
  );

  $$RecipesTableOrderingComposer get recipeId {
    final $$RecipesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recipeId,
      referencedTable: $db.recipes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecipesTableOrderingComposer(
            $db: $db,
            $table: $db.recipes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RecipeStepsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RecipeStepsTable> {
  $$RecipeStepsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get number =>
      $composableBuilder(column: $table.number, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<int> get durationMinutes => $composableBuilder(
    column: $table.durationMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get temperatureC => $composableBuilder(
    column: $table.temperatureC,
    builder: (column) => column,
  );

  $$RecipesTableAnnotationComposer get recipeId {
    final $$RecipesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recipeId,
      referencedTable: $db.recipes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecipesTableAnnotationComposer(
            $db: $db,
            $table: $db.recipes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RecipeStepsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RecipeStepsTable,
          RecipeStepRow,
          $$RecipeStepsTableFilterComposer,
          $$RecipeStepsTableOrderingComposer,
          $$RecipeStepsTableAnnotationComposer,
          $$RecipeStepsTableCreateCompanionBuilder,
          $$RecipeStepsTableUpdateCompanionBuilder,
          (RecipeStepRow, $$RecipeStepsTableReferences),
          RecipeStepRow,
          PrefetchHooks Function({bool recipeId})
        > {
  $$RecipeStepsTableTableManager(_$AppDatabase db, $RecipeStepsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RecipeStepsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RecipeStepsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RecipeStepsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> recipeId = const Value.absent(),
                Value<int> number = const Value.absent(),
                Value<String> body = const Value.absent(),
                Value<int?> durationMinutes = const Value.absent(),
                Value<int?> temperatureC = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RecipeStepsCompanion(
                id: id,
                recipeId: recipeId,
                number: number,
                body: body,
                durationMinutes: durationMinutes,
                temperatureC: temperatureC,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String recipeId,
                required int number,
                required String body,
                Value<int?> durationMinutes = const Value.absent(),
                Value<int?> temperatureC = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RecipeStepsCompanion.insert(
                id: id,
                recipeId: recipeId,
                number: number,
                body: body,
                durationMinutes: durationMinutes,
                temperatureC: temperatureC,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$RecipeStepsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({recipeId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (recipeId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.recipeId,
                                referencedTable: $$RecipeStepsTableReferences
                                    ._recipeIdTable(db),
                                referencedColumn: $$RecipeStepsTableReferences
                                    ._recipeIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$RecipeStepsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RecipeStepsTable,
      RecipeStepRow,
      $$RecipeStepsTableFilterComposer,
      $$RecipeStepsTableOrderingComposer,
      $$RecipeStepsTableAnnotationComposer,
      $$RecipeStepsTableCreateCompanionBuilder,
      $$RecipeStepsTableUpdateCompanionBuilder,
      (RecipeStepRow, $$RecipeStepsTableReferences),
      RecipeStepRow,
      PrefetchHooks Function({bool recipeId})
    >;
typedef $$TagsTableCreateCompanionBuilder =
    TagsCompanion Function({Value<int> id, required String name});
typedef $$TagsTableUpdateCompanionBuilder =
    TagsCompanion Function({Value<int> id, Value<String> name});

final class $$TagsTableReferences
    extends BaseReferences<_$AppDatabase, $TagsTable, TagRow> {
  $$TagsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$RecipeTagsTable, List<RecipeTagRow>>
  _recipeTagsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.recipeTags,
    aliasName: 'tags__id__recipe_tags__tag_id',
  );

  $$RecipeTagsTableProcessedTableManager get recipeTagsRefs {
    final manager = $$RecipeTagsTableTableManager(
      $_db,
      $_db.recipeTags,
    ).filter((f) => f.tagId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_recipeTagsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$TagsTableFilterComposer extends Composer<_$AppDatabase, $TagsTable> {
  $$TagsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> recipeTagsRefs(
    Expression<bool> Function($$RecipeTagsTableFilterComposer f) f,
  ) {
    final $$RecipeTagsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.recipeTags,
      getReferencedColumn: (t) => t.tagId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecipeTagsTableFilterComposer(
            $db: $db,
            $table: $db.recipeTags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TagsTableOrderingComposer extends Composer<_$AppDatabase, $TagsTable> {
  $$TagsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TagsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TagsTable> {
  $$TagsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  Expression<T> recipeTagsRefs<T extends Object>(
    Expression<T> Function($$RecipeTagsTableAnnotationComposer a) f,
  ) {
    final $$RecipeTagsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.recipeTags,
      getReferencedColumn: (t) => t.tagId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecipeTagsTableAnnotationComposer(
            $db: $db,
            $table: $db.recipeTags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TagsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TagsTable,
          TagRow,
          $$TagsTableFilterComposer,
          $$TagsTableOrderingComposer,
          $$TagsTableAnnotationComposer,
          $$TagsTableCreateCompanionBuilder,
          $$TagsTableUpdateCompanionBuilder,
          (TagRow, $$TagsTableReferences),
          TagRow,
          PrefetchHooks Function({bool recipeTagsRefs})
        > {
  $$TagsTableTableManager(_$AppDatabase db, $TagsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TagsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TagsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TagsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
              }) => TagsCompanion(id: id, name: name),
          createCompanionCallback:
              ({Value<int> id = const Value.absent(), required String name}) =>
                  TagsCompanion.insert(id: id, name: name),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$TagsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({recipeTagsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (recipeTagsRefs) db.recipeTags],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (recipeTagsRefs)
                    await $_getPrefetchedData<TagRow, $TagsTable, RecipeTagRow>(
                      currentTable: table,
                      referencedTable: $$TagsTableReferences
                          ._recipeTagsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$TagsTableReferences(db, table, p0).recipeTagsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.tagId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$TagsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TagsTable,
      TagRow,
      $$TagsTableFilterComposer,
      $$TagsTableOrderingComposer,
      $$TagsTableAnnotationComposer,
      $$TagsTableCreateCompanionBuilder,
      $$TagsTableUpdateCompanionBuilder,
      (TagRow, $$TagsTableReferences),
      TagRow,
      PrefetchHooks Function({bool recipeTagsRefs})
    >;
typedef $$RecipeTagsTableCreateCompanionBuilder =
    RecipeTagsCompanion Function({
      required String recipeId,
      required int tagId,
      Value<int> rowid,
    });
typedef $$RecipeTagsTableUpdateCompanionBuilder =
    RecipeTagsCompanion Function({
      Value<String> recipeId,
      Value<int> tagId,
      Value<int> rowid,
    });

final class $$RecipeTagsTableReferences
    extends BaseReferences<_$AppDatabase, $RecipeTagsTable, RecipeTagRow> {
  $$RecipeTagsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $RecipesTable _recipeIdTable(_$AppDatabase db) =>
      db.recipes.createAlias('recipe_tags__recipe_id__recipes__id');

  $$RecipesTableProcessedTableManager get recipeId {
    final $_column = $_itemColumn<String>('recipe_id')!;

    final manager = $$RecipesTableTableManager(
      $_db,
      $_db.recipes,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_recipeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $TagsTable _tagIdTable(_$AppDatabase db) =>
      db.tags.createAlias('recipe_tags__tag_id__tags__id');

  $$TagsTableProcessedTableManager get tagId {
    final $_column = $_itemColumn<int>('tag_id')!;

    final manager = $$TagsTableTableManager(
      $_db,
      $_db.tags,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_tagIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$RecipeTagsTableFilterComposer
    extends Composer<_$AppDatabase, $RecipeTagsTable> {
  $$RecipeTagsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$RecipesTableFilterComposer get recipeId {
    final $$RecipesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recipeId,
      referencedTable: $db.recipes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecipesTableFilterComposer(
            $db: $db,
            $table: $db.recipes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TagsTableFilterComposer get tagId {
    final $$TagsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tagId,
      referencedTable: $db.tags,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TagsTableFilterComposer(
            $db: $db,
            $table: $db.tags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RecipeTagsTableOrderingComposer
    extends Composer<_$AppDatabase, $RecipeTagsTable> {
  $$RecipeTagsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$RecipesTableOrderingComposer get recipeId {
    final $$RecipesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recipeId,
      referencedTable: $db.recipes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecipesTableOrderingComposer(
            $db: $db,
            $table: $db.recipes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TagsTableOrderingComposer get tagId {
    final $$TagsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tagId,
      referencedTable: $db.tags,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TagsTableOrderingComposer(
            $db: $db,
            $table: $db.tags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RecipeTagsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RecipeTagsTable> {
  $$RecipeTagsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$RecipesTableAnnotationComposer get recipeId {
    final $$RecipesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recipeId,
      referencedTable: $db.recipes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecipesTableAnnotationComposer(
            $db: $db,
            $table: $db.recipes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TagsTableAnnotationComposer get tagId {
    final $$TagsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tagId,
      referencedTable: $db.tags,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TagsTableAnnotationComposer(
            $db: $db,
            $table: $db.tags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RecipeTagsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RecipeTagsTable,
          RecipeTagRow,
          $$RecipeTagsTableFilterComposer,
          $$RecipeTagsTableOrderingComposer,
          $$RecipeTagsTableAnnotationComposer,
          $$RecipeTagsTableCreateCompanionBuilder,
          $$RecipeTagsTableUpdateCompanionBuilder,
          (RecipeTagRow, $$RecipeTagsTableReferences),
          RecipeTagRow,
          PrefetchHooks Function({bool recipeId, bool tagId})
        > {
  $$RecipeTagsTableTableManager(_$AppDatabase db, $RecipeTagsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RecipeTagsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RecipeTagsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RecipeTagsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> recipeId = const Value.absent(),
                Value<int> tagId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RecipeTagsCompanion(
                recipeId: recipeId,
                tagId: tagId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String recipeId,
                required int tagId,
                Value<int> rowid = const Value.absent(),
              }) => RecipeTagsCompanion.insert(
                recipeId: recipeId,
                tagId: tagId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$RecipeTagsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({recipeId = false, tagId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (recipeId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.recipeId,
                                referencedTable: $$RecipeTagsTableReferences
                                    ._recipeIdTable(db),
                                referencedColumn: $$RecipeTagsTableReferences
                                    ._recipeIdTable(db)
                                    .id,
                              )
                              as T;
                    }
                    if (tagId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.tagId,
                                referencedTable: $$RecipeTagsTableReferences
                                    ._tagIdTable(db),
                                referencedColumn: $$RecipeTagsTableReferences
                                    ._tagIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$RecipeTagsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RecipeTagsTable,
      RecipeTagRow,
      $$RecipeTagsTableFilterComposer,
      $$RecipeTagsTableOrderingComposer,
      $$RecipeTagsTableAnnotationComposer,
      $$RecipeTagsTableCreateCompanionBuilder,
      $$RecipeTagsTableUpdateCompanionBuilder,
      (RecipeTagRow, $$RecipeTagsTableReferences),
      RecipeTagRow,
      PrefetchHooks Function({bool recipeId, bool tagId})
    >;
typedef $$NutritionSnapshotsTableCreateCompanionBuilder =
    NutritionSnapshotsCompanion Function({
      required String recipeId,
      required double kcal,
      required double proteinG,
      required double carbsG,
      required double sugarsG,
      required double fatG,
      required double saturatedFatG,
      required double fiberG,
      required double saltG,
      required double coverage,
      required DateTime computedAt,
      Value<int> rowid,
    });
typedef $$NutritionSnapshotsTableUpdateCompanionBuilder =
    NutritionSnapshotsCompanion Function({
      Value<String> recipeId,
      Value<double> kcal,
      Value<double> proteinG,
      Value<double> carbsG,
      Value<double> sugarsG,
      Value<double> fatG,
      Value<double> saturatedFatG,
      Value<double> fiberG,
      Value<double> saltG,
      Value<double> coverage,
      Value<DateTime> computedAt,
      Value<int> rowid,
    });

final class $$NutritionSnapshotsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $NutritionSnapshotsTable,
          NutritionSnapshotRow
        > {
  $$NutritionSnapshotsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $RecipesTable _recipeIdTable(_$AppDatabase db) =>
      db.recipes.createAlias('nutrition_snapshots__recipe_id__recipes__id');

  $$RecipesTableProcessedTableManager get recipeId {
    final $_column = $_itemColumn<String>('recipe_id')!;

    final manager = $$RecipesTableTableManager(
      $_db,
      $_db.recipes,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_recipeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$NutritionSnapshotsTableFilterComposer
    extends Composer<_$AppDatabase, $NutritionSnapshotsTable> {
  $$NutritionSnapshotsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<double> get kcal => $composableBuilder(
    column: $table.kcal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get proteinG => $composableBuilder(
    column: $table.proteinG,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get carbsG => $composableBuilder(
    column: $table.carbsG,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get sugarsG => $composableBuilder(
    column: $table.sugarsG,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get fatG => $composableBuilder(
    column: $table.fatG,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get saturatedFatG => $composableBuilder(
    column: $table.saturatedFatG,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get fiberG => $composableBuilder(
    column: $table.fiberG,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get saltG => $composableBuilder(
    column: $table.saltG,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get coverage => $composableBuilder(
    column: $table.coverage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get computedAt => $composableBuilder(
    column: $table.computedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$RecipesTableFilterComposer get recipeId {
    final $$RecipesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recipeId,
      referencedTable: $db.recipes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecipesTableFilterComposer(
            $db: $db,
            $table: $db.recipes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$NutritionSnapshotsTableOrderingComposer
    extends Composer<_$AppDatabase, $NutritionSnapshotsTable> {
  $$NutritionSnapshotsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<double> get kcal => $composableBuilder(
    column: $table.kcal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get proteinG => $composableBuilder(
    column: $table.proteinG,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get carbsG => $composableBuilder(
    column: $table.carbsG,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get sugarsG => $composableBuilder(
    column: $table.sugarsG,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get fatG => $composableBuilder(
    column: $table.fatG,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get saturatedFatG => $composableBuilder(
    column: $table.saturatedFatG,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get fiberG => $composableBuilder(
    column: $table.fiberG,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get saltG => $composableBuilder(
    column: $table.saltG,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get coverage => $composableBuilder(
    column: $table.coverage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get computedAt => $composableBuilder(
    column: $table.computedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$RecipesTableOrderingComposer get recipeId {
    final $$RecipesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recipeId,
      referencedTable: $db.recipes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecipesTableOrderingComposer(
            $db: $db,
            $table: $db.recipes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$NutritionSnapshotsTableAnnotationComposer
    extends Composer<_$AppDatabase, $NutritionSnapshotsTable> {
  $$NutritionSnapshotsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<double> get kcal =>
      $composableBuilder(column: $table.kcal, builder: (column) => column);

  GeneratedColumn<double> get proteinG =>
      $composableBuilder(column: $table.proteinG, builder: (column) => column);

  GeneratedColumn<double> get carbsG =>
      $composableBuilder(column: $table.carbsG, builder: (column) => column);

  GeneratedColumn<double> get sugarsG =>
      $composableBuilder(column: $table.sugarsG, builder: (column) => column);

  GeneratedColumn<double> get fatG =>
      $composableBuilder(column: $table.fatG, builder: (column) => column);

  GeneratedColumn<double> get saturatedFatG => $composableBuilder(
    column: $table.saturatedFatG,
    builder: (column) => column,
  );

  GeneratedColumn<double> get fiberG =>
      $composableBuilder(column: $table.fiberG, builder: (column) => column);

  GeneratedColumn<double> get saltG =>
      $composableBuilder(column: $table.saltG, builder: (column) => column);

  GeneratedColumn<double> get coverage =>
      $composableBuilder(column: $table.coverage, builder: (column) => column);

  GeneratedColumn<DateTime> get computedAt => $composableBuilder(
    column: $table.computedAt,
    builder: (column) => column,
  );

  $$RecipesTableAnnotationComposer get recipeId {
    final $$RecipesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recipeId,
      referencedTable: $db.recipes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecipesTableAnnotationComposer(
            $db: $db,
            $table: $db.recipes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$NutritionSnapshotsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $NutritionSnapshotsTable,
          NutritionSnapshotRow,
          $$NutritionSnapshotsTableFilterComposer,
          $$NutritionSnapshotsTableOrderingComposer,
          $$NutritionSnapshotsTableAnnotationComposer,
          $$NutritionSnapshotsTableCreateCompanionBuilder,
          $$NutritionSnapshotsTableUpdateCompanionBuilder,
          (NutritionSnapshotRow, $$NutritionSnapshotsTableReferences),
          NutritionSnapshotRow,
          PrefetchHooks Function({bool recipeId})
        > {
  $$NutritionSnapshotsTableTableManager(
    _$AppDatabase db,
    $NutritionSnapshotsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NutritionSnapshotsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NutritionSnapshotsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NutritionSnapshotsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> recipeId = const Value.absent(),
                Value<double> kcal = const Value.absent(),
                Value<double> proteinG = const Value.absent(),
                Value<double> carbsG = const Value.absent(),
                Value<double> sugarsG = const Value.absent(),
                Value<double> fatG = const Value.absent(),
                Value<double> saturatedFatG = const Value.absent(),
                Value<double> fiberG = const Value.absent(),
                Value<double> saltG = const Value.absent(),
                Value<double> coverage = const Value.absent(),
                Value<DateTime> computedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => NutritionSnapshotsCompanion(
                recipeId: recipeId,
                kcal: kcal,
                proteinG: proteinG,
                carbsG: carbsG,
                sugarsG: sugarsG,
                fatG: fatG,
                saturatedFatG: saturatedFatG,
                fiberG: fiberG,
                saltG: saltG,
                coverage: coverage,
                computedAt: computedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String recipeId,
                required double kcal,
                required double proteinG,
                required double carbsG,
                required double sugarsG,
                required double fatG,
                required double saturatedFatG,
                required double fiberG,
                required double saltG,
                required double coverage,
                required DateTime computedAt,
                Value<int> rowid = const Value.absent(),
              }) => NutritionSnapshotsCompanion.insert(
                recipeId: recipeId,
                kcal: kcal,
                proteinG: proteinG,
                carbsG: carbsG,
                sugarsG: sugarsG,
                fatG: fatG,
                saturatedFatG: saturatedFatG,
                fiberG: fiberG,
                saltG: saltG,
                coverage: coverage,
                computedAt: computedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$NutritionSnapshotsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({recipeId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (recipeId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.recipeId,
                                referencedTable:
                                    $$NutritionSnapshotsTableReferences
                                        ._recipeIdTable(db),
                                referencedColumn:
                                    $$NutritionSnapshotsTableReferences
                                        ._recipeIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$NutritionSnapshotsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $NutritionSnapshotsTable,
      NutritionSnapshotRow,
      $$NutritionSnapshotsTableFilterComposer,
      $$NutritionSnapshotsTableOrderingComposer,
      $$NutritionSnapshotsTableAnnotationComposer,
      $$NutritionSnapshotsTableCreateCompanionBuilder,
      $$NutritionSnapshotsTableUpdateCompanionBuilder,
      (NutritionSnapshotRow, $$NutritionSnapshotsTableReferences),
      NutritionSnapshotRow,
      PrefetchHooks Function({bool recipeId})
    >;
typedef $$ImportJobsTableCreateCompanionBuilder =
    ImportJobsCompanion Function({
      required String id,
      required ImportStatus status,
      Value<String?> sharedText,
      Value<String?> sharedFilePath,
      Value<SourcePlatform?> platform,
      Value<String?> sourceUrl,
      Value<String?> sourceKey,
      Value<int> attempts,
      Value<ImportStatus?> failedStep,
      Value<String?> errorCode,
      Value<String?> errorDetail,
      Value<String?> recipeId,
      required ImportJobData data,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$ImportJobsTableUpdateCompanionBuilder =
    ImportJobsCompanion Function({
      Value<String> id,
      Value<ImportStatus> status,
      Value<String?> sharedText,
      Value<String?> sharedFilePath,
      Value<SourcePlatform?> platform,
      Value<String?> sourceUrl,
      Value<String?> sourceKey,
      Value<int> attempts,
      Value<ImportStatus?> failedStep,
      Value<String?> errorCode,
      Value<String?> errorDetail,
      Value<String?> recipeId,
      Value<ImportJobData> data,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$ImportJobsTableReferences
    extends BaseReferences<_$AppDatabase, $ImportJobsTable, ImportJobRow> {
  $$ImportJobsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $RecipesTable _recipeIdTable(_$AppDatabase db) =>
      db.recipes.createAlias('import_jobs__recipe_id__recipes__id');

  $$RecipesTableProcessedTableManager? get recipeId {
    final $_column = $_itemColumn<String>('recipe_id');
    if ($_column == null) return null;
    final manager = $$RecipesTableTableManager(
      $_db,
      $_db.recipes,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_recipeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ImportJobsTableFilterComposer
    extends Composer<_$AppDatabase, $ImportJobsTable> {
  $$ImportJobsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<ImportStatus, ImportStatus, String>
  get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get sharedText => $composableBuilder(
    column: $table.sharedText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sharedFilePath => $composableBuilder(
    column: $table.sharedFilePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<SourcePlatform?, SourcePlatform, String>
  get platform => $composableBuilder(
    column: $table.platform,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get sourceUrl => $composableBuilder(
    column: $table.sourceUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceKey => $composableBuilder(
    column: $table.sourceKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<ImportStatus?, ImportStatus, String>
  get failedStep => $composableBuilder(
    column: $table.failedStep,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get errorCode => $composableBuilder(
    column: $table.errorCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get errorDetail => $composableBuilder(
    column: $table.errorDetail,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<ImportJobData, ImportJobData, String>
  get data => $composableBuilder(
    column: $table.data,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$RecipesTableFilterComposer get recipeId {
    final $$RecipesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recipeId,
      referencedTable: $db.recipes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecipesTableFilterComposer(
            $db: $db,
            $table: $db.recipes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ImportJobsTableOrderingComposer
    extends Composer<_$AppDatabase, $ImportJobsTable> {
  $$ImportJobsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sharedText => $composableBuilder(
    column: $table.sharedText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sharedFilePath => $composableBuilder(
    column: $table.sharedFilePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get platform => $composableBuilder(
    column: $table.platform,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceUrl => $composableBuilder(
    column: $table.sourceUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceKey => $composableBuilder(
    column: $table.sourceKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get failedStep => $composableBuilder(
    column: $table.failedStep,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get errorCode => $composableBuilder(
    column: $table.errorCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get errorDetail => $composableBuilder(
    column: $table.errorDetail,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get data => $composableBuilder(
    column: $table.data,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$RecipesTableOrderingComposer get recipeId {
    final $$RecipesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recipeId,
      referencedTable: $db.recipes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecipesTableOrderingComposer(
            $db: $db,
            $table: $db.recipes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ImportJobsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ImportJobsTable> {
  $$ImportJobsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ImportStatus, String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get sharedText => $composableBuilder(
    column: $table.sharedText,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sharedFilePath => $composableBuilder(
    column: $table.sharedFilePath,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<SourcePlatform?, String> get platform =>
      $composableBuilder(column: $table.platform, builder: (column) => column);

  GeneratedColumn<String> get sourceUrl =>
      $composableBuilder(column: $table.sourceUrl, builder: (column) => column);

  GeneratedColumn<String> get sourceKey =>
      $composableBuilder(column: $table.sourceKey, builder: (column) => column);

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ImportStatus?, String> get failedStep =>
      $composableBuilder(
        column: $table.failedStep,
        builder: (column) => column,
      );

  GeneratedColumn<String> get errorCode =>
      $composableBuilder(column: $table.errorCode, builder: (column) => column);

  GeneratedColumn<String> get errorDetail => $composableBuilder(
    column: $table.errorDetail,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<ImportJobData, String> get data =>
      $composableBuilder(column: $table.data, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$RecipesTableAnnotationComposer get recipeId {
    final $$RecipesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recipeId,
      referencedTable: $db.recipes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecipesTableAnnotationComposer(
            $db: $db,
            $table: $db.recipes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ImportJobsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ImportJobsTable,
          ImportJobRow,
          $$ImportJobsTableFilterComposer,
          $$ImportJobsTableOrderingComposer,
          $$ImportJobsTableAnnotationComposer,
          $$ImportJobsTableCreateCompanionBuilder,
          $$ImportJobsTableUpdateCompanionBuilder,
          (ImportJobRow, $$ImportJobsTableReferences),
          ImportJobRow,
          PrefetchHooks Function({bool recipeId})
        > {
  $$ImportJobsTableTableManager(_$AppDatabase db, $ImportJobsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ImportJobsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ImportJobsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ImportJobsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<ImportStatus> status = const Value.absent(),
                Value<String?> sharedText = const Value.absent(),
                Value<String?> sharedFilePath = const Value.absent(),
                Value<SourcePlatform?> platform = const Value.absent(),
                Value<String?> sourceUrl = const Value.absent(),
                Value<String?> sourceKey = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<ImportStatus?> failedStep = const Value.absent(),
                Value<String?> errorCode = const Value.absent(),
                Value<String?> errorDetail = const Value.absent(),
                Value<String?> recipeId = const Value.absent(),
                Value<ImportJobData> data = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ImportJobsCompanion(
                id: id,
                status: status,
                sharedText: sharedText,
                sharedFilePath: sharedFilePath,
                platform: platform,
                sourceUrl: sourceUrl,
                sourceKey: sourceKey,
                attempts: attempts,
                failedStep: failedStep,
                errorCode: errorCode,
                errorDetail: errorDetail,
                recipeId: recipeId,
                data: data,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required ImportStatus status,
                Value<String?> sharedText = const Value.absent(),
                Value<String?> sharedFilePath = const Value.absent(),
                Value<SourcePlatform?> platform = const Value.absent(),
                Value<String?> sourceUrl = const Value.absent(),
                Value<String?> sourceKey = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<ImportStatus?> failedStep = const Value.absent(),
                Value<String?> errorCode = const Value.absent(),
                Value<String?> errorDetail = const Value.absent(),
                Value<String?> recipeId = const Value.absent(),
                required ImportJobData data,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => ImportJobsCompanion.insert(
                id: id,
                status: status,
                sharedText: sharedText,
                sharedFilePath: sharedFilePath,
                platform: platform,
                sourceUrl: sourceUrl,
                sourceKey: sourceKey,
                attempts: attempts,
                failedStep: failedStep,
                errorCode: errorCode,
                errorDetail: errorDetail,
                recipeId: recipeId,
                data: data,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ImportJobsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({recipeId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (recipeId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.recipeId,
                                referencedTable: $$ImportJobsTableReferences
                                    ._recipeIdTable(db),
                                referencedColumn: $$ImportJobsTableReferences
                                    ._recipeIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ImportJobsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ImportJobsTable,
      ImportJobRow,
      $$ImportJobsTableFilterComposer,
      $$ImportJobsTableOrderingComposer,
      $$ImportJobsTableAnnotationComposer,
      $$ImportJobsTableCreateCompanionBuilder,
      $$ImportJobsTableUpdateCompanionBuilder,
      (ImportJobRow, $$ImportJobsTableReferences),
      ImportJobRow,
      PrefetchHooks Function({bool recipeId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $RecipeSearchTableManager get recipeSearch =>
      $RecipeSearchTableManager(_db, _db.recipeSearch);
  $$RecipesTableTableManager get recipes =>
      $$RecipesTableTableManager(_db, _db.recipes);
  $$RecipeSourcesTableTableManager get recipeSources =>
      $$RecipeSourcesTableTableManager(_db, _db.recipeSources);
  $$IngredientGroupsTableTableManager get ingredientGroups =>
      $$IngredientGroupsTableTableManager(_db, _db.ingredientGroups);
  $$IngredientsTableTableManager get ingredients =>
      $$IngredientsTableTableManager(_db, _db.ingredients);
  $$RecipeStepsTableTableManager get recipeSteps =>
      $$RecipeStepsTableTableManager(_db, _db.recipeSteps);
  $$TagsTableTableManager get tags => $$TagsTableTableManager(_db, _db.tags);
  $$RecipeTagsTableTableManager get recipeTags =>
      $$RecipeTagsTableTableManager(_db, _db.recipeTags);
  $$NutritionSnapshotsTableTableManager get nutritionSnapshots =>
      $$NutritionSnapshotsTableTableManager(_db, _db.nutritionSnapshots);
  $$ImportJobsTableTableManager get importJobs =>
      $$ImportJobsTableTableManager(_db, _db.importJobs);
}
