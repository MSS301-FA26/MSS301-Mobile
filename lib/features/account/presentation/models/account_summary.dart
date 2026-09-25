import '../../../../core/money/vnd_money.dart';
import '../../data/models/account_dto.dart';

class AccountSummary {
  const AccountSummary({
    required this.userId,
    required this.name,
    required this.initials,
    required this.email,
    required this.membershipTier,
    required this.memberCode,
    required this.joinYear,
    required this.points,
    required this.walletBalance,
  });

  final int userId;
  final String name;
  final String initials;
  final String email;
  final String membershipTier;
  final String memberCode;
  final int joinYear;
  final int points;
  final VndMoney walletBalance;
}

AccountSummary mapAccountSummary(
  UserProfileDto profile,
  WalletDto wallet,
  LoyaltyDto loyalty,
) => AccountSummary(
  userId: profile.id,
  name: profile.fullName,
  initials: _initials(profile.fullName),
  email: profile.email,
  membershipTier: loyalty.points >= 1000 ? 'Diamond VIP' : 'Member',
  memberCode: 'CP-${profile.id.toString().padLeft(7, '0')}',
  joinYear: profile.createdAt.year,
  points: loyalty.points,
  walletBalance: wallet.balance,
);

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty || parts.first.isEmpty) return 'CP';
  if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
  return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
}
