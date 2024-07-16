param(
    [Parameter(Mandatory=$true)]
    [string]$InputPath
)
# param ABSOLUTELY MUST be at the top of the file or you will get an error. 
# Note that this comment is after the param entry...

# SCRIPT:   codify-path.ps1
# PURPOSE:  Take a Windows-style path (e.g. from copy path) and 
#           format it for compaitbility with vscode settings syntax
# AUTHOR:   Ian McMurray

# Usage: .\codify-path.ps1 -InputPath "C:\Users\ianfm\Source\amiga-dev-kit\circuitpy\lib"

# Perform the path conversion
$OutputPath = $InputPath -replace '\\', '/'
Write-Output "VSCode Path: $OutputPath"
