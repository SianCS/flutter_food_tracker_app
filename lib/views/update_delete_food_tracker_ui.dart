// ignore_for_file: sort_child_properties_last
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_food_tracker_app/models/food.dart';
import 'package:flutter_food_tracker_app/services/supabase_service.dart';
import 'package:image_picker/image_picker.dart';

class UpdateDeleteFoodTrackerUi extends StatefulWidget {
  // ตัวแปรรับข้อมูลการกินที่ส่งมาจากหน้า ShowAllFoodTrackerUi
  final Food? foodDataShowUD;

  const UpdateDeleteFoodTrackerUi({super.key, this.foodDataShowUD});

  @override
  State<UpdateDeleteFoodTrackerUi> createState() => _UpdateDeleteFoodTrackerUiState();
}

class _UpdateDeleteFoodTrackerUiState extends State<UpdateDeleteFoodTrackerUi> {
  // -------- คำสั่งส่วนของการเปิดกล้อง+แกลอรี่ -------------------------------
  Uint8List? imageByte; // เก็บรูปใหม่ที่จะใช้แสดงบน UI
  XFile? xFile; // เก็บรูปใหม่ที่จะใช้อัปโหลดไปที่ Supabase

  Future<void> pickPicture(ImageSource source) async {
    final pickImage = await ImagePicker().pickImage(
      source: source,
      imageQuality: 80,
    );

    if (pickImage != null) {
      final bytes = await pickImage.readAsBytes();
      setState(() {
        imageByte = bytes;
        xFile = pickImage;
      });
    }
  }

