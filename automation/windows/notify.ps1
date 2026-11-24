# Shows a Windows notification. Called by kb_notify in automation/lib.sh.
#   notify.ps1 -Title "Tasks: 1 due today" -Message "Book the MOT"
# Needs Windows PowerShell 5.1 (powershell.exe), which every Windows 10 and 11
# machine has; PowerShell 7 can't load the notification classes this way.
param(
    [string]$Title = 'Knowledge base',
    [string]$Message = ''
)
try {
    $null = [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime]
    $template = [Windows.UI.Notifications.ToastTemplateType]::ToastText02
    $xml = [Windows.UI.Notifications.ToastNotificationManager]::GetTemplateContent($template)
    $texts = $xml.GetElementsByTagName('text')
    $null = $texts.Item(0).AppendChild($xml.CreateTextNode($Title))
    $null = $texts.Item(1).AppendChild($xml.CreateTextNode($Message))
    $toast = New-Object Windows.UI.Notifications.ToastNotification $xml
    # Shown as coming from Windows PowerShell, which is registered on every machine.
    $appId = '{1AC14E77-02E7-4E5D-B744-2EB1AE5198B7}\WindowsPowerShell\v1.0\powershell.exe'
    [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($appId).Show($toast)
} catch {
    Write-Output "Couldn't show a notification: $($_.Exception.Message)"
}
