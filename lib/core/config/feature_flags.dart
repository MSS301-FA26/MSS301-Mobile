abstract final class FeatureFlags {
  static const independentFoodOrderPreview = bool.fromEnvironment(
    'ENABLE_INDEPENDENT_FOOD_ORDER_PREVIEW',
  );
  static const refundPreview = bool.fromEnvironment('ENABLE_REFUND_PREVIEW');
  static const voucherPreview = bool.fromEnvironment('ENABLE_VOUCHER_PREVIEW');
  static const vipPreview = bool.fromEnvironment('ENABLE_VIP_PREVIEW');
  static const socialMoviePreview = bool.fromEnvironment(
    'ENABLE_SOCIAL_MOVIE_PREVIEW',
  );
  static const popBotPreview = bool.fromEnvironment('ENABLE_POPBOT_PREVIEW');
  static const loyaltyCheckoutRedemption = bool.fromEnvironment(
    'ENABLE_LOYALTY_CHECKOUT_REDEMPTION',
  );
}
