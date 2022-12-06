$Mime = @"
{
    ".aac": "audio/aac",
    ".abw": "application/x-abiword",
    ".arc": "application/x-freearc",
    ".avif": "image/avif",
    ".avi": "video/x-msvideo",
    ".azw": "application/vnd.amazon.ebook",
    ".bin": "application/octet-stream",
    ".bmp": "image/bmp",
    ".bz": "application/x-bzip",
    ".bz2": "application/x-bzip2",
    ".cda": "application/x-cdf",
    ".csh": "application/x-csh",
    ".css": "text/css",
    ".csv": "text/csv",
    ".doc": "application/msword",
    ".docx": "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
    ".eot": "application/vnd.ms-fontobject",
    ".epub": "application/epub+zip",
    ".gz": "application/gzip",
    ".gif": "image/gif",
    ".htm,": "text/html",
    ".ico": "image/vnd.microsoft.icon",
    ".ics": "text/calendar",
    ".jar": "application/java-archive",
    ".jpeg,": "image/jpeg",
    ".js": "text/javascript",
    ".json": "application/json",
    ".jsonld": "application/ld+json",
    ".mid,": "audio/x-midi",
    ".mjs": "text/javascript",
    ".mp3": "audio/mpeg",
    ".mp4": "video/mp4",
    ".mpeg": "video/mpeg",
    ".mpkg": "application/vnd.apple.installer+xml",
    ".odp": "application/vnd.oasis.opendocument.presentation",
    ".ods": "application/vnd.oasis.opendocument.spreadsheet",
    ".odt": "application/vnd.oasis.opendocument.text",
    ".oga": "audio/ogg",
    ".ogv": "video/ogg",
    ".ogx": "application/ogg",
    ".opus": "audio/opus",
    ".otf": "font/otf",
    ".png": "image/png",
    ".pdf": "application/pdf",
    ".php": "application/x-httpd-php",
    ".ppt": "application/vnd.ms-powerpoint",
    ".pptx": "application/vnd.openxmlformats-officedocument.presentationml.presentation",
    ".rar": "application/vnd.rar",
    ".rtf": "application/rtf",
    ".sh": "application/x-sh",
    ".svg": "image/svg+xml",
    ".tar": "application/x-tar",
    ".tif,": "image/tiff",
    ".ts": "video/mp2t",
    ".ttf": "font/ttf",
    ".txt": "text/plain",
    ".vsd": "application/vnd.visio",
    ".wav": "audio/wav",
    ".weba": "audio/webm",
    ".webm": "video/webm",
    ".webp": "image/webp",
    ".woff": "font/woff",
    ".woff2": "font/woff2",
    ".xhtml": "application/xhtml+xml",
    ".xls": "application/vnd.ms-excel",
    ".xlsx": "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
    ".xml": "text/xml",
    ".xul": "application/vnd.mozilla.xul+xml",
    ".zip": "application/zip",
    ".7z": "application/x-7z-compressed"
}
"@ | ConvertFrom-Json

$listener = New-Object System.Net.HttpListener
$workpath = $PWD.Path
$ip = "http://+:80/"
$listener.Prefixes.Add($ip)
$listener.Start()
Write-Host ("Сервер запущен : " + $listener.Prefixes[0])

do {
    $Context = $listener.GetContext()
    $URL = $Context.Request.Url.LocalPath.substring(1)
    $FullPath = $workpath + "\" + $URL.Replace("/", "\")

    Write-Host ($Context.Request.UserHostName + " запрашивает " + $URL)

    if ($URL.Equals("stop")) {
        $buffer = [System.Text.Encoding]::UTF8.GetBytes("Done!")
        $context.Response.ContentLength64 = $buffer.Length
        $context.Response.OutputStream.Write($buffer, 0, $buffer.Length) 
        $context.Response.OutputStream.Close()
        $listener.Stop()
        $listener.Close()
    }

    $Context.Response.StatusCode = 404
    $buffer = [System.Text.Encoding]::UTF8.GetBytes("<h1>Файл не найден!</h1>")
    $Context.Response.ContentType = "text/html;charset=UTF-8"
    if (Test-Path -Path $FullPath -PathType Container) {
        [string]$html = "<h1>" + $FullPath + "</h1><ul>" 
        Get-ChildItem -Path $FullPath | ForEach-Object {
            $label = $_.NameString
            $html += "<li><a href='" + $URL + "/" + $label + "'>" + $label + "</a></li>"
        }
        $html += "</ul>"
        $buffer = [System.Text.Encoding]::UTF8.GetBytes($html)
        $Context.Response.StatusCode = 200
    }
    elseif (Test-Path -Path $FullPath -PathType Leaf) {
        $buffer = [System.IO.File]::ReadAllBytes($FullPath)
        $mtype = $Mime.("." + $FullPath.Split(".")[-1])
        if ($mtype) { 
            $Context.Response.ContentType = $mtype 
        }
        else {
            $Context.Response.ContentType = "application/octet-stream"
        }
        $Context.Response.StatusCode = 200
    }
    $context.Response.ContentLength64 = $buffer.Length
    $context.Response.OutputStream.Write($buffer, 0, $buffer.Length) 
    $context.Response.OutputStream.Close()
}while ($listener.IsListening)
