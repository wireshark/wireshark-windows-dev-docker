# escape=`

# This assumes that the host has at Qt installed in C:\Qt. Run with
# --volume c:\qt:c:\qt:ro

# Modified from https://code.qt.io/cgit/qbs/qbs.git/plain/docker/windowsservercore/Dockerfile
FROM mcr.microsoft.com/windows/servercore:1809
LABEL Description="Windows Server Core development environment for Wireshark"

USER ContainerAdministrator

# Disable crash dialog for release-mode runtimes
RUN reg add "HKLM\SOFTWARE\Microsoft\Windows\Windows Error Reporting" /v Disabled /t REG_DWORD /d 1 /f
RUN reg add "HKLM\SOFTWARE\Microsoft\Windows\Windows Error Reporting" /v DontShowUI /t REG_DWORD /d 1 /f

# Install Chocolatey.
RUN powershell -NoProfile -ExecutionPolicy Bypass -Command `
    $Env:chocolateyVersion = '0.10.15' ; `
    $Env:chocolateyUseWindowsCompression = 'false' ; `
    "[Net.ServicePointManager]::SecurityProtocol = \"tls12, tls11, tls\"; iex ((New-Object System.Net.WebClient).DownloadString('http://chocolatey.org/install.ps1'))" && SET "PATH=%PATH%;%ALLUSERSPROFILE%\chocolatey\bin"

# Install Visual C++ by hand, since Chocolatey's dotnetfx package is problematic.
# https://stackoverflow.com/a/62953087/82195
RUN powershell -NoProfile -ExecutionPolicy Bypass -Command `
    Invoke-WebRequest "https://aka.ms/vs/16/release/vs_community.exe" `
    -OutFile "%TEMP%\vs_community.exe" -UseBasicParsing

# VS component list:
# https://docs.microsoft.com/en-us/visualstudio/install/workload-component-id-vs-build-tools
# The PD builder has:
# {
#   "version": "1.0",
#   "components": [
#     "Microsoft.VisualStudio.Component.CoreEditor",
#     "Microsoft.VisualStudio.Workload.CoreEditor",
#     "Microsoft.VisualStudio.Component.Roslyn.Compiler",
#     "Microsoft.Component.MSBuild",
#     "Microsoft.VisualStudio.Component.TextTemplating",
#     "Microsoft.VisualStudio.Component.IntelliCode",
#     "Microsoft.VisualStudio.Component.VC.CoreIde",
#     "Microsoft.VisualStudio.Component.VC.Tools.x86.x64",
#     "Microsoft.VisualStudio.Component.Graphics.Tools",
#     "Microsoft.VisualStudio.Component.VC.DiagnosticTools",
#     "Microsoft.VisualStudio.Component.Windows10SDK.18362",
#     "Microsoft.VisualStudio.Component.Debugger.JustInTime",
#     "Microsoft.VisualStudio.Component.VC.Redist.14.Latest",
#     "Microsoft.VisualStudio.ComponentGroup.NativeDesktop.Core",
#     "Microsoft.VisualStudio.ComponentGroup.WebToolsExtensions.CMake",
#     "Microsoft.VisualStudio.Component.VC.CMake.Project",
#     "Microsoft.VisualStudio.Component.VC.ATL",
#     "Microsoft.VisualStudio.Workload.NativeDesktop",
#     "Microsoft.VisualStudio.Component.VC.Redist.MSM"
#   ]
# }
RUN "%TEMP%\vs_community.exe"  --quiet --wait --norestart --noUpdateInstaller `
    --add Microsoft.VisualStudio.Workload.NativeDesktop `
    --add Microsoft.VisualStudio.Workload.VCTools `
    --add Microsoft.VisualStudio.Component.Windows10SDK.18362 `
    --add Microsoft.VisualStudio.Component.VC.Tools.x86.x64 `
    --add Microsoft.VisualStudio.Component.VC.Redist.MSM

# Install various packages.
# XXX AsciidoctrJ requires a jre.
#    choco install -y asciidoctorj xsltproc docbook-bundle && `
RUN choco install -y python3 && `
    choco install -y strawberryperl && `
    choco install -y git && `
    choco install -y cmake && `
    choco install -y winflexbison3 && `
    choco install -y 7zip && `
    setx /M PATH "%PATH%;C:\Program Files\CMake\bin" && `
    setx /M PATH "%PATH%;C:\Strawberry\c\bin;C:\Strawberry\perl\site\bin;C:\Strawberry\perl\bin" && `
    setx /M PATH "%PATH%;C:\Program Files\Git\cmd"

# clcache for speeding up MSVC builds
# ENV CLCACHE_DIR="C:/.ccache"

# Expose the Qt directory.
VOLUME C:\Qt
