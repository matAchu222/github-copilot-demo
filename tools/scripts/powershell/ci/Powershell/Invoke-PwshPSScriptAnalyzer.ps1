<#
.SYNOPSIS
This script runs the Pwsh PSScriptAnalyzer on all Pwsh files which are provided as input.

.DESCRIPTION
Primariy intended for usage in CI/CD pipelines or as a pre-commit hook.
Input are the Pwsh files to run the linter on and output is the linter result.

.PARAMETER Files
The Pwsh files to run the linter on.
If no files are provided, the script will run on all Pwsh files in the current git directory.

.PARAMETER CheckOnly
If set, the linter will only check the files and not try to fix them.

.EXAMPLE
Invoke-PwshPSScriptAnalyzer.ps1 -Files "C:\path\to\file.ps1", "C:\path\to\other\file.ps1"

- Run the linter on the two files "C:\path\to\file.ps1" and "C:\path\to\other\file.ps1" and list any issue as error.

.EXAMPLE
Invoke-PwshPSScriptAnalyzer.ps1 -CheckOnly

- Run the linter on all Pwsh files in the current git directory and list any issue as error but do not fix them.

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
        HelpMessage = 'Switch to determine if files should be fixed automatically if possible or just checked.',
        Mandatory = $false,
        ValueFromPipeline = $false,
        ValueFromPipelineByPropertyName = $true,
        Position = 1
    )]
    [switch]
    $CheckOnly
)

<# ---------------- Begin main script ---------------- #>

BEGIN {
    try {
        $InformationPreference = 'Continue'
        $ErrorActionPreference = 'Stop'

        Write-Information "Running checks before script execution"
        Write-Verbose "Checking if PSScriptAnalyzer is installed"
        if (-not (Get-Module -ListAvailable -Name PSScriptAnalyzer)) {
            Write-Error "PSScriptAnalyzer is not installed. Please install it with 'Install-Module -Name PSScriptAnalyzer -Scope CurrentUser -Force'"
        }
        Write-Verbose "Checking if Pwsh files are provided"
        if (-not $Files) {
            Write-Verbose "No Pwsh files provided. Getting all Pwsh files in current git directory"
            if (-not (git rev-parse --is-inside-work-tree)) {
                Write-Error "Current directory is not a git repository. Please provide Python files or run the script in a git repository."
            }
            $Files = git ls-files | Where-Object { $_ -like "*.ps1" -or $_ -like "*.psm1" -or $_ -like "*.psd1" }
        }
        Write-Verbose "Ensuring that only valid Pwsh files are provided (ending with .ps1, .psm1 or .psd1)"
        if (($Files | Where-Object { $_ -notlike "*.ps1" -and $_ -notlike "*.psm1" -and $_ -notlike "*.psd1" } | Measure-Object).Count -gt 0) {
            Write-Warning "One or more of the provided files is not a Pwsh file. Only files ending with .ps1, .psm1, and .psd1 are valid."
            Write-Verbose "Filtering out all files which are not Pwsh files"
            $Files = $Files | Where-Object { $_ -like "*.ps1" -or $_ -like "*.psm1" -or $_ -like "*.psd1" }
            if ($Files.Count -eq 0) {
                Write-Warning "No valid Pwsh files provided. Exiting script."
                Exit
            }
        }
    }
    catch {
        $PSCmdlet.ThrowTerminatingError($PSItem)
    }
}

PROCESS {
    try {
        Write-Information "Starting Pwsh linter"
        Write-Verbose "Running on following files: $Files"


        $ScriptAnalyzerSettings = @{
            IncludeDefaultRules = $true
            Fix                 = $true
            Path                = $null
            ErrorAction         = 'Stop'
        }

        if ($CheckOnly) {
            $ScriptAnalyzerSettings.Fix = $false
        }

        foreach ($File in $Files) {
            Write-Verbose "Running linter on file $File"
            $ScriptAnalyzerSettings.Path = $File
            $OutputScriptAnalyzer = Invoke-ScriptAnalyzer @ScriptAnalyzerSettings
            Write-Output $OutputScriptAnalyzer
            if (($OutputScriptAnalyzer | Where-Object { $PSItem.Severity -EQ "Error" -or $PSItem.Severity -eq "Warning" }).Count -gt 0) {
                Write-Error "Linter found errors or warnings in file $File"
            }
        }
    }
    catch {
        $PSCmdlet.ThrowTerminatingError($PSItem)
    }
}

END {
    try {
        Write-Information "Finished linting"
    }
    catch {
        $PSCmdlet.ThrowTerminatingError($PSItem)
    }
}