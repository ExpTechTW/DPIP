/// Setting up the user's own AI service: base URL, key, model.
library;

import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/features/ai_chat/domain/ai_connection.dart';
import 'package:dpip/features/ai_chat/domain/ai_failure.dart';
import 'package:dpip/features/ai_chat/presentation/ai_setup.dart';
import 'package:dpip/features/ai_chat/presentation/ai_texts.dart';
import 'package:dpip/features/ai_chat/presentation/widgets/mcp_url_card.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/widgets/section_header.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class AiSettingsPage extends StatefulWidget {
  const AiSettingsPage({super.key});

  @override
  State<AiSettingsPage> createState() => _AiSettingsPageState();
}

class _AiSettingsPageState extends State<AiSettingsPage> {
  final TextEditingController _url = TextEditingController();
  final TextEditingController _key = TextEditingController();
  final TextEditingController _model = TextEditingController();

  bool _showKey = false;
  bool _saving = false;
  bool _listing = false;
  String? _urlError;
  String? _modelError;
  String? _listError;

  @override
  void initState() {
    super.initState();
    final saved = context.read<AiSetup>().connection;
    _url.text = saved.baseUrl;
    _model.text = saved.model;
  }

  @override
  void dispose() {
    _url.dispose();
    _key.dispose();
    _model.dispose();
    super.dispose();
  }

  String? _validUrl(AppLocalizations l10n) {
    final (:url, :problem) = normalizeBaseUrl(_url.text);
    setState(() => _urlError = baseUrlProblemText(l10n, problem));
    return url;
  }

