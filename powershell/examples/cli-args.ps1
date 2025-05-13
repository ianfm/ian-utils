# Basic CLI arg handling example
# Convert Windows-style path argument to vscode-syle pathk

# Check for args
if ($args.Count -eq 0) {
    Write-Output "Please provide a path as an argument."
    exit
}

# Convert path and print it
$InputPath = $args[0]
$OutputPath = $InputPath -replace '\\', '/'
Write-Host $OutputPath