/// AI chat feature providers.
library;

import 'package:dpip/core/di/shared_deps.dart';
import 'package:dpip/core/platform/secret_store.dart';
import 'package:dpip/core/realtime/app_time.dart';
import 'package:dpip/features/ai_chat/data/ai_settings_repository_impl.dart';
import 'package:dpip/features/ai_chat/data/dpip_mcp_tool_host.dart';
import 'package:dpip/features/ai_chat/data/openai_chat_model.dart';
import 'package:dpip/features/ai_chat/domain/system_prompt.dart';
import 'package:dpip/features/ai_chat/presentation/ai_chat_controller.dart';
import 'package:dpip/features/ai_chat/presentation/ai_setup.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

/// The AI assistant's setup and its one in-memory conversation.
///
/// Both are created on first use — opening the AI page — so a user who never
/// does pays for neither, and no key-storage read happens at launch.
List<SingleChildWidget> aiChatProviders(SharedDeps deps) {
  final settings = AiSettingsRepositoryImpl(
    deps.settings,
    PlatformSecretStore(),
    deps.apiClient,
  );
  final tools = DpipMcpToolHost(deps.apiClient);
  return [
    ChangeNotifierProvider<AiSetup>(create: (_) => AiSetup(settings)),
    ChangeNotifierProvider<AiChatController>(
      create: (_) => AiChatController(
        settings: settings,
        models: (connection, key) =>
            OpenAiChatModel(deps.apiClient, connection, key),
        tools: tools,
        places: () => _places(deps),
        taipeiNow: () => AppTime.utc8,
      ),
    ),
  ];
}

/// The user's townships, by name and code only — the explanation page says
/// no coordinates are sent, and none are.
List<PromptPlace> _places(SharedDeps deps) {
  final regions = deps.regionStore;
  final towns = deps.townDirectory;
  final current = regions.currentCode;
  return [
    if (towns.byCode(current) case final town?)
      PromptPlace(name: town.fullName, code: current!, current: true),
    for (final code in regions.savedCodes)
      if (code != current)
        if (towns.byCode(code) case final town?)
          PromptPlace(name: town.fullName, code: code, current: false),
  ];
}
