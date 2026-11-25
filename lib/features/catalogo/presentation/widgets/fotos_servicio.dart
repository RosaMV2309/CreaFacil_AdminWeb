import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/archivos/selector_archivos.dart';
import '../../../../core/design_system/cf_components.dart';
import '../../../../core/network/red.dart';
import '../../domain/servicios.dart';
import '../servicios_providers.dart';
import 'comunes_catalogo.dart';

/// Gestión de las fotos de un servicio en un diálogo [RF-04][RF-22].
///
/// - Subir: se comprueban la extensión y el tamaño antes de enviar; el
///   servidor valida el contenido real (400), el tamaño (413) y el máximo
///   de 8 fotos (409).
/// - Ordenar con botones «Mover a la izquierda/derecha» y «Usar como
///   portada»: funcionan con teclado y lector de pantalla, a diferencia del
///   arrastre.
/// - Borrar con confirmación.
class FotosServicio extends ConsumerStatefulWidget {
  const FotosServicio({required this.servicio, super.key});

  final ServicioResumen servicio;

  static const claveAviso = ValueKey('fotos-aviso');
  static const claveCerrar = ValueKey('fotos-cerrar');

  static ValueKey<String> claveFoto(String id) => ValueKey('foto-$id');
  static ValueKey<String> claveIzquierda(String id) =>
      ValueKey('foto-izquierda-$id');
  static ValueKey<String> claveDerecha(String id) =>
      ValueKey('foto-derecha-$id');
  static ValueKey<String> clavePortada(String id) =>
      ValueKey('foto-portada-$id');
  static ValueKey<String> claveBorrar(String id) => ValueKey('foto-borrar-$id');

  static const motivoLimite =
      'Este servicio ya tiene ${ValidacionesServicio.maxFotos} fotos, el '
      'máximo. Borra una para subir otra.';

  static Future<void> abrir(
    BuildContext context, {
    required ServicioResumen servicio,
  }) => CfDialog.mostrar<void>(
    context,
    builder: (_) => FotosServicio(servicio: servicio),
  );

  @override
  ConsumerState<FotosServicio> createState() => _FotosServicioState();
}

class _FotosServicioState extends ConsumerState<FotosServicio> {
  double? _progreso;
  bool _ocupado = false;
  AvisoCatalogo? _aviso;

  FotosServicioController get _controlador =>
      ref.read(fotosServicioProvider(widget.servicio.id).notifier);

  Future<void> _ejecutar(
    Future<void> Function() accion, {
    required String exito,
    String tituloError = 'No se pudo completar la acción',
  }) async {
    if (_ocupado) {
      return;
    }
    setState(() {
      _ocupado = true;
      _aviso = null;
    });
    AvisoCatalogo aviso;
    try {
      await accion();
      aviso = AvisoCatalogo(exito);
    } on ApiException catch (error) {
      aviso = _avisoDeError(error, tituloError);
    }
    if (mounted) {
      setState(() {
        _ocupado = false;
        _progreso = null;
        _aviso = aviso;
      });
    }
  }

  /// 400 con detalles (archivo que no es imagen), 413 (más de 5 MB), 409
  /// (máximo de fotos) y el resto: siempre con el mensaje del servidor.
  AvisoCatalogo _avisoDeError(ApiException error, String titulo) {
    final detalles = [for (final d in error.detalles) d.mensaje];
    return AvisoCatalogo(
      error.estadoHttp == 400 && detalles.isNotEmpty
          ? detalles.join('\n')
          : error.mensaje,
      titulo: switch (error.estadoHttp) {
        413 => 'Archivo demasiado grande',
        409 => 'Límite de fotos',
        404 => 'No encontrado',
        _ => titulo,
      },
      severidad: CfMessageSeverity.error,
    );
  }

  Future<void> _subir() async {
    if (_ocupado) {
      return;
    }
    final elegido = await ref
        .read(selectorArchivosProvider)
        .elegirImagen(extensiones: ValidacionesServicio.extensiones);
    if (elegido == null || !mounted) {
      return;
    }
    // Primero la extensión (sin leer el archivo), luego el tamaño.
    var error = ValidacionesServicio.archivo(elegido.nombre, 1);
    final bytes =
        error == null &&
            (elegido.tamano ?? 0) <= ValidacionesServicio.maxBytesFoto
        ? await elegido.leer()
        : null;
    error ??= ValidacionesServicio.archivo(
      elegido.nombre,
      bytes?.length ?? elegido.tamano ?? 0,
    );
    if (!mounted) {
      return;
    }
    if (error != null || bytes == null) {
      setState(
        () => _aviso = AvisoCatalogo(
          error ?? 'No se pudo leer el archivo.',
          titulo: 'Archivo no válido',
          severidad: CfMessageSeverity.error,
        ),
      );
      return;
    }
    setState(() => _progreso = 0);
    await _ejecutar(
      () => _controlador.subir(
        ArchivoFoto(nombre: elegido.nombre, bytes: bytes),
        progreso: (p) {
          if (mounted) {
            setState(() => _progreso = p);
          }
        },
      ),
      exito: 'Se subió la foto «${elegido.nombre}».',
      tituloError: 'No se pudo subir la foto',
    );
  }

