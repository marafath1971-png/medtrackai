import 'dart:async';

import 'package:medai/data/datasources/steps_cloud.dart';
import 'package:medai/domain/entities/step_day.dart';
import 'package:medai/services/steps_service.dart';

/// A phone whose step history is whatever the test says it is.
class FakeStepSource implements StepSource {
  StepAccess access = StepAccess.granted;

  /// Steps per hour-of-day for today, and totals for whole past days keyed by
  /// the day's start.
  List<int> todayHourly = List.filled(24, 0);
  Map<DateTime, int> pastDays = {};
  int reads = 0;
  bool installOpened = false;

  @override
  Future<StepAccess> status() async => access;

  @override
  Future<StepAccess> request() async => access;

  @override
  Future<int?> stepsBetween(DateTime start, DateTime end) async {
    reads++;
    final dayStart = DateTime(start.year, start.month, start.day);
    if (pastDays.containsKey(dayStart)) return pastDays[dayStart];
    var total = 0;
    for (var h = start.hour; h <= end.hour && h < 24; h++) {
      final hourStart = dayStart.add(Duration(hours: h));
      if (!hourStart.isBefore(end)) break;
      total += todayHourly[h];
    }
    return total;
  }

  @override
  Future<void> openInstall() async => installOpened = true;
}

/// Firestore, minus Firestore.
class FakeStepsCloud implements StepsCloud {
  @override
  String? uid = 'me';

  final saved = <StepDay>[];
  final partners = StreamController<List<StepPartner>>.broadcast();
  final days = <String, StreamController<Map<String, StepDay>>>{};
  final cheers = StreamController<List<StepCheer>>.broadcast();
  final consumed = <String>[];
  final sent = <StepCheerKind>[];
  final unpaired = <String>[];
  StepJoinResult joinResult = StepJoinResult.joined;
  String? lastCode;
  bool failCheer = false;

  StreamController<Map<String, StepDay>> daysOf(String uid) =>
      days.putIfAbsent(uid, StreamController.broadcast);

  @override
  Future<void> saveDay(StepDay day) async => saved.add(day);

  @override
  Stream<List<StepPartner>> watchPartners() => partners.stream;

  @override
  Stream<Map<String, StepDay>> watchDays(String ownerUid, {int limit = 30}) =>
      daysOf(ownerUid).stream;

  @override
  Future<String?> createInvite() async => 'ABC234';

  @override
  Future<StepJoinResult> redeemInvite(String code,
      {required String myName, required String myAvatar}) async {
    lastCode = code;
    return joinResult;
  }

  @override
  Future<void> unpair(String partnerUid) async => unpaired.add(partnerUid);

  @override
  Future<void> sendCheer(String partnerUid, StepCheerKind kind) async {
    if (failCheer) throw StateError('offline');
    sent.add(kind);
  }

  @override
  Stream<List<StepCheer>> watchCheers() => cheers.stream;

  @override
  Future<void> consumeCheer(String id) async => consumed.add(id);
}
