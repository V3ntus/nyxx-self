import 'package:nyxx_self/src/internal/shard/shard.dart';
import 'package:nyxx_self/src/typedefs.dart';

/// Raw gateway event
abstract class IRawEvent {
  /// Shard where event was received
  IShard get shard;

  /// Raw event data as deserialized json
  RawApiMap get rawData;
}

class RawEvent implements IRawEvent {
  @override
  final IShard shard;

  @override
  final RawApiMap rawData;

  RawEvent(this.shard, this.rawData);
}