  Future<void> _mover(FotoServicio foto, int destino) => _ejecutar(
    () => _controlador.mover(foto, destino),
    exito: destino == 0
        ? 'La foto es ahora la portada.'
        : 'Se guardó el nuevo orden.',
    tituloError: 'No se pudo cambiar el orden',
  );

  Future<void> _borrar(FotoServicio foto, int posicion) async {
    if (_ocupado) {
      return;
    }
    final confirmar = await CfConfirmDialog.mostrar(
      context,
      titulo: 'Borrar la foto $posicion',
      mensaje: foto.esPortada
          ? 'Es la portada: la siguiente foto pasará a ser la portada. Esta '
                'acción no se puede deshacer.'
          : 'La foto se borrará del servicio. Esta acción no se puede '
                'deshacer.',
      textoConfirmar: 'Borrar',
      peligro: true,
      icono: Icons.delete_outline_rounded,
    );
    if (!confirmar || !mounted) {
      return;
    }
    await _ejecutar(
      () => _controlador.borrar(foto),
      exito: 'Se borró la foto.',
      tituloError: 'No se pudo borrar la foto',
    );
  }

  List<CfGaleriaItem> _items(List<FotoServicio> fotos) => [
    for (var i = 0; i < fotos.length; i++)
      CfGaleriaItem(
        clave: FotosServicio.claveFoto(fotos[i].id),
        url: fotos[i].url,
        descripcion: i == 0
            ? 'Foto ${i + 1}, portada de ${widget.servicio.nombre}'
            : 'Foto ${i + 1} de ${widget.servicio.nombre}',
        insignia: i == 0 ? 'Portada' : null,
        acciones: [
          CfAccionFila(
            clave: FotosServicio.claveIzquierda(fotos[i].id),
            etiqueta: 'Mover a la izquierda',
            icono: Icons.arrow_back_rounded,
            onPressed: i == 0 || _ocupado
                ? null
                : () => _mover(fotos[i], i - 1),
          ),
          if (i > 0)
            CfAccionFila(
              clave: FotosServicio.clavePortada(fotos[i].id),
              etiqueta: 'Usar como portada',
              icono: Icons.star_outline_rounded,
              onPressed: _ocupado ? null : () => _mover(fotos[i], 0),
            ),
          CfAccionFila(
            clave: FotosServicio.claveDerecha(fotos[i].id),
            etiqueta: 'Mover a la derecha',
            icono: Icons.arrow_forward_rounded,
            onPressed: i == fotos.length - 1 || _ocupado
                ? null
                : () => _mover(fotos[i], i + 1),
          ),
          CfAccionFila(
            clave: FotosServicio.claveBorrar(fotos[i].id),
            etiqueta: 'Borrar',
            icono: Icons.delete_outline_rounded,
            peligro: true,
            onPressed: _ocupado ? null : () => _borrar(fotos[i], i + 1),
          ),
        ],
      ),
  ];

  @override
  Widget build(BuildContext context) {
    final tokens = CfTokens.of(context);
    final estado = ref.watch(fotosServicioProvider(widget.servicio.id));
    final fotos = estado.value;
    final error = estado.error;

    final Widget cuerpo;
    if (error != null) {
      cuerpo = CfErrorState(
        title: 'No se pudieron cargar las fotos',
        message: error is ApiException ? error.mensaje : null,
        onRetry: _controlador.recargar,
      );
    } else if (fotos == null) {
      cuerpo = const Center(child: CfSpinner(label: 'Cargando fotos…'));
    } else {
      final lleno = fotos.length >= ValidacionesServicio.maxFotos;
      cuerpo = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const CfMessage(
            text:
                'La primera foto es la portada que se ve en el catálogo. '
                'Usa las flechas o «Usar como portada» para cambiar el orden.',
          ),
          if (_aviso != null) ...[
            SizedBox(height: tokens.espacioLg),
            _aviso!.mostrar(
              key: FotosServicio.claveAviso,
              onClose: () => setState(() => _aviso = null),
            ),
          ],
          SizedBox(height: tokens.espacioLg),
          CfFileUpload(
            titulo: 'Subir una foto',
            textoBoton: 'Subir foto',
            ayuda:
                'JPG, PNG o WebP · máximo 5 MB · ${fotos.length} de '
                '${ValidacionesServicio.maxFotos} fotos',
            motivoDeshabilitado: lleno ? FotosServicio.motivoLimite : null,
            progreso: _progreso,
            onElegir: _ocupado ? null : _subir,
          ),
          SizedBox(height: tokens.espacioXl),
          CfGalleria(
            items: _items(fotos),
            textoVacio: 'Este servicio aún no tiene fotos',
            mensajeVacio: 'La primera que subas será la portada.',
          ),
        ],
      );
    }

    return CfDialog(
      titulo: 'Fotos del servicio',
      subtitulo: widget.servicio.nombre,
      anchoMaximo: 800,
      cerrable: !_ocupado,
      acciones: [
        CfButton(
          key: FotosServicio.claveCerrar,
          label: 'Cerrar',
          variant: CfButtonVariant.secondary,
          onPressed: _ocupado ? null : () => Navigator.of(context).pop(),
        ),
      ],
      child: cuerpo,
    );
  }
}
