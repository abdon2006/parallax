abstract class MissionEvent {
  const MissionEvent();
}

class MissionTargetChanged extends MissionEvent {
  final String target;

  const MissionTargetChanged(this.target);
}

class MissionConditionToggled extends MissionEvent {
  final String condition;

  const MissionConditionToggled(this.condition);
}

class MissionConditionsSet extends MissionEvent {
  final Set<String> conditions;

  const MissionConditionsSet(this.conditions);
}

class MissionStatusFilterChanged extends MissionEvent {
  final String statusFilter;

  const MissionStatusFilterChanged(this.statusFilter);
}

class MissionTop10Toggled extends MissionEvent {
  const MissionTop10Toggled();
}

class MissionLowRiskToggled extends MissionEvent {
  const MissionLowRiskToggled();
}

class MissionSearchChanged extends MissionEvent {
  final String query;

  const MissionSearchChanged(this.query);
}

class MissionSortChanged extends MissionEvent {
  final String sortBy;

  const MissionSortChanged(this.sortBy);
}

class MissionShortlistToggled extends MissionEvent {
  final int siteId;

  const MissionShortlistToggled(this.siteId);
}

class MissionShortlistCleared extends MissionEvent {
  const MissionShortlistCleared();
}

class MissionPresetApplied extends MissionEvent {
  final String presetName;

  const MissionPresetApplied(this.presetName);
}

class MissionProfileReset extends MissionEvent {
  const MissionProfileReset();
}
