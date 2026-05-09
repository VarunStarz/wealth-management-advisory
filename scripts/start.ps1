$root = Split-Path $PSScriptRoot -Parent

$backend = Start-Process -FilePath "$root\.venv\Scripts\python.exe" `
    -ArgumentList "api_server.py" `
    -WorkingDirectory $root `
    -PassThru

Write-Host "Backend started  -> http://localhost:8000  (PID $($backend.Id))"

$frontend = Start-Process -FilePath "$root\ui\node_modules\.bin\vite.cmd" `
    -WorkingDirectory "$root\ui" `
    -PassThru

Write-Host "Frontend started -> http://localhost:5173  (PID $($frontend.Id))"

"$($backend.Id)`n$($frontend.Id)" | Out-File "$PSScriptRoot\.pids" -Encoding utf8
Write-Host "Run stop.ps1 to shut both down."
