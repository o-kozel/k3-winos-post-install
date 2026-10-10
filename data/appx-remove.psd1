# AppX-застосунки, які видаляє tasks\80-Debloat.ps1 (для всіх користувачів і з образу системи).
#
# Запис - шаблон імені пакета з підстановками (*). Рядок через "#" не виконується, але лишається як
# документація свідомого рішення. Дублікатів у файлі немає (Pester-тест - Етап 7 плану);
# завантажувач додатково робить Sort-Object -Unique.
#
# УВАГА: Microsoft.GamingServices, Microsoft.GamingApp, Xbox*, XboxIdentityProvider свідомо ЗАЛИШАЮТЬСЯ
# (закоментовані): без них не працює Game Pass і частина ігор (див. WCS A8). Не розкоментовувати без потреби.
# Ніколи не додавати: Microsoft.DesktopAppInstaller (без нього немає winget), Microsoft.WindowsStore.
# Повторний прогін Debloat знову видалить усе, що збігається зі списком: якщо застосунок звідси
# свідомо встановлено пізніше - закоментувати його рядок.
@{
    Appx = @(
        # Неважливі AppX застосунки у Windows
        # 'Microsoft.3DBuilder'                  # Не постачається з Windows 11 (Етап 5).
        # 'Microsoft.Microsoft3DViewer'          # Не постачається з Windows 11 (RP §6.3).
        # 'Microsoft.AppConnector'               # Не постачається з Windows 11 (Етап 5).
        # 'Microsoft.BingFinance'                # Не постачається з Windows 11 (RP §6.3).
        'Microsoft.BingNews'
        # 'Microsoft.BingSports'                 # Не постачається з Windows 11 (Етап 5).
        # 'Microsoft.BingTranslator'             # Не постачається з Windows 11 (RP §6.3).
        'Microsoft.BingWeather'
        # 'Microsoft.BingFoodAndDrink'           # Не постачається з Windows 11 (RP §6.3).
        # 'Microsoft.BingHealthAndFitness'       # Не постачається з Windows 11 (RP §6.3).
        # 'Microsoft.BingTravel'                 # Не постачається з Windows 11 (RP §6.3).
        'Microsoft.MinecraftUWP'
        # 'Microsoft.GamingServices'
        # 'Microsoft.WindowsReadingList'         # Не постачається з Windows 11 (Етап 5).
        # 'Microsoft.GetHelp'                    # Засоби усунення неполадок Windows 11 - лишаємо.
        'Microsoft.Getstarted'
        # 'Microsoft.Messaging'                  # Не постачається з Windows 11 (RP §6.3).
        'Microsoft.MicrosoftSolitaireCollection'
        # 'Microsoft.NetworkSpeedTest'           # Не постачається з Windows 11 (RP §6.3).
        # 'Microsoft.News'                       # Не постачається з Windows 11 (RP §6.3).
        # 'Microsoft.Office.Lens'                # Не постачається з Windows 11 (RP §6.3).
        # 'Microsoft.Office.Sway'                # Не постачається з Windows 11 (RP §6.3).
        'Microsoft.Office.OneNote'               # OneNote для Windows 10 (підтримку завершено); десктопний OneNote з M365 не зачіпає.
        # 'Microsoft.OneConnect'                 # Не постачається з Windows 11 (RP §6.3).
        # 'Microsoft.People'                     # Не постачається з Windows 11 (RP §6.3).
        # 'Microsoft.Print3D'                    # Не постачається з Windows 11 (RP §6.3).
        # 'Microsoft.SkypeApp'                   # Не постачається з Windows 11; Skype закрито (RP §6.3).
        # 'Microsoft.Wallet'                     # Не постачається з Windows 11 (RP §6.3).
        'Microsoft.Whiteboard'
        # 'Microsoft.WindowsAlarms'              # Годинник: таймер, будильник, сеанси фокусування; заміни немає - лишаємо (RP §6.3).
        'microsoft.windowscommunicationsapps'    # Пошта й Календар (закриті Microsoft).
        'Microsoft.WindowsFeedbackHub'
        'Microsoft.WindowsMaps'
        # 'Microsoft.WindowsPhone'               # Не постачається з Windows 11 (Етап 5).
        'Microsoft.WindowsSoundRecorder'
        # 'Microsoft.XboxApp'
        # 'Microsoft.ConnectivityStore'          # Не постачається з Windows 11 (RP §6.3).
        # 'Microsoft.CommsPhone'                 # Не постачається з Windows 11 (RP §6.3).
        # 'Microsoft.ScreenSketch'               # Ножиці: Win+Shift+S, PrtScn, запис екрана - НЕ видаляти (WCS B2). ShareX ставиться поруч.
        # 'Microsoft.Xbox.TCUI'
        # 'Microsoft.XboxGameOverlay'
        # 'Microsoft.XboxGameCallableUI'
        'Microsoft.XboxSpeechToTextOverlay'
        # 'Microsoft.MixedReality.Portal'        # Не постачається з Windows 11 (Етап 5).
        # 'Microsoft.XboxIdentityProvider'
        'Microsoft.ZuneMusic'                    # Програвач мультимедіа; є VLC і mpv.
        'Microsoft.ZuneVideo'
        # 'Microsoft.YourPhone'                  # Зв'язок із телефоном - лишаємо (рішення RP §6.3).
        'Microsoft.MicrosoftOfficeHub'
        # 'Spotify'                              # Не збігається з іменем пакета; Spotify видаляє рядок SpotifyAB.SpotifyMusic нижче.
        'Disney.37853FC22B2CE'                   # Disney+ (раніше 'Disney+' - не збігався з іменем пакета)
        # 'Xbox'
        'BytedancePte.Ltd.TikTok'                        # TikTok
        'FACEBOOK.317180B0BB486'                         # Messenger
        'FACEBOOK.FACEBOOK'                              # Facebook
        'Facebook.Instagram*'                            # Instagram / Beta
        '*Twitter*'                                      # Twitter
        '*Viber*'
        'Clipchamp.Clipchamp'                            # Clipchamp – Video Editor
        'Microsoft.OutlookForWindows'                    # Microsoft Outlook
        'MicrosoftTeams'                                 # Microsoft Teams (класичний)
        'MSTeams'                                        # Microsoft Teams (новий)
        'MicrosoftWindows.Client.WebExperience'          # Taskbar Widgets
        'Microsoft.Copilot'                              # Copilot (RP §6.3)
        'Microsoft.BingSearch'                           # Bing Search (RP §6.3)
        'Microsoft.Todos'                                # Microsoft To Do (RP §6.3)
        'Microsoft.PowerAutomateDesktop'                 # Power Automate (RP §6.3)
        'MicrosoftCorporationII.MicrosoftFamily'         # Microsoft Family Safety (RP §6.3)
        'Microsoft.Windows.DevHome'                      # Dev Home, розвиток припинено (RP §6.3)

        # Спонсорські AppX застосунки у Windows
        # Ти можеш додати будь-які застосунки у форматі "*Назва застосунка*"
        '*EclipseManager*'
        '*ActiproSoftwareLLC*'
        # '*AdobeSystemsIncorporated.AdobePhotoshopExpress*'  # Покривається '*AdobePhotoshopExpress*' нижче.
        '*Duolingo-LearnLanguagesforFree*'               # Duolingo
        '*PandoraMediaInc*'
        '*CandyCrush*'                                   # Candy Crush
        '*BubbleWitch3Saga*'                             # Bubble Witch 3 Saga
        '*Wunderlist*'
        '*Flipboard*'                                    # Flipboard
        '*Facebook*'
        # '*Royal Revolt*'                               # Пробілів в іменах пакетів не буває; покривається '*RoyalRevolt*'.
        # '*Sway*'                                       # Sway не постачається з Windows 11 (RP §6.3).
        # '*Speed Test*'                                 # Пробілів в іменах пакетів не буває - шаблон нічого не знаходив.
        # '*Dolby*'                                      # НЕ видаляти: на ноутбуках це звуковий профіль динаміків від виробника (RP §6.3).
        '*ACGMediaPlayer*'
        '*Netflix*'                                      # Netflix
        '*OneCalendar*'
        # '*LinkedInforWindows*'                         # Покривається '*LinkedIn*' нижче.
        # '*HiddenCityMysteryofShadows*'                 # Покривається '*HiddenCity*' нижче.
        '*Hulu*'
        '*HiddenCity*'
        '*AdobePhotoshopExpress*'                        # Adobe Photoshop Express
        '*HotspotShieldFreeVPN*'
        '*LinkedIn*'
        'Amazon.com.Amazon'                              # Amazon Shop
        '*Asphalt8Airborne*'                             # Asphalt 8 Airbone
        '*AutodeskSketchBook*'
        '*CaesarsSlotsFreeCasino*'
        '*COOKINGFEVER*'
        '*CyberLinkMediaSuiteEssentials*'
        '*DisneyMagicKingdoms*'
        '*DrawboardPDF*'
        '*FarmVille2CountryEscape*'
        '*FitbitCoach*'
        '*Keeper*'
        '*MarchofEmpires*'
        '*NYTCrossword*'
        '*PhototasticCollage*'
        '*PicsArt-PhotoStudio*'
        '*PolarrPhotoEditorAcademicEdition*'
        '*RoyalRevolt*'                                  # Royal Revolt
        '*Shazam*'
        '*Sidia.LiveWallpaper*'                          # Live Wallpaper
        '*WinZipUniversal*'
        '*XING*'
        'AmazonVideo.PrimeVideo'                         # Amazon Prime Video
        '*iHeartRadio*'
        'CAF9E577.Plex'                                  # Plex (точне ім'я: '*Plex*' зачіпав би будь-який пакет із "plex" в імені)
        '*SlingTV*'
        'SpotifyAB.SpotifyMusic'                         # Spotify
        '*TuneInRadio*'

        # Опціонально: немає сенсу видаляти, але якщо тобі треба з якоїсь причини.
        # '*Microsoft.Advertising.Xaml*'                 # Бібліотека-залежність: видалення падає або ламає застосунки, Store її повертає (RP §6.3).
        # '*Microsoft.MSPaint*'
        '*Microsoft.MicrosoftStickyNotes*'               # Записки - видаляємо (рішення RP §6.3).
        # '*Microsoft.Windows.Photos*'
        # '*Microsoft.WindowsCalculator*'
        # '*Microsoft.WindowsStore*'
    )
}
