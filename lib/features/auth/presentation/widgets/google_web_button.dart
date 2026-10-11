import 'package:flutter/widgets.dart';
import 'package:google_sign_in_web/web_only.dart' as web;

Widget googleWebButton(double width) => web.renderButton(
  configuration: web.GSIButtonConfiguration(
    theme: web.GSIButtonTheme.filledBlack,
    size: web.GSIButtonSize.large,
    text: web.GSIButtonText.signinWith,
    shape: web.GSIButtonShape.rectangular,
    minimumWidth: width.clamp(1, 400),
    locale: 'vi',
  ),
);
