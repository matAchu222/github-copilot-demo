<#
.SYNOPSIS
This script runs the Terraform formatter on all Terraform files which are provided as input.

.DESCRIPTION
Primariy intended for usage in CI/CD pipelines or as a pre-commit hook.
Input are the Terraform files to run the formatter on and output are the formatted files.

.PARAMETER Files
The Terraform files to run the formatter on.
If no files are provided, the script will run on all Terraform files in the current git directory.

.PARAMETER CheckOnly
If set, the formatter will only check the files and not modify them.

.EXAMPLE
Invoke-TerraformFormat.ps1 -Files "C:\path\to\file.tf", "C:\path\to\other\file.tf"

- Run the formatter on the two files "C:\path\to\file.tf" and "C:\path\to\other\file.tf" and modify them.

.EXAMPLE
Invoke-TerraformFormat.ps1 -CheckOnly

- Run the formatter on all Terraform files in the current git directory and list any none formatted files as error.

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
        Write-Verbose "Checking if Terraform is installed"
        if (-not (Get-Command terraform -ErrorAction SilentlyContinue)) {
            Write-Error "Terraform is not installed. Please install Terraform and try again."
        }

        Write-Verbose "Checking if Terraform files are provided"
        if (-not $Files) {
            Write-Verbose "No Terraform files provided. Getting all Terraform files in current git directory"
            if (-not (git rev-parse --is-inside-work-tree)) {
                Write-Error "Current directory is not a git repository. Please provide Python files or run the script in a git repository."
            }
            $Files = git ls-files | Where-Object { $_ -like "*.tf" }
        }
        Write-Verbose "Ensuring that only valid Terraform files are provided (ending with .tf)"
        if (($Files | Where-Object { $_ -notlike "*.tf" } | Measure-Object).Count -gt 0) {
            Write-Warning "One or more of the provided files is not a Terraform file. Only files ending with .tf are valid."
            Write-Verbose "Filtering out all files which are not Terraform files"
            $Files = $Files | Where-Object { $_ -like "*.tf" }
            if ($Files.Count -eq 0) {
                Write-Warning "No valid Terraform files provided. Exiting script."
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
        Write-Information "Starting Terraform formatter"
        Write-Verbose "Running on following files: $Files"

        if ($CheckOnly) {
            Write-Verbose "Running Terraform formatter in check mode"
            $OutputTerraform = terraform fmt -check $Files 2>&1 | Out-String
            if ($OutputTerraform) {
                Write-Warning $OutputTerraform
                Write-Error "Terraform files are not formatted correctly. Please run the Terraform formatter on the files and try again."
            }
        }
        else {
            Write-Verbose "Running Terraform formatter in format mode"
            terraform fmt $Files
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