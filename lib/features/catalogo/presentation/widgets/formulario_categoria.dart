import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/cf_components.dart';
import '../../../../core/network/red.dart';
import '../../domain/entidades_catalogo.dart';
import '../../domain/validaciones_catalogo.dart';
import '../catalogo_providers.dart';
import 'comunes_catalogo.dart';

/// Formulario de una categoría en un diálogo [RF-22]. Si se indica
/// [categoria], edita; si no, crea. Devuelve la categoría guardada.
class FormularioCategoria extends ConsumerStatefulWidget {
  const FormularioCategoria({this.categoria, super.key});

  final Categoria? categoria;

  static const claveNombre = ValueKey('categoria-nombre');
  static const claveDescripcion = ValueKey('categoria-descripcion');
  static const claveOrden = ValueKey('categoria-orden');
  static const claveGuardar = ValueKey('categoria-guardar');
  static const claveAviso = ValueKey('categoria-aviso');

  static Future<Categoria?> abrir(
    BuildContext context, {
    Categoria? categoria,
  }) => CfDialog.mostrar<Categoria>(
    context,
    builder: (_) => FormularioCategoria(categoria: categoria),
  );

  @override
  ConsumerState<FormularioCategoria> createState() =>
      _FormularioCategoriaState();
}

class _FormularioCategoriaState extends ConsumerState<FormularioCategoria> {
  static const _campos = {'nombre', 'descripcion', 'orden'};

  final _formulario = GlobalKey<FormState>();
  late final _nombre = TextEditingController(text: widget.categoria?.nombre);
  late final _descripcion = TextEditingController(
    text: widget.categoria?.descripcion,
  );
  late final _orden = TextEditingController(
    text: '${widget.categoria?.orden ?? 0}',
  );

  bool _guardando = false;
  Map<String, String> _errores = const {};
  AvisoCatalogo? _aviso;

  bool get _edicion => widget.categoria != null;

  @override
  void dispose() {
    _nombre.dispose();
    _descripcion.dispose();
    _orden.dispose();
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
    final datos = DatosCategoria(
      nombre: ValidacionesCatalogo.normalizar(_nombre.text),
      descripcion: ValidacionesCatalogo.opcional(_descripcion.text),
      orden: ValidacionesCatalogo.ordenDe(_orden.text),
    );
    final controlador = ref.read(categoriasControllerProvider.notifier);
    final actual = widget.categoria;
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
      final guardada = actual == null
          ? await controlador.crear(datos)
          : await controlador.actualizar(actual.id, cambios!);
      if (mounted) {
        Navigator.of(context).pop(guardada);
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

  @override
  Widget build(BuildContext context) {
    final tokens = CfTokens.of(context);
    final separacion = SizedBox(height: tokens.espacioLg);
    return CfDialog(
      titulo: _edicion ? 'Editar categoría' : 'Nueva categoría',
      cerrable: !_guardando,
      acciones: [
        CfButton(
          label: 'Cancelar',
          variant: CfButtonVariant.text,
          onPressed: _guardando ? null : () => Navigator.of(context).pop(),
        ),
        CfButton(
          key: FormularioCategoria.claveGuardar,
          label: _edicion ? 'Guardar cambios' : 'Crear categoría',
          icon: Icons.save_outlined,
          loading: _guardando,
          onPressed: _guardar,
        ),
      ],
      child: Form(
        key: _formulario,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_aviso != null) ...[
              _aviso!.mostrar(key: FormularioCategoria.claveAviso),
              separacion,
            ],
            CfInputText(
              key: FormularioCategoria.claveNombre,
              label: 'Nombre',
              controller: _nombre,
              enabled: !_guardando,
              maxLength: ValidacionesCatalogo.nombreMax,
              textCapitalization: TextCapitalization.sentences,
              validator: ValidacionesCatalogo.nombre,
              errorText: _errores['nombre'],
              onChanged: (_) => _limpiarError('nombre'),
            ),
            separacion,
            CfTextarea(
              key: FormularioCategoria.claveDescripcion,
              label: 'Descripción (opcional)',
              controller: _descripcion,
              enabled: !_guardando,
              maxLength: ValidacionesCatalogo.descripcionMax,
              validator: ValidacionesCatalogo.descripcion,
              errorText: _errores['descripcion'],
              onChanged: (_) => _limpiarError('descripcion'),
            ),
            separacion,
            CfInputText(
              key: FormularioCategoria.claveOrden,
              label: 'Orden',
              helper:
                  'Posición en el catálogo (0 a 9999). Las de menor '
                  'número aparecen primero.',
              controller: _orden,
              enabled: !_guardando,
              keyboardType: TextInputType.number,
              maxLength: 4,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: ValidacionesCatalogo.orden,
              errorText: _errores['orden'],
              onChanged: (_) => _limpiarError('orden'),
              onSubmitted: (_) => _guardar(),
            ),
          ],
        ),
      ),
    );
  }
}
