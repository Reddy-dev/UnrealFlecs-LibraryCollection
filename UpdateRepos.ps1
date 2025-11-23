param(
    [switch]$Commit,                 # Add -Commit to auto-commit changes
    [string]$Message = "chore: update submodules to latest"
)

Write-Host "=== Updating git submodules to latest on their branches ===`n"

if (-not (Test-Path ".git")) {
    Write-Error "This directory does not look like a git repository (no .git folder)."
    exit 1
}

git --version > $null 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Error "git is not available on PATH."
    exit 1
}

if (-not (Test-Path ".gitmodules")) {
    Write-Host "No .gitmodules file found. Nothing to update."
    exit 0
}

Write-Host "Syncing submodule URLs from .gitmodules..."
git submodule sync --recursive
if ($LASTEXITCODE -ne 0) {
    Write-Error "git submodule sync failed."
    exit $LASTEXITCODE
}

Write-Host "Initializing submodules (if needed)..."
git submodule update --init --recursive
if ($LASTEXITCODE -ne 0) {
    Write-Error "git submodule update --init failed."
    exit $LASTEXITCODE
}

Write-Host "Updating submodules to latest remote commit on their branches..."
git submodule update --remote --merge --recursive
if ($LASTEXITCODE -ne 0) {
    Write-Error "git submodule update --remote --merge failed."
    exit $LASTEXITCODE
}

Write-Host "`n=== Submodule status after update ==="
git status --short --branch --submodule

if ($Commit) {
    git diff --quiet --ignore-submodules=dirty
    if ($LASTEXITCODE -eq 0) {
        Write-Host "`nNo changes detected; nothing to commit."
        exit 0
    }

    Write-Host "`nChanges detected. Creating commit..."
    git add .
    git commit -m "$Message"
    if ($LASTEXITCODE -ne 0) {
        Write-Error "git commit failed."
        exit $LASTEXITCODE
    }

    Write-Host "Commit created with message: '$Message'"
}

Write-Host "`nDone."
