<#
.SYNOPSIS
This script manages all available CI scripts.

.DESCRIPTION
The script is responsible for managing all scripts related to CI tasks.
It will be either called locally or by the CI system.

.PARAMETER Files
The files to be processed.

.PARAMETER Context
The context of the files to be processed / the CI origin.

.EXAMPLE
Invoke-HandlerForCI.ps1 -Files "C:\temp\file1.txt", "C:\temp\file2.txt" -Context "CI"

- The script will call all relevant CI scripts for the given files.

.NOTES
Author: Matthias Pfeiffer
Date:   2023-06-22
Version: 1.0

.LINK
https://github.com/matAchu222/github-copilot-demo

.COMPONENT
Requires PowerShell Core 7.0 or above
#>
#Requires -PSEdition Core
#Requires -Version 7.0

[CmdletBinding()]
param (
    [Parameter(
        HelpMessage = 'A string or array of strings with file paths.',
        Mandatory = $false,
        ValueFromPipeline = $true,
        ValueFromPipelineByPropertyName = $true,
        Position = 0
    )]
    [string[]]
    $Files,
    [Parameter(
        HelpMessage = 'A string which describes the context of the files to be processed / the CI origin.',
        Mandatory = $true,
        ValueFromPipeline = $false,
        ValueFromPipelineByPropertyName = $true,
        Position = 1
    )]
    [string]
    $Context
)

<# ---------------- Begin main script ---------------- #>

BEGIN {
    try {
        $InformationPreference = 'Continue'
        $ErrorActionPreference = 'Stop'

        $DirectoryHandler = $MyInvocation.MyCommand.Path | Split-Path -Parent
        $DirectoryCI = ($DirectoryHandler | Split-Path -Parent) | Join-Path -ChildPath "ci"

        Write-Information -MessageData "The CI Handler started."
        $ConfigFile = Join-Path -Path $DirectoryHandler -ChildPath "HandlerForCI.json"
        if (-not (Test-Path -Path $ConfigFile)) {
            Write-Error -Message "The config file '$ConfigFile' does not exist."
        }
        $Config = Get-Content -Path $ConfigFile | ConvertFrom-Json

        if (-not ($Config.subfolders)) {
            Write-Error -Message "The config file '$ConfigFile' does not contain any subfolders."
        }

        foreach ($subfolder in ($Config.subfolders)) {
            $subfolderPath = Join-Path -Path $DirectoryCI -ChildPath $subfolder.name
            if (-not (Test-Path -Path $subfolderPath)) {
                Write-Error -Message "The subfolder '$($subfolder.name)' does not exist."
            }
            if (-not ($subfolder.scripts)) {
                Write-Error -Message "The subfolder '$($subfolder.name)' does not contain any scripts."
            }
            foreach ($Script in $subfolder.scripts) {
                $scriptPath = Join-Path -Path $subfolderPath -ChildPath $Script.name
                if (-not (Test-Path -Path $scriptPath)) {
                    Write-Error -Message "The script '$($Script.name)' does not exist."
                }
            }
        }

        # TODO: Remove demo hack
        # Load current staged git file names manually if the provided string is multiple lines long
        if ($Files -is [string]) {
            $Files = git diff --cached --name-only --diff-filter=ACM
        }
        $Files = git diff --cached --name-only --diff-filter=ACM

        foreach ($File in $Files) {
            if (-not (Test-Path -Path $File)) {
                Write-Error -Message "The file '$File' does not exist."
            }
        }

        if (-not ($Files)) {
            Write-Warning "No files provided. All files in the current git directory will be processed."
            $Files = git ls-files
        }

        Write-Verbose "The following files will be processed: '$($Files -join "', '")'."
    }
    catch {
        $PSCmdlet.ThrowTerminatingError($PSItem)
    }
}

PROCESS {
    try {
        Write-Information -MessageData "The current context is '$Context'."

        foreach ($subfolder in $Config.subfolders) {
            if ($subfolder.allowed_file_types) {
                $FilesForSubfolder = $Files | Where-Object { $subfolder.allowed_file_types -contains (Split-Path -Path $_ -Extension) }
            }
            else {
                $FilesForSubfolder = $Files
            }
            if ($FilesForSubfolder) {
                $subfolderPath = Join-Path -Path $DirectoryCI -ChildPath $subfolder.name
                foreach ($Script in $subfolder.scripts) {
                    $ScriptPath = Join-Path -Path $subfolderPath -ChildPath $Script.name
                    $Parameters = $Script.parameters
                    Write-Information -MessageData "The script '$($Script.name)' will be called with the following parameters:"
                    Write-Information "$ScriptPath -Files $FilesForSubfolder $Parameters"
                    & $ScriptPath -Files $FilesForSubfolder @Parameters
                }
            }
        }
    }
    catch {
        $PSCmdlet.ThrowTerminatingError($PSItem)
    }
}

END {
    try {
        Write-Information -MessageData "The CI Handler finished."
    }
    catch {
        $PSCmdlet.ThrowTerminatingError($PSItem)
    }
}