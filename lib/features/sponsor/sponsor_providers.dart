/// Sponsor feature providers.
library;

import 'package:dpip/features/sponsor/data/sponsor_repository_impl.dart';
import 'package:dpip/features/sponsor/domain/sponsor_repository.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

/// The support / in-app-purchase repository, created once and disposed with the
/// app. It listens to the store's purchase stream for the app's lifetime so a
/// purchase that finishes after its page closes is still finalised.
List<SingleChildWidget> sponsorProviders() => [
  Provider<SponsorRepository>(
    create: (_) => InAppPurchaseSponsorRepository(InAppPurchase.instance),
    dispose: (_, repo) => repo.dispose(),
  ),
];
