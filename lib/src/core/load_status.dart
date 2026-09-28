/// Lifecycle of an asynchronous load owned by a controller.
enum LoadStatus {
  idle,
  loading,
  ready,
  failed;

  bool get isLoading => this == LoadStatus.loading;
  bool get isReady => this == LoadStatus.ready;
  bool get isFailed => this == LoadStatus.failed;
}
