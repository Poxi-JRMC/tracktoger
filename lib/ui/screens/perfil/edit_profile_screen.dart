import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tracktoger/controllers/control_usuario.dart';
import 'package:tracktoger/core/auth_service.dart';
import 'package:tracktoger/models/usuario.dart';

class EditProfileScreen extends StatefulWidget {
  final Usuario usuario;

  const EditProfileScreen({Key? key, required this.usuario}) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController firstNameController;
  late TextEditingController lastNameController;
  late TextEditingController emailController;
  late TextEditingController phoneController;
  String? avatarPath;
  bool loading = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // Use explicit nombre / apellido fields if available
    final first = widget.usuario.nombre;
    final last = widget.usuario.apellido;

    firstNameController = TextEditingController(text: first);
    lastNameController = TextEditingController(text: last);
    emailController = TextEditingController(text: widget.usuario.email);
    phoneController = TextEditingController(text: widget.usuario.telefono);
    avatarPath = widget.usuario.avatar;
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 80,
      );
      if (image != null) {
        setState(() {
          avatarPath = image.path;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al seleccionar imagen: $e')),
      );
    }
  }

  Future<void> _save() async {
    setState(() => loading = true);
    try {
      final first = firstNameController.text.trim();
      final last = lastNameController.text.trim();
      // Build updated usuario - keep nombre and apellido separate
      final updated = widget.usuario.copyWith(
        nombre: first.isNotEmpty ? first : widget.usuario.nombre,
        apellido: last.isNotEmpty ? last : widget.usuario.apellido,
        email: emailController.text.trim(),
        telefono: phoneController.text.trim(),
        avatar: avatarPath,
      );

      // Persist via controller
      final saved = await ControlUsuario().actualizarUsuario(updated);

      // Update AuthService and return
      AuthService.actualizarUsuario(saved);

      Navigator.of(context).pop(saved);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al guardar: $e')));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar perfil'),
        backgroundColor: const Color(0xFF1B1B1B),
        actions: [
          TextButton(
            onPressed: loading ? null : _save,
            child: loading
                ? const CircularProgressIndicator()
                : const Text('Guardar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      backgroundColor: const Color(0xFF101010),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () async {
                // show options
                showModalBottomSheet(
                  context: context,
                  builder: (_) => SafeArea(
                    child: Wrap(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.photo_camera),
                          title: const Text('Tomar foto'),
                          onTap: () {
                            Navigator.of(context).pop();
                            _pickImage(ImageSource.camera);
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.photo_library),
                          title: const Text('Seleccionar de la galería'),
                          onTap: () {
                            Navigator.of(context).pop();
                            _pickImage(ImageSource.gallery);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey.shade700,
                backgroundImage: avatarPath != null
                    ? FileImage(File(avatarPath!))
                    : null,
                child: avatarPath == null
                    ? const Icon(Icons.person, size: 48, color: Colors.white)
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: firstNameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Nombre',
                labelStyle: TextStyle(color: Colors.white70),
                filled: true,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: lastNameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Apellido',
                labelStyle: TextStyle(color: Colors.white70),
                filled: true,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emailController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Correo',
                labelStyle: TextStyle(color: Colors.white70),
                filled: true,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Teléfono',
                labelStyle: TextStyle(color: Colors.white70),
                filled: true,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: loading ? null : _save,
              icon: const Icon(Icons.save),
              label: const Text('Guardar cambios'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFCD11),
                foregroundColor: Colors.black,
                minimumSize: const Size.fromHeight(50),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
