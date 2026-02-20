import 'package:bcrypt/bcrypt.dart';

void main() {
  const password = 'Admin123!'; // 🔒 Cambia si quieres otra contraseña
  final hash = BCrypt.hashpw(password, BCrypt.gensalt());
  print('🔑 Hash generado para "$password":\n$hash');
}
