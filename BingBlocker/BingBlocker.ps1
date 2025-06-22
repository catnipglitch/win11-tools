<#
.SYNOPSIS
    BingBlocker - Bing検索を無効化するツール

.DESCRIPTION
    このスクリプトは、Windowsのレジストリを操作してBing検索を無効化します。
    管理者権限で実行する必要があります。

.NOTES
    作成者: BingBlocker
    バージョン: 1.0
    作成日: 2025/6/22
#>

# 文字コードをUTF-8に設定
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# 管理者権限の確認
function Test-Administrator {
    $currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    $currentUser.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
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
            
            # レジストリエクスポートコマンドを実行
            $regExportCmd = "reg export `"$Path`" `"$backupFile`" /y"
            Invoke-Expression -Command $regExportCmd | Out-Null
            
            Write-Host "レジストリのバックアップが完了しました: $backupFile" -ForegroundColor Green
            return $backupFile
        } else {
            Write-Host "指定されたレジストリパスが存在しないため、バックアップは作成されませんでした。" -ForegroundColor Yellow
            return $null
        }
    } catch {
        Write-Host "レジストリのバックアップ中にエラーが発生しました: $_" -ForegroundColor Red
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
    if (-not (Test-Administrator)) {
        Write-Host "このスクリプトは管理者権限で実行する必要があります。" -ForegroundColor Red
        Write-Host "PowerShellを管理者として実行し、再度スクリプトを実行してください。" -ForegroundColor Red
        return
    }
    
    # レジストリのバックアップ
    $backupFile = Backup-Registry -Path $registryPath
    
    try {
        # レジストリキーの存在確認
        $regPathPS = $registryPath.Replace("HKEY_CURRENT_USER", "HKCU:")
        $explorerPathPS = $explorerPath.Replace("HKEY_CURRENT_USER", "HKCU:")
        
        # Windowsキーの存在確認
        if (-not (Test-Path -Path $regPathPS)) {
            Write-Host "レジストリキー $registryPath が存在しません。作成します..." -ForegroundColor Yellow
            New-Item -Path $regPathPS -Force | Out-Null
        }
        
        # Explorerキーの存在確認
        if (-not (Test-Path -Path $explorerPathPS)) {
            Write-Host "レジストリキー $explorerPath が存在しません。作成します..." -ForegroundColor Yellow
            New-Item -Path $explorerPathPS -Force | Out-Null
        }
        
        # DWORD値の作成/変更
        Set-ItemProperty -Path $explorerPathPS -Name $valueName -Value $valueData -Type DWord -Force
        
        Write-Host "Bing検索が無効化されました。" -ForegroundColor Green
        Write-Host "設定を有効にするには、システムを再起動する必要があります。" -ForegroundColor Yellow
        
        # 再起動の確認
        $restart = Read-Host "今すぐ再起動しますか？ (Y/N)"
        if ($restart -eq "Y" -or $restart -eq "y") {
            Write-Host "システムを再起動します..." -ForegroundColor Yellow
            Restart-Computer -Force
        } else {
            Write-Host "後で手動でシステムを再起動してください。" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "エラーが発生しました: $_" -ForegroundColor Red
        
        if ($backupFile -ne $null) {
            Write-Host "バックアップファイルから復元することができます: $backupFile" -ForegroundColor Yellow
        }
    }
}

# スクリプトの実行
Main