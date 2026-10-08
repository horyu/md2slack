# 読み込み方: pwsh -STA を起動し、. ./dev-tools/clipboard-debug.ps1
if (-not $IsWindows) {
  throw "このスクリプトはWindows用です。"
}
if ([System.Threading.Thread]::CurrentThread.GetApartmentState() -ne 'STA') {
  throw "pwsh -STA でPowerShellを起動してください。"
}

Add-Type -AssemblyName System.Windows.Forms

function Show-ClipboardData {
  $data = [System.Windows.Forms.Clipboard]::GetDataObject()

  if ($null -eq $data) {
    Write-Host "クリップボードは空です"
    return
  }

  foreach ($format in $data.GetFormats($false)) {
    Write-Host "`n=== $format ==="

    try {
      $value = $data.GetData($format, $false)

      if ($null -eq $value) {
        Write-Host "(null)"
        continue
      }

      Write-Host "型: $($value.GetType().FullName)"

      if ($value -is [System.IO.Stream]) {
        $originalPosition = $value.Position

        try {
          $value.Position = 0
          $buffer = [System.IO.MemoryStream]::new()
          try {
            $value.CopyTo($buffer)
            $bytes = $buffer.ToArray()
          }
          finally {
            $buffer.Dispose()
          }
        }
        finally {
          $value.Position = $originalPosition
        }

        Write-Host "バイト数: $($bytes.Length)"
        Write-Host "--- 16進数 ---"
        Format-Hex -InputObject $bytes | Out-Host
        Write-Host "--- UTF-8として解釈 ---"
        Write-Host ([System.Text.Encoding]::UTF8.GetString($bytes))
        Write-Host "--- UTF-16LEとして解釈 ---"
        Write-Host ([System.Text.Encoding]::Unicode.GetString($bytes))
      }
      elseif ($value -is [byte[]]) {
        Format-Hex -InputObject $value | Out-Host
      }
      elseif ($value -is [string]) {
        Write-Host $value
      }
      else {
        $value | Format-List * -Force | Out-Host
      }
    }
    catch {
      Write-Host "取得失敗: $($_.Exception.Message)"
    }
  }
}