  void _toast(String text) => ScaffoldMessenger.maybeOf(context)
    ?..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));

  Future<void> _pickModel() async {
    final l10n = AppLocalizations.of(context);
    final url = _validUrl(l10n);
    if (url == null) return;
    setState(() {
      _listing = true;
      _listError = null;
    });
    List<String> models = const [];
    try {
      models = await context.read<AiSetup>().listModels(url, _key.text);
    } on AiException catch (error) {
      if (mounted) setState(() => _listError = aiFailureText(l10n, error));
    } finally {
      if (mounted) setState(() => _listing = false);
    }
    if (!mounted || _listError != null) return;
    if (models.isEmpty) {
      setState(() => _listError = l10n.aiSettingsNoModels);
      return;
    }
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => _ModelPicker(models: models),
    );
    if (picked != null && mounted) {
      setState(() {
        _model.text = picked;
        _modelError = null;
      });
    }
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final url = _validUrl(l10n);
    final model = _model.text.trim();
    setState(
      () => _modelError = model.isEmpty ? l10n.aiSettingsModelEmpty : null,
    );
    if (url == null || model.isEmpty) return;
    final typedKey = _key.text.trim();
    setState(() => _saving = true);
    try {
      await context.read<AiSetup>().save(
        AiConnection(baseUrl: url, model: model),
        // Left blank: keep the key already saved.
        apiKey: typedKey.isEmpty ? null : typedKey,
      );
    } catch (_) {
      // The platform's key storage refused; its message is not the user's
      // to read, and the log already has the code.
      if (mounted) {
        setState(() => _saving = false);
        _toast(l10n.aiSettingsSaveFailed);
      }
      return;
    }
    if (!mounted) return;
    _key.clear();
    setState(() => _saving = false);
    _toast(l10n.aiSettingsSaved);
    if (context.canPop()) context.pop();
  }

  Future<void> _removeKey() async {
    final l10n = AppLocalizations.of(context);
    final setup = context.read<AiSetup>();
    await setup.save(setup.connection, apiKey: '');
    if (mounted) _toast(l10n.aiSettingsKeyRemoved);
  }

  Future<void> _forget() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text(l10n.aiSettingsForgetTitle),
        content: Text(l10n.aiSettingsForgetBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialog, true),
            child: Text(l10n.aiSettingsForgetConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await context.read<AiSetup>().forget();
    if (!mounted) return;
    setState(() {
      _url.clear();
      _key.clear();
      _model.clear();
      _urlError = _modelError = _listError = null;
    });
    _toast(l10n.aiSettingsForgotten);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final setup = context.watch<AiSetup>();
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: colors.onSurfaceVariant,
    );
    return Scaffold(
      appBar: AppBar(title: Text(l10n.aiSettingsTitle)),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.xl + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          SectionHeader(l10n.aiSettingsService),
          Text(l10n.aiSettingsServiceBody, style: muted),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final preset in aiPresets)
                ActionChip(
                  label: Text(preset.name),
                  onPressed: () => setState(() {
                    _url.text = preset.baseUrl;
                    _urlError = null;
                    _listError = null;
                  }),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _url,
            keyboardType: TextInputType.url,
            autocorrect: false,
            enableSuggestions: false,
            decoration: InputDecoration(
              labelText: l10n.aiSettingsBaseUrl,
              hintText: aiPresets.first.baseUrl,
              helperText: l10n.aiSettingsBaseUrlHelper,
              helperMaxLines: 3,
              errorText: _urlError,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _key,
            obscureText: !_showKey,
            autocorrect: false,
            enableSuggestions: false,
            decoration: InputDecoration(
              labelText: l10n.aiSettingsApiKey,
              helperText: setup.hasKey
                  ? l10n.aiSettingsApiKeySaved
                  : l10n.aiSettingsApiKeyHelper,
              helperMaxLines: 3,
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                tooltip: _showKey
                    ? l10n.aiSettingsHideKey
                    : l10n.aiSettingsShowKey,
                onPressed: () => setState(() => _showKey = !_showKey),
                icon: Icon(
                  _showKey
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
              ),
            ),
          ),
          if (setup.hasKey)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                onPressed: _removeKey,
                icon: const Icon(Icons.key_off_outlined),
                label: Text(l10n.aiSettingsRemoveKey),
              ),
            ),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _model,
            autocorrect: false,
            enableSuggestions: false,
            decoration: InputDecoration(
              labelText: l10n.aiSettingsModel,
              helperText: l10n.aiSettingsModelHelper,
              helperMaxLines: 3,
              errorText: _modelError ?? _listError,
              errorMaxLines: 4,
              border: const OutlineInputBorder(),
              suffixIcon: _listing
                  ? const Padding(
                      padding: EdgeInsets.all(AppSpacing.md),
                      child: SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : IconButton(
                      tooltip: l10n.aiSettingsFetchModels,
                      onPressed: _pickModel,
                      icon: const Icon(Icons.list_alt_outlined),
                    ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: Text(l10n.aiSettingsSave),
          ),
          const SizedBox(height: AppSpacing.xxl),
          SectionHeader(l10n.aiSettingsPrivacy),
          Text(l10n.aiSettingsPrivacyBody, style: muted),
          const SizedBox(height: AppSpacing.xl),
          const McpUrlCard(),
          if (setup.connection.baseUrl.isNotEmpty || setup.hasKey) ...[
            const SizedBox(height: AppSpacing.xl),
            OutlinedButton.icon(
              onPressed: _forget,
              style: OutlinedButton.styleFrom(foregroundColor: colors.error),
              icon: const Icon(Icons.delete_outline),
              label: Text(l10n.aiSettingsForget),
            ),
          ],
        ],
      ),
    );
  }
}

class _ModelPicker extends StatefulWidget {
  const _ModelPicker({required this.models});

  final List<String> models;

  @override
  State<_ModelPicker> createState() => _ModelPickerState();
}

class _ModelPickerState extends State<_ModelPicker> {
  String _filter = '';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final needle = _filter.toLowerCase();
    final shown = [
      for (final id in widget.models)
        if (needle.isEmpty || id.toLowerCase().contains(needle)) id,
    ];
    return FractionallySizedBox(
      heightFactor: 0.85,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: TextField(
              autofocus: widget.models.length > 12,
              autocorrect: false,
              onChanged: (text) => setState(() => _filter = text.trim()),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: l10n.aiSettingsFilterModels,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.only(
                bottom: MediaQuery.paddingOf(context).bottom,
              ),
              itemCount: shown.length,
              itemBuilder: (context, index) => ListTile(
                leading: const Icon(Icons.memory_outlined),
                title: Text(shown[index]),
                onTap: () => Navigator.pop(context, shown[index]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
