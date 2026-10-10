# Ручні кроки після прогону: Invoke-PostInstall.ps1 друкує їх наприкінці (Show-ManualSteps) і зберігає
# у текстовий файл поруч із журналом. Це ЄДИНЕ місце, де ведеться перелік (README лише посилається сюди).
#
# Формат запису: @{ Group = <розділ>; Title = <що зробити>; Task = <задача>; How = @(<кроки>) }
#   * Розділи друкуються в порядку першої появи; телеметрія - першою.
#   * Task (необов'язково): крок показується, лише якщо ця задача виконувалась у прогоні (не SKIPPED).
#     Без Task - показується завжди.
@{
    Steps = @(
        # --- Телеметрія: те, що скрипт не може вимкнути сам (налаштування всередині програм і акаунтів)
        @{ Group = 'Телеметрія і приватність'; Task = 'Configuration'
           Title = 'Windows: перевірити, що вимкнення телеметрії застосувалось'
           How = @(
               'Скрипт уже вимкнув телеметрію (O&O ShutUp10, політики, служба DiagTrack) - тут лише перевірка.'
               'Параметри -> Конфіденційність і безпека -> Діагностика та відгуки:'
               '  "Надсилати додаткові діагностичні дані" - вимкнено; "Персоналізовані можливості" - вимкнено;'
               '  "Частота відгуків" - Ніколи.'
               'Параметри -> Конфіденційність і безпека -> Загальні: усі перемикачі вимкнено.'
               'Напис "Деякими параметрами керує ваша організація" - очікуваний: так виглядають політики скрипта.'
           ) }
        @{ Group = 'Телеметрія і приватність'; Task = 'AppTelemetry'
           Title = 'VS Code, Claude Code, Codex CLI: файли налаштувань уже змінено - перевірити й доробити'
           How = @(
               'Задача AppTelemetry вимкнула телеметрію у файлах (оригінали - поруч, *.postinstall.bak):'
               '  %APPDATA%\Code\User\settings.json     - "telemetry.telemetryLevel": "off"'
               '  %USERPROFILE%\.claude\settings.json   - env: DISABLE_TELEMETRY, DISABLE_ERROR_REPORTING = 1'
               '  %USERPROFILE%\.codex\config.toml      - analytics.enabled = false, otel.metrics_exporter = "none"'
               'Якщо прогін був під іншим обліковим записом адміністратора - файли в ЙОГО профілі; запустіть'
               '  .\Invoke-PostInstall.ps1 -Only AppTelemetry від свого імені.'
               'VS Code: після встановлення розширень пошукати "telemetry" (Ctrl+,) - частина має власні перемикачі.'
           ) }
        @{ Group = 'Телеметрія і приватність'; Task = 'Software'
           Title = 'Claude і ChatGPT: заборонити навчання моделей на ваших даних (налаштування акаунта)'
           How = @(
               'claude.ai -> Settings -> Privacy -> "Help improve Claude" - вимкнути.'
               'chatgpt.com -> Settings -> Data controls -> "Improve the model for everyone" - вимкнути (діє і для Codex).'
           ) }
        @{ Group = 'Телеметрія і приватність'; Task = 'Software'
           Title = 'Antigravity: вимкнути телеметрію'
           How = @(
               'Settings -> Account -> "Enable Telemetry" - вимкнути.'
               'Окремого перемикача "не навчати на моїх даних" немає; для конфіденційного коду - робочий акаунт Workspace/GCP.'
           ) }
        @{ Group = 'Телеметрія і приватність'; Task = 'Software'
           Title = 'Brave: вимкнути аналітику'
           How = @(
               'brave://settings/privacy -> вимкнути:'
               '  "Allow privacy-preserving product analytics (P3A)",'
               '  "Automatically send daily usage ping to Brave",'
               '  "Automatically send diagnostic reports".'
           ) }
        @{ Group = 'Телеметрія і приватність'; Task = 'Software'
           Title = 'PowerToys, Discord, Podman Desktop, UniGetUI'
           How = @(
               'PowerToys: Налаштування -> Загальні -> "Діагностичні дані" - вимкнути.'
               'Discord: Налаштування користувача -> Дані та конфіденційність -> "Використовувати дані для покращення Discord" - вимкнути.'
               'Podman Desktop: на першому запуску зняти галочку телеметрії (пізніше: Settings -> Preferences -> Telemetry).'
               'UniGetUI: у налаштуваннях вимкнути надсилання анонімної статистики, якщо перемикач є.'
           ) }

        # --- Драйвер GPU і залізо (WCS C1, C2, C6)
        @{ Group = 'Драйвер GPU і залізо'; Task = 'Software'
           Title = 'Чистий драйвер NVIDIA: DDU -> NVCleanstall'
           How = @(
               'Завантажити NVCleanstall, вибрати лише "Display driver" (без NVIDIA App / GeForce Experience),'
               '  у твіках інсталятора відмітити "Disable Installer Telemetry & Advertising" - зібрати пакет.'
               'Перезавантажитись у безпечний режим -> DDU -> "Clean and restart".'
               'Після перезавантаження встановити зібраний драйвер.'
           ) }
        @{ Group = 'Драйвер GPU і залізо'
           Title = 'Режими ноутбука: MUX, живлення, екран'
           How = @(
               'Lenovo Vantage (або фірмовий застосунок): режим GPU -> лише дискретна (dGPU only); режим Performance.'
               'Параметри -> Система -> Живлення -> Режим живлення: "Найкраща продуктивність".'
               'Максимальна частота оновлення екрана; G-Sync у панелі NVIDIA; Resizable BAR у BIOS.'
               'HAGS (апаратне планування GPU): зіграти кілька сесій; з''явилися фризи - вимкнути.'
           ) }
        @{ Group = 'Драйвер GPU і залізо'
           Title = 'Звук ноутбука: Nahimic і Lenovo Vantage з Microsoft Store'
           How = @(
               'winget install --id 9N36PPMP8S23 --source msstore   # Nahimic'
               'winget install --id 9WZDNCRFJ4MV --source msstore   # Lenovo Vantage'
               'На ноутбуці іншого виробника - його власний аудіозастосунок.'
           ) }

        # --- Система
        @{ Group = 'Система'; Task = 'Software'
           Title = 'WSL2 для Podman'
           How = @(
               'У консолі адміністратора: wsl --install --no-distribution'
               'Перезавантажитись -> Podman Desktop -> створити Podman machine.'
           ) }
        @{ Group = 'Система'; Task = 'Software'
           Title = 'Автозапуск: пройтися Autoruns'
           How = @(
               'Запустити Autoruns64 (Sysinternals) від адміністратора -> вкладка Logon -> зняти галочки з непотрібного.'
           ) }
        @{ Group = 'Система'
           Title = 'DNS через HTTPS і Контроль пам''яті'
           How = @(
               'Параметри -> Мережа та Інтернет -> Wi-Fi/Ethernet -> Призначення DNS-сервера -> Змінити -> Вручну:'
               '  IPv4 1.1.1.1 і 1.0.0.1, шифрування DNS - "Лише зашифровано (DNS через HTTPS)".'
               'Параметри -> Система -> Пам''ять -> Контроль пам''яті - увімкнути.'
           ) }

        # --- Програми
        @{ Group = 'Програми'; Task = 'Software'
           Title = 'Вхід в облікові записи'
           How = @(
               'Claude Code (claude), Codex (codex), Antigravity, Steam, Discord, Google Drive.'
           ) }
        @{ Group = 'Програми'; Task = 'Software'
           Title = 'Перевірити те, що могло не встановитись'
           How = @(
               'Пакети з WARN у таблиці вище - див. журнал прогону.'
               'VMware Workstation: якщо не встановився - завантажити з порталу Broadcom вручну.'
               'PowerToys: чи працює пошук через Everything (плагін для Run; у Command Palette - перевірити окремо).'
           ) }
        @{ Group = 'Програми'
           Title = 'Блокування реклами в браузері'
           How = @(
               'У Brave вже є Shields; в інших браузерах - розширення uBlock Origin.'
           ) }
    )
}
