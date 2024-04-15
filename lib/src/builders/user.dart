import 'package:nyxx_self/src/builders/builder.dart';
import 'package:nyxx_self/src/builders/image.dart';
import 'package:nyxx_self/src/builders/sentinels.dart';
import 'package:nyxx_self/src/models/user/user.dart';

class UserUpdateBuilder extends UpdateBuilder<User> {
  /// New user's username.
  String? username;

  /// New user's avatar.
  ImageBuilder? avatar;

  /// New user's banner.
  ImageBuilder? banner;

  UserUpdateBuilder({this.username, this.avatar = sentinelImageBuilder, this.banner = sentinelImageBuilder});

  @override
  Map<String, Object?> build() => {
        if (username != null) 'username': username!,
        if (!identical(avatar, sentinelImageBuilder)) 'avatar': avatar?.buildDataString(),
        if (!identical(banner, sentinelImageBuilder)) 'banner': banner?.buildDataString(),
      };
}
