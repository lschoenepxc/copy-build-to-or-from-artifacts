param (
    [switch]$CopyBuildToArtifacts,

    [switch]$RestoreBuildFromArtifacts
)

# ps1 from composite action
Write-Host "Goodbye!";

# Folder Paths
$RootPath = $MyInvocation.PSScriptRoot;

# Artifacts
$ArtifactsDir = "$RootPath\artifacts";

# Build
$BuildArtifacts = "$ArtifactsDir\Build";
$CommercialBuildArtifacts = "$ArtifactsDir\BuildCommercial";

function Initialize {
    Write-Step "Initializing"

    # First check the powershell version
    if ($PSVersionTable.PSVersion.Major -lt 5) {
        Write-Host ("The needed major powershell version for this script is 5. Your version: " + ($PSVersionTable.PSVersion.ToString()))
        exit 1;
    }

    # Initialize Folders
    CreateFolderIfNotExists $ArtifactsDir;
    CreateFolderIfNotExists $BuildArtifacts;

    # Environment Variable Defaults
    if (-not $env:MORYX_BUILD_CONFIG) {
        $env:MORYX_BUILD_CONFIG = "Debug";
    }

    if (-not $env:MORYX_COMMERCIAL_BUILD) {
        $env:MORYX_COMMERCIAL_BUILD = $False;
    }


    # Printing Variables
    Write-Step "Printing global variables"
    Write-Variable "RootPath" $RootPath;

    Write-Step "Printing environment variables"
    Write-Variable "MORYX_BUILD_CONFIG" $env:MORYX_BUILD_CONFIG;
    Write-Variable "MORYX_COMMERCIAL_BUILD" $env:MORYX_COMMERCIAL_BUILD;
}

function CopyBuildToArtifacts([string]$TargetPath){
    Write-Step "Going into Copy Build To Artifacts";
    # ForEach($csprojItem in Get-ChildItem $SearchPath -Recurse -Include "*.csproj") { 
    #     # Check if the project should be packed
    #     if (-not (ShouldCreatePackage $csprojItem)) { continue; }

    #     $projectName = ([System.IO.Path]::GetFileNameWithoutExtension($csprojItem.Name));
    #     $assemblyPath = [System.IO.Path]::Combine($csprojItem.DirectoryName, "bin", $env:MORYX_BUILD_CONFIG);
        
    #     # Remove `staticwebassets.runtime.json` since it has no relevance for 
    #     # publishing but would break the build
    #     Get-ChildItem -Path $assemblyPath -Recurse -Filter "*.staticwebassets.runtime.json" | 
    #         ForEach-Object { Remove-Item $_.FullName -Force }

    #     # Check if the project was build
    #     If(-not (Test-Path $assemblyPath)){ continue; }

    #     $assemblyArtifactPath = [System.IO.Path]::Combine($TargetPath, $projectName, "bin", $env:MORYX_BUILD_CONFIG);
    #     CopyAndReplaceFolder $assemblyPath $assemblyArtifactPath;

    #     $objPath = [System.IO.Path]::Combine($csprojItem.DirectoryName, "obj");
    #     $objArtifactPath = [System.IO.Path]::Combine($TargetPath, $projectName, "obj");
    #     CopyAndReplaceFolder $objPath $objArtifactPath;
    #     Write-Host "Copied build of $csprojItem to artifacts..." 
    # }
}

function RestoreBuildFromArtifacts {
    Write-Step "Going into Restore Build from artifacts";

    # Create txt for test with artifacts path
    New-Item $BuildArtifacts\test.txt;
    Set-Content $BuildArtifacts\test.txt 'Test for artifacts. Laura Schoene'
    # Restore build artifacts to project (only one project at a time)
    # foreach ($CsprojItem in Get-ChildItem $RootPath -Recurse -Filter *.csproj) {
    #     if (-not (ShouldCreatePackage $CsprojItem)) { return; }

    #     Write-Host "Copy build of $CsprojItem from artifacts..." 
    #     $artifacts = (&{If($env:MORYX_COMMERCIAL_BUILD -eq $True) {$CommercialBuildArtifacts} Else {$BuildArtifacts}});
    #     $buildPath = [System.IO.Path]::Combine($CsprojItem.DirectoryName, "bin", $env:MORYX_BUILD_CONFIG);
    #     $projectBinArtifacts = [System.IO.Path]::Combine($artifacts, $projectName, "bin", $env:MORYX_BUILD_CONFIG);
    #     CopyAndReplaceFolder $projectBinArtifacts $buildPath;
    #     $objPath = [System.IO.Path]::Combine($CsprojItem.DirectoryName, "obj");
    #     $projectObjArtifacts = [System.IO.Path]::Combine($artifacts, $projectName, "obj");
    #     CopyAndReplaceFolder $projectObjArtifacts $objPath;
    # }
}

function ShouldCreatePackage($csprojItem){
    $csprojFullName = $csprojItem.FullName;
    [xml]$csprojContent = Get-Content $csprojFullName
    $createPackage = $csprojContent.Project.PropertyGroup | Where-Object {-not ($null -eq $_.CreatePackage)} | ForEach-Object{$_.CreatePackage}
    if ($null -eq $createPackage -or "false" -eq $createPackage) {
        Write-Host-Warning "Skipping $csprojItem..."
        return $False;
    }
    return $True;
}

function CreateFolderIfNotExists([string]$Folder) {
    if (-not (Test-Path $Folder)) {
        Write-Host "Creating missing directory '$Folder'"
        New-Item $Folder -Type Directory | Out-Null
    }
}

function CopyAndReplaceFolder([string]$SourceDir, [string]$TargetDir) {
    # Remove old folder if exists
    if (Test-Path $TargetDir) {
        Write-Host "Target path already exists, replacing ..." -ForegroundColor Yellow
        Remove-Item -Recurse -Force $TargetDir
    }

    # Copy to target path
    Copy-Item -Path $SourceDir -Recurse -Destination $TargetDir -Container
}

function Write-Step([string]$step) {
    Write-Host "########################################################################################################" -foreground Magenta;
    Write-Host "#### $step" -foreground Magenta;
    Write-Host "########################################################################################################" -foreground Magenta
}

function Write-Variable ([string]$variableName, [string]$variableValue) {
    Write-Host ($variableName + " = " + $variableValue)
}

# Initialize Toolkit
Initialize;

if ($CopyBuildToArtifacts) {
    CopyBuildToArtifacts (&{If($env:MORYX_COMMERCIAL_BUILD -eq $True) {$CommercialBuildArtifacts} Else {$BuildArtifacts}})
}

if ($RestoreBuildFromArtifacts) {
    RestoreBuildFromArtifacts
}