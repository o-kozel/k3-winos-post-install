# Пакети, які ставить tasks\90-Software.ps1 (через Install-AppPackage).
# Читається через Import-PowerShellDataFile.
#
# Формат запису: @{ Id = <Id пакета>; Source = 'choco' | 'winget'; Params = <лише choco>; Comment = <навіщо> }
#   * Source за замовчуванням 'choco'.
#   * winget ставиться за --exact --id, тому Id має бути ПОВНИМ (Publisher.Package), а не частиною назви.
# Закоментовані записи лишено навмисно: це документація рішень.
#
# Порядок збережено як у старому скрипті. PowerShell 7 та oh-my-posh ставляться окремим блоком
# (tasks\95-Shell.ps1), а не звідси.
@{
    Packages = @(
        # --- базові утиліти
        @{ Id = 'chocolatey-core.extension'; Comment = 'Допоміжні функції Chocolatey для інших пакетів' }
        @{ Id = 'bulk-crap-uninstaller'; Comment = 'Видалення програм разом із залишками' }
        @{ Id = 'everything'; Comment = 'Пошук файлів. Швидший та ефективніший за стандартний; основа заміни служби WSearch' }
        @{ Id = '7zip'; Comment = 'Архіватор' }
        @{ Id = 'powertoys'; Comment = 'PowerToys: Run (Alt+Space), FancyZones тощо' }
        @{ Id = 'everythingpowertoys'; Comment = 'Плагін Everything для PowerToys Run, щоб швидко шукати файли' }
        @{ Id = 'sublimetext3'; Comment = 'Блокнот Sublime Text 3. TODO (Етап 6): застаріла major-версія, платна - прибрати' }
        @{ Id = 'vscode'; Comment = 'VS Code' }
        @{ Id = 'git.install'
           Params = '/GitAndUnixToolsOnPath /WindowsTerminal /NoAutoCrlf /SChannel /WindowsTerminalProfile'
           Comment = 'Git з параметрами. Окремого пакета git немає свідомо: він залежить від git.install, тому при встановленні git першим --params ніколи не застосовувались (Етап 4, дефект 11)' }
        @{ Id = 'wget'; Comment = 'wget' }
        @{ Id = 'LocalSend.LocalSend'; Source = 'winget'; Comment = 'Передача файлів у локальній мережі (як AirDrop). Раніше було "winget install localsend" без --exact' }

        # --- мої особисті додатки: бібліотеки
        @{ Id = 'dotnetfx'; Comment = '.NET Framework. TODO (Етап 6, п. 6.3): три перехресні пакети .NET - лишити один' }
        @{ Id = 'dotnet4.6'; Comment = '.NET Framework 4.6' }
        @{ Id = 'dotnet'; Comment = '.NET' }
        @{ Id = 'nodejs'; Comment = 'NodeJS' }
        @{ Id = 'directx'; Comment = 'DirectX (d3dx9-redist потрібен старим іграм; для ігрової машини лишаємо)' }
        @{ Id = 'openjdk'; Comment = 'Java' }

        # --- системні застосунки
        @{ Id = 'teracopy'; Comment = 'TeraCopy' }
        @{ Id = 'glaryutilities-free'; Comment = 'Glary Utilities. TODO (Етап 6, F6): прибрати, замінити на UniGetUI' }
        @{ Id = 'docker-desktop'; Comment = 'Docker Desktop. TODO (Етап 6): замінити на Podman Desktop' }
        @{ Id = 'eartrumpet'; Comment = 'EarTrumpet: мікшер гучності по застосунках' }

        # --- застосунки
        @{ Id = 'googledrive'; Comment = 'Google Drive' }
        @{ Id = 'discord'; Comment = 'Discord' }
        # @{ Id = 'skype'; Comment = 'Skype - продукт припинено' }
        @{ Id = 'paint.net'; Comment = 'Paint.NET' }
        @{ Id = 'qbittorrent'; Comment = 'qBitTorrent' }
        @{ Id = 'okular'; Comment = 'Okular (перегляд PDF)' }
        @{ Id = 'vmwareworkstation'; Comment = 'VMware Workstation Pro' }
        @{ Id = 'brave'; Comment = 'Браузер Brave' }
        @{ Id = 'vlc'; Comment = 'VLC Media Player' }
        @{ Id = 'angryip'; Comment = 'Angry IP Scanner: сканування мережі' }
        @{ Id = 'procmon'; Comment = 'Process Monitor (Sysinternals). У старому скрипті коментар помилково казав "для сканування мережі"' }
        @{ Id = 'windirstat'; Comment = 'WinDirStat: аналіз зайнятого місця на диску. У старому скрипті коментар помилково казав "для сканування мережі"' }
        @{ Id = 'superf4'; Comment = 'SuperF4: Ctrl+Alt+F4 завершує програму примусово (Alt+F4 лише просить її закритись). Автозапуск - завдання планувальника в tasks\92-Autostart.ps1' }
    )
}
