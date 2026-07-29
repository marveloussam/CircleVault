abstract class AppStrings {
  // App
  static const String appName = 'Circle Vault';
  static const String tagline = 'Save Together. Grow Together.';

  // Auth — Signup
  static const String signup = 'Sign Up';
  static const String createAccount = 'Create Account';
  static const String fullName = 'Full Name';
  static const String fullNameHint = 'Enter your full name';
  static const String phoneNumber = 'Phone Number';
  static const String phoneHint = '+2348012345678';
  static const String password = 'Password';
  static const String passwordHint = 'Minimum 8 characters';
  static const String alreadyHaveAccount = 'Already have an account? ';
  static const String loginLink = 'Log In';
  static const String email = 'Email';
  static const String emailHint = 'Enter your email address';

  // Auth — OTP
  static const String verifyPhone = 'Verify Your Phone';
  static const String otpSentTo = 'A 6-digit code was sent to ';
  static const String enterOtp = 'Enter OTP';
  static const String verify = 'Verify';
  static const String resendCode = 'Resend Code';
  static const String resendIn = 'Resend in ';
  static const String seconds = 's';
  static const String didNotReceive = "Didn't receive the code? ";

  // Auth — Login
  static const String login = 'Log In';
  static const String welcomeBack = 'Welcome Back';
  static const String loginSubtitle = 'Enter your phone and password';
  static const String noAccount = "Don't have an account? ";
  static const String signupLink = 'Sign Up';
  static const String forgotPassword = 'Forgot Password?';

  // Home
  static const String goodMorning = 'Good morning';
  static const String goodAfternoon = 'Good afternoon';
  static const String goodEvening = 'Good evening';
  static const String myCircles = 'My Circles';
  static const String recentTransactions = 'Recent Transactions';
  static const String noCirclesYet = 'You haven\'t joined any circles yet.';
  static const String noTransactions = 'No transactions yet.';
  static const String getAiTip = 'Get AI Tip';
  static const String totalSavings = 'Total Savings';
  static const String viewAll = 'View All';

  // Circles
  static const String circles = 'Circles';
  static const String createCircle = 'Create Circle';
  static const String circleName = 'Circle Name';
  static const String circleNameHint = 'e.g. Family Savings Group';
  static const String contributionAmount = 'Contribution Amount (NGN)';
  static const String contributionAmountHint = 'e.g. 5000';
  static const String frequency = 'Contribution Frequency';
  static const String totalMembers = 'Total Members';
  static const String totalMembersHint = 'e.g. 10';
  static const String weekly = 'Weekly';
  static const String biweekly = 'Bi-Weekly';
  static const String monthly = 'Monthly';
  static const String members = 'Members';
  static const String nextContribution = 'Next Contribution';
  static const String currentRound = 'Current Round';
  static const String viewLedger = 'View Ledger';
  static const String addMember = 'Add Member';
  static const String startCircle = 'Start Circle';
  static const String pauseCircle = 'Pause Circle';
  static const String rotationOrder = 'Rotation Order';
  static const String noMembersYet = 'No members yet.';

  // Ledger
  static const String ledger = 'Ledger';
  static const String contribution = 'CONTRIBUTION';
  static const String payout = 'PAYOUT';
  static const String fee = 'FEE';
  static const String refund = 'REFUND';
  static const String reference = 'Ref: ';

  // Payment
  static const String addCard = 'Add Card';
  static const String addCardSubtitle = 'Securely save your card for automatic contributions';
  static const String cardAdded = 'Card added successfully!';
  static const String proceedToAddCard = 'Proceed to Add Card';
  static const String paymentSecured = 'Payment secured by Paystack';

  // AI Advisory
  static const String aiAdvisor = 'AI Advisor';
  static const String personalizedTips = 'Personalised Financial Tips';
  static const String refreshTip = 'Get New Tip';
  static const String tipHistory = 'Previous Tips';
  static const String generatingTip = 'Generating your tip...';
  static const String noTipsYet = 'Tap the button below to get your first tip!';

  // Profile
  static const String profile = 'Profile';
  static const String logout = 'Log Out';
  static const String logoutConfirm = 'Are you sure you want to log out?';
  static const String cancel = 'Cancel';
  static const String confirm = 'Confirm';

  // Errors
  static const String genericError = 'Something went wrong. Please try again.';
  static const String networkError = 'No internet connection.';
  static const String sessionExpired = 'Your session has expired. Please log in again.';
  static const String invalidPhone = 'Enter a valid Nigerian phone number (+234XXXXXXXXXX).';
  static const String invalidPassword = 'Password must be at least 8 characters.';
  static const String invalidName = 'Name must be at least 2 characters.';
  static const String otpInvalid = 'Invalid or expired OTP. Please try again.';
  static const String cardError = 'Card verification failed. Please try again.';

  // Status labels
  static const String statusPending = 'PENDING';
  static const String statusActive = 'ACTIVE';
  static const String statusCompleted = 'COMPLETED';
  static const String statusPaused = 'PAUSED';

  // Navigation
  static const String home = 'Home';
  static const String navCircles = 'Circles';
  static const String navLedger = 'Ledger';
  static const String navProfile = 'Profile';
}
