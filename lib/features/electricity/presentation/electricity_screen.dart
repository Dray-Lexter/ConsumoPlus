import 'package:consumo_plus/app/routes/app_routes.dart';
import 'package:consumo_plus/app/theme/app_colors.dart';
import 'package:consumo_plus/app/theme/app_radii.dart';
import 'package:consumo_plus/app/theme/app_spacing.dart';
import 'package:consumo_plus/features/electricity/application/electricity_state.dart';
import 'package:consumo_plus/features/electricity/application/electricity_view_model.dart';
import 'package:consumo_plus/features/electricity/presentation/electricity_account_status_screen.dart';
import 'package:consumo_plus/features/electricity/presentation/electricity_consumption_screen.dart';
import 'package:consumo_plus/features/electricity/presentation/electricity_copy.dart';
import 'package:consumo_plus/features/electricity/presentation/electricity_payment_screen.dart';
import 'package:consumo_plus/features/electricity/presentation/electricity_supply_screen.dart';
import 'package:consumo_plus/features/electricity/presentation/widgets/electricity_login_form.dart';
import 'package:consumo_plus/features/electricity/presentation/widgets/electricity_summary.dart';
import 'package:flutter/material.dart';

typedef ElectricityViewModelFactory = Future<ElectricityViewModel> Function();

class ElectricityScreen extends StatefulWidget {
  const ElectricityScreen({required this.createViewModel, super.key});

  final ElectricityViewModelFactory createViewModel;

  @override
  State<ElectricityScreen> createState() => _ElectricityScreenState();
}

class _ElectricityScreenState extends State<ElectricityScreen> {
  final _contractController = TextEditingController();
  final _passwordController = TextEditingController();
  ElectricityViewModel? _viewModel;
  Object? _preparationError;
  var _authorized = false;
  var _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  Future<void> _prepare() async {
    try {
      final viewModel = await widget.createViewModel();
      if (!mounted) {
        viewModel.dispose();
        return;
      }
      _viewModel = viewModel;
      viewModel.addListener(_onChanged);
      await viewModel.initialize();
      if (!mounted) return;
      _contractController.text = viewModel.state.rememberedContract ?? '';
      setState(() {});
    } on Object catch (error) {
      if (mounted) setState(() => _preparationError = error);
    }
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  bool get _canSubmit {
    final busy = _viewModel?.state.status == ElectricityStatus.synchronizing;
    return !busy &&
        _authorized &&
        _contractController.text.trim().isNotEmpty &&
        _passwordController.text.isNotEmpty;
  }

  Future<void> _submit() async {
    final viewModel = _viewModel;
    if (viewModel == null || !_canSubmit) return;
    try {
      await viewModel.synchronize(
        contractNumber: _contractController.text.trim(),
        password: _passwordController.text,
      );
    } finally {
      _passwordController.clear();
      if (mounted) setState(() => _obscurePassword = true);
    }
  }

  Future<void> _requestUpdate() async {
    final viewModel = _viewModel;
    final account = viewModel?.state.snapshot?.account;
    if (viewModel == null || account == null) return;
    final request = await showDialog<_ElectricityCredentials>(
      context: context,
      builder: (_) =>
          _UpdateElectricityDialog(initialContract: account.contractNumber),
    );
    if (request == null || !mounted) return;
    await viewModel.synchronize(
      contractNumber: request.contractNumber,
      password: request.password,
    );
  }

  void _openStatus() {
    final status = _viewModel?.state.snapshot?.latestAccountStatus;
    if (status == null) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: AppRoutes.electricityStatus),
        builder: (_) => ElectricityAccountStatusScreen(status: status),
      ),
    );
  }

  void _openConsumptions() {
    final records = _viewModel?.state.snapshot?.consumptionRecords;
    if (records == null) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: AppRoutes.electricityConsumptions),
        builder: (_) => ElectricityConsumptionScreen(records: records),
      ),
    );
  }

  void _openPayments() {
    final records = _viewModel?.state.snapshot?.paymentRecords;
    if (records == null) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: AppRoutes.electricityPayments),
        builder: (_) => ElectricityPaymentScreen(records: records),
      ),
    );
  }

  void _openSupply() {
    final account = _viewModel?.state.snapshot?.account;
    if (account == null) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: AppRoutes.electricitySupply),
        builder: (_) => ElectricitySupplyScreen(account: account),
      ),
    );
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar datos de Electricidad'),
        content: const Text(
          'Se borrarán únicamente los datos cifrados de Electrosur y el número de contrato recordado. Tus datos de Agua permanecerán intactos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            key: const Key('confirmDeleteElectricityData'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) await _deleteAndRecreate();
  }

  Future<void> _deleteAndRecreate() async {
    final old = _viewModel;
    if (old == null) return;
    await old.deleteElectricityData();
    old.removeListener(_onChanged);
    old.dispose();
    _viewModel = null;
    _contractController.clear();
    _passwordController.clear();
    _authorized = false;
    if (mounted) {
      setState(() {});
      await _prepare();
    }
  }

  @override
  void dispose() {
    final viewModel = _viewModel;
    if (viewModel != null) {
      viewModel.removeListener(_onChanged);
      viewModel.dispose();
    }
    _passwordController.clear();
    _passwordController.dispose();
    _contractController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    key: const Key('electricityScreen'),
    appBar: AppBar(
      title: const Text(
        '${ElectricityCopy.title} · ${ElectricityCopy.provider}',
      ),
    ),
    body: SafeArea(child: _body()),
  );

  Widget _body() {
    if (_preparationError != null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Text(
            'No pudimos abrir el almacenamiento cifrado de Electricidad.',
          ),
        ),
      );
    }
    final viewModel = _viewModel;
    if (viewModel == null ||
        viewModel.state.status == ElectricityStatus.loadingLocal) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: AppSpacing.md),
            Text(ElectricityCopy.loadingLocal),
          ],
        ),
      );
    }
    final state = viewModel.state;
    if (state.snapshot != null) {
      return ListView(
        key: const Key('electricityDataList'),
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          if (state.errorMessage != null) ...[
            _Message(error: true, text: state.errorMessage!),
            const SizedBox(height: AppSpacing.md),
          ],
          if (state.syncSummary != null) ...[
            _Message(error: false, text: state.syncSummary!),
            const SizedBox(height: AppSpacing.md),
          ],
          ElectricitySummary(
            snapshot: state.snapshot!,
            busy:
                state.status == ElectricityStatus.synchronizing ||
                state.status == ElectricityStatus.deleting,
            shouldRecommendUpdate: state.shouldRecommendUpdate,
            onUpdate: _requestUpdate,
            onStatus: _openStatus,
            onConsumptions: _openConsumptions,
            onPayments: _openPayments,
            onSupply: _openSupply,
            onDelete: _confirmDelete,
          ),
        ],
      );
    }
    final busy = state.status == ElectricityStatus.synchronizing;
    return ListView(
      key: const Key('electricityEmptyList'),
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Text(
          ElectricityCopy.emptyTitle,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: AppSpacing.sm),
        const Text(ElectricityCopy.emptyBody),
        const SizedBox(height: AppSpacing.lg),
        if (state.errorMessage != null) ...[
          _Message(error: true, text: state.errorMessage!),
          const SizedBox(height: AppSpacing.md),
        ],
        ElectricityLoginForm(
          contractController: _contractController,
          passwordController: _passwordController,
          authorized: _authorized,
          obscurePassword: _obscurePassword,
          busy: busy,
          onAuthorizationChanged: (value) =>
              setState(() => _authorized = value ?? false),
          onTogglePassword: () =>
              setState(() => _obscurePassword = !_obscurePassword),
          onChanged: () => setState(() {}),
          onSubmit: _canSubmit ? _submit : null,
        ),
      ],
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.error, required this.text});
  final bool error;
  final String text;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Material(
      color: error ? AppColors.errorContainer : AppColors.electricityContainer,
      borderRadius: BorderRadius.circular(AppRadii.sm),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Text(text),
      ),
    ),
  );
}

