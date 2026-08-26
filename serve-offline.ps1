$ErrorActionPreference = "Stop"
$Root = (Split-Path -Parent $MyInvocation.MyCommand.Path)
$Port = 8000
$Listener = [System.Net.HttpListener]::new()
$Listener.Prefixes.Add("http://localhost:$Port/")

try {
  $Listener.Start()
} catch {
  Write-Host "Não foi possível iniciar o servidor local na porta $Port." -ForegroundColor Red
  Write-Host "Tente abrir index.html diretamente com Chrome ou Edge." -ForegroundColor Yellow
  Read-Host "Pressione Enter para fechar"
  exit 1
}

$MimeTypes = @{
  ".html" = "text/html; charset=utf-8"
  ".js" = "text/javascript; charset=utf-8"
  ".css" = "text/css; charset=utf-8"
  ".png" = "image/png"
  ".jpg" = "image/jpeg"
  ".jpeg" = "image/jpeg"
  ".webp" = "image/webp"
  ".svg" = "image/svg+xml"
  ".json" = "application/json; charset=utf-8"
  ".webmanifest" = "application/manifest+json"
  ".txt" = "text/plain; charset=utf-8"
  ".woff" = "font/woff"
  ".woff2" = "font/woff2"
}

Start-Process "http://localhost:$Port/"
Write-Host "Sphere World aberto em http://localhost:$Port/" -ForegroundColor Green
Write-Host "Mantenha esta janela aberta enquanto estiver jogando." -ForegroundColor Yellow
Write-Host "Feche esta janela para encerrar o jogo." -ForegroundColor Yellow

try {
  while ($Listener.IsListening) {
    $Context = $Listener.GetContext()
    $RelativePath = [System.Uri]::UnescapeDataString($Context.Request.Url.AbsolutePath.TrimStart('/'))
    if ([string]::IsNullOrWhiteSpace($RelativePath)) { $RelativePath = "index.html" }
    $RelativePath = $RelativePath.Replace('/', [System.IO.Path]::DirectorySeparatorChar)
    $FullPath = [System.IO.Path]::GetFullPath((Join-Path $Root $RelativePath))
    $RootWithSeparator = $Root.TrimEnd([System.IO.Path]::DirectorySeparatorChar) + [System.IO.Path]::DirectorySeparatorChar

    if ($FullPath.StartsWith($RootWithSeparator, [System.StringComparison]::OrdinalIgnoreCase) -and (Test-Path -LiteralPath $FullPath -PathType Leaf)) {
      $Bytes = [System.IO.File]::ReadAllBytes($FullPath)
      $Extension = [System.IO.Path]::GetExtension($FullPath).ToLowerInvariant()
      if ($MimeTypes.ContainsKey($Extension)) { $Context.Response.ContentType = $MimeTypes[$Extension] }
      $Context.Response.ContentLength64 = $Bytes.Length
      $Context.Response.StatusCode = 200
      $Context.Response.OutputStream.Write($Bytes, 0, $Bytes.Length)
    } else {
      $Context.Response.StatusCode = 404
    }
    $Context.Response.Close()
  }
} finally {
  $Listener.Stop()
  $Listener.Close()
}
