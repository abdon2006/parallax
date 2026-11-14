import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:parallax/data/repositories/analog_repository.dart';
import 'package:parallax/logic/bloc/analog_events.dart';
import 'package:parallax/logic/bloc/analog_states.dart';

class AnalogBloc extends Bloc<AnalogEvents, AnalogStates> {
  final AnalogRepository analogRepository;

  AnalogBloc({required this.analogRepository}) : super(const AnalogInitial()) {
    on<FetchAnalogsEvent>((event, emit) async {
      emit(const AnalogLoading());
      final result = await analogRepository.loadData();
      result.fold(
        (failure) => emit(AnalogError(failure.message)),
        (data) => emit(FetchAnalogsSuccess(data)),
      );
    });
  }
}
