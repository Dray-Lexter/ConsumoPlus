import 'package:consumo_plus/app/theme/app_colors.dart';
import 'package:consumo_plus/app/routes/app_routes.dart';
import 'package:consumo_plus/app/theme/app_spacing.dart';
import 'package:consumo_plus/app/theme/app_radii.dart';
import 'package:consumo_plus/features/water/application/water_state.dart';
import 'package:consumo_plus/features/water/application/water_view_model.dart';
import 'package:consumo_plus/features/water/application/password_request.dart';
import 'package:consumo_plus/features/water/presentation/water_copy.dart';
import 'package:consumo_plus/features/water/presentation/billing_history_screen.dart';
import 'package:consumo_plus/features/water/presentation/payment_history_screen.dart';
import 'package:consumo_plus/features/water/presentation/supply_details_screen.dart';
import 'package:consumo_plus/features/water/presentation/widgets/http_risk_notice.dart';
import 'package:consumo_plus/features/water/presentation/widgets/water_login_form.dart';
import 'package:consumo_plus/features/water/presentation/widgets/water_summary.dart';
import 'package:flutter/material.dart';

typedef WaterViewModelFactory = Future<WaterViewModel> Function();

class WaterScreen extends StatefulWidget {
  const WaterScreen({required this.createViewModel, super.key});

  final WaterViewModelFactory createViewModel;

  @override
  State<WaterScreen> createState() => _WaterScreenState();
}

class _WaterScreenState extends State<WaterScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  WaterViewModel? _viewModel;
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
      viewModel.addListener(_onViewModelChanged);
      await viewModel.initialize();
      if (!mounted) return;
      _usernameController.text = viewModel.state.rememberedUsername ?? '';
      setState(() {});
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _preparationError = error);
    }
  }

  void _onViewModelChanged() {
    if (mounted) setState(() {});
  }

  bool get _canSubmit {
    final busy = _viewModel?.state.status == WaterStatus.synchronizing;
    return !busy &&
        _authorized &&
        _usernameController.text.trim().isNotEmpty &&
        _passwordController.text.isNotEmpty;
  }

  Future<void> _submit() async {
    final viewModel = _viewModel;
    if (viewModel == null || !_canSubmit) return;
    final username = _usernameController.text.trim();
    final password = _passwordController.text;
    try {
      await viewModel.synchronize(username: username, password: password);
    } finally {
      _passwordController.clear();
      if (mounted) setState(() => _obscurePassword = true);
    }
  }

  Future<void> _requestUpdate() async {
    final viewModel = _viewModel;
    final snapshot = viewModel?.state.snapshot;
    if (viewModel == null || snapshot == null) return;
    final request = await showDialog<PasswordRequest>(
      context: context,
      builder: (_) =>
          _UpdatePasswordDialog(initialUsername: snapshot.account.customerCode),
    );
    if (request == null || !mounted) return;
    await viewModel.synchronize(
      username: request.username,
      password: request.password,
    );
  }

  void _openBilling() {
    final snapshot = _viewModel?.state.snapshot;
    if (snapshot == null) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: AppRoutes.waterBilling),
        builder: (_) => BillingHistoryScreen(records: snapshot.billingRecords),
      ),
    );
  }

  void _openPayments() {
    final snapshot = _viewModel?.state.snapshot;
    if (snapshot == null) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: AppRoutes.waterPayments),
        builder: (_) => PaymentHistoryScreen(records: snapshot.paymentRecords),
      ),
    );
  }

  void _openSupply() {
    final snapshot = _viewModel?.state.snapshot;
    if (snapshot == null) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: AppRoutes.waterSupply),
        builder: (_) => SupplyDetailsScreen(
          account: snapshot.account,
          onChangeSupply: _deleteAndRecreate,
          onDeleteData: _deleteAndRecreate,
        ),
      ),
    );
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar datos de Agua'),
        content: const Text(
          'Se borraran la copia cifrada, el usuario recordado y la clave local '
          'de Agua. Tus datos de Electricidad no se modificaran.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            key: const Key('confirmDeleteWaterData'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await _deleteAndRecreate();
    }
  }

  Future<void> _deleteAndRecreate() async {
    final old = _viewModel;
    if (old == null) return;
    await old.deleteWaterData();
    old.removeListener(_onViewModelChanged);
    old.dispose();
    _viewModel = null;
    _usernameController.clear();
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
      viewModel.removeListener(_onViewModelChanged);
      viewModel.dispose();
    }
    _passwordController.clear();
    _passwordController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('waterScreen'),
      appBar: AppBar(
        title: const Text('${WaterCopy.title} · ${WaterCopy.provider}'),
      ),
      body: SafeArea(child: _buildBody(context)),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_preparationError != null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Text('No pudimos abrir el almacenamiento cifrado de Agua.'),
        ),
      );
    }

    final viewModel = _viewModel;
    if (viewModel == null ||
        viewModel.state.status == WaterStatus.loadingLocal) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: AppSpacing.md),
            Text(WaterCopy.loadingLocal),
          ],
        ),
      );
    }

    final state = viewModel.state;
    if (state.snapshot != null) {
      return ListView(
        key: const Key('waterDataList'),
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          if (state.errorMessage != null) _ErrorMessage(state.errorMessage!),
          if (state.errorMessage != null) const SizedBox(height: AppSpacing.md),
          if (state.syncSummary != null) ...[
            _SuccessMessage(state.syncSummary!),
            const SizedBox(height: AppSpacing.md),
          ],
          WaterSummary(
            snapshot: state.snapshot!,
            shouldRecommendUpdate: state.shouldRecommendUpdate,
            busy:
                state.status == WaterStatus.synchronizing ||
                state.status == WaterStatus.deleting,
            onUpdate: _requestUpdate,
            onBilling: _openBilling,
            onPayments: _openPayments,
            onSupply: _openSupply,
            onDelete: _confirmDelete,
          ),
        ],
      );
    }

    final busy = state.status == WaterStatus.synchronizing;
    return ListView(
      key: const Key('waterEmptyList'),
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Text(
          WaterCopy.emptyTitle,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: AppSpacing.sm),
        const Text(WaterCopy.emptyBody),
        const SizedBox(height: AppSpacing.lg),
        if (state.errorMessage != null) ...[
          _ErrorMessage(state.errorMessage!),
          const SizedBox(height: AppSpacing.md),
        ],
        WaterLoginForm(
          usernameController: _usernameController,
          passwordController: _passwordController,
          authorized: _authorized,
          obscurePassword: _obscurePassword,
          busy: busy,
          onAuthorizationChanged: (value) {
            setState(() => _authorized = value ?? false);
          },
          onTogglePassword: () {
            setState(() => _obscurePassword = !_obscurePassword);
          },
          onChanged: () => setState(() {}),
          onSubmit: _canSubmit ? _submit : null,
        ),
      ],
    );
  }
}

