import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:parallax/core/constants/condition_catalog.dart';
import 'package:parallax/data/storage/mission_storage.dart';
import 'package:parallax/logic/bloc/mission_events.dart';
import 'package:parallax/logic/bloc/mission_states.dart';

class MissionBloc extends Bloc<MissionEvent, MissionState> {
  final MissionStorage? storage;

  MissionBloc({MissionState initialState = const MissionState(), this.storage})
    : super(initialState) {
    on<MissionTargetChanged>((event, emit) {
      emit(state.copyWith(target: event.target));
    });

    on<MissionConditionToggled>((event, emit) {
      final conditions = {...state.conditions};
      if (conditions.contains(event.condition)) {
        conditions.remove(event.condition);
      } else {
        conditions.add(event.condition);
      }
      emit(state.copyWith(conditions: conditions));
    });

    on<MissionConditionsSet>((event, emit) {
      emit(state.copyWith(conditions: {...event.conditions}));
    });

    on<MissionStatusFilterChanged>((event, emit) {
      emit(state.copyWith(statusFilter: event.statusFilter));
    });

    on<MissionTop10Toggled>((event, emit) {
      emit(state.copyWith(top10Only: !state.top10Only));
    });

    on<MissionLowRiskToggled>((event, emit) {
      emit(state.copyWith(lowRiskOnly: !state.lowRiskOnly));
    });

    on<MissionSearchChanged>((event, emit) {
      emit(state.copyWith(searchQuery: event.query));
    });

    on<MissionSortChanged>((event, emit) {
      emit(state.copyWith(sortBy: event.sortBy));
    });

    on<MissionShortlistToggled>((event, emit) {
      final shortlist = {...state.shortlist};
      if (shortlist.contains(event.siteId)) {
        shortlist.remove(event.siteId);
      } else if (shortlist.length < 3) {
        shortlist.add(event.siteId);
      } else {
        return;
      }
      emit(state.copyWith(shortlist: shortlist));
    });

    on<MissionShortlistCleared>((event, emit) {
      emit(state.copyWith(shortlist: const {}));
    });

    on<MissionPresetApplied>((event, emit) {
      final preset = presetByName(event.presetName);
      if (preset == null) return;
      emit(
        state.copyWith(
          conditions: {...preset.conditions},
          statusFilter: 'Usable',
          top10Only: false,
          lowRiskOnly: preset.lowRiskOnly,
          searchQuery: '',
        ),
      );
    });

    on<MissionProfileReset>((event, emit) {
      emit(
        state.copyWith(
          conditions: const {},
          statusFilter: 'Usable',
          top10Only: false,
          lowRiskOnly: false,
          searchQuery: '',
          sortBy: 'rank',
        ),
      );
    });
  }

  @override
  void onChange(Change<MissionState> change) {
    super.onChange(change);
    unawaited(storage?.save(change.nextState.toJson()));
  }
}
