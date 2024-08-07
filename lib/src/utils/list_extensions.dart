extension ListX<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    for (final element in this) {
      if (test(element)) return element;
    }
    return null;
  }

  Map<T, R> associate<R>(R Function(T) transform) {
    final map = <T, R>{};
    for (final element in this) {
      map[element] = transform(element);
    }
    return map;
  }
}
