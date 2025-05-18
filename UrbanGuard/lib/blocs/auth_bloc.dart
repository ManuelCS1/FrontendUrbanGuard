import 'package:flutter_bloc/flutter_bloc.dart';

abstract class AuthEvent {}
class LoginEvent extends AuthEvent {
  final String email;
  final String password;
  LoginEvent(this.email, this.password);
}
class LogoutEvent extends AuthEvent {}

abstract class AuthState {}
class AuthInitial extends AuthState {}
class AuthLoading extends AuthState {}
class Authenticated extends AuthState {
  final String userId;
  Authenticated(this.userId);
}
class AuthError extends AuthState {
  final String message;
  AuthError(this.message);
}

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc() : super(AuthInitial()) {
    on<LoginEvent>((event, emit) async {
      emit(AuthLoading());
      await Future.delayed(Duration(seconds: 1));
      // Simulación: solo acepta test@test.com y 1234
      if (event.email == "test@test.com" && event.password == "1234") {
        emit(Authenticated("1"));
      } else {
        emit(AuthError("Credenciales incorrectas"));
      }
    });
    on<LogoutEvent>((event, emit) async {
      emit(AuthInitial());
    });
  }
}