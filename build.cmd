@echo off
setlocal

:: Check prerequisites
if not "%VisualStudioVersion%" == "14.0" (
    echo Error: build.cmd should be run from a Visual Studio 2015 Command Prompt.  
    echo        Please see https://github.com/Microsoft/msbuild/wiki/Building-Testing-and-Debugging for build instructions.
    exit /b 1
)

:: Check for a custom MSBuild path. If not defined, default to the one in your path.
if not defined MSBUILDCUSTOMPATH (
    if "%MSBUILD_RUNTIME_TYPE%" == "Core" (
        set MSBUILDCUSTOMPATH="%~dp0\packages\Microsoft.DotNet.BuildTools\dnxcore50\corerun.exe" "%~dp0\packages\Microsoft.DotNet.BuildTools\dnxcore50\MSBuild.exe"
    ) else (
        set MSBUILDCUSTOMPATH=MSBuild.exe
    )
) else (
    set MSBUILDCUSTOMPATH="%MSBUILDCUSTOMPATH"
)


if not "%MSBUILD_RUNTIME_TYPE%" == "Core" (
    set NODEREUSE=/nodeReuse:false
) else (
    set NODEREUSE=
)

echo ** Restoring build tools
powershell -NoProfile -NoLogo -File %~dp0bootstrap\download-tools.ps1 %*

echo ** MSBuild Path: %MSBUILDCUSTOMPATH%
echo ** Building all sources

:: Call MSBuild
echo ** %MSBUILDCUSTOMPATH% "%~dp0build.proj" /verbosity:minimal %NODEREUSE% /fileloggerparameters:Verbosity=diag;LogFile="%~dp0msbuild.log" %*
%MSBUILDCUSTOMPATH% "%~dp0build.proj" /verbosity:minimal %NODEREUSE% /fileloggerparameters:Verbosity=diag;LogFile="%~dp0msbuild.log" %*
set BUILDERRORLEVEL=%ERRORLEVEL%
echo.

:: Pull the build summary from the log file
findstr /ir /c:".*Warning(s)" /c:".*Error(s)" /c:"Time Elapsed.*" "%~dp0msbuild.log"
echo ** Build completed. Exit code: %BUILDERRORLEVEL%

exit /b %BUILDERRORLEVEL%
