import 'package:mongo_dart/mongo_dart.dart';
import '../models/cliente.dart';
import '../data/services/database_service.dart';

/// Controlador para la gestión de clientes
/// Maneja las operaciones CRUD de clientes usando MongoDB
class ControlCliente {
  final DatabaseService _dbService = DatabaseService();

  /// Registra un nuevo cliente
  Future<Cliente> registrarCliente(Cliente cliente) async {
    String clienteId = cliente.id;
    if (clienteId.isEmpty) {
      clienteId = ObjectId().toHexString();
    }

    // Validar que el email sea único
    final todos = await consultarTodosClientes();
    if (todos.any((c) => c.email == cliente.email && c.id != clienteId)) {
      throw Exception('Ya existe un cliente con ese email');
    }

    final clienteToInsert = cliente.copyWith(id: clienteId);
    await _dbService.insertarCliente(clienteToInsert.toMap());
    print('✅ Cliente registrado en MongoDB: ${clienteToInsert.nombreCompleto} (ID: $clienteId)');
    return clienteToInsert;
  }

  /// Actualiza un cliente existente
  Future<Cliente> actualizarCliente(Cliente cliente) async {
    final existente = await consultarCliente(cliente.id);
    if (existente == null) {
      throw Exception('Cliente no encontrado');
    }

    // Validar email único (excepto para el mismo cliente)
    final todos = await consultarTodosClientes();
    if (todos.any((c) => c.email == cliente.email && c.id != cliente.id)) {
      throw Exception('Ya existe otro cliente con ese email');
    }

    await _dbService.actualizarCliente(cliente.toMap());
    return cliente;
  }

  /// Obtiene un cliente por su ID
  Future<Cliente?> consultarCliente(String id) async {
    return await _dbService.consultarCliente(id);
  }

  /// Obtiene todos los clientes
  Future<List<Cliente>> consultarTodosClientes({bool soloActivos = true}) async {
    return await _dbService.consultarTodosClientes(soloActivos: soloActivos);
  }

  /// Elimina un cliente (desactiva)
  Future<bool> eliminarCliente(String id) async {
    return await _dbService.eliminarCliente(id);
  }

  /// Busca clientes por nombre o email
  Future<List<Cliente>> buscarClientes(String busqueda) async {
    final todos = await consultarTodosClientes();
    final busquedaLower = busqueda.toLowerCase();
    return todos.where((c) {
      return c.nombre.toLowerCase().contains(busquedaLower) ||
          c.apellido.toLowerCase().contains(busquedaLower) ||
          c.email.toLowerCase().contains(busquedaLower) ||
          (c.empresa?.toLowerCase().contains(busquedaLower) ?? false);
    }).toList();
  }
}

