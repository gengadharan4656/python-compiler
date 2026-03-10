class AppConstants {
  static const int defaultTimeoutSeconds = 10;
  static const int maxOutputLines = 2000;
  static const int maxFileSizeMB = 20;
  static const double defaultFontSize = 14.0;
  static const int defaultTabWidth = 4;
  static const String channelName = 'com.pydroid.app/python_bridge';
  static const String methodInit = 'initPython';
  static const String methodRun = 'runCode';
  static const String methodStop = 'stopCode';
  static const String methodListPackages = 'listPackages';
  static const String methodEnablePackage = 'enablePackage';
  static const String methodDisablePackage = 'disablePackage';
  static const String outputEventChannel = 'com.pydroid.app/python_output';
}
