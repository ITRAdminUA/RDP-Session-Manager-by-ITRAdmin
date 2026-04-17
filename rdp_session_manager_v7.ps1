Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# ---------------------------------------
# Кэш Full Name локальных пользователей
$global:UserFullNames = @{}
Get-WmiObject Win32_UserAccount | Where-Object { $_.LocalAccount -eq $true } |
ForEach-Object {
    $global:UserFullNames[$_.Name] = if ($_.FullName) { $_.FullName } else { $_.Name }
}

# ---------------------------------------
# Главное окно
$form = New-Object Windows.Forms.Form
$form.Text = "RDP Session Manager by ITRAdmin v1.7"
$form.Size = New-Object Drawing.Size(900,500)

# ListView
$list = New-Object Windows.Forms.ListView
$list.View = 'Details'
$list.FullRowSelect = $true
$list.GridLines = $true
$list.Dock = 'Fill'
$list.Height = 350

$list.Columns.Add("User",120)
$list.Columns.Add("Full Name",180)   # 👈 НОВАЯ КОЛОНКА
$list.Columns.Add("Session",120)
$list.Columns.Add("ID",50)
$list.Columns.Add("Status",100)
$list.Columns.Add("Idle",100)

$form.Controls.Add($list)

# ---------------------------------------
# Сортировка ListView
$global:IsLoading = $false
$global:SortColumn = 0
$global:SortOrder = [System.Windows.Forms.SortOrder]::Ascending

function Sort-ListView {
    param([System.Windows.Forms.ListView]$lv)
    
    $items = @()
    foreach ($item in $lv.Items) { $items += $item }

    $items = $items | Sort-Object -Property {
        $val = $_.SubItems[$global:SortColumn].Text
        if ($val -match '^\d+$') { [int]$val } else { $val }
    } -Descending:($global:SortOrder -eq [System.Windows.Forms.SortOrder]::Descending)

    $lv.Items.Clear()
    foreach ($item in $items) { $lv.Items.Add($item) }
}

$list.Add_ColumnClick({
    param($sender,$e)
    if ($global:SortColumn -eq $e.Column) {
        $global:SortOrder = if ($global:SortOrder -eq [System.Windows.Forms.SortOrder]::Ascending) {
            [System.Windows.Forms.SortOrder]::Descending
        } else {
            [System.Windows.Forms.SortOrder]::Ascending
        }
    } else {
        $global:SortColumn = $e.Column
        $global:SortOrder = [System.Windows.Forms.SortOrder]::Ascending
    }
    Sort-ListView -lv $list
})

# ---------------------------------------
# Получение сессий
function Get-Sessions {
try { [Console]::OutputEncoding = [System.Text.Encoding]::GetEncoding(866) } catch {}
    $sessions = @()
    $raw = quser 2>$null | Select-Object -Skip 1
    foreach ($line in $raw) {
        $line = $line.Trim()
        $parts = $line -split '\s+',5
        if ($parts.Count -ge 4) {
            $id = $parts[2]
            if ($id -notmatch '^\d+$') { $id = $null }
            $sessions += [PSCustomObject]@{
                User = $parts[0]
                Session = $parts[1]
                ID = $id
                Status = $parts[3]
                Idle = if ($parts.Count -ge 5) { $parts[4] } else { "" }
            }
        }
    }
    return $sessions
}

# ---------------------------------------
# Загрузка сессий
function Load-Sessions {

    if ($global:IsLoading) { return }
    $global:IsLoading = $true

    try {
        $selectedUsers = @()
        foreach ($item in $list.SelectedItems) { $selectedUsers += $item.SubItems[0].Text }

        $sortCol = $global:SortColumn
        $sortOrder = $global:SortOrder

        $list.BeginUpdate()
        $list.Items.Clear()

        $sessions = Get-Sessions

        foreach ($s in $sessions) {

            $fullName = if ($global:UserFullNames.ContainsKey($s.User)) {
                $global:UserFullNames[$s.User]
            } else {
                $s.User
            }

            $item = New-Object Windows.Forms.ListViewItem($s.User)
            $item.SubItems.Add($fullName)
            $item.SubItems.Add($s.Session)

            $sessionID = if ($s.ID) { $s.ID } else { "" }
            $item.SubItems.Add($sessionID)
            $item.SubItems.Add($s.Status)
            $item.SubItems.Add($s.Idle)

            if ($s.Status -eq "Active") { 
                $item.BackColor = 'LightGreen' 
            } elseif ($s.ID -eq $null) {
                $item.BackColor = 'LightGray'
            } else {
                $item.BackColor = 'Khaki'
            }

            $list.Items.Add($item)

            if ($selectedUsers -contains $s.User) { $item.Selected = $true }
        }

        $global:SortColumn = $sortCol
        $global:SortOrder = $sortOrder

        Sort-ListView -lv $list
        $list.EndUpdate()
    }
    catch {
        # ❗ ВАЖНО — не спамим окна
        # можно лог писать в файл при желании
    }
    finally {
        $global:IsLoading = $false
    }
}

