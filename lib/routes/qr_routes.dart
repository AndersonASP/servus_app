import 'package:go_router/go_router.dart';
import '../features/volunteers/checkin_qr/checkin_qr_screen.dart';

final List<GoRoute> qrRoutes = [
  GoRoute(
    path: '/qr-checkin',
    builder: (context, state) => const CheckinQrScreen(),
  ),
];