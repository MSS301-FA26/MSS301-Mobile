import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_routes.dart';
import '../../application/booking_checkpoint.dart';
import '../../application/booking_completion_controller.dart';

Future<void> resumeBooking(
  BuildContext context,
  WidgetRef ref,
  int bookingId,
) async {
  try {
    final controller = ref.read(bookingCompletionProvider.notifier);
    final payment = await controller.findExistingPayment(bookingId);
    if (!context.mounted) return;
    context.go(
      payment == null
          ? AppRoutes.concessions(bookingId)
          : AppRoutes.payment(payment.id),
    );
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể tải lại đơn. Vui lòng thử lại.'),
        ),
      );
    }
  }
}

class ResumeBookingBanner extends ConsumerWidget {
  const ResumeBookingBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(resumableBookingProvider)
      .when(
        loading: () => const SizedBox.shrink(),
        error: (_, _) => const SizedBox.shrink(),
        data: (booking) => booking == null
            ? const SizedBox.shrink()
            : ListTile(
                leading: const Icon(Icons.confirmation_number_outlined),
                title: const Text('Tiếp tục đơn đang đặt'),
                subtitle: Text(booking.bookingCode),
                trailing: TextButton(
                  onPressed: () => resumeBooking(context, ref, booking.id),
                  child: const Text('Tiếp tục'),
                ),
              ),
      );
}
