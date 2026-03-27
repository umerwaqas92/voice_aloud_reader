import 'runtime_flags_impl.dart'
    if (dart.library.io) 'runtime_flags_io.dart'
    if (dart.library.html) 'runtime_flags_web.dart';

bool get isInTest => isInTestImpl;
