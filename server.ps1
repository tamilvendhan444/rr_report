param(
    [int]$Port = 8080,
    [string]$Root = "d:\rr report"
)

$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$Port/")
$listener.Prefixes.Add("http://127.0.0.1:$Port/")

try {
    $listener.Start()
    Write-Host "Server running at http://localhost:$Port/"
    Write-Host "Serving directory: $Root"
    
    while ($listener.IsListening) {
        $context = $listener.GetContext()
        $request = $context.Request
        $response = $context.Response

        $localPath = $request.Url.LocalPath.TrimStart('/')
        if ([string]::IsNullOrWhiteSpace($localPath)) {
            $localPath = "pressure_players_dashboard.html"
        }

        $filePath = Join-Path $Root $localPath

        if (Test-Path $filePath -PathType Leaf) {
            $bytes = [System.IO.File]::ReadAllBytes($filePath)
            if ($filePath -match "\.html$") {
                $response.ContentType = "text/html; charset=utf-8"
            } elseif ($filePath -match "\.css$") {
                $response.ContentType = "text/css"
            } elseif ($filePath -match "\.js$") {
                $response.ContentType = "application/javascript"
            } elseif ($filePath -match "\.json$") {
                $response.ContentType = "application/json"
            } else {
                $response.ContentType = "application/octet-stream"
            }
            $response.ContentLength64 = $bytes.Length
            $response.OutputStream.Write($bytes, 0, $bytes.Length)
        } else {
            $response.StatusCode = 404
            $notFound = [System.Text.Encoding]::UTF8.GetBytes("404 Not Found")
            $response.OutputStream.Write($notFound, 0, $notFound.Length)
        }
        $response.Close()
    }
} finally {
    $listener.Stop()
}