class _ElectricityCredentials {
  const _ElectricityCredentials({
    required this.contractNumber,
    required this.password,
  });
  final String contractNumber;
  final String password;
}

class _UpdateElectricityDialog extends StatefulWidget {
  const _UpdateElectricityDialog({required this.initialContract});
  final String initialContract;

  @override
  State<_UpdateElectricityDialog> createState() =>
      _UpdateElectricityDialogState();
}

class _UpdateElectricityDialogState extends State<_UpdateElectricityDialog> {
  late final TextEditingController _contract;
  final _password = TextEditingController();
  var _authorized = false;
  var _obscure = true;

  bool get _canSubmit =>
      _authorized &&
      _contract.text.trim().isNotEmpty &&
      _password.text.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _contract = TextEditingController(text: widget.initialContract);
  }

  @override
  void dispose() {
    _password.clear();
    _password.dispose();
    _contract.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Actualizar Electricidad'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(ElectricityCopy.httpRiskTitle),
          const SizedBox(height: AppSpacing.md),
          TextField(
            key: const Key('updateElectricityContractField'),
            controller: _contract,
            autocorrect: false,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: ElectricityCopy.contractLabel,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            key: const Key('updateElectricityPasswordField'),
            controller: _password,
            obscureText: _obscure,
            enableSuggestions: false,
            autocorrect: false,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: ElectricityCopy.passwordLabel,
              suffixIcon: IconButton(
                tooltip: _obscure ? 'Mostrar clave' : 'Ocultar clave',
                onPressed: () => setState(() => _obscure = !_obscure),
                icon: Icon(
                  _obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            ),
          ),
          CheckboxListTile(
            key: const Key('updateElectricityHttpAuthorization'),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: _authorized,
            onChanged: (value) => setState(() => _authorized = value ?? false),
            title: const Text(ElectricityCopy.authorization),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Cancelar'),
      ),
      FilledButton(
        key: const Key('confirmElectricityUpdate'),
        onPressed: _canSubmit
            ? () {
                final result = _ElectricityCredentials(
                  contractNumber: _contract.text.trim(),
                  password: _password.text,
                );
                _password.clear();
                Navigator.of(context).pop(result);
              }
            : null,
        child: const Text('Actualizar'),
      ),
    ],
  );
}
