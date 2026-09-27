import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ProvisionalPreviewFeature {
  independentFood,
  refund,
  vouchers,
  vip,
  favorites,
  notifications,
}

class ProvisionalPreviewItem {
  const ProvisionalPreviewItem({
    required this.id,
    required this.title,
    required this.subtitle,
    this.status,
  });

  final int id;
  final String title;
  final String subtitle;
  final String? status;
}

abstract interface class ProvisionalPreviewRepository {
  Future<List<ProvisionalPreviewItem>> getItems(
    ProvisionalPreviewFeature feature,
  );
}

class MockProvisionalPreviewRepository implements ProvisionalPreviewRepository {
  @override
  Future<List<ProvisionalPreviewItem>> getItems(
    ProvisionalPreviewFeature feature,
  ) async => switch (feature) {
    ProvisionalPreviewFeature.independentFood => const [
      ProvisionalPreviewItem(
        id: 1,
        title: 'Combo Couple',
        subtitle: '2 bắp + 2 nước • 159.000đ',
        status: 'Còn hàng',
      ),
      ProvisionalPreviewItem(
        id: 2,
        title: 'Combo Solo',
        subtitle: '1 bắp + 1 nước • 89.000đ',
        status: 'Còn hàng',
      ),
    ],
    ProvisionalPreviewFeature.refund => const [
      ProvisionalPreviewItem(
        id: 1,
        title: 'Hoàn về CineWallet',
        subtitle: 'Mức hoàn và deadline chỉ là dữ liệu preview.',
        status: 'Cần xác nhận',
      ),
    ],
    ProvisionalPreviewFeature.vouchers => const [
      ProvisionalPreviewItem(
        id: 1,
        title: 'WELCOME50',
        subtitle: 'Giảm 50.000đ • Dữ liệu provisional',
        status: 'Có thể dùng',
      ),
      ProvisionalPreviewItem(
        id: 2,
        title: 'COMBO20',
        subtitle: 'Giảm 20% combo • Dữ liệu provisional',
        status: 'Hết hạn',
      ),
    ],
    ProvisionalPreviewFeature.vip => const [
      ProvisionalPreviewItem(
        id: 1,
        title: 'CinePremier Gold',
        subtitle: 'Quyền lợi demo, chưa phải membership contract.',
        status: 'Preview',
      ),
    ],
    ProvisionalPreviewFeature.favorites => const [
      ProvisionalPreviewItem(
        id: 1101,
        title: 'Inception',
        subtitle: 'Đã lưu trong mock local',
        status: 'Yêu thích',
      ),
    ],
    ProvisionalPreviewFeature.notifications => const [
      ProvisionalPreviewItem(
        id: 1,
        title: 'Vé của bạn đã sẵn sàng',
        subtitle: 'Nhấn để mở Đơn của tôi',
        status: 'Chưa đọc',
      ),
      ProvisionalPreviewItem(
        id: 2,
        title: 'Suất chiếu sắp bắt đầu',
        subtitle: 'Còn 2 giờ trước giờ chiếu',
        status: 'Đã đọc',
      ),
    ],
  };
}

final provisionalPreviewRepositoryProvider =
    Provider<ProvisionalPreviewRepository>(
      (ref) => MockProvisionalPreviewRepository(),
    );

final provisionalPreviewItemsProvider =
    FutureProvider.family<
      List<ProvisionalPreviewItem>,
      ProvisionalPreviewFeature
    >((ref, feature) {
      return ref.watch(provisionalPreviewRepositoryProvider).getItems(feature);
    });