# ---------------------------------------
# Получение выбранной сессии
function Get-SelectedSession {
    if ($list.SelectedItems.Count -eq 0) { return $null }

    $idText = $list.SelectedItems[0].SubItems[3].Text   # 👈 сдвиг
    $sessionName = $list.SelectedItems[0].SubItems[2].Text

    if ($idText -match '^\d+$') { return $idText } else { return $sessionName }
}

# ---------------------------------------
# GUI InputBox
function Show-InputBox($prompt, $title) {
    $formBox = New-Object Windows.Forms.Form
    $formBox.Text = $title
    $formBox.Size = New-Object Drawing.Size(400,150)
    $formBox.StartPosition = "CenterParent"
    $formBox.TopMost = $true

    $txt = New-Object Windows.Forms.TextBox
    $txt.Width = 350
    $txt.Location = New-Object Drawing.Point(20,20)
    $formBox.Controls.Add($txt)

    $btnOK = New-Object Windows.Forms.Button
    $btnOK.Text = "OK"
    $btnOK.Location = New-Object Drawing.Point(150,60)
    $btnOK.Add_Click({ $formBox.Tag = $txt.Text; $formBox.Close() })
    $formBox.Controls.Add($btnOK)

    $formBox.ShowDialog($form)  
    return $formBox.Tag
}

# ---------------------------------------
# Панель кнопок
$panel = New-Object Windows.Forms.FlowLayoutPanel
$panel.Dock = 'Bottom'
$panel.Height = 80

# Shadow
$btnShadow = New-Object Windows.Forms.Button
$btnShadow.Text = "Shadow"
$btnShadow.BackColor = 'LightBlue'
$btnShadow.Add_Click({
    $sel = Get-SelectedSession
    if ($sel) {
        try {
            Get-Process mstsc -ErrorAction SilentlyContinue |
                Where-Object { $_.MainWindowTitle -like "*Shadow*" } |
                Stop-Process -Force -ErrorAction SilentlyContinue

            Start-Process "mstsc.exe" -ArgumentList "/shadow:$sel /control /noConsentPrompt"
        } catch {
            [System.Windows.Forms.MessageBox]::Show("Не удалось подключиться к сессии: $_")
        }
    } else {
        [System.Windows.Forms.MessageBox]::Show("Выберите сессию")
    }
})
$panel.Controls.Add($btnShadow)

# Refresh
$btnRefresh = New-Object Windows.Forms.Button
$btnRefresh.Text = "Refresh"
$btnRefresh.Add_Click({ Load-Sessions })
$panel.Controls.Add($btnRefresh)

# Logoff
$btnLogoff = New-Object Windows.Forms.Button
$btnLogoff.Text = "Logoff"
$btnLogoff.BackColor = 'Tomato'

$btnLogoff.Add_Click({
    if ($list.SelectedItems.Count -eq 0) { return }

    foreach ($item in $list.SelectedItems) {
        $idText = $item.SubItems[3].Text
        try {
            if ($idText -match '^\d+$') {
                logoff $idText
            } else {
                logoff $item.SubItems[2].Text
            }
        } catch {}
    }

    Load-Sessions
})
$panel.Controls.Add($btnLogoff)

# Disconnect
$btnDisc = New-Object Windows.Forms.Button
$btnDisc.Text = "Disconnect"
$btnDisc.BackColor = 'Orange'
$btnDisc.Add_Click({
    try { $sel = Get-SelectedSession; if ($sel) { tsdiscon $sel; Load-Sessions } } catch {}
})
$panel.Controls.Add($btnDisc)

# Message User
$btnMsg = New-Object Windows.Forms.Button
$btnMsg.Text = "Message User"
$btnMsg.Add_Click({
    try {
        $sel = Get-SelectedSession
        if ($sel) {
            $msg = Show-InputBox "Введите сообщение" "Message"
            if ($msg) { msg $sel $msg }
        }
    } catch {}
})
$panel.Controls.Add($btnMsg)

# Message All
$btnMsgAll = New-Object Windows.Forms.Button
$btnMsgAll.Text = "Message All"
$btnMsgAll.Add_Click({
    try {
        $msg = Show-InputBox "Введите сообщение всем" "Broadcast"
        if ($msg) {
            $sessions = Get-Sessions | Where-Object { $_.ID -ne $null }
            foreach ($s in $sessions) { try { msg $s.ID $msg } catch {} }
        }
    } catch {}
})
$panel.Controls.Add($btnMsgAll)

$form.Controls.Add($panel)

# ---------------------------------------
# Таймер
$timer = New-Object Windows.Forms.Timer
$timer.Interval = 5000
$timer.Add_Tick({
    try { Load-Sessions } catch {}
})
$timer.Start()

# ---------------------------------------
# Запуск
Load-Sessions
[void]$form.ShowDialog()