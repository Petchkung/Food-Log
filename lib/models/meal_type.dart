import 'package:flutter/material.dart';

/// มื้ออาหาร
enum MealType {
  breakfast('มื้อเช้า', Icons.wb_sunny_outlined),
  lunch('มื้อกลางวัน', Icons.lunch_dining_outlined),
  dinner('มื้อเย็น', Icons.dark_mode_outlined),
  snack('ของว่าง', Icons.cookie_outlined);

  const MealType(this.label, this.icon);

  final String label;
  final IconData icon;

  /// แปลงจากข้อความที่เก็บในฐานข้อมูล ถ้าไม่รู้จักให้เป็นของว่าง
  static MealType fromName(String? name) => MealType.values.firstWhere(
        (m) => m.name == name,
        orElse: () => MealType.snack,
      );

  /// เดามื้อจากเวลา ใช้เป็นค่าเริ่มต้นตอนเพิ่มอาหาร
  static MealType suggestFor(DateTime time) {
    final h = time.hour;
    if (h >= 5 && h < 11) return MealType.breakfast;
    if (h >= 11 && h < 15) return MealType.lunch;
    if (h >= 17 && h < 22) return MealType.dinner;
    return MealType.snack;
  }
}