import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/cf_components.dart';
import '../../../../core/network/red.dart';
import '../../domain/entidades_catalogo.dart';
import '../../domain/precio.dart';
import '../../domain/servicios.dart';
import '../../domain/validaciones_catalogo.dart';
import '../servicios_providers.dart';
import 'comunes_catalogo.dart';

/// Formulario de un servicio en un diálogo [RF-22][RF-05][RF-04].
///
/// Se usa un `CfDialog` (como en categorías y materiales) para no perder la
/// tabla de vista. Al editar solo se envía lo que cambió; el precio
/// referencial es opcional y viaja como texto.
class FormularioServicio extends ConsumerStatefulWidget {
  const FormularioServicio({this.servicio, super.key});

  /// Ficha completa del servicio que se edita; `null` para crear.
  final ServicioDetalle? servicio;

  static const claveCategoria = ValueKey('servicio-categoria');
  static const claveNombre = ValueKey('servicio-nombre');
  static const claveDescripcion = ValueKey('servicio-descripcion');
  static const claveDimensiones = ValueKey('servicio-dimensiones');
  static const claveObservaciones = ValueKey('servicio-observaciones');
  static const clavePrecio = ValueKey('servicio-precio');
  static const claveMateriales = ValueKey('servicio-materiales');
  static const claveGuardar = ValueKey('servicio-guardar');
  static const claveAviso = ValueKey('servicio-aviso');
  static const claveAvisoCategoria = ValueKey('servicio-aviso-categoria');

  static const avisoCategoriaInactiva =
      'Esta categoría está inactiva: el servicio no se verá en el catálogo '
      'hasta que la actives.';

  static Future<ServicioDetalle?> abrir(
    BuildContext context, {
    ServicioDetalle? servicio,
  }) => CfDialog.mostrar<ServicioDetalle>(
    context,
    builder: (_) => FormularioServicio(servicio: servicio),
  );

  @override
  ConsumerState<FormularioServicio> createState() => _FormularioServicioState();
}

class _FormularioServicioState extends ConsumerState<FormularioServicio> {
  static const _campos = {
    'categoriaId',
    'nombre',
    'descripcion',
    'dimensionesOrientativas',
    'observaciones',
    'precioBaseReferencial',
    'materialIds',
  };

  final _formulario = GlobalKey<FormState>();
  late final _nombre = TextEditingController(text: widget.servicio?.nombre);
  late final _descripcion = TextEditingController(
    text: widget.servicio?.descripcion,
  );
  late final _dimensiones = TextEditingController(
    text: widget.servicio?.dimensionesOrientativas,
  );
  late final _observaciones = TextEditingController(
    text: widget.servicio?.observaciones,
  );
  late final _precio = TextEditingController(
    text: widget.servicio?.precioBaseReferencial?.textoApi,
  );
  late String? _categoriaId = widget.servicio?.categoria.id;
  late Set<String> _materiales = {
    for (final m in widget.servicio?.materiales ?? const <MaterialDeServicio>[])
      m.id,
  };

  bool _guardando = false;
  Map<String, String> _errores = const {};
  AvisoCatalogo? _aviso;

  bool get _edicion => widget.servicio != null;

