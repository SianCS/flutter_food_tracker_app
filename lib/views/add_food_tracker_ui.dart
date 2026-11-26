// ignore_for_file: sort_child_properties_last
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_food_tracker_app/models/food.dart';
import 'package:flutter_food_tracker_app/services/supabase_service.dart';
import 'package:image_picker/image_picker.dart';

class AddFoodTrackerUi extends StatefulWidget {
  const AddFoodTrackerUi({super.key});

  @override
  State<AddFoodTrackerUi> createState() => _AddFoodTrackerUiState();
}

class _AddFoodTrackerUiState extends State<AddFoodTrackerUi> {
  // -------- คำสั่งส่วนของการเปิดกล้อง+แกลอรี่ -------------------------------
  Uint8List? imageByte; // เก็บรูปที่จะใช้แสดงบน UI
  XFile? xFile; // เก็บรูปที่จะใช้อัปโหลดไปที่ Supabase

  // เมธอดเปิดกล้องหรือแกลอรี่ (ส่ง source เข้ามาว่าจะเอาแบบไหน)
  Future<void> pickPicture(ImageSource source) async {
    final pickImage = await ImagePicker().pickImage(
      source: source,
      imageQuality: 80,
    );

    // ตรวจสอบก่อนว่าผู้ใช้ถ่าย/เลือกรูปไหม (ถ้ากดยกเลิกจะได้ null)
    if (pickImage != null) {
      final bytes = await pickImage.readAsBytes();
      setState(() {
        imageByte = bytes;
        xFile = pickImage;
      });
    }
  }

  // เมธอดแสดง BottomSheet ให้เลือกว่าจะถ่ายรูปหรือเลือกจากแกลอรี่
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

  // -------- มื้ออาหาร --------------------------------------------------
  final List<String> meals = ['เช้า', 'กลางวัน', 'เย็น', 'ว่าง'];
  String foodMeal = 'เช้า'; // มื้อที่ถูกเลือกอยู่ (ค่าเริ่มต้น = เช้า)

  bool isSaving = false; // กันกดบันทึกซ้ำระหว่างกำลังอัปโหลด

  // เมธอดเปิดปฏิทินให้เลือกวันที่
  Future<void> pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        // toString() ได้ '2026-03-19 00:00:00.000' ตัดเอาแค่ 10 ตัวแรก = '2026-03-19'
        foodDateCtrl.text = picked.toString().substring(0, 10);
      });
    }
  }

  // เมธอดแสดง SnackBar
  void showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // เมธอดล้างข้อมูลที่ป้อนและเลือกทั้งหมด
  void clearData() {
    setState(() {
      foodNameCtrl.clear();
      foodPriceCtrl.clear();
      foodPersonCtrl.clear();
      foodDateCtrl.clear();
      foodMeal = 'เช้า';
      imageByte = null;
      xFile = null;
    });
  }

  // เมธอดบันทึกข้อมูล
  Future<void> saveData() async {
    // Validate UI
    if (foodNameCtrl.text.trim().isEmpty ||
        foodPriceCtrl.text.trim().isEmpty ||
        foodPersonCtrl.text.trim().isEmpty ||
        foodDateCtrl.text.isEmpty) {
      showSnackBar('กรุณาป้อนข้อมูลให้ครบ...', Colors.red);
      return; //*** อย่าลืมใส่ return นะ
    }

    // tryParse จะคืน null ถ้าแปลงไม่ได้ (เช่นพิมพ์ 'abc') แทนที่จะทำให้แอป crash แบบ parse
    final price = double.tryParse(foodPriceCtrl.text.trim());
    final person = int.tryParse(foodPersonCtrl.text.trim());
    if (price == null || person == null) {
      showSnackBar('กินไปกี่บาท / กินกี่คน ต้องเป็นตัวเลข', Colors.red);
      return;
    }

    setState(() => isSaving = true);

    try {
      // ถ้ามีการถ่าย/เลือกรูป ให้อัปโหลดไป Bucket ก่อน แล้วเอาที่อยู่รูปมาเก็บลง Table
      String imageUrl = '';
      if (xFile != null) {
        imageUrl = await SupabaseService().uploadFileToSupabase(xFile!);
      }

      // แพ็กข้อมูลผ่าน Constructor ของ Food แล้วส่งไปบันทึกลง Table
      Food food = Food(
        foodName: foodNameCtrl.text.trim(),
        foodMeal: foodMeal,
        foodPrice: price,
        foodPerson: person,
        foodDate: foodDateCtrl.text,
        foodImageUrl: imageUrl,
      );
      await SupabaseService().insertDataToTableFood(food);

      // หลัง await ต้องเช็ค mounted ก่อนใช้ context (เผื่อผู้ใช้ออกจากหน้าไปแล้ว)
      if (!mounted) return;
      showSnackBar('บันทึกข้อมูลเสร็จสิ้น', Colors.green);
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => isSaving = false);
      showSnackBar('บันทึกไม่สำเร็จ: $e', Colors.red);
    }
  }

  // Widget ปุ่มเลือกมื้อ: ถ้าเป็นมื้อที่เลือกอยู่ = สีเขียว, ไม่ได้เลือก = สีเทา
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

  // Widget หัวข้อของแต่ละช่อง
  Widget label(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(text),
    );
  }

  @override
  void dispose() {
    foodNameCtrl.dispose();
    foodPriceCtrl.dispose();
    foodPersonCtrl.dispose();
    foodDateCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red,
        title: const Text(
          'Food Tracker (เพิ่ม)',
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
                // ใช้ Ternary Operator ____ ? _____ : _____
                InkWell(
                  onTap: showPickPictureOption,
                  child: xFile == null
                      ? Icon(
                          Icons.camera_alt_outlined,
                          size: MediaQuery.of(context).size.width * 0.3,
                          color: Colors.grey,
                        )
                      : Image.memory(
                          imageByte!,
                          width: MediaQuery.of(context).size.width * 0.35,
                          height: MediaQuery.of(context).size.width * 0.35,
                          fit: BoxFit.cover,
                        ),
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
                  readOnly: true, // ห้ามพิมพ์เอง ให้เลือกจากปฏิทินอย่างเดียว
                  onTap: pickDate,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                    hintText: 'เช่น 2026-01-31',
                    suffixIcon: const Icon(Icons.calendar_month),
                  ),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: isSaving ? null : saveData,
                  child: isSaving
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.white),
                        )
                      : Text(
                          'บันทึก',
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
                  onPressed: clearData,
                  child: Text(
                    'ยกเลิก',
                    style: TextStyle(
                      fontSize: MediaQuery.of(context).size.height * 0.02,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    fixedSize: Size(MediaQuery.of(context).size.width, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
