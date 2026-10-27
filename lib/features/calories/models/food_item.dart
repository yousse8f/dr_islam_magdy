class FoodPresetItem {
  final String nameAr;
  final String nameEn;
  final int caloriesPer100g;
  final String defaultUnit;
  final String category; // 'breakfast', 'snack', 'lunch', 'dinner'

  const FoodPresetItem({
    required this.nameAr,
    required this.nameEn,
    required this.caloriesPer100g,
    required this.defaultUnit,
    required this.category,
  });

  String getName(bool isArabic) => isArabic ? nameAr : nameEn;
}

class LoggedFood {
  final String id;
  final String name;
  final double amount; // quantity in grams or units
  final String unit;
  final int calories;
  final String
  mealType; // 'breakfast', 'morning_snack', 'lunch', 'evening_snack', 'dinner'
  final bool isCustom;

  LoggedFood({
    required this.id,
    required this.name,
    required this.amount,
    required this.unit,
    required this.calories,
    required this.mealType,
    this.isCustom = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'amount': amount,
    'unit': unit,
    'calories': calories,
    'mealType': mealType,
    'isCustom': isCustom,
  };

  factory LoggedFood.fromJson(Map<String, dynamic> json) => LoggedFood(
    id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
    name: json['name'] ?? '',
    amount: (json['amount'] as num).toDouble(),
    unit: json['unit'] ?? 'جرام',
    calories: (json['calories'] as num).toInt(),
    mealType: json['mealType'] ?? 'breakfast',
    isCustom: json['isCustom'] ?? false,
  );
}

class FoodDatabase {
  static const List<FoodPresetItem> commonFoods = [
    // ----------------- BREAKFAST (الفطار) -----------------
    FoodPresetItem(
      nameAr: 'فول مدمس بالزيت والليمون',
      nameEn: 'Foul Mudammas with Oil & Lemon',
      caloriesPer100g: 110,
      defaultUnit: 'جرام',
      category: 'breakfast',
    ),
    FoodPresetItem(
      nameAr: 'طعمية / فلافل مصرية',
      nameEn: 'Egyptian Taameya / Falafel',
      caloriesPer100g: 330,
      defaultUnit: 'جرام',
      category: 'breakfast',
    ),
    FoodPresetItem(
      nameAr: 'جبنة بيضاء بالطماطم والزيت',
      nameEn: 'White Cheese with Tomatoes & Oil',
      caloriesPer100g: 180,
      defaultUnit: 'جرام',
      category: 'breakfast',
    ),
    FoodPresetItem(
      nameAr: 'جبنة قريش بالزيتون والزعتر',
      nameEn: 'Cottage Cheese with Olives & Thyme',
      caloriesPer100g: 105,
      defaultUnit: 'جرام',
      category: 'breakfast',
    ),
    FoodPresetItem(
      nameAr: 'بيض مقلي بالزبدة أو السمن',
      nameEn: 'Fried Eggs in Butter',
      caloriesPer100g: 196,
      defaultUnit: 'جرام',
      category: 'breakfast',
    ),
    FoodPresetItem(
      nameAr: 'بيض مسلوق',
      nameEn: 'Boiled Egg',
      caloriesPer100g: 155,
      defaultUnit: 'جرام',
      category: 'breakfast',
    ),
    FoodPresetItem(
      nameAr: 'عجة بيض بالخضار',
      nameEn: 'Egyptian Omelet with Veggies',
      caloriesPer100g: 160,
      defaultUnit: 'جرام',
      category: 'breakfast',
    ),
    FoodPresetItem(
      nameAr: 'شكشوكة مصرية',
      nameEn: 'Egyptian Shakshuka',
      caloriesPer100g: 120,
      defaultUnit: 'جرام',
      category: 'breakfast',
    ),
    FoodPresetItem(
      nameAr: 'فطير مشلتت',
      nameEn: 'Feteer Meshaltet',
      caloriesPer100g: 380,
      defaultUnit: 'جرام',
      category: 'breakfast',
    ),
    FoodPresetItem(
      nameAr: 'قشطة وعسل أبيض',
      nameEn: 'Cream and Honey',
      caloriesPer100g: 350,
      defaultUnit: 'جرام',
      category: 'breakfast',
    ),
    FoodPresetItem(
      nameAr: 'جبنة رومي',
      nameEn: 'Roumi Cheese',
      caloriesPer100g: 400,
      defaultUnit: 'جرام',
      category: 'breakfast',
    ),
    FoodPresetItem(
      nameAr: 'لانشون بلدي',
      nameEn: 'Egyptian Luncheon Meat',
      caloriesPer100g: 250,
      defaultUnit: 'جرام',
      category: 'breakfast',
    ),

    // ----------------- SNACKS (السناكس والحلويات والمشروبات) -----------------
    FoodPresetItem(
      nameAr: 'بليلة بالحليب والمكسرات',
      nameEn: 'Balila with Milk & Nuts',
      caloriesPer100g: 110,
      defaultUnit: 'جرام',
      category: 'snack',
    ),
    FoodPresetItem(
      nameAr: 'مهلبية بالمكسرات',
      nameEn: 'Muhallebi Pudding',
      caloriesPer100g: 130,
      defaultUnit: 'جرام',
      category: 'snack',
    ),
    FoodPresetItem(
      nameAr: 'أم علي بالمكسرات',
      nameEn: 'Om Ali Dessert',
      caloriesPer100g: 290,
      defaultUnit: 'جرام',
      category: 'snack',
    ),
    FoodPresetItem(
      nameAr: 'رز باللبن مصري',
      nameEn: 'Egyptian Rice Pudding',
      caloriesPer100g: 140,
      defaultUnit: 'جرام',
      category: 'snack',
    ),
    FoodPresetItem(
      nameAr: 'ترمس مسلوق بالكمون',
      nameEn: 'Boiled Lupini Beans',
      caloriesPer100g: 120,
      defaultUnit: 'جرام',
      category: 'snack',
    ),
    FoodPresetItem(
      nameAr: 'حمص الشام (الحلبسة)',
      nameEn: 'Hommos El Sham',
      caloriesPer100g: 90,
      defaultUnit: 'جرام',
      category: 'snack',
    ),
    FoodPresetItem(
      nameAr: 'بطاطا حلوة مشوية',
      nameEn: 'Baked Sweet Potato',
      caloriesPer100g: 90,
      defaultUnit: 'جرام',
      category: 'snack',
    ),
    FoodPresetItem(
      nameAr: 'ذرة مشوية',
      nameEn: 'Roasted Corn',
      caloriesPer100g: 115,
      defaultUnit: 'جرام',
      category: 'snack',
    ),
    FoodPresetItem(
      nameAr: 'كحك العيد بالملبن/العجوة',
      nameEn: 'Eid Kahk Cookie',
      caloriesPer100g: 450,
      defaultUnit: 'جرام',
      category: 'snack',
    ),
    FoodPresetItem(
      nameAr: 'بسكويت نشادر',
      nameEn: 'Nashader Biscuit',
      caloriesPer100g: 420,
      defaultUnit: 'جرام',
      category: 'snack',
    ),
    FoodPresetItem(
      nameAr: 'عصير قصب السكر',
      nameEn: 'Sugarcane Juice',
      caloriesPer100g: 70,
      defaultUnit: 'جرام',
      category: 'snack',
    ),
    FoodPresetItem(
      nameAr: 'عصير عرقسوس',
      nameEn: 'Erkousous Drink',
      caloriesPer100g: 35,
      defaultUnit: 'جرام',
      category: 'snack',
    ),

    // ----------------- LUNCH (الغداء) -----------------
    FoodPresetItem(
      nameAr: 'كشري مصري بالصلصة والدقة',
      nameEn: 'Egyptian Koshari',
      caloriesPer100g: 160,
      defaultUnit: 'جرام',
      category: 'lunch',
    ),
    FoodPresetItem(
      nameAr: 'ملوخية أوراق بالدجاج',
      nameEn: 'Molokhia with Chicken',
      caloriesPer100g: 75,
      defaultUnit: 'جرام',
      category: 'lunch',
    ),
    FoodPresetItem(
      nameAr: 'محشي كرنب مصري',
      nameEn: 'Stuffed Cabbage (Mahshi)',
      caloriesPer100g: 130,
      defaultUnit: 'جرام',
      category: 'lunch',
    ),
    FoodPresetItem(
      nameAr: 'محشي ورق عنب',
      nameEn: 'Stuffed Grape Leaves',
      caloriesPer100g: 145,
      defaultUnit: 'جرام',
      category: 'lunch',
    ),
    FoodPresetItem(
      nameAr: 'محشي باذنجان وفلفل',
      nameEn: 'Stuffed Eggplant & Pepper',
      caloriesPer100g: 140,
      defaultUnit: 'جرام',
      category: 'lunch',
    ),
    FoodPresetItem(
      nameAr: 'رقاق باللحمة المفرومة',
      nameEn: 'Egyptian Rqaq with Meat',
      caloriesPer100g: 210,
      defaultUnit: 'جرام',
      category: 'lunch',
    ),
    FoodPresetItem(
      nameAr: 'مكرونة بشاميل',
      nameEn: 'Macaroni Bechamel',
      caloriesPer100g: 180,
      defaultUnit: 'جرام',
      category: 'lunch',
    ),
    FoodPresetItem(
      nameAr: 'بامية باللحمة',
      nameEn: 'Okra Stew with Meat (Bamya)',
      caloriesPer100g: 85,
      defaultUnit: 'جرام',
      category: 'lunch',
    ),
    FoodPresetItem(
      nameAr: 'فاصوليا خضراء بالصلصة',
      nameEn: 'Green Beans Stew',
      caloriesPer100g: 70,
      defaultUnit: 'جرام',
      category: 'lunch',
    ),
    FoodPresetItem(
      nameAr: 'مسقعة باللحمة المفرومة',
      nameEn: 'Egyptian Moussaka with Meat',
      caloriesPer100g: 150,
      defaultUnit: 'جرام',
      category: 'lunch',
    ),
    FoodPresetItem(
      nameAr: 'صينية بطاطس بالفراخ',
      nameEn: 'Potato & Chicken Tray',
      caloriesPer100g: 125,
      defaultUnit: 'جرام',
      category: 'lunch',
    ),
    FoodPresetItem(
      nameAr: 'كفتة مشوية',
      nameEn: 'Grilled Kofta',
      caloriesPer100g: 250,
      defaultUnit: 'جرام',
      category: 'lunch',
    ),
    FoodPresetItem(
      nameAr: 'كباب حلة باللحم',
      nameEn: 'Stewed Beef (Kebab Halla)',
      caloriesPer100g: 220,
      defaultUnit: 'جرام',
      category: 'lunch',
    ),
    FoodPresetItem(
      nameAr: 'حواوشي مصري',
      nameEn: 'Egyptian Hawawshi',
      caloriesPer100g: 280,
      defaultUnit: 'جرام',
      category: 'lunch',
    ),
    FoodPresetItem(
      nameAr: 'شوربة لسان عصفور',
      nameEn: 'Orzo Soup',
      caloriesPer100g: 95,
      defaultUnit: 'جرام',
      category: 'lunch',
    ),
    FoodPresetItem(
      nameAr: 'سمك بلطي مشوي',
      nameEn: 'Grilled Tilapia Fish',
      caloriesPer100g: 130,
      defaultUnit: 'جرام',
      category: 'lunch',
    ),
    FoodPresetItem(
      nameAr: 'سمك بواري مقلي',
      nameEn: 'Fried Bouri Fish',
      caloriesPer100g: 210,
      defaultUnit: 'جرام',
      category: 'lunch',
    ),
    FoodPresetItem(
      nameAr: 'أرز صيادية بالسمك',
      nameEn: 'Sayadieh Fish Rice',
      caloriesPer100g: 150,
      defaultUnit: 'جرام',
      category: 'lunch',
    ),

    // ----------------- DINNER (العشاء) -----------------
    FoodPresetItem(
      nameAr: 'فول بالبيض المسلوق',
      nameEn: 'Foul with Boiled Eggs',
      caloriesPer100g: 130,
      defaultUnit: 'جرام',
      category: 'dinner',
    ),
    FoodPresetItem(
      nameAr: 'جبنة قريش بالطماطم والزيتون',
      nameEn: 'Cottage Cheese Salad',
      caloriesPer100g: 95,
      defaultUnit: 'جرام',
      category: 'dinner',
    ),
    FoodPresetItem(
      nameAr: 'بيض أومليت بالخضار',
      nameEn: 'Omelet with Vegetables',
      caloriesPer100g: 170,
      defaultUnit: 'جرام',
      category: 'dinner',
    ),
    FoodPresetItem(
      nameAr: 'بطاطس محمرة',
      nameEn: 'French Fries',
      caloriesPer100g: 312,
      defaultUnit: 'جرام',
      category: 'dinner',
    ),
    FoodPresetItem(
      nameAr: 'مسقعة خضار بدون لحمة',
      nameEn: 'Vegetarian Moussaka',
      caloriesPer100g: 110,
      defaultUnit: 'جرام',
      category: 'dinner',
    ),
    FoodPresetItem(
      nameAr: 'شوربة عدس أصفر مصري',
      nameEn: 'Egyptian Yellow Lentil Soup',
      caloriesPer100g: 90,
      defaultUnit: 'جرام',
      category: 'dinner',
    ),
    FoodPresetItem(
      nameAr: 'زبادي بالعسل',
      nameEn: 'Yogurt with Honey',
      caloriesPer100g: 85,
      defaultUnit: 'جرام',
      category: 'dinner',
    ),
    FoodPresetItem(
      nameAr: 'عيش بلدي مع حلاوة طحينية',
      nameEn: 'Baladi Bread with Halawa',
      caloriesPer100g: 350,
      defaultUnit: 'جرام',
      category: 'dinner',
    ),
    FoodPresetItem(
      nameAr: 'جبنة مثلثات / إبريز',
      nameEn: 'Triangle Processed Cheese',
      caloriesPer100g: 280,
      defaultUnit: 'جرام',
      category: 'dinner',
    ),
    FoodPresetItem(
      nameAr: 'بطاطس مسلوقة بالكمون',
      nameEn: 'Boiled Potato with Cumin',
      caloriesPer100g: 87,
      defaultUnit: 'جرام',
      category: 'dinner',
    ),
  ];
}
