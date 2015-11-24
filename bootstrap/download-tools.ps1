# Function that creates the .\bin\obj\dotnetcli\ directory.
function CreateCliDirectory
{
    New-Item -ItemType Directory -Force -Path $dotNetCliRoot
}

# Function that downloads latest version of dotnet cli and installs it in .\bin\obj\dotnetcli\
function DownloadAndUnZipCli
{
    (New-Object Net.WebClient).DownloadFile('https://dotnetcli.blob.core.windows.net/dotnet/dev/Binaries/Latest/dotnet-win-x64.latest.zip', $dotnetCliRoot + '\dotnet-win-x64.latest.zip')
    (New-Object -com shell.application).namespace($dotnetCliRoot + '').CopyHere((new-object -com shell.application).namespace($dotnetCliRoot + 'dotnet-win-x64.latest.zip').Items(),16)
}

#function RestoreBuildToolsAndDnu
#{
#    & $dotNetCmd restore $projectJson --packages $packagesDir

#    # Remove Version from BuildTools Path
#    Move-Item ($packagesDir + 'Microsoft.DotNet.BuildTools\1.0.25-prerelease-00121\*') ($packagesDir + 'Microsoft.DotNet.BuildTools\')
#    Remove-Item -Path ($packagesDir + 'Microsoft.DotNet.BuildTools\1.0.25-prerelease-00121')

#    # Remove Version from dnu
#    Move-Item ($packagesDir + 'dnx-coreclr-win-x86\1.0.0-rc2-16128\*') ($packagesDir + 'dnx-coreclr-win-x86\')
#    Remove-Item -Path ($packagesDir + 'dnx-coreclr-win-x86\1.0.0-rc2-16128')
#}

function BootstrapBuildTools
{
	$json = @"
{
  "dependencies": {
    "Microsoft.DotNet.BuildTools.Bootstrapper": "$buildToolsVersion"
  },
  "frameworks": {
    "dnxcore50": { },
    "net46": { }
  }
}
"@

	$jsonFolder = Split-Path -Parent $bootstrapperProjectJson
	If (-Not (Test-Path $jsonFolder -PathType Container)) {
		New-Item -ItemType Directory -Force -Path $jsonFolder
	}

	Set-Content $bootstrapperProjectJson $json

	& "$dotnet-restore" $bootstrapperProjectJson --packages $packagesDir

	$RestoreBuildTools = $packagesDir + "Microsoft.DotNet.BuildTools.Bootstrapper\$buildToolsVersion\lib\RestoreBuildTools.ps1"
	Write-Output "Restoring build tools using bootstrapper: $RestoreBuildTools"

	& $RestoreBuildTools -RepoRoot $repoRoot -DotNetCliBin $dotnetCliBin -TargetFramework $targetFramework
	#& $dotNetCmd publish $bootstrapperProjectJson -f $targetFramework -r win7-x64 -o $BuildToolsDir
}

$repoRoot = Split-Path -Parent $PSScriptRoot
$dotnetCliRoot = $repoRoot + '\bin\obj\dotnetcli\'
$dotnetCliBin = $dotnetCliRoot + 'bin\'
$dotnet = $dotnetCliBin + 'dotnet'
#$dotnetCmd = $dotnetCliRoot + 'bin\dotnet.exe'
$bootstrapperProjectJson = $repoRoot + '\bin\obj\bootstrap\project.json'
$packagesDir = $repoRoot + '\packages\'
$buildToolsVersion = '1.0.25-prerelease-01027'
$targetFramework = 'net46'
$BuildToolsDir = $packagesDir + 'Microsoft.DotNet.BuildTools\' + $targetFramework + '\'

# Restore and Unzip dotnet cli if it doesn't exist
If (-Not (Test-Path $dotnetCliRoot)) { CreateCliDirectory }
If (-Not (Test-Path $dotnetCliBin -PathType Container)) { DownloadAndUnZipCli }

BootstrapBuildTools

## Restore BuildTools if they don't exist
#If (-Not (Test-Path $BuildToolsDir)) { RestoreBuildToolsAndDnu }

## Call PublishRuntime
#& ($BuildToolsDir + 'tool-runtime\PublishRuntime.ps1') -ProjectDir $repoRoot