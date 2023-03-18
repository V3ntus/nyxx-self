import 'dart:core';
import 'package:nyxx_self/src/core/guild/guild.dart';
import 'package:nyxx_self/src/core/snowflake.dart';
import 'package:nyxx_self/src/core/snowflake_entity.dart';
import 'package:nyxx_self/src/core/profile/partial_connection.dart';
import 'package:nyxx_self/src/core/user/member.dart';
import 'package:nyxx_self/src/core/user/nitro_type.dart';
import 'package:nyxx_self/src/core/user/user.dart';
import 'package:nyxx_self/src/internal/cache/cacheable.dart';
import 'package:nyxx_self/src/nyxx.dart';
import 'package:nyxx_self/src/typedefs.dart';
import 'package:nyxx_self/src/utils/utils.dart';

abstract class IProfile implements SnowflakeEntity {
  /// Reference to client
  INyxx get client;

  /// The user's connected accounts shown on the profile. Can be [null].
  List<PartialConnection?> get connectedAccounts;

  /// The user's [Member] profile if accessed from a guild;
  Member? get guildMember;

  // TODO: implement guildMemberProfile

  /// A list of guilds that you share with the user. [null] if you did not fetch mutuals.
  List<Cacheable<Snowflake, IGuild>?> get mutualGuilds;

  /// A [DateTime] object representing when this user started boosting a server. Can be [null].
  DateTime? get boostingSince;

  /// A [DateTime] object representing when this user acquired nitro. Can be [null].
  DateTime? get nitroSince;

  /// A [NitroType] object indicating what Nitro level this user has.
  NitroType get nitroType;

  /// The [User] object of the user.
  IUser get user;

  // TODO: implement userProfile
}

class Profile extends SnowflakeEntity implements IProfile {
  /// Reference to client
  @override
  final INyxx client;

  /// The user's connected accounts shown on the profile. Can be [null].
  @override
  late final List<PartialConnection?> connectedAccounts;

  /// The user's [Member] profile if accessed from a guild;
  @override
  Member? guildMember;

  /// A list of guilds that you share with the user. [null] if you did not fetch mutuals.
  @override
  late final List<Cacheable<Snowflake, IGuild>?> mutualGuilds;

  /// A [DateTime] object representing when this user started boosting a server. Can be [null].
  @override
  DateTime? boostingSince;

  /// A [DateTime] object representing when this user acquired nitro. Can be [null].
  @override
  DateTime? nitroSince;

  /// A [NitroType] object indicating what Nitro level this user has.
  @override
  late final NitroType nitroType;

  /// The [User] object of the user.
  @override
  late final IUser user;

  /// Takes a list of mutual guilds from the profile and converts it
  /// into a list of [GuildCacheable] objects.
  List<Cacheable<Snowflake, IGuild>?> _parseMutualGuilds(
      List<Map<String, dynamic>> mutualGuilds) {
    if (mutualGuilds.isEmpty) return [];

    return [
      for (var guild in mutualGuilds)
        GuildCacheable(client, Snowflake(guild["id"] as String))
    ];
  }

  /// Creates an instance of [Profile]
  Profile(this.client, RawApiMap raw)
      : super(Snowflake(raw["user"]["id"])) {
    connectedAccounts = [
      for (var account in raw["connected_accounts"] as List)
        PartialConnection(account as Map<String, dynamic>)
    ];
    if (raw["guild_mamber_profile"]?["guild_id"] != null) {
      guildMember = Member(client, raw["guild_member"] as Map<String, dynamic>,
          Snowflake(raw["guild_member_profile"]["guild_id"] as String));
    }
    mutualGuilds =
        _parseMutualGuilds(raw["mutual_guilds"] as List<Map<String, dynamic>>);
    boostingSince = parseTime(raw["premium_guild_since"] as String);
    nitroSince = parseTime(raw["premium_since"] as String);
    nitroType = NitroType.from(raw["premium_type"] as int);
    user = User(client, raw["user"] as Map<String, dynamic>);
  }
}
