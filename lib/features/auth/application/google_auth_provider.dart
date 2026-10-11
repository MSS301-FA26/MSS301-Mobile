import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/google_auth_adapter.dart';

final googleAuthAdapterProvider = Provider<GoogleAuthAdapter>(
  (ref) => GoogleSignInAuthAdapter(GoogleOAuthConfig.fromDartDefines()),
);
