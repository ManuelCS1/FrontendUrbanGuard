import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

abstract class MapEvent {}
class UpdateLocationEvent extends MapEvent {
  final LatLng location;
  UpdateLocationEvent(this.location);
}
class SelectDestinationEvent extends MapEvent {
  final LatLng destination;
  SelectDestinationEvent(this.destination);
}

abstract class MapState {}
class MapInitial extends MapState {}
class LocationUpdated extends MapState {
  final LatLng location;
  LocationUpdated(this.location);
}
class DestinationSelected extends MapState {
  final LatLng destination;
  DestinationSelected(this.destination);
}

class MapBloc extends Bloc<MapEvent, MapState> {
  MapBloc() : super(MapInitial()) {
    on<UpdateLocationEvent>((event, emit) {
      emit(LocationUpdated(event.location));
    });
    on<SelectDestinationEvent>((event, emit) {
      emit(DestinationSelected(event.destination));
    });
  }
}