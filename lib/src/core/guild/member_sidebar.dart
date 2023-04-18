import 'dart:async';

import 'package:logging/logging.dart';
import 'package:nyxx_self/src/core/channel/channel.dart';
import 'package:nyxx_self/src/core/channel/guild/guild_channel.dart';
import 'package:nyxx_self/src/core/channel/guild/voice_channel.dart';
import 'package:nyxx_self/src/core/channel/text_channel.dart';

import 'package:nyxx_self/src/core/guild/guild.dart';
import 'package:nyxx_self/src/core/permissions/permissions.dart';
import 'package:nyxx_self/src/core/user/member.dart';
import 'package:nyxx_self/src/events/raw_event.dart';
import 'package:nyxx_self/src/nyxx.dart';

Logger logger = Logger("scraper");

abstract class IMemberSidebar {
  IGuild get guild;

  bool get subscribing;

  Iterable<IGuildChannel> get channels;

  Future<void> start();

  Future<void> scrape();
}

class MemberSidebar extends IMemberSidebar {
  late final IMember selfMember;

  late final INyxxWebsocket ws;

  int limit() {
    return (guild.memberCount ?? guild.presences.length) >= 1000
        ? guild.presences.length
        : (guild.memberCount ?? guild.presences.length);
  }

  // Thanks to @dolfies
  List<Map<int, int>> getRanges() {
    const int chunk = 100;
    const int end = 99;
    int amount = limit();
    if (amount == 0) {
      throw Exception("Member/presence count is required to compute ranges");
    }

    int ceiling = (amount / chunk).ceil() * chunk;
    List<Map<int, int>> ranges = [];
    for (var i = 0; i < (ceiling / chunk); ++i) {
      int min = i * chunk;
      int max = min + end;
      ranges.add({min: max});
    }
    return ranges;
  }

  Future<List<IGuildChannel>> getChannels(int amount) async {
    Set<IGuildChannel> ret = {};

    List<IChannel> channels = [];
    selfMember = await guild.selfMember.getOrDownload();
    for (var channel in guild.channels) {
      if (channel is! StageVoiceGuildChannel && (await channel.effectivePermissions(selfMember)).readMessageHistory) {
        channels.add(channel);
      }
    }

    if (guild.rulesChannel != null) {
      ITextChannel? rulesChannel = await guild.rulesChannel?.getOrDownload();
      if (rulesChannel != null) {
        channels.insert(0, rulesChannel);
      }
    }

    while (ret.length < amount && channels.isNotEmpty) {
      IChannel channel = channels.removeLast();
      for (var o in (channel as IGuildChannel).permissionOverrides) {
        if (o.type == 1) {
          Permissions p = Permissions.fromOverwrite(o.permissions.raw, o.allow, o.deny);
          if (!p.readMessageHistory) break;
        }
      }
      ret.add(channel);
    }

    return ret.toList();
  }

  @override
  final IGuild guild;

  @override
  bool subscribing = false;

  @override
  Iterable<IGuildChannel> channels;

  @override
  Future<void> start() async {
    try {
      await scrape();
    } on AsyncError {
      // pass - would this go to the catch below?
    } catch (err) {
      logger.warning(
          "Member list scraping failed for guild ${guild.id.id.toString()} (${err.toString()})");
    } finally {
      // TODO: implement done() ?
    }
  }

  @override
  Future<void> scrape() async {
    // TODO: implement scrape
    subscribing = true;

    bool predicate(IRawEvent rawEvent) {
      return rawEvent.rawData["t"] == "GUILD_MEMBER_LIST_UPDATE" &&
          rawEvent.rawData["guild_id"] == guild.id.toString() &&
          (rawEvent.rawData["ops"] as List? ?? []).any((op) => op["op"] == "SYNC");
    }

    while (subscribing) {
      try {
        ws.requestLazyGuild(guild.id);
        await Future.any([ws.shardManager.rawEvent.firstWhere(predicate), Future.delayed(const Duration(seconds: 10), () {
          throw TimeoutException("Discord did not send a response to the guild subscription");
        })]);
      } on TimeoutException {
        logger.warning("Discord did not send a response to the guild subscription");
        subscribing = false;
        break;
      }
    }
  }

  MemberSidebar(this.guild, this.channels) {
    ws = (guild.client as INyxxWebsocket);
  }
}
