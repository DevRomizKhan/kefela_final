class BengaliUtils {
  static int parseBengaliNumber(String bengaliNum) {
    const bengaliDigits = {
      '০': '0', '১': '1', '২': '2', '৩': '3', '৪': '4',
      '৫': '5', '৬': '6', '৭': '7', '৮': '8', '৯': '9'
    };
    String englishNum = bengaliNum.trim();
    bengaliDigits.forEach((bengali, english) {
      englishNum = englishNum.replaceAll(bengali, english);
    });
    return int.tryParse(englishNum) ?? 0;
  }

  static String toBengaliNumber(int number) {
    const englishDigits = {
      '0': '০', '1': '১', '2': '২', '3': '৩', '4': '৪',
      '5': '৫', '6': '৬', '7': '৭', '8': '৮', '9': '৯'
    };
    String bengaliNum = number.toString();
    englishDigits.forEach((english, bengali) {
      bengaliNum = bengaliNum.replaceAll(english, bengali);
    });
    return bengaliNum;
  }

  static String getBengaliMonth(int month) {
    const months = [
      'জানুয়ারী', 'ফেব্রুয়ারী', 'মার্চ', 'এপ্রিল', 'মে', 'জুন',
      'জুলাই', 'আগস্ট', 'সেপ্টেম্বর', 'অক্টোবর', 'নভেম্বর', 'ডিসেম্বর'
    ];
    return months[month - 1];
  }

  static String getBengaliDay(int day) {
    const days = [
      'সোমবার', 'মঙ্গলবার', 'বুধবার', 'বৃহস্পতিবার',
      'শুক্রবার', 'শনিবার', 'রবিবার'
    ];
    return days[day - 1];
  }
}
