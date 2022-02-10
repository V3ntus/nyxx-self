import 'package:nyxx/src/utils/enum.dart';

/// Style for a button.
@Deprecated("Use ButtonStyle")
class ComponentStyle extends IEnum<int> {
  /// A blurple button
  static const primary = ComponentStyle._create(1);

  /// A grey button
  static const secondary = ComponentStyle._create(2);

  /// A green button
  static const success = ComponentStyle._create(3);

  /// A red button
  static const danger = ComponentStyle._create(4);

  /// A button that navigates to a URL
  static const link = ComponentStyle._create(5);

  /// Creates instance of [ComponentStyle]
  ComponentStyle.from(int value) : super(value);
  const ComponentStyle._create(int value) : super(value);
}

/// Style for a button.
class ButtonStyle extends IEnum<int> {
  /// A blurple button
  static const primary = ButtonStyle._create(1);

  /// A grey button
  static const secondary = ButtonStyle._create(2);

  /// A green button
  static const success = ButtonStyle._create(3);

  /// A red button
  static const danger = ButtonStyle._create(4);

  /// A button that navigates to a URL
  static const link = ButtonStyle._create(5);

  /// Creates instance of [ComponentStyle]
  ButtonStyle.from(int value) : super(value);
  const ButtonStyle._create(int value) : super(value);
}
