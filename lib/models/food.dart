class Food {
  String? foodId;
  String? foodName;
  String? foodMeal;
  double? foodPrice;
  int? foodPerson;
  String? foodDate;
  String? foodImageUrl;

  // Constructor
  Food({
    this.foodId,
    this.foodName,
    this.foodMeal,
    this.foodPrice,
    this.foodPerson,
    this.foodDate,
    this.foodImageUrl,
  });

  // แปลง Supabase ข้อมูลจาก JSON เป็น Object เพื่อใช้ใน Flutter
  factory Food.fromJson(Map<String, dynamic> json) {
    return Food(
      foodId: json['id'] as String?,
      foodName: json['foodName'] as String?,
      foodMeal: json['foodMeal'] as String?,
      // ใช้ num แล้วค่อย toDouble() เพราะ Supabase อาจส่ง 250 (int) หรือ 234.75 (double) มา
      foodPrice: (json['foodPrice'] as num?)?.toDouble(),
      foodPerson: json['foodPerson'] as int?,
      foodDate: json['foodDate'] as String?,
      foodImageUrl: json['foodimageUrl'] as String?,
    );
  }

  // แปลงข้อมูลจาก Object เป็น JSON เพื่อส่งไปยัง Supabase
  Map<String, dynamic> toJson() {
    return {
      'foodName': foodName,
      'foodMeal': foodMeal,
      'foodPrice': foodPrice,
      'foodPerson': foodPerson,
      'foodDate': foodDate,
      'foodimageUrl': foodImageUrl,
    };
  }
}
