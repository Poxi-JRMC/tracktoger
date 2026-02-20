import 'package:flutter/material.dart';
import '../../../models/alquiler.dart';

class EditarAlquilerScreen extends StatelessWidget {
  final Alquiler alquiler;

  const EditarAlquilerScreen({super.key, required this.alquiler});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Alquiler'),
        backgroundColor: const Color(0xFF1B1B1B),
      ),
      body: const Center(
        child: Text('Pantalla de edición - En desarrollo'),
      ),
    );
  }
}

