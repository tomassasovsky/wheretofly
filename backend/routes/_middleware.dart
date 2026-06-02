import 'package:backend/app_container.dart';
import 'package:backend/middleware/auth.dart';
import 'package:backend/services/jwt_service.dart';
import 'package:dart_frog/dart_frog.dart';

Handler middleware(Handler handler) {
  return handler
      .use(corsMiddleware)
      .use(provider<JwtService>((_) => AppContainer.instance.jwtService));
}
