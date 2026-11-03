import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_log/app/app_check.dart';
import 'package:food_log/data/food_repository.dart';
import 'package:food_log/data/local_database.dart';
import 'package:food_log/firebase_options.dart';
import 'package:food_log/models/food_entry.dart';
import 'package:food_log/models/meal_type.dart';
import 'package:food_log/services/firestore_sync_service.dart';
import 'package:integration_test/integration_test.dart';

/// เติมข้อมูลตัวอย่าง 14 วันให้บัญชีเดโม (ลงทั้ง SQLite ในเครื่อง และ Firestore)
///
/// รันบน emulator/มือถือที่จะใช้สาธิต — รันซ้ำได้ (ลบข้อมูลเดโมเดิมก่อนทุกครั้ง)
/// flutter test integration_test/seed_demo_data_test.dart --dart-define=DEMO_PASSWORD=รหัสผ่าน
///
/// วันที่นับย้อนจาก "วันนี้" จึงควรรันใหม่ในเช้าวันนำเสนอ
const demoEmail = String.fromEnvironment(
  'DEMO_EMAIL',
  defaultValue: 'demo@foodlog.app',
);
const demoPassword = String.fromEnvironment('DEMO_PASSWORD');

/// เมนู: ชื่อ, kcal, โปรตีน, คาร์บ, ไขมัน (กรัม)
typedef Dish = (String, double, double, double, double);

const Dish jok = ('โจ๊กหมูใส่ไข่', 250, 12, 35, 7);
const Dish khaoTom = ('ข้าวต้มกุ้ง', 280, 18, 38, 6);
const Dish toast = ('ขนมปังปิ้ง + ไข่ดาว', 320, 14, 30, 16);
const Dish eggs = ('ไข่ต้ม 2 ฟอง', 155, 13, 1, 11);
const Dish patongko = ('ปาท่องโก๋ + นมถั่วเหลือง', 380, 9, 45, 18);
const Dish khaoManGai = ('ข้าวมันไก่', 600, 25, 65, 26);
const Dish kaprao = ('ข้าวกะเพราไก่ไข่ดาว', 580, 28, 62, 24);
const Dish noodle = ('ก๋วยเตี๋ยวเรือ', 350, 18, 40, 12);
const Dish padThai = ('ผัดไทยกุ้งสด', 550, 20, 70, 20);
const Dish somtam = ('ส้มตำไทย + ไก่ย่าง', 450, 35, 30, 18);
const Dish khaoPad = ('ข้าวผัดหมู', 560, 20, 72, 20);
const Dish tomYum = ('ต้มยำกุ้ง + ข้าวสวย', 480, 25, 55, 16);
const Dish greenCurry = ('แกงเขียวหวานไก่ + ข้าวสวย', 620, 26, 60, 30);
const Dish suki = ('สุกี้น้ำทะเล', 380, 28, 30, 14);
const Dish garlicPork = ('ข้าวหมูทอดกระเทียม', 580, 24, 66, 22);
const Dish yumWoonsen = ('ยำวุ้นเส้น', 300, 18, 32, 10);
const Dish mookata = ('หมูกระทะ', 950, 45, 60, 55);
const Dish thaiTea = ('ชาไทยเย็น', 250, 3, 40, 8);
const Dish banana = ('กล้วยหอม', 105, 1, 27, 0);
const Dish yogurt = ('โยเกิร์ตรสธรรมชาติ', 150, 8, 18, 5);
const Dish bubbleTea = ('ชานมไข่มุก', 350, 2, 58, 10);

