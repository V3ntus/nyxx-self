import 'package:nyxx_self/src/typedefs.dart';

/// Provides abstraction for builders
// ignore: one_member_abstracts
abstract class Builder {
  /// Returns built response for api
  RawApiMap build();
}
