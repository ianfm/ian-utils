# PowerShell script to display instructions

Clear-Host  # Clears the console for a clean output

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "    Set up git tab completions etc.      " -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Cyan

# Define the instructions
$instructions = @(
    "1. Open PowerShell as an Administrator",
    "Install-Module posh-git -Scope CurrentUser -Force",
    "2. Run as User",
    "Add-PoshGitToProfile -AllHosts"
)

# Print each instruction with formatting
foreach ($instruction in $instructions) {
    Write-Host $instruction -ForegroundColor Yellow
}

Write-Host ""  # Add a newline for readability"
