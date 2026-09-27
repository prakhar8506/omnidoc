/// Average nutrition for common foods. Values are per one default serving
/// (one egg, one roti, one bowl) or per 100 g when [per100g] is true.
class CatalogFood {
  const CatalogFood({
    required this.id,
    required this.aliases,
    required this.servingName,
    required this.kcal,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.fiber = 0,
    this.allergens = const [],
    this.per100g = false,
    this.meat = false,
    this.egg = false,
    this.dairy = false,
  });

  final String id;
  final List<String> aliases;
  final String servingName;
  final double kcal;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;
  final List<String> allergens;
  final bool per100g;
  final bool meat;
  final bool egg;
  final bool dairy;
}

const List<CatalogFood> foodCatalog = [
  CatalogFood(id: 'egg', aliases: ['eggs', 'egg', 'anda', 'ande'], servingName: 'large egg', kcal: 72, protein: 6.3, carbs: 0.4, fat: 4.8, allergens: ['egg'], egg: true),
  CatalogFood(id: 'egg_white', aliases: ['egg whites', 'egg white'], servingName: 'egg white', kcal: 17, protein: 3.6, carbs: 0.2, fat: 0.1, allergens: ['egg'], egg: true),
  CatalogFood(id: 'roti', aliases: ['chapati', 'chapatti', 'roti', 'phulka'], servingName: 'roti', kcal: 104, protein: 3.1, carbs: 18, fat: 2.5, fiber: 2.2, allergens: ['wheat', 'gluten']),
  CatalogFood(id: 'paratha', aliases: ['paratha', 'parantha'], servingName: 'paratha', kcal: 180, protein: 4, carbs: 24, fat: 8, fiber: 2, allergens: ['wheat', 'gluten']),
  CatalogFood(id: 'rice', aliases: ['white rice', 'steamed rice', 'chawal', 'rice'], servingName: 'cup cooked', kcal: 205, protein: 4.3, carbs: 45, fat: 0.4, fiber: 0.6),
  CatalogFood(id: 'brown_rice', aliases: ['brown rice'], servingName: 'cup cooked', kcal: 216, protein: 5, carbs: 45, fat: 1.8, fiber: 3.5),
  CatalogFood(id: 'dal', aliases: ['toor dal', 'moong dal', 'masoor dal', 'dal', 'daal', 'lentils'], servingName: 'bowl', kcal: 170, protein: 11, carbs: 28, fat: 2, fiber: 8),
  CatalogFood(id: 'rajma', aliases: ['rajma', 'kidney beans'], servingName: 'bowl', kcal: 220, protein: 15, carbs: 32, fat: 4, fiber: 11),
  CatalogFood(id: 'chole', aliases: ['chole', 'chana masala', 'chickpeas', 'chana'], servingName: 'bowl', kcal: 210, protein: 14, carbs: 32, fat: 4, fiber: 9),
  CatalogFood(id: 'paneer', aliases: ['paneer'], servingName: '100 g', kcal: 265, protein: 18, carbs: 4, fat: 20, allergens: ['dairy', 'milk'], per100g: true, dairy: true),
  CatalogFood(id: 'tofu', aliases: ['tofu'], servingName: '100 g', kcal: 76, protein: 8, carbs: 2, fat: 5, allergens: ['soy'], per100g: true),
  CatalogFood(id: 'chicken', aliases: ['chicken breast', 'grilled chicken', 'chicken'], servingName: '100 g cooked', kcal: 165, protein: 31, carbs: 0, fat: 3.6, per100g: true, meat: true),
  CatalogFood(id: 'chicken_curry', aliases: ['chicken curry'], servingName: 'bowl', kcal: 250, protein: 24, carbs: 8, fat: 14, meat: true),
  CatalogFood(id: 'fish', aliases: ['fish curry', 'grilled fish', 'fish', 'salmon'], servingName: '100 g', kcal: 140, protein: 22, carbs: 0, fat: 5, allergens: ['fish'], per100g: true, meat: true),
  CatalogFood(id: 'mutton', aliases: ['mutton', 'lamb'], servingName: '100 g', kcal: 250, protein: 25, carbs: 0, fat: 16, per100g: true, meat: true),
  CatalogFood(id: 'milk', aliases: ['toned milk', 'milk'], servingName: 'cup', kcal: 120, protein: 6.6, carbs: 9, fat: 6, allergens: ['dairy', 'milk'], dairy: true),
  CatalogFood(id: 'curd', aliases: ['greek yogurt', 'yogurt', 'curd', 'dahi'], servingName: 'bowl', kcal: 98, protein: 8, carbs: 7, fat: 4, allergens: ['dairy', 'milk'], dairy: true),
  CatalogFood(id: 'banana', aliases: ['banana', 'kela'], servingName: 'medium', kcal: 105, protein: 1.3, carbs: 27, fat: 0.4, fiber: 3.1),
  CatalogFood(id: 'apple', aliases: ['apple'], servingName: 'medium', kcal: 95, protein: 0.5, carbs: 25, fat: 0.3, fiber: 4.4),
  CatalogFood(id: 'orange', aliases: ['orange'], servingName: 'medium', kcal: 62, protein: 1.2, carbs: 15, fat: 0.2, fiber: 3.1),
  CatalogFood(id: 'oats', aliases: ['oats', 'oatmeal', 'oat porridge'], servingName: '50 g dry', kcal: 190, protein: 6.5, carbs: 33, fat: 3.5, fiber: 5, allergens: ['gluten']),
  CatalogFood(id: 'almonds', aliases: ['almonds', 'almond', 'badam'], servingName: '10 almonds', kcal: 70, protein: 2.5, carbs: 2.5, fat: 6, fiber: 1.2, allergens: ['nuts', 'tree nuts']),
  CatalogFood(id: 'peanuts', aliases: ['peanut butter', 'peanuts', 'peanut'], servingName: 'handful', kcal: 160, protein: 7, carbs: 5, fat: 14, allergens: ['peanut', 'peanuts']),
  CatalogFood(id: 'bread', aliases: ['toast', 'bread slice', 'bread'], servingName: 'slice', kcal: 80, protein: 3, carbs: 14, fat: 1, fiber: 1, allergens: ['wheat', 'gluten']),
  CatalogFood(id: 'oil', aliases: ['olive oil', 'cooking oil', 'oil'], servingName: 'teaspoon', kcal: 40, protein: 0, carbs: 0, fat: 4.5),
  CatalogFood(id: 'ghee', aliases: ['ghee'], servingName: 'teaspoon', kcal: 45, protein: 0, carbs: 0, fat: 5, allergens: ['dairy'], dairy: true),
  CatalogFood(id: 'dosa', aliases: ['dosa'], servingName: 'dosa', kcal: 120, protein: 3, carbs: 18, fat: 4, fiber: 1),
  CatalogFood(id: 'idli', aliases: ['idli'], servingName: 'idli', kcal: 58, protein: 2, carbs: 12, fat: 0.3, fiber: 0.5),
  CatalogFood(id: 'poha', aliases: ['poha'], servingName: 'bowl', kcal: 250, protein: 6, carbs: 40, fat: 8, fiber: 2),
  CatalogFood(id: 'upma', aliases: ['upma'], servingName: 'bowl', kcal: 220, protein: 5, carbs: 32, fat: 8, fiber: 3, allergens: ['gluten']),
  CatalogFood(id: 'sabzi', aliases: ['mixed vegetables', 'sabzi', 'vegetable curry', 'bhindi', 'palak'], servingName: 'bowl', kcal: 120, protein: 3, carbs: 12, fat: 6, fiber: 4),
  CatalogFood(id: 'salad', aliases: ['salad'], servingName: 'bowl', kcal: 40, protein: 1.5, carbs: 8, fat: 0.4, fiber: 2),
  CatalogFood(id: 'whey', aliases: ['whey protein', 'protein shake', 'whey'], servingName: 'scoop', kcal: 120, protein: 24, carbs: 3, fat: 1.5, allergens: ['dairy', 'milk'], dairy: true),
  CatalogFood(id: 'samosa', aliases: ['samosa'], servingName: 'piece', kcal: 260, protein: 5, carbs: 28, fat: 14, allergens: ['wheat', 'gluten']),
  CatalogFood(id: 'pizza', aliases: ['pizza'], servingName: 'slice', kcal: 285, protein: 12, carbs: 36, fat: 10, allergens: ['wheat', 'gluten', 'dairy']),
  CatalogFood(id: 'tea', aliases: ['chai', 'tea'], servingName: 'cup', kcal: 40, protein: 1, carbs: 5, fat: 1.5, allergens: ['dairy'], dairy: true),
];

CatalogFood? matchFood(String text) {
  final q = text.toLowerCase().trim();
  if (q.isEmpty) return null;
  CatalogFood? best;
  var bestLen = 0;
  for (final food in foodCatalog) {
    for (final alias in food.aliases) {
      if (q.contains(alias) && alias.length > bestLen) {
        best = food;
        bestLen = alias.length;
      }
    }
  }
  return best;
}
