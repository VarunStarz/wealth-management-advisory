$pidFile = "$PSScriptRoot\.pids"

if (-not (Test-Path $pidFile)) {
    Write-Host "No running session found (.pids missing)."
    exit 0
}

Get-Content $pidFile | Where-Object { $_.Trim() } | ForEach-Object {
    $id = [int]$_.Trim()
    try {
        Stop-Process -Id $id -Force -ErrorAction Stop
        Write-Host "Stopped PID $id"
    } catch {
        Write-Host "PID $id already stopped or not found"
    }
}

Remove-Item $pidFile -Force
Write-Host "All processes stopped."
