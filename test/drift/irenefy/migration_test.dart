// dart format width=80
// ignore_for_file: unused_local_variable, unused_import
import 'package:drift/drift.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:irenefy/data/db/app_database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'generated/schema.dart';

import 'generated/schema_v1.dart' as v1;
import 'generated/schema_v2.dart' as v2;

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late SchemaVerifier verifier;

  setUpAll(() {
    verifier = SchemaVerifier(GeneratedHelper());
  });

  group('simple database migrations', () {
    // These simple tests verify all possible schema updates with a simple (no
    // data) migration. This is a quick way to ensure that written database
    // migrations properly alter the schema.
    const versions = GeneratedHelper.versions;
    for (final (i, fromVersion) in versions.indexed) {
      group('from $fromVersion', () {
        for (final toVersion in versions.skip(i + 1)) {
          test('to $toVersion', () async {
            final schema = await verifier.schemaAt(fromVersion);
            final db = AppDatabase(schema.newConnection());
            await verifier.migrateAndValidate(db, toVersion);
            await db.close();
          });
        }
      });
    }
  });

  // The following template shows how to write tests ensuring your migrations
  // preserve existing data.
  // Testing this can be useful for migrations that change existing columns
  // (e.g. by alterating their type or constraints). Migrations that only add
  // tables or columns typically don't need these advanced tests. For more
  // information, see https://drift.simonbinder.eu/migrations/tests/#verifying-data-integrity
  // TODO: This generated template shows how these tests could be written. Adopt
  // it to your own needs when testing migrations with data integrity.
  test('migration from v1 to v2 does not corrupt data', () async {
    // Add data to insert into the old database, and the expected rows after the
    // migration.
    // TODO: Fill these lists
    final oldRecipesData = <v1.RecipesData>[];
    final expectedNewRecipesData = <v2.RecipesData>[];

    final oldRecipeSourcesData = <v1.RecipeSourcesData>[];
    final expectedNewRecipeSourcesData = <v2.RecipeSourcesData>[];

    final oldIngredientGroupsData = <v1.IngredientGroupsData>[];
    final expectedNewIngredientGroupsData = <v2.IngredientGroupsData>[];

    final oldIngredientsData = <v1.IngredientsData>[];
    final expectedNewIngredientsData = <v2.IngredientsData>[];

    final oldRecipeStepsData = <v1.RecipeStepsData>[];
    final expectedNewRecipeStepsData = <v2.RecipeStepsData>[];

    final oldTagsData = <v1.TagsData>[];
    final expectedNewTagsData = <v2.TagsData>[];

    final oldRecipeTagsData = <v1.RecipeTagsData>[];
    final expectedNewRecipeTagsData = <v2.RecipeTagsData>[];

    final oldNutritionSnapshotsData = <v1.NutritionSnapshotsData>[];
    final expectedNewNutritionSnapshotsData = <v2.NutritionSnapshotsData>[];

    final oldImportJobsData = <v1.ImportJobsData>[];
    final expectedNewImportJobsData = <v2.ImportJobsData>[];

    await verifier.testWithDataIntegrity(
      oldVersion: 1,
      newVersion: 2,
      createOld: v1.DatabaseAtV1.new,
      createNew: v2.DatabaseAtV2.new,
      openTestedDatabase: AppDatabase.new,
      createItems: (batch, oldDb) {
        batch.insertAll(oldDb.recipes, oldRecipesData);
        batch.insertAll(oldDb.recipeSources, oldRecipeSourcesData);
        batch.insertAll(oldDb.ingredientGroups, oldIngredientGroupsData);
        batch.insertAll(oldDb.ingredients, oldIngredientsData);
        batch.insertAll(oldDb.recipeSteps, oldRecipeStepsData);
        batch.insertAll(oldDb.tags, oldTagsData);
        batch.insertAll(oldDb.recipeTags, oldRecipeTagsData);
        batch.insertAll(oldDb.nutritionSnapshots, oldNutritionSnapshotsData);
        batch.insertAll(oldDb.importJobs, oldImportJobsData);
      },
      validateItems: (newDb) async {
        expect(expectedNewRecipesData, await newDb.select(newDb.recipes).get());
        expect(
          expectedNewRecipeSourcesData,
          await newDb.select(newDb.recipeSources).get(),
        );
        expect(
          expectedNewIngredientGroupsData,
          await newDb.select(newDb.ingredientGroups).get(),
        );
        expect(
          expectedNewIngredientsData,
          await newDb.select(newDb.ingredients).get(),
        );
        expect(
          expectedNewRecipeStepsData,
          await newDb.select(newDb.recipeSteps).get(),
        );
        expect(expectedNewTagsData, await newDb.select(newDb.tags).get());
        expect(
          expectedNewRecipeTagsData,
          await newDb.select(newDb.recipeTags).get(),
        );
        expect(
          expectedNewNutritionSnapshotsData,
          await newDb.select(newDb.nutritionSnapshots).get(),
        );
        expect(
          expectedNewImportJobsData,
          await newDb.select(newDb.importJobs).get(),
        );
      },
    );
  });
}
