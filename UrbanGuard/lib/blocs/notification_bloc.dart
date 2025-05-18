import 'package:flutter_bloc/flutter_bloc.dart';

abstract class NotificationEvent {}
class ShowNotificationEvent extends NotificationEvent {
  final String message;
  ShowNotificationEvent(this.message);
}

abstract class NotificationState {}
class NotificationInitial extends NotificationState {}
class NotificationShown extends NotificationState {
  final String message;
  NotificationShown(this.message);
}

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  NotificationBloc() : super(NotificationInitial()) {
    on<ShowNotificationEvent>((event, emit) {
      emit(NotificationShown(event.message));
    });
  }
}