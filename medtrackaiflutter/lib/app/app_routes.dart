import 'dart:io';
import '../../domain/entities/entities.dart';
import '../../models/product_analysis.dart';

/// Central route paths for go_router.
abstract final class AppRoutes {
  static const loading = '/loading';
  static const onboarding = '/onboarding';
  static const auth = '/auth';
  static const authPinVerify = '/auth/pin-verify';
  static const home = '/home';
  static const analytics = '/analytics';
  static const alarms = '/alarms';
  static const circle = '/circle';
  static const scan = '/scan';
  static const scanPill = '/scan/pill';
  static const scanHistory = '/scan/history';
  static const scanHelp = '/scan/help';
  static const scanAccuracy = '/scan/accuracy';
  static const statsAnalytics = '/stats/analytics';
  static const statsInventory = '/stats/inventory';
  static const statsTrophy = '/stats/trophy';
  static const statsWrapped = '/stats/wrapped';
  static const statsMedWrapped = '/stats/med-wrapped';
  static const statsBuddies = '/stats/buddies';
  static const settingsGlobal = '/settings/global';
  static const settingsPrivacy = '/settings/privacy';
  static const settingsTerms = '/settings/terms';
  static const settingsTheme = '/settings/theme';
  static const focusMode = '/focus';
  static const impactVisualizer = '/impact';
  static const familyAddDependent = '/family/add-dependent';
  static const familyAddMember = '/family/add-member';
  static const familyPin = '/family/pin';
  static const familyEditMember = '/family/edit-member';
  static const analysisProduct = '/analysis/product';
  static const analysisChat = '/analysis/chat';
  static const medicineDetail = '/medicine/:medId';
  static const adminGrowth = '/admin/growth';

  static String medicineDetailPath(int medId, {bool edit = false}) {
    final base = '/medicine/$medId';
    return edit ? '$base?edit=true' : base;
  }

  static String familyAddMemberPath({bool dialog = false}) {
    return dialog ? '$familyAddMember?dialog=true' : familyAddMember;
  }
}

class ProductAnalysisRouteArgs {
  final ProductAnalysis product;
  final File? imageFile;

  const ProductAnalysisRouteArgs({
    required this.product,
    this.imageFile,
  });
}

class ProductChatRouteArgs {
  final ProductAnalysis product;

  const ProductChatRouteArgs({required this.product});
}

class PinVerificationRouteArgs {
  final String correctPin;
  final String profileName;

  const PinVerificationRouteArgs({
    required this.correctPin,
    required this.profileName,
  });
}

class ProfilePinRouteArgs {
  final ManagedProfile profile;

  const ProfilePinRouteArgs({required this.profile});
}

class EditFamilyMemberRouteArgs {
  final ManagedProfile member;

  const EditFamilyMemberRouteArgs({required this.member});
}
