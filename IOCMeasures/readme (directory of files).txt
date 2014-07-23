Start here for now: FindContrastTradeoffThresholdOksana.m

Main parameter file:
    Parameters.m

Contrast staircase-specific functions:
    FindContrastThreshold.m - ROUGH
    FindContrastThresholdAmb.m - ROUGH
    ContrastStaircaseHelpers.m
    StatModelContrast.m

Contrast tradeoff staircase-specific functions:
    FindContrastTradeoffThresholdOksana.m
    ContrastTradeoffStaircaseHelpers.m
    StatModelContrastTradeoff.m

Dot staircase-specific functions:
    FindDotThreshold.m
    FindDotThersholdIterative.m - INCOMPLETE
    FindDotThreshExperiment.m
    DotStaircaseHelpers.m
    StatModelDots.m

Generic staircase and parameter utility functions:
    FindThreshold.m % main staircase program
    Breaktime.m
    GenericInitStaircase.m
    GenericUpdateHelper.m
    CalcGarciaPerezStaircase.m

Hardware setup and abstraction functions:
    InitializeHardware.m
    CleanupHardware.m
    ScreenCustomStereo.m
    LumToColor.m

Hardware calibration programs:
    DisplayLumForCalibration.m
    Bit-stealing data/DataSetupScript.m

RDK-specific display routine:
    RanDotKgram.m

RDK helper functions:
    RandCos.m

Analysis for signal contrast thresholds vs noise contrasts, mono/dicop'ic
    GraphResults.m - ROUGH
    Reanalyze.m - ROUGH
    QuickAnalyzeTs.m - ROUGH

For convenience in running experiments: Main.m

For testing/debugging/run configurations:
    Test_ScreenCustomStereo.m
    Test_RanDotKgram.m

For incomplete/suspicous code, search for TODO, FIXME, KLUDGE, or HACK
(using the "TODO/FIXME report" feature of MATLAB)
