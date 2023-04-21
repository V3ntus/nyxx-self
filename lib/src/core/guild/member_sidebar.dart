import 'dart:async';

import 'package:logging/logging.dart';
import 'package:nyxx_self/src/core/channel/channel.dart';
import 'package:nyxx_self/src/core/channel/guild/guild_channel.dart';
import 'package:nyxx_self/src/core/channel/guild/voice_channel.dart';
import 'package:nyxx_self/src/core/channel/text_channel.dart';

import 'package:nyxx_self/src/core/guild/guild.dart';
import 'package:nyxx_self/src/core/permissions/permissions.dart';
import 'package:nyxx_self/src/core/snowflake.dart';
import 'package:nyxx_self/src/core/user/member.dart';
import 'package:nyxx_self/src/events/raw_event.dart';
import 'package:nyxx_self/src/nyxx.dart';

Logger logger = Logger("scraper");

typedef Range = Map<int, int>;

// Thanks to @dolfies
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

  late List<Range> ranges;

  bool safe() {
    return (guild.memberCount ?? 0) >= 75000;
  }

  int limit() {
    // TODO: assert guild.presences and fetch if needed
    return (guild.memberCount ?? (guild.presences.length)) >= 1000 ? guild.presences.length : (guild.memberCount ?? guild.presences.length);
  }

  Range amalgamate(Range original, Range value) {
    return {original.keys.first: value.values.first - 99};
  }

  List<Range> getRanges() {
    const int chunk = 100;
    const int end = 99;
    int amount = limit();
    if (amount == 0) {
      throw Exception("Member/presence count is required to compute ranges");
    }

    int ceiling = (amount / chunk).ceil() * chunk;
    List<Range> ranges = [];
    for (var i = 0; i < (ceiling / chunk); ++i) {
      int min = i * chunk;
      int max = min + end;
      ranges.add({min: max});
    }
    return ranges;
  }

  List<Range> getCurrentRanges() {
    List<Range> ret = [];
    List<Range> ranges = this.ranges;
    Range current;

    for (int i = 0; i < 3; i++) {
      if (safe()) {
        try {
          ret.add(ranges.removeLast());
        } on IndexError {
          break;
        }
      } else {
        try {
          current = ranges.removeLast();
        } on IndexError {
          break;
        }
        for (int i = 0; i < 3; i++) {
          try {
            current = amalgamate(current, ranges.removeLast());
          } on IndexError {
            break;
          }
        }
        ret.add(current);
      }
    }
    return ret;
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
      logger.warning("Member list scraping failed for guild ${guild.id.id.toString()} (${err.toString()})");
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
      Map<Snowflake, List<Range>> requests = {};

      for (var channel in channels) {
        List<Range> ranges = getCurrentRanges();
        requests[channel.id] = ranges;
      }

      if (requests.isEmpty) {
        logger.severe("Failed to automatically choose channels to scrape");
        break;
      }

      try {
        ws.requestLazyGuild(guild.id, channels: requests);
        await Future.any([
          ws.shardManager.rawEvent.firstWhere(predicate),
          Future.delayed(const Duration(seconds: 10), () {
            throw TimeoutException("Discord did not send a response to the guild subscription");
          })
        ]);
      } on TimeoutException {
        List<int> r = [requests.values.last.last.keys.first, requests.values.last.last.values.first];
        if ([for (var i = r[0]; i <= r[1]; i++) i].contains(limit()) || limit() < r[1]) {
          subscribing = false;
          break;
        } else {
          if (safe()) {
            logger.warning("Discord did not send a response to the guild subscription");
          }
          ranges = getRanges();
          subscribing = false;
          await scrape();
          return;
        }
      }

      List<int> r = [requests.values.last.last.keys.first, requests.values.last.last.values.first];
      if ([for (var i = r[0]; i <= r[1]; i++) i].contains(limit()) || limit() < r[1]) {
        subscribing = false;
        break;
      }
    }
  }

  MemberSidebar(this.guild, this.channels) {
    ws = (guild.client as INyxxWebsocket);
    ranges = getRanges();
  }
}
