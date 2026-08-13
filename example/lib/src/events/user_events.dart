sealed class UserEvent {}

class UserRequestZoomIn extends UserEvent {}

class UserRequestZoomOut extends UserEvent {}

class UserRequestJumpPage extends UserEvent {
  final int page;
  final double? offsetX;
  final double? zoom;
  UserRequestJumpPage(this.page, this.offsetX,this.zoom);
}