  void showPickPictureOption() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.red),
              title: const Text('ถ่ายรูป'),
              onTap: () {
                Navigator.pop(context);
                pickPicture(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.red),
              title: const Text('เลือกจากแกลอรี่'),
              onTap: () {
                Navigator.pop(context);
                pickPicture(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }
  // --------------------------------------------------------------------

  // -------- ตัวควบคุม TextField ----------------------------------------
  TextEditingController foodNameCtrl = TextEditingController();
  TextEditingController foodPriceCtrl = TextEditingController();
  TextEditingController foodPersonCtrl = TextEditingController();
  TextEditingController foodDateCtrl = TextEditingController();

  final List<String> meals = ['เช้า', 'กลางวัน', 'เย็น', 'ว่าง'];
  String foodMeal = 'เช้า';

  bool isWorking = false; // กันกดปุ่มซ้ำระหว่างกำลังบันทึก/ลบ

  // ที่อยู่รูปเดิม (ถ้าไม่มีรูปจะเป็น '')
  String get oldImageUrl => widget.foodDataShowUD?.foodImageUrl ?? '';

  // ชื่อไฟล์รูปเดิมใน Storage = ส่วนสุดท้ายของ url
  // ต้อง decode ก่อน เพราะใน url ช่องว่างกลายเป็น %20 แต่ชื่อไฟล์จริงใน Storage เป็นช่องว่าง
  // เช่น .../food_tracker_tb/123_Screenshot%202569.png -> 123_Screenshot 2569.png
  String get oldImageFileName => Uri.decodeComponent(oldImageUrl.split('/').last);

  @override
  void initState() {
    super.initState();
    // เอาข้อมูลเดิมมาแสดงในช่องต่างๆ
    final food = widget.foodDataShowUD;
    foodNameCtrl.text = food?.foodName ?? '';
    foodPriceCtrl.text = food?.foodPrice?.toString() ?? '';
    foodPersonCtrl.text = food?.foodPerson?.toString() ?? '';
    foodDateCtrl.text = food?.foodDate ?? '';
    foodMeal = food?.foodMeal ?? 'เช้า';
  }

  @override
  void dispose() {
    foodNameCtrl.dispose();
    foodPriceCtrl.dispose();
    foodPersonCtrl.dispose();
    foodDateCtrl.dispose();
    super.dispose();
  }

  Future<void> pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(foodDateCtrl.text) ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        foodDateCtrl.text = picked.toString().substring(0, 10);
      });
    }
  }

  void showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // เมธอดบันทึกการแก้ไข
  Future<void> updateData() async {
    // Validate UI
    if (foodNameCtrl.text.trim().isEmpty ||
        foodPriceCtrl.text.trim().isEmpty ||
        foodPersonCtrl.text.trim().isEmpty ||
        foodDateCtrl.text.isEmpty) {
      showSnackBar('กรุณาป้อนข้อมูลให้ครบ...', Colors.red);
      return;
    }

    final price = double.tryParse(foodPriceCtrl.text.trim());
    final person = int.tryParse(foodPersonCtrl.text.trim());
    if (price == null || person == null) {
      showSnackBar('กินไปกี่บาท / กินกี่คน ต้องเป็นตัวเลข', Colors.red);
      return;
    }

    setState(() => isWorking = true);

    try {
      // ถ้าไม่ได้ถ่ายรูปใหม่ ใช้รูปเดิม
      String imageUrl = oldImageUrl;

      if (xFile != null) {
        // ถ่ายรูปใหม่: ถ้ามีรูปเดิมให้ลบออกจาก Storage ก่อน
        // ชื่อไฟล์คือส่วนสุดท้ายของ url เช่น .../food_tracker_tb/1732600000_abc.jpg -> 1732600000_abc.jpg
        if (oldImageUrl != '') {
          await SupabaseService().deleteFileFromBucketFood(oldImageFileName);
        }
        // แล้วอัปโหลดรูปใหม่
        imageUrl = await SupabaseService().uploadFileToSupabase(xFile!);
      }

      Food food = Food(
        foodName: foodNameCtrl.text.trim(),
        foodMeal: foodMeal,
        foodPrice: price,
        foodPerson: person,
        foodDate: foodDateCtrl.text,
        foodImageUrl: imageUrl,
      );
      await SupabaseService().updateDataToTableFood(food, widget.foodDataShowUD!.foodId!);

      if (!mounted) return;
      showSnackBar('แก้ไขข้อมูลเสร็จสิ้น', Colors.green);
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => isWorking = false);
      showSnackBar('แก้ไขไม่สำเร็จ: $e', Colors.red);
    }
  }

  // เมธอดลบข้อมูล (ถามยืนยันก่อน)
  Future<void> deleteData() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยืนยันการลบ'),
        content: Text('ต้องการลบ "${widget.foodDataShowUD?.foodName}" ใช่ไหม?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ไม่ลบ'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ลบ', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => isWorking = true);

    try {
      // ถ้ามีรูป ลบรูปออกจาก Storage ก่อน
      if (oldImageUrl != '') {
        await SupabaseService().deleteFileFromBucketFood(oldImageFileName);
      }
      // แล้วลบข้อมูลออกจาก Table
      await SupabaseService().deleteDataFromTableFood(widget.foodDataShowUD!.foodId!);

      if (!mounted) return;
      showSnackBar('ลบข้อมูลเสร็จสิ้น', Colors.green);
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => isWorking = false);
      showSnackBar('ลบไม่สำเร็จ: $e', Colors.red);
    }
  }

  Widget mealButton(String meal) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: ElevatedButton(
          onPressed: () {
            setState(() {
              foodMeal = meal;
            });
          },
          child: Text(
            meal,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: foodMeal == meal ? Colors.green : Colors.grey,
            padding: EdgeInsets.zero,
          ),
        ),
      ),
    );
  }

  Widget label(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(text),
    );
  }

  // แสดงรูป: รูปใหม่ที่เพิ่งถ่าย > รูปเดิมจาก Supabase > โลโก้
  Widget showImage() {
    final size = MediaQuery.of(context).size.width * 0.35;
    if (xFile != null) {
      return Image.memory(imageByte!, width: size, height: size, fit: BoxFit.cover);
    }
    if (oldImageUrl != '') {
      return Image.network(
        oldImageUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        // ถ้าโหลดรูปไม่ได้ ให้แสดงโลโก้แทน
        errorBuilder: (context, error, stackTrace) => Image.asset(
          'assets/images/logo.png',
          width: size,
          height: size,
        ),
      );
    }
    return Image.asset('assets/images/logo.png', width: size, height: size, fit: BoxFit.cover);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red,
        title: const Text(
          'Food Tracker (แก้ไข/ลบ)',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(top: 50, left: 40, right: 40, bottom: 50),
          child: Center(
            child: Column(
              children: [
                InkWell(
                  onTap: showPickPictureOption,
                  child: showImage(),
                ),
                const SizedBox(height: 30),
                label('กินอะไร'),
                TextField(
                  controller: foodNameCtrl,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                    hintText: 'เช่น KFC, Pizza',
                  ),
                ),
                const SizedBox(height: 20),
                label('กินมื้อไหน'),
                const SizedBox(height: 5),
                Row(
                  children: meals.map((meal) => mealButton(meal)).toList(),
                ),
                const SizedBox(height: 20),
                label('กินไปกี่บาท'),
                TextField(
                  controller: foodPriceCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                    hintText: 'เช่น 299.50',
                  ),
                ),
                const SizedBox(height: 20),
                label('กินกันกี่คน'),
                TextField(
                  controller: foodPersonCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                    hintText: 'เช่น 3',
                  ),
                ),
                const SizedBox(height: 20),
                label('กินไปวันไหน'),
                TextField(
                  controller: foodDateCtrl,
                  readOnly: true,
                  onTap: pickDate,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                    hintText: 'เช่น 2026-01-31',
                    suffixIcon: const Icon(Icons.calendar_month),
                  ),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: isWorking ? null : updateData,
                  child: Text(
                    'บันทึกแก้ไข',
                    style: TextStyle(
                      fontSize: MediaQuery.of(context).size.height * 0.02,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    disabledBackgroundColor: Colors.green[200],
                    fixedSize: Size(MediaQuery.of(context).size.width, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                ),
                const SizedBox(height: 15),
                ElevatedButton(
                  onPressed: isWorking ? null : deleteData,
                  child: Text(
                    'ลบข้อมูล',
                    style: TextStyle(
                      fontSize: MediaQuery.of(context).size.height * 0.02,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    disabledBackgroundColor: Colors.red[200],
                    fixedSize: Size(MediaQuery.of(context).size.width, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                ),
                if (isWorking) ...[
                  const SizedBox(height: 20),
                  const CircularProgressIndicator(color: Colors.red),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
