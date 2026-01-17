import 'package:json_annotation/json_annotation.dart';

part 'changelog.g.dart';

@JsonSerializable()
class GithubRelease {
  final String url;
  @JsonKey(name: 'assets_url')
  final String assetsUrl;
  @JsonKey(name: 'upload_url')
  final String uploadUrl;
  @JsonKey(name: 'html_url')
  final String htmlUrl;
  final int id;
  final GithubUser author;
  @JsonKey(name: 'node_id')
  final String nodeId;
  @JsonKey(name: 'tag_name')
  final String tagName;
  @JsonKey(name: 'target_commitish')
  final String targetCommitish;
  final String name;
  final bool draft;
  final bool prerelease;
  @JsonKey(name: 'created_at')
  final String createdAt;
  @JsonKey(name: 'published_at')
  final String publishedAt;
  final List<GithubReleaseAsset> assets;
  @JsonKey(name: 'tarball_url')
  final String tarballUrl;
  @JsonKey(name: 'zipball_url')
  final String zipballUrl;
  final String body;
  final GithubReleaseReactions? reactions;

  GithubRelease({
    required this.url,
    required this.assetsUrl,
    required this.uploadUrl,
    required this.htmlUrl,
    required this.id,
    required this.author,
    required this.nodeId,
    required this.tagName,
    required this.targetCommitish,
    required this.name,
    required this.draft,
    required this.prerelease,
    required this.createdAt,
    required this.publishedAt,
    required this.assets,
    required this.tarballUrl,
    required this.zipballUrl,
    required this.body,
    this.reactions,
  });

  factory GithubRelease.fromJson(Map<String, dynamic> json) =>
      _$GithubReleaseFromJson(json);
  Map<String, dynamic> toJson() => _$GithubReleaseToJson(this);
}

@JsonSerializable()
class GithubReleaseAsset {
  final String url;
  @JsonKey(name: 'browser_download_url')
  final String browserDownloadUrl;
  final int id;
  @JsonKey(name: 'node_id')
  final String nodeId;
  final String name;
  final String label;
  final String state;
  @JsonKey(name: 'content_type')
  final String contentType;
  final int size;
  @JsonKey(name: 'download_count')
  final int downloadCount;
  @JsonKey(name: 'created_at')
  final String createdAt;
  @JsonKey(name: 'updated_at')
  final String updatedAt;
  final GithubUser uploader;

  GithubReleaseAsset({
    required this.url,
    required this.browserDownloadUrl,
    required this.id,
    required this.nodeId,
    required this.name,
    required this.label,
    required this.state,
    required this.contentType,
    required this.size,
    required this.downloadCount,
    required this.createdAt,
    required this.updatedAt,
    required this.uploader,
  });

  factory GithubReleaseAsset.fromJson(Map<String, dynamic> json) =>
      _$GithubReleaseAssetFromJson(json);
  Map<String, dynamic> toJson() => _$GithubReleaseAssetToJson(this);
}

@JsonSerializable()
class GithubUser {
  final String login;
  final int id;
  @JsonKey(name: 'node_id')
  final String nodeId;
  @JsonKey(name: 'avatar_url')
  final String avatarUrl;
  @JsonKey(name: 'gravatar_id')
  final String gravatarId;
  final String url;
  @JsonKey(name: 'html_url')
  final String htmlUrl;
  @JsonKey(name: 'followers_url')
  final String followersUrl;
  @JsonKey(name: 'following_url')
  final String followingUrl;
  @JsonKey(name: 'gists_url')
  final String gistsUrl;
  @JsonKey(name: 'starred_url')
  final String starredUrl;
  @JsonKey(name: 'subscriptions_url')
  final String subscriptionsUrl;
  @JsonKey(name: 'organizations_url')
  final String organizationsUrl;
  @JsonKey(name: 'repos_url')
  final String reposUrl;
  @JsonKey(name: 'events_url')
  final String eventsUrl;
  @JsonKey(name: 'received_events_url')
  final String receivedEventsUrl;
  final String type;
  @JsonKey(name: 'user_view_type')
  final String userViewType;
  @JsonKey(name: 'site_admin')
  final bool siteAdmin;

  GithubUser({
    required this.login,
    required this.id,
    required this.nodeId,
    required this.avatarUrl,
    required this.gravatarId,
    required this.url,
    required this.htmlUrl,
    required this.followersUrl,
    required this.followingUrl,
    required this.gistsUrl,
    required this.starredUrl,
    required this.subscriptionsUrl,
    required this.organizationsUrl,
    required this.reposUrl,
    required this.eventsUrl,
    required this.receivedEventsUrl,
    required this.type,
    required this.userViewType,
    required this.siteAdmin,
  });

  factory GithubUser.fromJson(Map<String, dynamic> json) =>
      _$GithubUserFromJson(json);
  Map<String, dynamic> toJson() => _$GithubUserToJson(this);
}

@JsonSerializable()
class GithubReleaseReactions {
  final String url;
  @JsonKey(name: 'total_count')
  final int totalCount;
  @JsonKey(name: '+1')
  final int plusOne;
  @JsonKey(name: '-1')
  final int minusOne;
  final int laugh;
  final int hooray;
  final int confused;
  final int heart;
  final int rocket;
  final int eyes;

  GithubReleaseReactions({
    required this.url,
    required this.totalCount,
    required this.plusOne,
    required this.minusOne,
    required this.laugh,
    required this.hooray,
    required this.confused,
    required this.heart,
    required this.rocket,
    required this.eyes,
  });

  factory GithubReleaseReactions.fromJson(Map<String, dynamic> json) =>
      _$GithubReleaseReactionsFromJson(json);
  Map<String, dynamic> toJson() => _$GithubReleaseReactionsToJson(this);
}
