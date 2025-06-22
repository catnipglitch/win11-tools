<#
.SYNOPSIS
    BingBlocker - Disable Bing Search Tool

.DESCRIPTION
    This script modifies Windows registry to disable Bing search.
    Administrator privileges are required.

.NOTES
    Author: BingBlocker
    Version: 1.0
    Date: 2025/6/22
#>

# 文字コードをUTF-8に設定
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

# 管理者権限の確認
function Test-Administrator {
    $currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentUser.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}

# 管理者権限の確認（バッチファイルで既に確認済み）
function Confirm-Administrator {
    if (-not (Test-Administrator)) {
        Write-Host "This script requires administrator privileges." -ForegroundColor Red
        Write-Host "Please run the RunBingBlocker.bat file as administrator." -ForegroundColor Red
        Write-Host "`nPress any key to exit..." -ForegroundColor Cyan
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        exit
    }
}

# レジストリのバックアップ
function Backup-Registry {
    param (
        [string]$Path,
        [string]$BackupDir = "$env:USERPROFILE\Documents\BingBlockerBackup"
    )

    try {
        # バックアップディレクトリが存在しない場合は作成
        if (-not (Test-Path -Path $BackupDir)) {
            New-Item -Path $BackupDir -ItemType Directory -Force | Out-Null
        }

        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $backupFile = Join-Path -Path $BackupDir -ChildPath "RegistryBackup_$timestamp.reg"
        
        # レジストリのエクスポート
        $regPath = $Path.Replace("HKEY_CURRENT_USER", "HKCU:")
        if (Test-Path -Path $regPath) {
            $parentPath = Split-Path -Path $regPath -Parent
            $leafName = Split-Path -Path $regPath -Leaf
            
            # Execute registry export command
            $regExportCmd = "reg export `"$Path`" `"$backupFile`" /y"
            Invoke-Expression -Command $regExportCmd | Out-Null
            
            Write-Host "Registry backup completed: $backupFile" -ForegroundColor Green
            return $backupFile
        } else {
            Write-Host "The specified registry path does not exist. No backup was created." -ForegroundColor Yellow
            return $null
        }
    } catch {
        Write-Host "Error occurred during registry backup: $_" -ForegroundColor Red
        return $null
    }
}

# メイン処理
function Main {
    # レジストリキーのパス
    $registryPath = "HKEY_CURRENT_USER\Software\Policies\Microsoft\Windows"
    $explorerPath = "$registryPath\Explorer"
    $valueName = "DisableSearchBoxSuggestions"
    $valueData = 1
    
    # 管理者権限の確認
    Confirm-Administrator
    
    # レジストリのバックアップ
    $backupFile = Backup-Registry -Path $registryPath
    
    try {
        # Check registry key existence
        $regPathPS = $registryPath.Replace("HKEY_CURRENT_USER", "HKCU:")
        $explorerPathPS = $explorerPath.Replace("HKEY_CURRENT_USER", "HKCU:")
        
        # Check Windows key existence
        if (-not (Test-Path -Path $regPathPS)) {
            Write-Host "Registry key $registryPath does not exist. Creating..." -ForegroundColor Yellow
            New-Item -Path $regPathPS -Force | Out-Null
        }
        
        # Check Explorer key existence
        if (-not (Test-Path -Path $explorerPathPS)) {
            Write-Host "Registry key $explorerPath does not exist. Creating..." -ForegroundColor Yellow
            New-Item -Path $explorerPathPS -Force | Out-Null
        }
        
        # Create/modify DWORD value
        Set-ItemProperty -Path $explorerPathPS -Name $valueName -Value $valueData -Type DWord -Force
        
        Write-Host "Bing search has been disabled." -ForegroundColor Green
        Write-Host "You need to restart your system to apply the settings." -ForegroundColor Yellow
        
        # Confirm restart
        $restart = Read-Host "Do you want to restart now? (Y/N)"
        if ($restart -eq "Y" -or $restart -eq "y") {
            Write-Host "Restarting system..." -ForegroundColor Yellow
            Restart-Computer -Force
        } else {
            Write-Host "Please restart your system manually later." -ForegroundColor Yellow
        }
    } catch {
        Write-Host "An error occurred: $_" -ForegroundColor Red
        
        if ($backupFile -ne $null) {
            Write-Host "You can restore from the backup file: $backupFile" -ForegroundColor Yellow
        }
    }
}

# スクリプトの実行
Main

# スクリプト終了前に一時停止
Write-Host "`nPress any key to exit..." -ForegroundColor Cyan
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")