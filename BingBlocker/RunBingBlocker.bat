@echo off
chcp 932 > nul
REM BingBlocker実行バッチファイル
REM 管理者権限でPowerShellスクリプトを実行します

echo BingBlocker - Bing検索を無効化するツール
echo.
echo このツールは管理者権限で実行する必要があります。
echo.

REM 管理者権限で実行
powershell -Command "Start-Process powershell -ArgumentList '-ExecutionPolicy Bypass -File \"%~dp0BingBlocker.ps1\"' -Verb RunAs"

echo.
echo 処理が完了しました。
pause