sealed class UserEvent {}

class UserJumpToPage extends UserEvent {
  final int page;
  UserJumpToPage(this.page);
}

class UserZoom extends UserEvent {
  final double zoom;
  UserZoom(this.zoom);
}

class UserSetOffsetX extends UserEvent {
  final double offsetX;
  final double zoom;
  UserSetOffsetX(this.offsetX, this.zoom);
}

class UserRequestToPdfViewerStateRefersh extends UserEvent {}
