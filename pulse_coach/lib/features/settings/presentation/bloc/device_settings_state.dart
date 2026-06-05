class DeviceSettingsState {
  const DeviceSettingsState({
    this.isLoading = true,
    this.healthPermissionGranted,
    this.isWearConnected,
    this.pendingSyncCount = 0,
    this.weatherCachedAt,
    this.exerciseCachedAt,
    this.isOnline = false,
  });

  final bool isLoading;
  final bool? healthPermissionGranted;
  final bool? isWearConnected;
  final int pendingSyncCount;
  final DateTime? weatherCachedAt;
  final DateTime? exerciseCachedAt;
  final bool isOnline;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is DeviceSettingsState &&
            other.isLoading == isLoading &&
            other.healthPermissionGranted == healthPermissionGranted &&
            other.isWearConnected == isWearConnected &&
            other.pendingSyncCount == pendingSyncCount &&
            other.weatherCachedAt == weatherCachedAt &&
            other.exerciseCachedAt == exerciseCachedAt &&
            other.isOnline == isOnline;
  }

  @override
  int get hashCode => Object.hash(
    isLoading,
    healthPermissionGranted,
    isWearConnected,
    pendingSyncCount,
    weatherCachedAt,
    exerciseCachedAt,
    isOnline,
  );
}
