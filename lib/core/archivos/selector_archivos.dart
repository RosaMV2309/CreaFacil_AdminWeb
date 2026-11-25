import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Archivo elegido por la usuaria. Los bytes se leen solo cuando hacen
/// falta (después de comprobar la extensión y el tamaño).
class ArchivoElegido {
  const ArchivoElegido({required this.nombre, required this.leer, this.tamano});

  final String nombre;

  /// Tamaño en bytes, si la plataforma lo conoce sin leer el archivo.
  final int? tamano;
  final Future<Uint8List> Function() leer;
}

/// Abre el selector de archivos del sistema (o del navegador).
abstract interface class SelectorArchivos {
  /// Devuelve `null` si la usuaria cancela.
  Future<ArchivoElegido?> elegirImagen({required List<String> extensiones});
}

/// Implementación con `file_picker` (funciona en la web y en Android).
class SelectorArchivosPlataforma implements SelectorArchivos {
  const SelectorArchivosPlataforma();

  @override
  Future<ArchivoElegido?> elegirImagen({
    required List<String> extensiones,
  }) async {
    final archivo = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: extensiones,
    );
    if (archivo == null) {
      return null;
    }
    return ArchivoElegido(
      nombre: archivo.name,
      tamano: archivo.lengthSync(),
      leer: archivo.readAsBytes,
    );
  }
}

/// Selector de archivos; en las pruebas se sustituye por uno simulado.
final selectorArchivosProvider = Provider<SelectorArchivos>(
  (ref) => const SelectorArchivosPlataforma(),
);