class _UpdatePasswordDialog extends StatefulWidget {
  const _UpdatePasswordDialog({required this.initialUsername});

  final String initialUsername;

  @override
  State<_UpdatePasswordDialog> createState() => _UpdatePasswordDialogState();
}

class _UpdatePasswordDialogState extends State<_UpdatePasswordDialog> {
  late final TextEditingController _usernameController;
  final _controller = TextEditingController();
  var _authorized = false;
  var _obscure = true;

  bool get _canSubmit =>
      _authorized &&
      _usernameController.text.trim().isNotEmpty &&
      _controller.text.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.initialUsername);
  }

  @override
  void dispose() {
    _controller.clear();
    _controller.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Actualizar Agua'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const HttpRiskNotice(),
            const SizedBox(height: AppSpacing.md),
            TextField(
              key: const Key('updateWaterUsernameField'),
              controller: _usernameController,
              autocorrect: false,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: WaterCopy.usernameLabel,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              key: const Key('updateWaterPasswordField'),
              controller: _controller,
              obscureText: _obscure,
              enableSuggestions: false,
              autocorrect: false,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: WaterCopy.passwordLabel,
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _obscure = !_obscure),
                  tooltip: _obscure
                      ? WaterCopy.showPassword
                      : WaterCopy.hidePassword,
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
            ),
            CheckboxListTile(
              key: const Key('updateWaterHttpAuthorization'),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: _authorized,
              onChanged: (value) =>
                  setState(() => _authorized = value ?? false),
              title: const Text(WaterCopy.httpAuthorization),
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
          key: const Key('confirmWaterUpdate'),
          onPressed: _canSubmit
              ? () {
                  final request = PasswordRequest(
                    username: _usernameController.text.trim(),
                    password: _controller.text,
                  );
                  _controller.clear();
                  Navigator.of(context).pop(request);
                }
              : null,
          child: const Text('Actualizar'),
        ),
      ],
    );
  }
}

class _ErrorMessage extends StatelessWidget {
  const _ErrorMessage(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Material(
        color: AppColors.errorContainer,
        borderRadius: BorderRadius.circular(AppRadii.sm),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: AppColors.error),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Text(message)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SuccessMessage extends StatelessWidget {
  const _SuccessMessage(this.message);
  final String message;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Material(
      color: AppColors.waterContainer,
      borderRadius: BorderRadius.circular(AppRadii.sm),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Text(message),
      ),
    ),
  );
}
