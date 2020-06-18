part of nyxx;

/// Spawns, connects, monitors, manages and terminates shards.
/// Sharding will be automatic if no user settings are supplied in
/// [ClientOptions] when instantiating [Nyxx] client instance.
///
/// Discord gateways implement a method of user-controlled guild sharding which
/// allows for splitting events across a number of gateway connections.
/// Guild sharding is entirely user controlled, and requires no state-sharing
/// between separate connections to operate.
class ShardManager implements Disposable {
  /// Emitted when the shard is ready.
  late Stream<Shard> onConnected = this._onConnect.stream;

  /// Emitted when the shard encounters a connection error.
  late Stream<Shard> onDisconnect = this._onDisconnect.stream;

  /// Emitted when shard receives member chunk.
  late Stream<MemberChunkEvent> onMemberChunk = this._onMemberChunk.stream;

  final StreamController<Shard> _onConnect = StreamController.broadcast();
  final StreamController<Shard> _onDisconnect = StreamController.broadcast();
  final StreamController<MemberChunkEvent> _onMemberChunk = StreamController.broadcast();

  final Logger _logger = Logger("Shard Manager");

  /// List of shards
  Iterable<Shard> get shards => List.unmodifiable(_shards.values);

  /// Average gateway latency across all shards
  Duration get gatewayLatency
    => Duration(milliseconds: (this.shards.map((e) => e.gatewayLatency.inMilliseconds)
        .fold<int>(0, (first, second) => first + second)) ~/ shards.length);

  final _WS _ws;
  final int _numShards;
  final Map<int, Shard> _shards = {};

  /// Starts shard manager
  ShardManager._new(this._ws, this._numShards) {
    _connect(_numShards - 1);
  }

  /// Sets presences on every shard
  void setPresence(PresenceBuilder presenceBuilder) {
    for (final shard in shards) {
      shard.setPresence(presenceBuilder);
    }
  }

  void _connect(int shardId) {
    if(shardId < 0) {
      return;
    }

    final shard = Shard._new(shardId, this, _ws.gateway);
    _shards[shardId] = shard;

    Future.delayed(const Duration(seconds: 1, milliseconds: 500), () => _connect(shardId - 1));
  }

  @override
  Future<void> dispose() async {
    for(final shard in this._shards.values) {
      await shard.dispose();
    }

    await this._onConnect.close();
    await this._onDisconnect.close();
    await this._onMemberChunk.close();
  }
}