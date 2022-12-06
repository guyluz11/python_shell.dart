import "dart:io";

import "package:archive/archive_io.dart";
import "package:dio/dio.dart";
import "package:path/path.dart" as path;

import "config.dart" as config;
import "listener.dart";
import "shell/instance.dart";
import "shell/manager.dart";

/// PythonShell Class
class PythonShell {
  PythonShell(PythonShellConfig shellConfig);

  void clear() => ShellManager.clear();

  Future<void> initialize() async {
    print("Initializing shell...");
    config.defaultPythonVersion =
        config.checkPythonVersion(config.defaultPythonVersion);
    if (!Directory(config.appDir).existsSync())
      Directory(config.appDir).createSync();
    if (!Directory(config.instanceDir).existsSync())
      Directory(config.instanceDir).createSync();
    if (!Directory(config.tempDir).existsSync())
      Directory(config.tempDir).createSync();

    String pythonDir = "";
    if (Platform.isWindows) {
      print("Check default python binary files...");
      pythonDir = path.join(config.appDir, "python");
      if (!Directory(pythonDir).existsSync()) {
        String pythonBinaryFile = path.join(config.tempDir, "python.zip");
        await Dio().download(
            "https://www.python.org/ftp/python/${config.defaultPythonVersion}/python-${config.defaultPythonVersion}-embed-amd64.zip",
            pythonBinaryFile);
        await extractFileToDisk(pythonBinaryFile, pythonDir);
        File(pythonBinaryFile).deleteSync();

        String pythonPthFile = path.join(pythonDir,
            "python${config.defaultPythonVersion.replaceAll(".${config.defaultPythonVersion.split(".").last}", "").replaceAll(".", "")}._pth");
        File(pythonPthFile).writeAsStringSync(File(pythonPthFile)
            .readAsStringSync()
            .replaceAll("#import site", "import site"));
      }
      print("Python check finished.");

      config.defaultPythonPath = path.join(pythonDir, "python.exe");
    }

    if (File(config.defaultPythonPath).existsSync()) {
      print("Default settings for virtualenv...");
      var result = Process.runSync(config.defaultPythonPath,
          ["-m", "pip", "install", "pip", "--upgrade"]);

      if (result.exitCode == 0) {
        print('result Requirements installed successfully.');
      } else {
        print('result Error while installing requirements, exist code '
            '${result.exitCode}\nStdout: ${result.stdout}\n'
            'Stderr: ${result.stderr}');
      }

      if (result.stderr.toString().trim() != "") {
        String pipInstallFile = path.join(config.tempDir, "get-pip.py");

        await Dio().download(
            "https://bootstrap.pypa.io/pip/get-pip.py", pipInstallFile);
        ProcessResult pipInstallFileProcess =
            Process.runSync(config.defaultPythonPath, [pipInstallFile]);

        if (pipInstallFileProcess.exitCode == 0) {
          print('pipInstallFileProcess Requirements installed successfully.');
        } else {
          print(
              'pipInstallFileProcess Error while installing requirements, exist code '
              '${pipInstallFileProcess.exitCode}\nStdout: ${pipInstallFileProcess.stdout}\n'
              'Stderr: ${pipInstallFileProcess.stderr}');
        }

        File(pipInstallFile).deleteSync();
      }

      ProcessResult virtualenvSettings = Process.runSync(
          config.defaultPythonPath,
          ["-m", "pip", "install", "virtualenv", "--upgrade"]);
      print("Virtualenv settings finished.");

      if (virtualenvSettings.exitCode == 0) {
        print('virtualenvSettings Requirements installed successfully.');
      } else {
        print(
            'virtualenvSettings Error while installing requirements, exist code '
            '${virtualenvSettings.exitCode}\nStdout: ${virtualenvSettings.stdout}\n'
            'Stderr: ${virtualenvSettings.stderr}');
      }
    }
    String defaultEnvDir = path.join(config.instanceDir, "default");
    if (!Directory(defaultEnvDir).existsSync()) {
      print("Creating default env...");
      ShellManager.createInstance(instanceName: "default");
      print("Default env created.");
    }

    print("Shell initialized.");
  }

  Future<void> runFile(
    String pythonFile, {
    ShellInstance? instance,
    String? workingDirectory,
    ShellListener? listener,
    bool echo = true,
  }) async {
    instance = instance ?? ShellManager.getInstance("default");
    await instance.runFile(pythonFile,
        workingDirectory: workingDirectory, listener: listener, echo: echo);
  }

  Future<void> runString(
    String pythonCode, {
    List<String> arguments = const [],
    ShellInstance? instance,
    String? workingDirectory,
    ShellListener? listener,
    bool echo = true,
  }) async {
    instance = instance ?? ShellManager.getInstance("default");
    await instance.runString(pythonCode,
        arguments: arguments,
        workingDirectory: workingDirectory,
        listener: listener,
        echo: echo);
  }
}

/// PythonShell Configuration Class
/// * [defaultPythonPath]: Default python path to use
/// * [defaultPythonVersion]: Default python version to use
class PythonShellConfig {
  PythonShellConfig({
    defaultPythonPath = "python3",
    defaultPythonVersion = "3.9.13",
  }) {
    if ((Platform.isLinux || Platform.isMacOS)) {
      if (["python", "python2", "python3"].contains(defaultPythonPath)) {
        config.defaultPythonPath = "/usr/bin/$defaultPythonPath";
      } else if (!File(defaultPythonPath).existsSync()) {
        config.defaultPythonPath = "/usr/bin/python3";
      }
    }
  }
}
