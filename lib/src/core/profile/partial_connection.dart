import 'package:nyxx_self/src/core/profile/connection_type.dart';
import 'package:nyxx_self/src/typedefs.dart';

abstract class IPartialConnection {
  /// The connection's account ID.
  String get id;

  /// The connection's account name.
  String get name;

  /// The connection type (ex. youtube, facebook, twitter) of type [ConnectionType].
  ConnectionType get type;

  /// True if connection is verified.
  bool get verified;

  /// True if connection is visible on the user's profile.
  bool get visible;

  /// Returns a URL to the connection's profile, if available.
  String? get url;
}

class PartialConnection implements IPartialConnection {
  @override
  late final String id;

  @override
  late final String name;

  @override
  late final ConnectionType type;

  @override
  String? url;

  @override
  late final bool verified;

  @override
  late final bool visible;

  PartialConnection(RawApiMap raw) {
    id = raw["id"] as String;
    name = raw["name"] as String;
    type = ConnectionType.from(raw["type"] as String);
    url = raw["url"] as String?;
    verified = raw["verified"] as bool? ?? false;
    visible = raw["visible"] as bool? ?? false;
  }
}