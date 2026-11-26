import 'package:flutter/material.dart';
import 'package:flutter_food_tracker_app/models/food.dart';
import 'package:flutter_food_tracker_app/services/supabase_service.dart';
import 'package:flutter_food_tracker_app/views/add_food_tracker_ui.dart';
import 'package:flutter_food_tracker_app/views/update_delete_food_tracker_ui.dart';

class ShowAllFoodTrackerUi extends StatefulWidget {
  const ShowAllFoodTrackerUi({super.key});

  @override
  State<ShowAllFoodTrackerUi> createState() => _ShowAllFoodTrackerUiState();
}

class _ShowAllFoodTrackerUiState extends State<ShowAllFoodTrackerUi> {
  // ตัวแปรเก็บข้อมูลการกินทั้งหมดที่ดึงมาจาก Supabase
  List<Food>? foods;

  // เมธอดดึงข้อมูลการกินทั้งหมดจาก Supabase
  Future<void> fetchAllFoods() async {
    final data = await SupabaseService().getAllDataFromTableFood();

    setState(() {
      foods = data;
    });
  }

  @override
  void initState() {
    super.initState();
    fetchAllFoods();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red,
        title: Text(
          'Food Tracker',
          style: TextStyle(
            fontSize: MediaQuery.of(context).size.width * 0.05,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddFoodTrackerUi(),
            ),
          );
          // กลับมาจากหน้าเพิ่มแล้ว ดึงข้อมูลใหม่อีกครั้ง
          fetchAllFoods();
        },
        backgroundColor: Colors.red,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: Center(
        child: Column(
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.03),
            Image.asset(
              'assets/images/logo.png',
              width: MediaQuery.of(context).size.width * 0.3,
              height: MediaQuery.of(context).size.width * 0.3,
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.02),
            // ส่วนแสดงรายการการกินทั้งหมด
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 20, right: 20, bottom: 80),
                child: ListView.builder(
                  itemCount: foods?.length ?? 0,
                  itemBuilder: (context, index) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        onTap: () async {
                          // กดที่รายการ ไปหน้าแก้ไข/ลบ พร้อมส่งข้อมูลรายการที่เลือกไปด้วย
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => UpdateDeleteFoodTrackerUi(
                                foodDataShowUD: foods![index],
                              ),
                            ),
                          );
                          // กลับมาแล้วดึงข้อมูลใหม่อีกครั้ง
                          fetchAllFoods();
                        },
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        tileColor: index % 2 == 0 ? Colors.green[50] : Colors.grey[100],
                        leading: foods![index].foodImageUrl == null || foods![index].foodImageUrl == ''
                            ? Image.asset(
                                'assets/images/logo.png',
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                              )
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: Image.network(
                                  foods![index].foodImageUrl!,
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                  // ถ้าโหลดรูปไม่ได้ ให้แสดงโลโก้ขนาดเท่าเดิมแทนกล่อง error (กันล้นจอ)
                                  errorBuilder: (context, error, stackTrace) => Image.asset(
                                    'assets/images/logo.png',
                                    width: 50,
                                    height: 50,
                                  ),
                                ),
                              ),
                        title: Text('กิน: ${foods![index].foodName}'),
                        subtitle: Text(
                          'วันที่: ${foods![index].foodDate} มื้อ: ${foods![index].foodMeal}\n'
                          'ราคา: ${foods![index].foodPrice?.toStringAsFixed(2)} บาท (${foods![index].foodPerson} คน)',
                        ),
                        trailing: const Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.red,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
