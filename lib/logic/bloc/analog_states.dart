import 'package:equatable/equatable.dart';
import 'package:parallax/data/models/analogs_data.dart';

abstract class AnalogStates extends Equatable {
  const AnalogStates();
}

class AnalogLoading extends AnalogStates {
  const AnalogLoading();

  @override
  List<Object?> get props => [];
}

class AnalogInitial extends AnalogStates {
  const AnalogInitial();

  @override
  List<Object?> get props => [];
}

class FetchAnalogsSuccess extends AnalogStates {
  final AnalogsData data;

  const FetchAnalogsSuccess(this.data);

  @override
  List<Object?> get props => [data];
}

class AnalogError extends AnalogStates {
  final String message;

  const AnalogError(this.message);

  @override
  List<Object?> get props => [message];
}
