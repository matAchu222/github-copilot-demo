<#
.SYNOPSIS
This script runs the Python Black formatter on all Python files which are provided as input.

.DESCRIPTION
Primariy intended for usage in CI/CD pipelines or as a pre-commit hook.
Input are the Python files to run the formatter on and output is the formatted files.

.PARAMETER Files
The Python files to run the formatter on.
If no files are provided, the script will run on all Python files in the current git directory.

.PARAMETER CheckOnly
If set, the formatter will only check the files and not modify them.
Any none formatted files will be listed as error.

.EXAMPLE
Invoke-PythonFormatterBlack.ps1 -Files "C:\path\to\file.py", "C:\path\to\other\file.py"

- Run the formatter on the two files "C:\path\to\file.py" and "C:\path\to\other\file.py" and modify them.

.EXAMPLE
Invoke-PythonFormatterBlack.ps1 -CheckOnly

- Run the formatter on all Python files in the current git directory and list any none formatted files as error.

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
        HelpMessage = 'Switch to determine if files should be formatted or just checked.',
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
        Write-Verbose "Checking if Python is installed"
        if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
            Write-Error "Python is not installed. Please install Python and try again."
        }
        elseif ((python -c "import black" 2>&1) -match "No module") {
            Write-Error "Black is not installed. Please install Black and try again."
        }
        Write-Verbose "Checking if Python files are provided"
        if (-not $Files) {
            Write-Verbose "No Python files provided. Getting all Python files in current git directory"
            if (-not (git rev-parse --is-inside-work-tree)) {
                Write-Error "Current directory is not a git repository. Please provide Python files or run the script in a git repository."
            }
            $Files = git ls-files | Where-Object { $_ -like "*.py" }
        }
        Write-Verbose "Ensuring that only valid Python files are provided (ending with .py)"
        if (($Files | Where-Object { $_ -notlike "*.py*" } | Measure-Object).Count -gt 0) {
            Write-Warning "One or more of the provided files is not a Python file. Only files ending with .py* are valid."
            Write-Verbose "Filtering out all files which are not Python files"
            $Files = $Files | Where-Object { $_ -like "*.py*" }
            if ($Files.Count -eq 0) {
                Write-Warning "No valid Python files provided. Exiting script."
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
        Write-Information "Starting Python formatter"
        Write-Verbose "Running on following files: $Files"

        if ($CheckOnly) {
            Write-Verbose "Running formatter in check only mode"
            $OutputBlack = python -m black --check $Files 2>&1 | Out-String
            if ($OutputBlack -match "reformat") {
                Write-Warning $OutputBlack
                Write-Error "One or more files are not formatted. Please run the formatter in modify mode to format the files."
            }
            Write-Information $OutputBlack
        }
        else {
            Write-Verbose "Running formatter in modify mode"
            python -m black $Files
        }
    }
    catch {
        $PSCmdlet.ThrowTerminatingError($PSItem)
    }
}

END {
    try {
        Write-Information "Finished formatting"
    }
    catch {
        $PSCmdlet.ThrowTerminatingError($PSItem)
    }
}