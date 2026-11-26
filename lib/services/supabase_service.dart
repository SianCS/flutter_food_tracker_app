import 'package:flutter_food_tracker_app/models/food.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  //** สร้าง instance ของ SupabaseClient เพื่อใช้เชื่อมต่อกับ Supabase Database และ Storage
  final supabase = Supabase.instance.client;

  //1. อัปโหลดไฟล์รูปไปที่ Storage (Bucket: food_tracker_tb) แล้วคืนที่อยู่รูป (public url)
  Future<String> uploadFileToSupabase(XFile xfile) async {
    final newFileName = '${DateTime.now().millisecondsSinceEpoch}_${xfile.name}';

    await supabase.storage.from('food_tracker_tb').uploadBinary(
          newFileName,
          await xfile.readAsBytes(),
          fileOptions: FileOptions(contentType: xfile.mimeType),
        );

    return supabase.storage.from('food_tracker_tb').getPublicUrl(newFileName);
  }

  //2. เพิ่มข้อมูลลง Table:food_tracker_tb
  Future<void> insertDataToTableFood(Food food) async {
    await supabase.from('food_tracker_tb').insert(food.toJson());
  }

  //3. ดึงข้อมูลทั้งหมดจาก Table:food_tracker_tb (เรียงวันที่ใหม่สุดขึ้นก่อน)
  Future<List<Food>> getAllDataFromTableFood() async {
    final response = await supabase.from('food_tracker_tb').select('*').order('foodDate', ascending: false);
    return response.map((e) => Food.fromJson(e)).toList();
  }

  //4. ลบไฟล์รูปออกจาก Storage (Bucket: food_tracker_tb)
  Future<void> deleteFileFromBucketFood(String fileName) async {
    await supabase.storage.from('food_tracker_tb').remove([fileName]);
  }

  //5. แก้ไขข้อมูลใน Table:food_tracker_tb
  Future<void> updateDataToTableFood(Food food, String id) async {
    await supabase.from('food_tracker_tb').update(food.toJson()).eq('id', id);
  }

  //6. ลบข้อมูลออกจาก Table:food_tracker_tb
  Future<void> deleteDataFromTableFood(String id) async {
    await supabase.from('food_tracker_tb').delete().eq('id', id);
  }
}
