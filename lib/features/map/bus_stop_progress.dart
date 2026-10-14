export '../../data/transit/bus_stop_progress.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/transit/bus_stop_event.dart';
import '../../data/transit/transit_repository.dart';

final busStopEventsProvider = FutureProvider.autoDispose
    .family<List<BusStopEvent>, String>((ref, tripId) {
      return ref.read(transitRepositoryProvider).getBusStopEvents(tripId);
    });
