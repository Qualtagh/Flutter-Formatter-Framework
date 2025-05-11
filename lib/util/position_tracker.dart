typedef PositionPredicate = bool Function(int pos);
typedef PositionUpdater = int Function(int pos);

class PositionListTracker {
  final List<PositionTracker> trackers;

  PositionListTracker(List<int> positions) : trackers = positions.map((pos) => PositionTracker(pos)).toList();

  int operator [](int index) => trackers[index].current;

  void updateIfOld(PositionPredicate predicate, PositionUpdater updater) {
    for (final tracker in trackers) {
      tracker.updateIfOld(predicate, updater);
    }
  }

  void updateIfNew(PositionPredicate predicate, PositionUpdater updater) {
    for (final tracker in trackers) {
      tracker.updateIfNew(predicate, updater);
    }
  }
}

class PositionTracker {
  int old;
  int current;

  PositionTracker(int pos) : old = pos, current = pos;

  void updateIfOld(PositionPredicate predicate, PositionUpdater updater) {
    if (predicate(old)) {
      current = updater(current);
    }
  }

  void updateIfNew(PositionPredicate predicate, PositionUpdater updater) {
    if (predicate(current)) {
      current = updater(current);
    }
  }
}
