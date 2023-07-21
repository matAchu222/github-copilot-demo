<#
.SYNOPSIS
This script runs the Python linter PyLint on all Python files which are provided as input.

.DESCRIPTION
Primariy intended for usage in CI/CD pipelines or as a pre-commit hook.
Input are the Python files to run the linter on and output is the linter results.

.PARAMETER Files
The Python files to run the linter on.
If no files are provided, the script will run on all Python files in the current directory.

.PARAMETER RequiredScore
The minimum score required for the linter to pass.

.EXAMPLE
Invoke-PythonLinterPyLint.ps1 -Files "C:\path\to\file.py", "C:\path\to\other\file.py"

- Run the linter on the two files "C:\path\to\file.py" and "C:\path\to\other\file.py".

.EXAMPLE
Invoke-PythonLinterPyLint.ps1 -RequiredScore 9

- Run the linter on all Python files in the current git repository and fail if the linter score is below 9, as this was changed from the default value.

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
        HelpMessage = 'Defines which linter score is the lowest acceptable level.',
        Mandatory = $false,
        ValueFromPipeline = $false,
        ValueFromPipelineByPropertyName = $true,
        Position = 1
    )]
    [ValidateRange(0.00, 10.00)]
    [ValidateScript({ $_ -match '^\d+(\.\d{1,2})?$' })]
    [float]$RequiredScore = 8.00
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
        elseif ((python -c "import pylint" 2>&1) -match "No module") {
            Write-Error "PyLint is not installed. Please install PyLint and try again."
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
        Write-Information "Starting Python linter"
        Write-Verbose "Running on following files: $Files"

        $OutputPyLint = python3.9 -m pylint $Files 2>&1 | Out-String

        [float]$ExtractedScore = ($OutputPyLint | Select-String -Pattern 'Your code has been rated at \d+(\.\d{1,2})?\/10' | Select-Object -Last 1).Matches.Value -replace 'Your code has been rated at ', '' -replace '/10', ''

        if ($ExtractedScore -notmatch '^\d+(\.\d{1,2})?$') {
            Write-Warning $OutputPyLint
            Write-Error "The extracted linter score is not a number. Please check if PyLint output changed and adjust script accordingly."
        }

        if ($ExtractedScore -lt $RequiredScore) {
            Write-Warning $OutputPyLint
            Write-Error "The linter score is with '$ExtractedScore' below the required score of '$RequiredScore'. Please fix the issues and try again."
        }
        Write-Information $OutputPyLint
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