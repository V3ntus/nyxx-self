import 'package:nyxx_self/src/builders/builder.dart';
import 'package:nyxx_self/src/builders/sentinels.dart';
import 'package:nyxx_self/src/models/guild/guild_widget.dart';
import 'package:nyxx_self/src/models/snowflake.dart';

class WidgetSettingsUpdateBuilder extends UpdateBuilder<WidgetSettings> {
  bool? isEnabled;

  Snowflake? channelId;

  WidgetSettingsUpdateBuilder({this.isEnabled, this.channelId = sentinelSnowflake});

  @override
  Map<String, Object?> build() => {
        if (isEnabled != null) 'enabled': isEnabled,
        if (!identical(channelId, sentinelSnowflake)) 'channel_id': channelId?.toString(),
      };
}
