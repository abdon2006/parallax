import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:parallax/core/router/app_router.dart';
import 'package:parallax/core/theme/app_theme.dart';
import 'package:parallax/data/repositories/analog_repository.dart';
import 'package:parallax/data/storage/mission_storage.dart';
import 'package:parallax/logic/bloc/analog_bloc.dart';
import 'package:parallax/logic/bloc/analog_events.dart';
import 'package:parallax/logic/bloc/mission_bloc.dart';
import 'package:parallax/logic/bloc/mission_states.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  MissionStorage? storage;
  Map<String, dynamic>? savedMission;
  try {
    storage = await MissionStorage.create();
    savedMission = storage.load();
  } catch (_) {
    // Persistence is optional: the app still works with a fresh session.
  }

  final initialState = savedMission == null
      ? const MissionState()
      : MissionState.fromJson(savedMission);

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) =>
              AnalogBloc(analogRepository: AnalogRepository())
                ..add(const FetchAnalogsEvent()),
        ),
        BlocProvider(
          create: (_) =>
              MissionBloc(initialState: initialState, storage: storage),
        ),
      ],
      child: const ParallaxApp(),
    ),
  );
}

class ParallaxApp extends StatelessWidget {
  const ParallaxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Parallax',
      theme: AppTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      routerConfig: AppRouter.router,
    );
  }
}
