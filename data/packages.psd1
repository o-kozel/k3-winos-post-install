# Пакети, які ставить tasks\90-Software.ps1 (через Install-AppPackage).
# Читається через Import-PowerShellDataFile.
#
# Формат запису: @{ Id = <Id пакета>; Source = 'choco' | 'winget'; Params = <лише choco>; Comment = <навіщо> }
#   * Source за замовчуванням 'choco'.
#   * winget ставиться за --exact --id, тому Id має бути ПОВНИМ (Publisher.Package), а не частиною назви.
# Закоментовані записи лишено навмисно: це документація рішень.
#
# Набір переглянуто в RP §6.3 (2026-10-10). Id звірено через winget show / choco search --exact.
# PowerShell 7 та oh-my-posh ставляться окремим блоком (tasks\95-Shell.ps1), а не звідси.
@{
    Packages = @(
        # --- базові утиліти
        # @{ Id = 'chocolatey-core.extension' }  # Прибрано (RP §6.3): Chocolatey ставить його сам як залежність пакетів, яким він потрібен
        @{ Id = 'bulk-crap-uninstaller'; Comment = 'Видалення програм разом із залишками' }
        @{ Id = 'everything'; Comment = 'Пошук файлів. Швидший та ефективніший за стандартний; основа заміни служби WSearch' }
        @{ Id = '7zip'; Comment = 'Архіватор' }
        @{ Id = 'powertoys'; Comment = 'PowerToys: Run (Alt+Space), FancyZones тощо' }
        @{ Id = 'everythingpowertoys'; Comment = 'Плагін Everything для PowerToys Run. Сумісність із Command Palette (наступник Run у нових PowerToys) перевірити на першому прогоні' }
        # @{ Id = 'sublimetext3' }  # Прибрано (RP §6.3): застаріла major-версія, платна; є VS Code, для швидких правок - Notepad++
        @{ Id = 'notepadplusplus'; Comment = 'Notepad++: швидкі правки текстових файлів (замість Sublime Text 3)' }
        @{ Id = 'vscode'; Comment = 'VS Code. Телеметрію вимикати в settings.json (WCS F5; розгортання settings.json - окремий крок плану)' }
        @{ Id = 'git.install'
           Params = '/GitAndUnixToolsOnPath /WindowsTerminal /NoAutoCrlf /SChannel /WindowsTerminalProfile'
           Comment = 'Git з параметрами. Окремого пакета git немає свідомо: він залежить від git.install, тому при встановленні git першим --params ніколи не застосовувались (Етап 4, дефект 11)' }
        # @{ Id = 'wget' }  # Прибрано (RP §6.3): curl.exe є в Windows з коробки
        @{ Id = 'LocalSend.LocalSend'; Source = 'winget'; Comment = 'Передача файлів у локальній мережі (як AirDrop). Раніше було "winget install localsend" без --exact' }
        @{ Id = 'Devolutions.UniGetUI'; Source = 'winget'; Comment = 'UniGetUI: сповіщення й оновлення встановлених програм (winget + choco). Замінює Glary Utilities' }

        # --- мої особисті додатки: бібліотеки
        # @{ Id = 'dotnetfx' }   # Прибрано (RP §6.3): .NET Framework 4.8.1 уже входить у Windows 11
        # @{ Id = 'dotnet4.6' }  # Прибрано (RP §6.3): повністю перекритий .NET Framework 4.8
        @{ Id = 'Microsoft.DotNet.DesktopRuntime.10'; Source = 'winget'; Comment = '.NET 10 Desktop Runtime (LTS). Замінює пакет dotnet; інші версії програми попросять самі' }
        @{ Id = 'nodejs-lts'; Comment = 'Node.js LTS: потрібен MCP-серверам AI-агентів (npx). LTS, а не nodejs (той ставить проміжну версію)' }
        @{ Id = 'directx'; Comment = 'DirectX (d3dx9-redist потрібен старим іграм; для ігрової машини лишаємо)' }
        @{ Id = 'vcredist-all'; Comment = 'Visual C++ Redistributable усіх версій: без нього не стартує багато ігор і програм (MSVCP140.dll тощо)' }
        # @{ Id = 'openjdk' }  # Прибрано (RP §6.3): Java не потрібна (немає Java-розробки, немає Minecraft Java)

        # --- AI-агенти
        @{ Id = 'Anthropic.ClaudeCode'; Source = 'winget'; Comment = 'Claude Code (CLI)' }
        @{ Id = 'OpenAI.Codex'; Source = 'winget'; Comment = 'Codex CLI' }
        @{ Id = 'Google.Antigravity'; Source = 'winget'; Comment = 'Google Antigravity: IDE з агентами' }

        # --- системні застосунки
        # @{ Id = 'teracopy' }             # Прибрано (RP §6.3): вбудованого копіювання Windows 11 досить
        # @{ Id = 'glaryutilities-free' }  # Прибрано (RP §6.3, WCS F6): перевірку оновлень робить UniGetUI, видалення - BCU
        # @{ Id = 'docker-desktop' }       # Замінено на Podman (RP §6.3, WCS B1)
        @{ Id = 'RedHat.Podman'; Source = 'winget'; Comment = 'Podman: контейнери (замість Docker). Працює через WSL2' }
        @{ Id = 'RedHat.Podman-Desktop'; Source = 'winget'; Comment = 'Podman Desktop: графічний інтерфейс до Podman' }
        @{ Id = 'eartrumpet'; Comment = 'EarTrumpet: мікшер гучності по застосунках' }
        @{ Id = 'sysinternals'; Comment = 'Sysinternals Suite: Process Monitor, Process Explorer, Autoruns, TCPView. Замінює окремий procmon' }
        @{ Id = 'hwinfo'; Comment = 'HWiNFO64: датчики, температури, троттлінг' }
        @{ Id = 'crystaldiskinfo'; Comment = 'CrystalDiskInfo: стан (SMART) NVMe-дисків' }

        # --- ігри
        @{ Id = 'Valve.Steam'; Source = 'winget'; Comment = 'Steam' }
        @{ Id = 'ddu'; Comment = 'Display Driver Uninstaller: чисте видалення драйвера GPU. Лише ставиться; запуск - ручний крок' }
        @{ Id = 'TechPowerUp.NVCleanstall'; Source = 'winget'; Comment = 'NVCleanstall: драйвер NVIDIA без GeForce Experience і телеметрії. Лише ставиться; запуск - ручний крок' }

        # --- застосунки
        @{ Id = 'googledrive'; Comment = 'Google Drive' }
        @{ Id = 'discord'; Comment = 'Discord' }
        @{ Id = 'paint.net'; Comment = 'Paint.NET' }
        @{ Id = 'qbittorrent'; Comment = 'qBitTorrent' }
        @{ Id = 'okular'; Comment = 'Okular (перегляд PDF)' }
        @{ Id = 'vmwareworkstation'; Comment = 'VMware Workstation Pro. Пакет choco відстає від поточної версії, а завантаження перенесено за обліковий запис Broadcom - якщо не встановиться, ставити вручну' }
        @{ Id = 'brave'; Comment = 'Браузер Brave' }
        @{ Id = 'vlc'; Comment = 'VLC Media Player' }
        @{ Id = 'shinchiro.mpv'; Source = 'winget'; Comment = 'mpv: другий програвач поруч із VLC (WCS D2). Не choco: там пакет застарів' }
        @{ Id = 'OBSProject.OBSStudio'; Source = 'winget'; Comment = 'OBS Studio: запис і стрими (NVENC)' }
        @{ Id = 'ShareX.ShareX'; Source = 'winget'; Comment = 'ShareX: знімки й запис екрана. Працює поруч із Ножицями (Win+Shift+S лишається за ними)' }
        @{ Id = 'angryip'; Comment = 'Angry IP Scanner: сканування мережі' }
        # @{ Id = 'procmon' }     # Замінено на sysinternals (RP §6.3)
        # @{ Id = 'windirstat' }  # Замінено на wiztree (RP §6.3)
        @{ Id = 'wiztree'; Comment = 'WizTree: аналіз зайнятого місця на диску (читає MFT - секунди замість хвилин)' }
        @{ Id = 'superf4'; Comment = 'SuperF4: Ctrl+Alt+F4 завершує програму примусово (Alt+F4 лише просить її закритись). Автозапуск - завдання планувальника в tasks\92-Autostart.ps1' }
    )
}
