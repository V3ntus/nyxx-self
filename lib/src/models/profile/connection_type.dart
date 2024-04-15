/// Connection types indicate which service the connection is.
enum ConnectionType {
  unknown._(""),
  battlenet._("battlenet"),
  contacts._("contacts"),
  crunchroll._("crunchroll"),
  ebay._("ebay"),
  epicgames._("epicgames"),
  facebook._("facebook"),
  github._("github"),
  instagram._("instagram"),
  leagueoflegends._("leagueoflegends"),
  paypal._("paypal"),
  playstation._("playstation"),
  reddit._("reddit"),
  riotgames._("riotgames"),
  samsung._("samsung"),
  spotify._("spotify"),
  skype._("skype"), // no longer obtainable
  steam._("steam"),
  tiktok._("tiktok"),
  twitch._("twitch"),
  twitter._("twitter"),
  youtube._("youtube"),
  xbox._("xbox");

  /// The value of this [ConnectionType]
  final String value;

  const ConnectionType._(this.value);

  @override
  String toString() => 'ConnectionType($value)';
}
