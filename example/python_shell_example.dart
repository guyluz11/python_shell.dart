import "package:python_shell/python_shell.dart";

void main() async {
  var shell = PythonShell(PythonShellConfig());
  await shell.initialize();

  var instance = ShellManager.getInstance("default");
  instance.installRequires(["aioesphomeapi"]);
  await instance.runString(
    """
print('before')
import os
print('after os')

import aioesphomeapi
print ('after aioesphomeapi')

""",
    echo: true,
  );

  print("finished");
}
