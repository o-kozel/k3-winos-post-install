# AppX-застосунки, які видаляє tasks\80-Debloat.ps1 (для всіх користувачів і з образу системи).
#
# Запис - шаблон імені пакета з підстановками (*). Рядок через "#" не виконується, але лишається як
# документація свідомого рішення. Дублікатів у файлі немає (Pester-тест - Етап 7 плану);
# завантажувач додатково робить Sort-Object -Unique.
#
# УВАГА: Microsoft.GamingServices, Xbox*, XboxIdentityProvider свідомо ЗАЛИШАЮТЬСЯ (закоментовані):
# без них не працює Game Pass і частина ігор (див. WCS A8). Не розкоментовувати без потреби.
@{
    Appx = @(
        # Неважливі AppX застосунки у Windows
        # 'Microsoft.3DBuilder'                  # Не постачається з Windows 11 (Етап 5).
        'Microsoft.Microsoft3DViewer'
        # 'Microsoft.AppConnector'               # Не постачається з Windows 11 (Етап 5).
        'Microsoft.BingFinance'
        'Microsoft.BingNews'
        # 'Microsoft.BingSports'                 # Не постачається з Windows 11 (Етап 5).
        'Microsoft.BingTranslator'
        'Microsoft.BingWeather'
        'Microsoft.BingFoodAndDrink'
        'Microsoft.BingHealthAndFitness'
        'Microsoft.BingTravel'
        'Microsoft.MinecraftUWP'
        # 'Microsoft.GamingServices'
        # 'Microsoft.WindowsReadingList'         # Не постачається з Windows 11 (Етап 5).
        # 'Microsoft.GetHelp'
        'Microsoft.Getstarted'
        'Microsoft.Messaging'
        'Microsoft.MicrosoftSolitaireCollection'
        'Microsoft.NetworkSpeedTest'
        'Microsoft.News'
        'Microsoft.Office.Lens'
        'Microsoft.Office.Sway'
        'Microsoft.Office.OneNote'
        'Microsoft.OneConnect'
        'Microsoft.People'
        'Microsoft.Print3D'
        'Microsoft.SkypeApp'
        'Microsoft.Wallet'
        'Microsoft.Whiteboard'
        'Microsoft.WindowsAlarms'
        'microsoft.windowscommunicationsapps'
        'Microsoft.WindowsFeedbackHub'
        'Microsoft.WindowsMaps'
        # 'Microsoft.WindowsPhone'               # Не постачається з Windows 11 (Етап 5).
        'Microsoft.WindowsSoundRecorder'
        # 'Microsoft.XboxApp'
        'Microsoft.ConnectivityStore'
        'Microsoft.CommsPhone'
        'Microsoft.ScreenSketch'
        # 'Microsoft.Xbox.TCUI'
        # 'Microsoft.XboxGameOverlay'
        # 'Microsoft.XboxGameCallableUI'
        'Microsoft.XboxSpeechToTextOverlay'
        # 'Microsoft.MixedReality.Portal'        # Не постачається з Windows 11 (Етап 5).
        # 'Microsoft.XboxIdentityProvider'
        'Microsoft.ZuneMusic'
        'Microsoft.ZuneVideo'
        'Microsoft.YourPhone'
        'Microsoft.MicrosoftOfficeHub'
        'Spotify'
        'Disney+'
        # 'Xbox'
        'BytedancePte.Ltd.TikTok'                        # TikTok
        'FACEBOOK.317180B0BB486'                         # Messenger
        'FACEBOOK.FACEBOOK'                              # Facebook
        'Facebook.Instagram*'                            # Instagram / Beta
        '*Twitter*'                                      # Twitter
        '*Viber*'
        'Clipchamp.Clipchamp'                            # Clipchamp – Video Editor
        'Microsoft.OutlookForWindows'                    # Microsoft Outlook
        'MicrosoftTeams'                                 # Microsoft Teams
        'MicrosoftWindows.Client.WebExperience'          # Taskbar Widgets

        # Спонсорські AppX застосунки у Windows
        # Ти можеш додати будь-які застосунки у форматі "*Назва застосунка*"
        '*EclipseManager*'
        '*ActiproSoftwareLLC*'
        '*AdobeSystemsIncorporated.AdobePhotoshopExpress*'
        '*Duolingo-LearnLanguagesforFree*'               # Duolingo
        '*PandoraMediaInc*'
        '*CandyCrush*'                                   # Candy Crush
        '*BubbleWitch3Saga*'                             # Bubble Witch 3 Saga
        '*Wunderlist*'
        '*Flipboard*'                                    # Flipboard
        '*Facebook*'
        '*Royal Revolt*'
        '*Sway*'
        '*Speed Test*'
        '*Dolby*'                                        # Dolby Products (Like Atmos)
        '*ACGMediaPlayer*'
        '*Netflix*'                                      # Netflix
        '*OneCalendar*'
        '*LinkedInforWindows*'
        '*HiddenCityMysteryofShadows*'
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
        '*Plex*'                                         # Plex
        '*SlingTV*'
        'SpotifyAB.SpotifyMusic'                         # Spotify
        '*TuneInRadio*'

        # Опціонально: немає сенсу видаляти, але якщо тобі треба з якоїсь причини.
        '*Microsoft.Advertising.Xaml*'
        # '*Microsoft.MSPaint*'
        '*Microsoft.MicrosoftStickyNotes*'
        # '*Microsoft.Windows.Photos*'
        # '*Microsoft.WindowsCalculator*'
        # '*Microsoft.WindowsStore*'
    )
}
