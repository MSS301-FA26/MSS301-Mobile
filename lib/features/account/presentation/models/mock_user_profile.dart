class MockUserProfile {
  const MockUserProfile({
    required this.name,
    required this.initials,
    required this.email,
    required this.membershipTier,
    required this.memberCode,
    required this.joinDate,
    required this.points,
    required this.walletBalance,
  });

  final String name;
  final String initials;
  final String email;
  final String membershipTier;
  final String memberCode;
  final String joinDate;
  final int points;
  final int walletBalance;
}

const mockUserProfile = MockUserProfile(
  name: 'Alex Nguyen',
  initials: 'AN',
  email: 'alex.nguyen@cinepremier.vn',
  membershipTier: 'Diamond VIP',
  memberCode: 'CP-992-8114',
  joinDate: '2024',
  points: 12850,
  walletBalance: 450000,
);