  @override
  void dispose() {
    for (final c in [
      _nombre,
      _descripcion,
      _dimensiones,
      _observaciones,
      _precio,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _limpiarError(String campo) {
    if (_errores.containsKey(campo)) {
      setState(() => _errores = {..._errores}..remove(campo));
    }
  }

  Future<void> _guardar() async {
    if (_guardando) {
      return;
    }
    final habiaErrores = _errores.isNotEmpty;
    setState(() {
      _errores = const {};
      _aviso = null;
    });
    // Los errores del servidor se muestran con forceErrorText: hay que
    // esperar a que desaparezcan antes de validar, o validate() fallaría.
    if (habiaErrores) {
      await WidgetsBinding.instance.endOfFrame;
    }
    if (!mounted || !(_formulario.currentState?.validate() ?? false)) {
      return;
    }
    final datos = DatosServicio(
      categoriaId: _categoriaId!,
      nombre: ValidacionesCatalogo.normalizar(_nombre.text),
      descripcion: ValidacionesCatalogo.opcional(_descripcion.text),
      dimensionesOrientativas: ValidacionesCatalogo.opcional(_dimensiones.text),
      observaciones: ValidacionesCatalogo.opcional(_observaciones.text),
      precioBaseReferencial: _precio.text.trim().isEmpty
          ? null
          : Precio.intentar(_precio.text),
      materialIds: _materiales.toList()..sort(),
    );
    final controlador = ref.read(serviciosControllerProvider.notifier);
    final actual = widget.servicio;
    final cambios = actual == null ? null : datos.cambiosRespectoA(actual);
    if (cambios != null && cambios.isEmpty) {
      setState(
        () => _aviso = const AvisoCatalogo(
          'No hay cambios que guardar.',
          severidad: CfMessageSeverity.info,
        ),
      );
      return;
    }
    setState(() => _guardando = true);
    try {
      final guardado = actual == null
          ? await controlador.crear(datos)
          : await controlador.actualizar(actual.id, cambios!);
      if (mounted) {
        Navigator.of(context).pop(guardado);
      }
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      final errores = ErroresFormulario.desde(error, _campos);
      setState(() {
        _guardando = false;
        _errores = errores.porCampo;
        _aviso = errores.aviso;
      });
    }
  }

  List<CfOpcion<String?>> _opcionesCategoria(List<Categoria> categorias) {
    final actual = widget.servicio?.categoria;
    return [
      for (final c in categorias)
        CfOpcion(c.id, c.activa ? c.nombre : '${c.nombre} (inactiva)'),
      // Por si la categoría actual no llegó en la lista.
      if (actual != null && !categorias.any((c) => c.id == actual.id))
        CfOpcion(
          actual.id,
          actual.activa ? actual.nombre : '${actual.nombre} (inactiva)',
        ),
    ];
  }

  /// Materiales activos más los que el servicio ya tenía y ahora están
  /// desactivados (se conservan, marcados como «inactivo»).
  List<CfOpcionMultiple<String>> _opcionesMateriales(
    List<MaterialCatalogo> activos,
  ) {
    final idsActivos = {for (final m in activos) m.id};
    final opciones =
        [
          for (final m in activos)
            CfOpcionMultiple(m.id, '${m.nombre} (${m.unidad})'),
          for (final m
              in widget.servicio?.materiales ?? const <MaterialDeServicio>[])
            if (!idsActivos.contains(m.id))
              CfOpcionMultiple(
                m.id,
                '${m.nombre} (${m.unidad})',
                nota: 'inactivo',
              ),
        ]..sort(
          (a, b) =>
              a.etiqueta.toLowerCase().compareTo(b.etiqueta.toLowerCase()),
        );
    return opciones;
  }

  @override
  Widget build(BuildContext context) {
    final tokens = CfTokens.of(context);
    final separacion = SizedBox(height: tokens.espacioLg);
    final categorias = ref.watch(opcionesCategoriasProvider);
    final materiales = ref.watch(materialesActivosProvider);
    final errorCarga = categorias.error ?? materiales.error;

    final Widget cuerpo;
    if (errorCarga != null) {
      cuerpo = CfErrorState(
        title: 'No se pudieron cargar las categorías o los materiales',
        message: errorCarga is ApiException ? errorCarga.mensaje : null,
        onRetry: () {
          ref
            ..invalidate(opcionesCategoriasProvider)
            ..invalidate(materialesActivosProvider);
        },
      );
    } else if (!categorias.hasValue || !materiales.hasValue) {
      cuerpo = const Center(child: CfSpinner(label: 'Cargando opciones…'));
    } else {
      final listaCategorias = categorias.requireValue;
      final seleccionada = listaCategorias
          .where((c) => c.id == _categoriaId)
          .firstOrNull;
      cuerpo = Form(
        key: _formulario,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_aviso != null) ...[
              _aviso!.mostrar(key: FormularioServicio.claveAviso),
              separacion,
            ],
            CfSelect<String?>(
              key: FormularioServicio.claveCategoria,
              label: 'Categoría',
              hint: 'Elige una categoría',
              valor: _categoriaId,
              opciones: _opcionesCategoria(listaCategorias),
              validator: ValidacionesServicio.categoria,
              errorText: _errores['categoriaId'],
              onChanged: _guardando
                  ? null
                  : (id) {
                      setState(() => _categoriaId = id);
                      _limpiarError('categoriaId');
                    },
            ),
            if (seleccionada != null && !seleccionada.activa) ...[
              SizedBox(height: tokens.espacioMd),
              const CfMessage(
                key: FormularioServicio.claveAvisoCategoria,
                severity: CfMessageSeverity.warning,
                text: FormularioServicio.avisoCategoriaInactiva,
              ),
            ],
            separacion,
            CfInputText(
              key: FormularioServicio.claveNombre,
              label: 'Nombre',
              controller: _nombre,
              enabled: !_guardando,
              maxLength: ValidacionesServicio.nombreMax,
              textCapitalization: TextCapitalization.sentences,
              validator: ValidacionesServicio.nombre,
              errorText: _errores['nombre'],
              onChanged: (_) => _limpiarError('nombre'),
            ),
            separacion,
            CfTextarea(
              key: FormularioServicio.claveDescripcion,
              label: 'Descripción (opcional)',
              controller: _descripcion,
              enabled: !_guardando,
              maxLength: ValidacionesServicio.descripcionMax,
              validator: ValidacionesServicio.textoMaximo(
                'La descripción',
                ValidacionesServicio.descripcionMax,
              ),
              errorText: _errores['descripcion'],
              onChanged: (_) => _limpiarError('descripcion'),
            ),
            separacion,
            CfInputText(
              key: FormularioServicio.claveDimensiones,
              label: 'Dimensiones orientativas (opcional)',
              hint: 'Por ejemplo, 2 x 3 m',
              controller: _dimensiones,
              enabled: !_guardando,
              maxLength: ValidacionesServicio.dimensionesMax,
              validator: ValidacionesServicio.textoMaximo(
                'Las dimensiones',
                ValidacionesServicio.dimensionesMax,
              ),
              errorText: _errores['dimensionesOrientativas'],
              onChanged: (_) => _limpiarError('dimensionesOrientativas'),
            ),
            separacion,
            CfTextarea(
              key: FormularioServicio.claveObservaciones,
              label: 'Observaciones (opcional)',
              controller: _observaciones,
              enabled: !_guardando,
              minLines: 2,
              maxLength: ValidacionesServicio.observacionesMax,
              validator: ValidacionesServicio.textoMaximo(
                'Las observaciones',
                ValidacionesServicio.observacionesMax,
              ),
              errorText: _errores['observaciones'],
              onChanged: (_) => _limpiarError('observaciones'),
            ),
            separacion,
            CfInputText(
              key: FormularioServicio.clavePrecio,
              label: r'Precio referencial «desde» ($, opcional)',
              helper:
                  'Déjalo vacío si no quieres mostrar precio. Con punto '
                  'decimal y como máximo 2 decimales (por ejemplo, 120.50). '
                  'En el catálogo se muestra como referencial (RN-01).',
              controller: _precio,
              enabled: !_guardando,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              maxLength: 12,
              prefixIcon: Icons.attach_money_rounded,
              validator: ValidacionesServicio.precioOpcional,
              errorText: _errores['precioBaseReferencial'],
              onChanged: (_) => _limpiarError('precioBaseReferencial'),
            ),
            separacion,
            CfMultiSelect<String>(
              key: FormularioServicio.claveMateriales,
              label: 'Materiales habituales',
              ayuda:
                  'Solo se pueden añadir materiales activos. Los que ya '
                  'tenía y ahora están inactivos se conservan.',
              textoVacio: 'No hay materiales activos.',
              opciones: _opcionesMateriales(materiales.requireValue),
              seleccionados: _materiales,
              errorText: _errores['materialIds'],
              onChanged: _guardando
                  ? null
                  : (nuevos) {
                      setState(() => _materiales = nuevos);
                      _limpiarError('materialIds');
                    },
            ),
          ],
        ),
      );
    }

    return CfDialog(
      titulo: _edicion ? 'Editar servicio' : 'Nuevo servicio',
      cerrable: !_guardando,
      anchoMaximo: 640,
      acciones: [
        CfButton(
          label: 'Cancelar',
          variant: CfButtonVariant.text,
          onPressed: _guardando ? null : () => Navigator.of(context).pop(),
        ),
        CfButton(
          key: FormularioServicio.claveGuardar,
          label: _edicion ? 'Guardar cambios' : 'Crear servicio',
          icon: Icons.save_outlined,
          loading: _guardando,
          onPressed: categorias.hasValue && materiales.hasValue
              ? _guardar
              : null,
        ),
      ],
      child: cuerpo,
    );
  }
}
