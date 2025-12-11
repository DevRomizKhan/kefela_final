class Validators {
  static String? required(String? value, [String fieldName = 'ফিল্ড']) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName প্রয়োজন';
    }
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return 'ইমেইল প্রয়োজন';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'সঠিক ইমেইল দিন';
    }
    return null;
  }

  static String? number(String? value, {int? min, int? max}) {
    if (value == null || value.isEmpty) return 'সংখ্যা প্রয়োজন';
    final number = int.tryParse(value);
    if (number == null) return 'সঠিক সংখ্যা দিন';
    if (min != null && number < min) return 'সর্বনিম্ন $min হতে হবে';
    if (max != null && number > max) return 'সর্বোচ্চ $max হতে পারে';
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.isEmpty) {
      return 'ফোন নম্বর প্রয়োজন';
    }
    final phoneRegex = RegExp(r'^01[3-9]\d{8}$');
    if (!phoneRegex.hasMatch(value)) {
      return 'সঠিক বাংলাদেশী ফোন নম্বর দিন';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'পাসওয়ার্ড প্রয়োজন';
    }
    if (value.length < 6) {
      return 'পাসওয়ার্ড কমপক্ষে ৬ অক্ষরের হতে হবে';
    }
    return null;
  }

  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'পাসওয়ার্ড নিশ্চিত করুন';
    }
    if (value != password) {
      return 'পাসওয়ার্ড মিলছে না';
    }
    return null;
  }
}
