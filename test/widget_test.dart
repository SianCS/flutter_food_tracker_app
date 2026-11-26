import 'package:flutter_food_tracker_app/models/food.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Food.fromJson / toJson', () {
    final food = Food.fromJson({
      'id': 'abc',
      'foodName': 'KFC',
      'foodMeal': 'เช้า',
      'foodPrice': 250, // Supabase อาจส่งเป็น int มา
      'foodPerson': 2,
      'foodDate': '2026-03-19',
      'foodimageUrl': '',
    });

    expect(food.foodPrice, 250.0);
    expect(food.toJson()['foodMeal'], 'เช้า');
    expect(food.toJson().containsKey('id'), false);
  });
}
