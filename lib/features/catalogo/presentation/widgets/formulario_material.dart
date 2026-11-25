import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/cf_components.dart';
import '../../../../core/network/red.dart';
import '../../domain/entidades_catalogo.dart';
import '../../domain/precio.dart';
import '../../domain/validaciones_catalogo.dart';
import '../catalogo_providers.dart';
import 'comunes_catalogo.dart';

/// Formulario de un material en un diálogo [RF-22][RF-08]. El precio se
/// valida con la misma expresión regular que el servidor y viaja como
/// texto (nunca como `double`).
class FormularioMaterial extends ConsumerStatefulWidget {
  const FormularioMaterial({this.material, super.key});

  final MaterialCatalogo? material;

  static const claveNombre = ValueKey('material-nombre');
  static const claveUnidad = ValueKey('material-unidad');
  static const clavePrecio = ValueKey('material-precio');
  static const claveDescripcion = ValueKey('material-descripcion');
  static const claveGuardar = ValueKey('material-guardar');
  static const claveAviso = ValueKey('material-aviso');
  static const claveNotaPrecio = ValueKey('material-nota-precio');

  /// Nota de RN-02 al editar el precio.
  static const notaPrecio =
      'Cambiar el precio no modifica las cotizaciones ya guardadas: '
      'conservan el precio con el que se calcularon (RN-02).';

  static Future<MaterialCatalogo?> abrir(
    BuildContext context, {
    MaterialCatalogo? material,
  }) => CfDialog.mostrar<MaterialCatalogo>(
    context,
    builder: (_) => FormularioMaterial(material: material),
  );

  @override
  ConsumerState<FormularioMaterial> createState() => _FormularioMaterialState();
}

class _FormularioMaterialState extends ConsumerState<FormularioMaterial> {
  static const _campos = {'nombre', 'unidad', 'precioUnitario', 'descripcion'};

  final _formulario = GlobalKey<FormState>();
  late final _nombre = TextEditingController(text: widget.material?.nombre);
  late final _unidad = TextEditingController(text: widget.material?.unidad);
  late final _precio = TextEditingController(
    text: widget.material?.precioUnitario.textoApi,
  );
  late final _descripcion = TextEditingController(
    text: widget.material?.descripcion,
  );

  bool _guardando = false;
  Map<String, String> _errores = const {};
  AvisoCatalogo? _aviso;

  bool get _edicion => widget.material != null;

  @override
  void dispose() {
    _nombre.dispose();
    _unidad.dispose();
    _precio.dispose();
    _descripcion.dispose();
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
    final datos = DatosMaterial(
      nombre: ValidacionesCatalogo.normalizar(_nombre.text),
      unidad: ValidacionesCatalogo.normalizar(_unidad.text),
      precioUnitario: Precio.intentar(_precio.text)!,
      descripcion: ValidacionesCatalogo.opcional(_descripcion.text),
    );
    final controlador = ref.read(materialesControllerProvider.notifier);
    final actual = widget.material;
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

  @override
  Widget build(BuildContext context) {
    final tokens = CfTokens.of(context);
    final separacion = SizedBox(height: tokens.espacioLg);
    return CfDialog(
      titulo: _edicion ? 'Editar material' : 'Nuevo material',
      cerrable: !_guardando,
      acciones: [
        CfButton(
          label: 'Cancelar',
          variant: CfButtonVariant.text,
          onPressed: _guardando ? null : () => Navigator.of(context).pop(),
        ),
        CfButton(
          key: FormularioMaterial.claveGuardar,
          label: _edicion ? 'Guardar cambios' : 'Crear material',
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
              _aviso!.mostrar(key: FormularioMaterial.claveAviso),
              separacion,
            ],
            CfInputText(
              key: FormularioMaterial.claveNombre,
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
            CfInputText(
              key: FormularioMaterial.claveUnidad,
              label: 'Unidad',
              hint: 'metro, litro, unidad…',
              controller: _unidad,
              enabled: !_guardando,
              maxLength: ValidacionesCatalogo.unidadMax,
              validator: ValidacionesCatalogo.unidad,
              errorText: _errores['unidad'],
              onChanged: (_) => _limpiarError('unidad'),
            ),
            separacion,
            CfInputText(
              key: FormularioMaterial.clavePrecio,
              label: 'Precio unitario (\$)',
              helper:
                  'Mayor que 0, con punto decimal y como máximo 2 '
                  'decimales (por ejemplo, 4.50).',
              controller: _precio,
              enabled: !_guardando,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              maxLength: 12,
              prefixIcon: Icons.attach_money_rounded,
              validator: Precio.validar,
              errorText: _errores['precioUnitario'],
              onChanged: (_) => _limpiarError('precioUnitario'),
            ),
            if (_edicion) ...[
              SizedBox(height: tokens.espacioMd),
              const CfMessage(
                key: FormularioMaterial.claveNotaPrecio,
                text: FormularioMaterial.notaPrecio,
              ),
            ],
            separacion,
            CfTextarea(
              key: FormularioMaterial.claveDescripcion,
              label: 'Descripción (opcional)',
              controller: _descripcion,
              enabled: !_guardando,
              maxLength: ValidacionesCatalogo.descripcionMax,
              validator: ValidacionesCatalogo.descripcion,
              errorText: _errores['descripcion'],
              onChanged: (_) => _limpiarError('descripcion'),
            ),
          ],
        ),
      ),
    );
  }
}
