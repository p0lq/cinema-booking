final _emailRe = RegExp(r'^[\w.+-]+@[\w-]+(\.[\w-]+)*\.[a-zA-Z]{2,}$');
final _phoneCharsRe = RegExp(r'^\+?[\d\s()-]+$');
final _nameRe = RegExp(r"^[A-Za-zА-Яа-яЁёӘәҒғҚқҢңӨөҰұҮүҺһІі\s'-]+$");

String? validateFullName(String? v) {
  final value = v?.trim() ?? '';
  if (value.isEmpty) return 'Введите ФИО';
  if (!_nameRe.hasMatch(value)) return 'ФИО может содержать только буквы, пробел и дефис';
  if (value.split(RegExp(r'\s+')).length < 2) return 'Укажите минимум фамилию и имя';
  return null;
}

String? validatePhone(String? v) {
  final value = v?.trim() ?? '';
  if (value.isEmpty) return 'Введите номер телефона';
  if (!_phoneCharsRe.hasMatch(value)) return 'Номер может содержать только цифры, +, пробел, скобки и дефис';
  final digits = value.replaceAll(RegExp(r'\D'), '');
  if (digits.length < 10 || digits.length > 12) return 'Номер должен содержать 10–12 цифр';
  return null;
}

String? validateEmail(String? v) {
  final value = v?.trim() ?? '';
  if (value.isEmpty) return 'Введите Email';
  if (!_emailRe.hasMatch(value)) return 'Некорректный формат Email (пример: name@mail.kz)';
  return null;
}
