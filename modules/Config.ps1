# =====================================================================
# CONFIG.PS1 - Application Definitions, Categories & Presets
# =====================================================================

# Custom Preset Directory
$script:PresetDir = Join-Path $env:APPDATA "HumanTouch-Optimizer\Presets"

# Application definitions grouped by category
$script:AppCategories = [ordered]@{
    "BROWSERS" = @(
        @{ Name = "Google Chrome";       Id = "Google.Chrome" }
        @{ Name = "Mozilla Firefox";     Id = "Mozilla.Firefox" }
        @{ Name = "Brave Browser";       Id = "Brave.Brave" }
        @{ Name = "Microsoft Edge";      Id = "Microsoft.Edge" }
        @{ Name = "Opera Browser";       Id = "Opera.Opera" }
        @{ Name = "Opera GX";           Id = "Opera.OperaGX" }
        @{ Name = "Vivaldi";            Id = "Vivaldi.Vivaldi" }
    )
    "COMMUNICATION" = @(
        @{ Name = "Discord";            Id = "Discord.Discord" }
        @{ Name = "Telegram";           Id = "Telegram.TelegramDesktop" }
        @{ Name = "WhatsApp";           Id = "WhatsApp.WhatsApp" }
        @{ Name = "Zoom";               Id = "Zoom.Zoom" }
        @{ Name = "Skype";              Id = "Microsoft.Skype" }
        @{ Name = "Microsoft Teams";    Id = "Microsoft.Teams" }
        @{ Name = "Slack";              Id = "SlackTechnologies.Slack" }
    )
    "GAMING" = @(
        @{ Name = "Steam";              Id = "Valve.Steam" }
        @{ Name = "Epic Games Launcher";Id = "EpicGames.EpicGamesLauncher" }
        @{ Name = "GOG Galaxy";         Id = "GOG.Galaxy" }
        @{ Name = "EA App";             Id = "ElectronicArts.EADesktop" }
        @{ Name = "Ubisoft Connect";    Id = "Ubisoft.Connect" }
        @{ Name = "Battle.net";         Id = "Blizzard.BattleNet" }
    )
    "SYSTEM TOOLS" = @(
        @{ Name = "7-Zip";              Id = "7zip.7zip" }
        @{ Name = "WinRAR";             Id = "RARLab.WinRAR" }
        @{ Name = "Notepad++";          Id = "Notepad++.Notepad++" }
        @{ Name = "PowerToys";          Id = "Microsoft.PowerToys" }
        @{ Name = "Everything Search";  Id = "voidtools.Everything" }
        @{ Name = "TreeSize Free";      Id = "JAMSoftware.TreeSize.Free" }
        @{ Name = "CPU-Z";              Id = "CPUID.CPU-Z" }
    )
    "MEDIA" = @(
        @{ Name = "VLC Media Player";   Id = "VideoLAN.VLC" }
        @{ Name = "Spotify";            Id = "Spotify.Spotify" }
        @{ Name = "OBS Studio";         Id = "OBSProject.OBSStudio" }
        @{ Name = "GIMP";               Id = "GIMP.GIMP" }
        @{ Name = "Audacity";           Id = "Audacity.Audacity" }
        @{ Name = "HandBrake";          Id = "HandBrake.HandBrake" }
        @{ Name = "ShareX";             Id = "ShareX.ShareX" }
    )
    "DEVELOPMENT" = @(
        @{ Name = "Visual Studio Code"; Id = "Microsoft.VisualStudioCode" }
        @{ Name = "Git";                Id = "Git.Git" }
        @{ Name = "Node.js LTS";        Id = "OpenJS.NodeJS.LTS" }
        @{ Name = "Python 3";           Id = "Python.Python.3.12" }
        @{ Name = "Docker Desktop";     Id = "Docker.DockerDesktop" }
        @{ Name = "Postman";            Id = "Postman.Postman" }
        @{ Name = "Windows Terminal";   Id = "Microsoft.WindowsTerminal" }
    )
}

# Built-in preset definitions (app IDs)
$script:BuiltInPresets = @{
    "Gaming" = @(
        "Google.Chrome"
        "Discord.Discord"
        "Valve.Steam"
        "EpicGames.EpicGamesLauncher"
        "GOG.Galaxy"
        "ElectronicArts.EADesktop"
        "Ubisoft.Connect"
        "Blizzard.BattleNet"
        "7zip.7zip"
        "Spotify.Spotify"
    )
    "Work" = @(
        "Google.Chrome"
        "Mozilla.Firefox"
        "Microsoft.Teams"
        "SlackTechnologies.Slack"
        "Zoom.Zoom"
        "Notepad++.Notepad++"
        "Microsoft.PowerToys"
        "Microsoft.VisualStudioCode"
        "Git.Git"
        "7zip.7zip"
    )
    "Media" = @(
        "Google.Chrome"
        "VideoLAN.VLC"
        "Spotify.Spotify"
        "OBSProject.OBSStudio"
        "GIMP.GIMP"
        "Audacity.Audacity"
        "HandBrake.HandBrake"
        "ShareX.ShareX"
    )
}
