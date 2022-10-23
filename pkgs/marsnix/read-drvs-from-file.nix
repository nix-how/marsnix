let
  b = builtins;
  # read newline separated drv paths from file.
  text = b.readFile (b.getEnv "DRVS");
  lines = b.filter (x: x != [] && x != "") (b.split "\n" text);

  # load a .drv file so that the evaluator accepts it as derivation
  loadDrv = drvFile:
    {
      name = "";
      type = "derivation";
      drvPath =
        b.appendContext drvFile {"${drvFile}" = {allOutputs = true;};};
      outputName = "out";
    };

  # generate list of derivations
  drvs = map loadDrv lines;
in
  drvs
