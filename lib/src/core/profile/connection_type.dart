import 'package:nyxx_self/src/utils/enum.dart';

/// Connection types indicate which service the connection is.
class ConnectionType extends IEnum<String> {
  static const ConnectionType unknown = ConnectionType._create("");
  static const ConnectionType battlenet = ConnectionType._create("battlenet");
  static const ConnectionType contacts = ConnectionType._create("contacts");
  static const ConnectionType crunchyroll = ConnectionType._create("crunchroll");
  static const ConnectionType ebay = ConnectionType._create("ebay");
  static const ConnectionType epicgames = ConnectionType._create("epicgames");
  static const ConnectionType facebook = ConnectionType._create("facebook");
  static const ConnectionType github = ConnectionType._create("github");
  static const ConnectionType instagram = ConnectionType._create("instagram");
  static const ConnectionType leagueoflegends = ConnectionType._create("leagueoflegends");
  static const ConnectionType paypal = ConnectionType._create("paypal");
  static const ConnectionType playstation = ConnectionType._create("playstation");
  static const ConnectionType reddit = ConnectionType._create("reddit");
  static const ConnectionType riotgames = ConnectionType._create("riotgames");
  static const ConnectionType samsung = ConnectionType._create("samsung");
  static const ConnectionType spotify = ConnectionType._create("spotify");
  static const ConnectionType skype = ConnectionType._create("skype"); // no longer obtainable
  static const ConnectionType steam = ConnectionType._create("steam");
  static const ConnectionType tiktok = ConnectionType._create("tiktok");
  static const ConnectionType twitch = ConnectionType._create("twitch");
  static const ConnectionType twitter = ConnectionType._create("twitter");
  static const ConnectionType youtube = ConnectionType._create("youtube");
  static const ConnectionType xbox = ConnectionType._create("xbox");

  ConnectionType.from(String? value) : super(value ?? "");
  const ConnectionType._create(String? value) : super(value ?? "");

  @override
  bool operator ==(dynamic other) {
    if (other is String) {
      return other == value;
    }

    return super == other;
  }

  @override
  int get hashCode => value.hashCode;
}
