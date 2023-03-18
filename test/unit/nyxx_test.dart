import 'package:nyxx_self/src/client_options.dart';
import 'package:nyxx_self/src/core/snowflake.dart';
import 'package:nyxx_self/src/internal/exceptions/missing_token_error.dart';
import 'package:nyxx_self/src/nyxx.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

main() {
  test("nyxx rest constructor", () {
    expect(() => NyxxFactory.createNyxxRest("", 0, Snowflake.zero(), options: ClientOptions()), throwsA(isA<MissingTokenError>()));
    expect(() => NyxxFactory.createNyxxRest("test", 0, Snowflake.zero(), options: ClientOptions()), isNotNull);
  });
}
