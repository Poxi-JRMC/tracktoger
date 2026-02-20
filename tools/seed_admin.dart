// ===========================================
// Script de inicialización (seed) para Tracktoger
// Crea los permisos base, el rol de administrador
// y un usuario admin con email y contraseña por defecto.
// ===========================================

import 'package:mongo_dart/mongo_dart.dart';
import 'package:bcrypt/bcrypt.dart';

Future<void> main() async {
  // ✅ Tu conexión real a MongoDB Atlas (sin el +srv)
  final mongoUrl =
      r"mongodb://johanutb_db_user:KxHPmhF8PZwY3gUD@cluster0.xl6k3iu.mongodb.net:27017/tracktoger";

  print('Conectando a la base de datos...');
  final db = Db(mongoUrl);
  await db.open();
  print('✅ Conexión establecida con éxito.');

  final permisosColl = db.collection('permisos');
  final rolesColl = db.collection('roles');
  final usuariosColl = db.collection('usuarios');

  // =====================================
  // 1️⃣ Inserta los permisos base del rol admin
  // =====================================
  final permisos = [
    {
      'id': 'perm_admin_create',
      'nombre': 'Crear (admin)',
      'descripcion': 'Permite crear recursos administrativos',
      'modulo': 'admin',
      'accion': 'crear',
      'activo': true,
    },
    {
      'id': 'perm_admin_read',
      'nombre': 'Leer (admin)',
      'descripcion': 'Permite leer recursos administrativos',
      'modulo': 'admin',
      'accion': 'leer',
      'activo': true,
    },
    {
      'id': 'perm_admin_update',
      'nombre': 'Actualizar (admin)',
      'descripcion': 'Permite actualizar recursos administrativos',
      'modulo': 'admin',
      'accion': 'actualizar',
      'activo': true,
    },
    {
      'id': 'perm_admin_delete',
      'nombre': 'Eliminar (admin)',
      'descripcion': 'Permite eliminar recursos administrativos',
      'modulo': 'admin',
      'accion': 'eliminar',
      'activo': true,
    },
  ];

  for (var p in permisos) {
    final exists = await permisosColl.findOne(where.eq('id', p['id']));
    if (exists == null) {
      await permisosColl.insert(p);
      print('🟢 Permiso insertado: ${p['id']}');
    } else {
      print('ℹ️ Permiso ya existía: ${p['id']}');
    }
  }

  // =====================================
  // 2️⃣ Crea el rol ADMIN
  // =====================================
  final adminRoleId = ObjectId().toHexString();
  final adminRole = {
    '_id': ObjectId.parse(adminRoleId), // Usar ObjectId como _id
    'id': adminRoleId, // También guardar como campo id para facilidad
    'nombre': 'Administrador',
    'descripcion': 'Rol con permisos totales de administración',
    'permisos': permisos.map((p) => p['id']).toList(),
    'activo': true,
    'fechaCreacion': DateTime.now().toIso8601String(),
  };

  final roleExists = await rolesColl.findOne(where.eq('id', adminRole['id']));
  if (roleExists == null) {
    await rolesColl.insert(adminRole);
    print('🟢 Rol admin insertado. (ID: $adminRoleId)');
  } else {
    print('ℹ️ El rol admin ya existía.');
  }

  // =====================================
  // 2.5️⃣ Crea el rol OPERADOR
  // =====================================
  final operadorRoleId = ObjectId().toHexString();
  final operadorRole = {
    '_id': ObjectId.parse(operadorRoleId),
    'id': operadorRoleId,
    'nombre': 'Operador',
    'descripcion': 'Rol para operarios del sistema',
    'permisos': [
      'perm_operador_read', // Permiso de lectura
      'perm_operador_create', // Permiso de crear
    ],
    'activo': true,
    'fechaCreacion': DateTime.now().toIso8601String(),
  };

  final operadorExists = await rolesColl.findOne(
    where.eq('id', operadorRole['id']),
  );
  if (operadorExists == null) {
    await rolesColl.insert(operadorRole);
    print('🟢 Rol operador insertado. (ID: $operadorRoleId)');
  } else {
    print('ℹ️ El rol operador ya existía.');
  }

  // =====================================
  // 3️⃣ Crea el usuario ADMIN principal
  // =====================================
  final adminEmail = 'admin@tracktoger.local';
  final plainPassword = 'Admin123!'; // ⚠️ Cámbiala en producción

  final userExists = await usuariosColl.findOne(where.eq('email', adminEmail));
  if (userExists != null) {
    print('ℹ️ Ya existe un usuario admin con el email $adminEmail');
  } else {
    final hashed = BCrypt.hashpw(plainPassword, BCrypt.gensalt());
    final adminUserId = ObjectId().toHexString();
    final adminUser = {
      '_id': ObjectId.parse(adminUserId),
      'id': adminUserId,
      'nombre': 'Administrador',
      'apellido': 'Principal',
      'email': adminEmail,
      'telefono': '',
      'avatar': null,
      'fechaRegistro': DateTime.now().toIso8601String(),
      'activo': true,
      'roles': [adminRoleId], // Usar el ID del rol admin creado
      'password': hashed,
      'codigoVerificacion': null,
    };
    await usuariosColl.insert(adminUser);
    print(
      '🟢 Usuario admin creado: $adminEmail / Contraseña: $plainPassword (ID: $adminUserId)',
    );
  }

  await db.close();
  print('✅ Seed completado exitosamente.');
}
