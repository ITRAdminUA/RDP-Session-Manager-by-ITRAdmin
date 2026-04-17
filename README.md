# RDP Session Manager by ITRAdmin

<img width="1107" height="616" alt="image" src="https://github.com/user-attachments/assets/5f5520bb-e241-4b6c-82f2-51afeea91860" />


Simple GUI tool for managing Remote Desktop (RDP) sessions on Windows
servers or workstations.

Built with PowerShell and Windows Forms.

------------------------------------------------------------------------

# 🇬🇧 English

## Description

RDP Session Manager is a lightweight graphical utility for
administrators that allows monitoring and managing active Remote Desktop
sessions.

The tool uses native Windows commands such as: - quser - logoff - msg -
tsdiscon

## Features

-   View active RDP sessions
-   Display username and full name
-   Sort sessions by clicking column headers
-   Highlight session status with colors
-   Shadow (remote control) user session
-   Disconnect session
-   Logoff user
-   Send message to selected user
-   Broadcast message to all sessions
-   Automatic refresh every 5 seconds

## Interface

Columns: - User - Full Name - Session - ID - Status - Idle Time

Color indicators: - Green --- Active session - Yellow --- Disconnected
session - Gray --- System or unknown session

## Requirements

-   Windows Server / Windows 10 / Windows 11
-   PowerShell
-   Administrator privileges recommended
-   Remote Desktop Services

## Run

powershell.exe -ExecutionPolicy Bypass -File RDP-Session-Manager.ps1

------------------------------------------------------------------------

# 🇺🇦 Українська

## Опис

RDP Session Manager --- це легка графічна утиліта для адміністраторів,
яка дозволяє переглядати та керувати активними RDP-сесіями.

Програма використовує стандартні Windows команди: - quser - logoff -
msg - tsdiscon

## Можливості

-   Перегляд активних RDP-сесій
-   Відображення користувача та повного імені
-   Сортування колонок
-   Кольорове відображення статусу
-   Shadow (віддалене керування)
-   Disconnect сесії
-   Logoff користувача
-   Надсилання повідомлення
-   Broadcast повідомлення всім користувачам
-   Автоматичне оновлення кожні 5 секунд

------------------------------------------------------------------------

# 🇷🇺 Русский

## Описание

RDP Session Manager --- простая графическая утилита для администраторов
для управления RDP-сессиями.

Используются стандартные команды Windows: - quser - logoff - msg -
tsdiscon

## Возможности

-   Просмотр RDP-сессий
-   Отображение полного имени пользователя
-   Сортировка колонок
-   Цветовая индикация состояния
-   Shadow подключение
-   Disconnect сессии
-   Logoff пользователя
-   Отправка сообщений
-   Broadcast сообщение всем пользователям
-   Автообновление каждые 5 секунд

------------------------------------------------------------------------

## Author

ITRAdmin
