class MealIngredient {
  final String nameAr;
  final String nameEn;
  final double weightGrams;
  final String householdMeasureAr;
  final String householdMeasureEn;
  final double caloriesPer100g;
  final String sourceId;
  final String sourceUrl;

  const MealIngredient({
    required this.nameAr,
    required this.nameEn,
    required this.weightGrams,
    required this.householdMeasureAr,
    required this.householdMeasureEn,
    required this.caloriesPer100g,
    required this.sourceId,
    required this.sourceUrl,
  });

  double get calculatedCalories => (weightGrams * caloriesPer100g) / 100.0;
}

class MealSuggestion {
  final String id;
  final String titleAr;
  final String titleEn;
  final String category; // 'breakfast_dinner' or 'lunch'
  final List<MealIngredient> ingredients;
  final String prepMethodAr;
  final String prepMethodEn;
  final String notesAr;

  const MealSuggestion({
    required this.id,
    required this.titleAr,
    required this.titleEn,
    required this.category,
    required this.ingredients,
    required this.prepMethodAr,
    required this.prepMethodEn,
    this.notesAr = 'سعرات تقريبية للحصة المذكورة',
  });

  int get totalCalories {
    double total = 0;
    for (var ing in ingredients) {
      total += ing.calculatedCalories;
    }
    return total.round();
  }
}