/// แผนอาหารแต่ละวัน (index 0 = วันนี้, 1 = เมื่อวาน, ...)
/// มีทั้งวันที่ต่ำกว่าเป้าและเกินเป้า 2,000 kcal ให้กราฟสถิติดูมีชีวิต
/// วันนี้มีแค่มื้อเช้า + กลางวัน เพื่อเหลือมื้อเย็นไว้สาธิตการเพิ่มอาหาร
const List<List<(MealType, Dish)>> plan = [
  [(MealType.breakfast, toast), (MealType.lunch, kaprao)], // 900
  [
    (MealType.breakfast, jok),
    (MealType.lunch, khaoPad),
    (MealType.snack, thaiTea),
    (MealType.dinner, greenCurry),
    (MealType.snack, bubbleTea),
  ], // 2,030 เกินเป้า
  [
    (MealType.breakfast, eggs),
    (MealType.lunch, padThai),
    (MealType.snack, yogurt),
    (MealType.dinner, suki),
  ], // 1,235
  [
    (MealType.breakfast, khaoTom),
    (MealType.lunch, somtam),
    (MealType.snack, banana),
    (MealType.dinner, tomYum),
  ], // 1,315
  [
    (MealType.breakfast, patongko),
    (MealType.lunch, kaprao),
    (MealType.snack, bubbleTea),
    (MealType.dinner, mookata),
  ], // 2,260 เกินเป้า
  [
    (MealType.breakfast, toast),
    (MealType.lunch, noodle),
    (MealType.snack, thaiTea),
    (MealType.dinner, garlicPork),
  ], // 1,500
  [
    (MealType.breakfast, jok),
    (MealType.lunch, khaoManGai),
    (MealType.snack, thaiTea),
    (MealType.dinner, greenCurry),
  ], // 1,720
  [
    (MealType.breakfast, khaoTom),
    (MealType.lunch, noodle),
    (MealType.dinner, yumWoonsen),
  ], // 930
  [
    (MealType.breakfast, eggs),
    (MealType.lunch, khaoManGai),
    (MealType.snack, banana),
    (MealType.dinner, tomYum),
  ], // 1,340
  [
    (MealType.breakfast, jok),
    (MealType.lunch, padThai),
    (MealType.snack, bubbleTea),
    (MealType.dinner, mookata),
  ], // 2,100 เกินเป้า
  [
    (MealType.breakfast, toast),
    (MealType.lunch, somtam),
    (MealType.dinner, suki),
  ], // 1,150
  [
    (MealType.breakfast, patongko),
    (MealType.lunch, khaoPad),
    (MealType.snack, yogurt),
    (MealType.dinner, garlicPork),
  ], // 1,670
  [
    (MealType.breakfast, khaoTom),
    (MealType.lunch, kaprao),
    (MealType.dinner, greenCurry),
  ], // 1,480
  [
    (MealType.breakfast, eggs),
    (MealType.lunch, noodle),
    (MealType.snack, thaiTea),
    (MealType.dinner, yumWoonsen),
  ], // 1,055
];

int hourFor(MealType meal, int nth) => switch (meal) {
  MealType.breakfast => 8,
  MealType.lunch => 12,
  MealType.dinner => 19,
  MealType.snack => nth == 0 ? 15 : 21, // ของว่างตัวที่ 2 ของวัน = มื้อดึก
};

Future<User> signInOrCreate() async {
  final auth = FirebaseAuth.instance;
  try {
    final cred = await auth.signInWithEmailAndPassword(
      email: demoEmail,
      password: demoPassword,
    );
    return cred.user!;
  } on FirebaseAuthException {
    // ยังไม่มีบัญชี → สร้างใหม่ (ถ้ามีแล้วแต่รหัสผิด จะ error email-already-in-use)
    final cred = await auth.createUserWithEmailAndPassword(
      email: demoEmail,
      password: demoPassword,
    );
    return cred.user!;
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'เติมข้อมูลเดโม 14 วัน',
    (tester) async {
      // กันเผลอลบข้อมูลบัญชีจริง: ใช้ได้เฉพาะบัญชีที่ขึ้นต้นด้วย demo
      expect(demoEmail.startsWith('demo'), isTrue, reason: 'ใช้กับบัญชีเดโมเท่านั้น');

      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      await activateAppCheck();
      final user = await signInOrCreate();
      final uid = user.uid;

      final repo = FoodRepository(
        local: await LocalDatabase.open(),
        cloud: FirestoreSyncService(),
      );

      // 1) ดึงข้อมูลจาก cloud มาก่อน แล้วลบข้อมูลเดโมเดิม (ย้อนหลัง 60 วัน) ให้รันซ้ำได้
      await repo.sync(uid);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final old = await repo.entriesForRange(
        uid,
        today.subtract(const Duration(days: 60)),
        today.add(const Duration(days: 1)),
      );
      for (final e in old) {
        await repo.delete(uid, e.id);
      }

      // 2) ตั้งเป้า 2,000 kcal แล้วเติมอาหารตามแผน
      await repo.setDailyGoal(uid, 2000);
      var count = 0;
      for (var daysAgo = 0; daysAgo < plan.length; daysAgo++) {
        final day = DateTime(today.year, today.month, today.day - daysAgo);
        var snacks = 0;
        for (final (meal, dish) in plan[daysAgo]) {
          final (name, kcal, protein, carbs, fat) = dish;
          final hour = hourFor(meal, meal == MealType.snack ? snacks++ : 0);
          final ok = await repo.save(
            uid,
            FoodEntry(
              id: FoodEntry.newId(),
              userId: uid,
              name: name,
              calories: kcal,
              protein: protein,
              carbs: carbs,
              fat: fat,
              mealType: meal,
              eatenAt: DateTime(day.year, day.month, day.day, hour),
            ),
          );
          expect(ok, isTrue, reason: 'ส่งขึ้น Firestore ไม่สำเร็จ: $name');
          count++;
        }
      }

      tester.printToConsole('เติมข้อมูล $count รายการ ให้ $demoEmail ($uid) แล้ว');
      await FirebaseAuth.instance.signOut();
    },
    skip: demoPassword.isEmpty,
    timeout: const Timeout(Duration(minutes: 5)),
  );
}
