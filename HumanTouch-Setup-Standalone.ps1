#Requires -Version 5.1
<#
.SYNOPSIS
    HumanTouch Optimizer v2.0 - Modern Windows Application Installer
.DESCRIPTION
    Production-ready modular PowerShell GUI installer using winget.
    Features: Horizontal card layout, 3 icon presets, custom preset
    save/load, install animation feedback, internet check, DPI scaling.
.VERSION
    2.0
#>

# =====================================================================
# AUTO-ELEVATE TO ADMINISTRATOR
# =====================================================================
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal   = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-Administrator)) {
    $scriptPath = $MyInvocation.MyCommand.Definition
    $arguments  = "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`""
    Start-Process -FilePath "powershell.exe" -ArgumentList $arguments -Verb RunAs
    exit
}

# =====================================================================
# ASSEMBLIES
# =====================================================================
Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase
Add-Type -AssemblyName System.Windows.Forms

# =====================================================================
# WINGET CHECK
# =====================================================================
function Test-Winget {
    $wingetCmd = Get-Command winget -ErrorAction SilentlyContinue
    if ($null -eq $wingetCmd) {
        [System.Windows.MessageBox]::Show(
            "winget (Windows Package Manager) was not found.`n`nPlease install App Installer from the Microsoft Store.",
            "winget Not Found",
            [System.Windows.MessageBoxButton]::OK,
            [System.Windows.MessageBoxImage]::Error
        ) | Out-Null
        exit 1
    }
}
Test-Winget

# =====================================================================
# LOAD MODULES
# =====================================================================
# Standalone Mode Activated


# --- MODULE: Config.ps1 START ---
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

# --- MODULE: Config.ps1 END ---


# --- MODULE: XAML.ps1 START ---
# =====================================================================
# XAML.PS1 - Window XAML Definition
# Horizontal card layout, resizable, DPI-friendly, with overlays
# =====================================================================
[xml]$script:XAML = @'
<Window
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    Title="HumanTouch Optimizer"
    Width="1060"
    Height="640"
    MinWidth="820"
    MinHeight="500"
    WindowStartupLocation="CenterScreen"
    ResizeMode="CanResizeWithGrip"
    WindowStyle="None"
    AllowsTransparency="True"
    Background="Transparent"
    FontFamily="Segoe UI Variable Display, Segoe UI, sans-serif"
    TextOptions.TextFormattingMode="Display"
    TextOptions.TextRenderingMode="ClearType"
    UseLayoutRounding="True"
    SnapsToDevicePixels="True">

    <Window.Resources>
        <DropShadowEffect x:Key="WindowShadow" BlurRadius="30" ShadowDepth="6" Direction="270" Color="#000000" Opacity="0.7"/>
        <DropShadowEffect x:Key="CardShadow" BlurRadius="16" ShadowDepth="3" Direction="270" Color="#000000" Opacity="0.35"/>
        <DropShadowEffect x:Key="ButtonShadow" BlurRadius="12" ShadowDepth="2" Direction="270" Color="#5B6CF9" Opacity="0.35"/>

        <!-- DARK SCROLLBAR THUMB (shared template) -->
        <ControlTemplate x:Key="DarkVertThumb" TargetType="Thumb">
            <Border CornerRadius="4" Background="#3A4580" Margin="1,2,1,2" Opacity="0.7">
                <Border.Triggers>
                    <EventTrigger RoutedEvent="MouseEnter">
                        <BeginStoryboard>
                            <Storyboard>
                                <DoubleAnimation Storyboard.TargetProperty="Opacity" To="1" Duration="0:0:0.15"/>
                            </Storyboard>
                        </BeginStoryboard>
                    </EventTrigger>
                    <EventTrigger RoutedEvent="MouseLeave">
                        <BeginStoryboard>
                            <Storyboard>
                                <DoubleAnimation Storyboard.TargetProperty="Opacity" To="0.7" Duration="0:0:0.25"/>
                            </Storyboard>
                        </BeginStoryboard>
                    </EventTrigger>
                </Border.Triggers>
            </Border>
        </ControlTemplate>

        <ControlTemplate x:Key="DarkHorizThumb" TargetType="Thumb">
            <Border CornerRadius="4" Background="#3A4580" Margin="2,1,2,1" Opacity="0.7"/>
        </ControlTemplate>

        <!-- GLOBAL VERTICAL SCROLLBAR -->
        <Style TargetType="ScrollBar">
            <Setter Property="Background" Value="Transparent"/>
            <Setter Property="Width" Value="8"/>
            <Setter Property="MinWidth" Value="8"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="ScrollBar">
                        <Border CornerRadius="4" Background="#0D1020" Margin="1">
                            <Track x:Name="PART_Track" IsDirectionReversed="True">
                                <Track.Thumb>
                                    <Thumb Template="{StaticResource DarkVertThumb}"/>
                                </Track.Thumb>
                            </Track>
                        </Border>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
            <Style.Triggers>
                <Trigger Property="Orientation" Value="Horizontal">
                    <Setter Property="Width" Value="Auto"/>
                    <Setter Property="Height" Value="8"/>
                    <Setter Property="MinHeight" Value="8"/>
                    <Setter Property="Template">
                        <Setter.Value>
                            <ControlTemplate TargetType="ScrollBar">
                                <Border CornerRadius="4" Background="#0D1020" Margin="1">
                                    <Track x:Name="PART_Track" IsDirectionReversed="False">
                                        <Track.Thumb>
                                            <Thumb Template="{StaticResource DarkHorizThumb}"/>
                                        </Track.Thumb>
                                    </Track>
                                </Border>
                            </ControlTemplate>
                        </Setter.Value>
                    </Setter>
                </Trigger>
            </Style.Triggers>
        </Style>

        <!-- TOGGLE CHECKBOX -->
        <Style x:Key="ToggleCheckBox" TargetType="CheckBox">
            <Setter Property="Foreground" Value="#B8C4E8"/>
            <Setter Property="FontSize" Value="12"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Margin" Value="0,1,0,1"/>
            <Setter Property="HorizontalAlignment" Value="Stretch"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="CheckBox">
                        <Border x:Name="RootBorder" Background="Transparent" CornerRadius="6" Padding="8,5,8,5" HorizontalAlignment="Stretch">
                            <Grid>
                                <Grid.ColumnDefinitions>
                                    <ColumnDefinition Width="32"/>
                                    <ColumnDefinition Width="*"/>
                                </Grid.ColumnDefinitions>
                                <Border x:Name="ToggleTrack" Grid.Column="0" Width="30" Height="16" CornerRadius="8"
                                        Background="#40141D45" BorderBrush="#55243875" BorderThickness="1" VerticalAlignment="Center">
                                    <Border x:Name="ToggleThumb" Width="10" Height="10" CornerRadius="5"
                                            Background="#507A8CFF" HorizontalAlignment="Left" Margin="2,0,0,0"/>
                                </Border>
                                <ContentPresenter Grid.Column="1" VerticalAlignment="Center" Margin="8,0,0,0"/>
                            </Grid>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsChecked" Value="True">
                                <Setter TargetName="ToggleTrack" Property="Background">
                                    <Setter.Value>
                                        <LinearGradientBrush StartPoint="0,0" EndPoint="1,0">
                                            <GradientStop Color="#3B4BE8" Offset="0"/>
                                            <GradientStop Color="#5B6CF9" Offset="1"/>
                                        </LinearGradientBrush>
                                    </Setter.Value>
                                </Setter>
                                <Setter TargetName="ToggleTrack" Property="BorderBrush" Value="#5B6CF9"/>
                                <Setter TargetName="ToggleThumb" Property="Background" Value="White"/>
                                <Setter TargetName="ToggleThumb" Property="HorizontalAlignment" Value="Right"/>
                                <Setter TargetName="ToggleThumb" Property="Margin" Value="0,0,2,0"/>
                                <Setter TargetName="RootBorder" Property="Background" Value="#30141D45"/>
                            </Trigger>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="RootBorder" Property="Background" Value="#40203065"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <!-- PRIMARY BUTTON -->
        <Style x:Key="PrimaryBtn" TargetType="Button">
            <Setter Property="Foreground" Value="White"/>
            <Setter Property="FontSize" Value="12"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="Height" Value="38"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="BtnBorder" CornerRadius="10" Effect="{StaticResource ButtonShadow}">
                            <Border.Background>
                                <LinearGradientBrush StartPoint="0,0" EndPoint="1,0">
                                    <GradientStop Color="#5B6CF9" Offset="0"/>
                                    <GradientStop Color="#7A8CFF" Offset="1"/>
                                </LinearGradientBrush>
                            </Border.Background>
                            <Grid>
                                <Border x:Name="HoverOverlay" CornerRadius="10" Background="White" Opacity="0"/>
                                <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                            </Grid>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="HoverOverlay" Property="Opacity" Value="0.08"/>
                            </Trigger>
                            <Trigger Property="IsPressed" Value="True">
                                <Setter TargetName="HoverOverlay" Property="Opacity" Value="0.15"/>
                            </Trigger>
                            <Trigger Property="IsEnabled" Value="False">
                                <Setter TargetName="BtnBorder" Property="Opacity" Value="0.35"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <!-- SECONDARY BUTTON -->
        <Style x:Key="SecondaryBtn" TargetType="Button">
            <Setter Property="Foreground" Value="#7B8CDE"/>
            <Setter Property="FontSize" Value="11"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="Height" Value="34"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="BtnBorder" CornerRadius="10" Background="#4010183A"
                                BorderBrush="#443B4BE8" BorderThickness="1">
                            <Grid>
                                <Border x:Name="HoverOverlay" CornerRadius="10" Opacity="0">
                                    <Border.Background>
                                        <LinearGradientBrush StartPoint="0,0" EndPoint="1,0">
                                            <GradientStop Color="#1E2448" Offset="0"/>
                                            <GradientStop Color="#1A2040" Offset="1"/>
                                        </LinearGradientBrush>
                                    </Border.Background>
                                </Border>
                                <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                            </Grid>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="HoverOverlay" Property="Opacity" Value="1"/>
                                <Setter TargetName="BtnBorder" Property="BorderBrush" Value="#4A5AE0"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <!-- ICON BUTTON (Presets) -->
        <Style x:Key="IconBtn" TargetType="Button">
            <Setter Property="Width" Value="44"/>
            <Setter Property="Height" Value="44"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="FontFamily" Value="Segoe MDL2 Assets"/>
            <Setter Property="FontSize" Value="18"/>
            <Setter Property="Foreground" Value="#7B8CDE"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="IcBorder" CornerRadius="10" Background="#4010183A"
                                BorderBrush="#443B4BE8" BorderThickness="1">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="IcBorder" Property="Background" Value="#1E2448"/>
                                <Setter TargetName="IcBorder" Property="BorderBrush" Value="#4A5AE0"/>
                                <Setter Property="Foreground" Value="#9BA8FF"/>
                            </Trigger>
                            <Trigger Property="IsEnabled" Value="False">
                                <Setter TargetName="IcBorder" Property="Opacity" Value="0.4"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <!-- WINDOW CONTROL BUTTONS -->
        <Style x:Key="CloseBtn" TargetType="Button">
            <Setter Property="Foreground" Value="#4A5070"/>
            <Setter Property="Width" Value="30"/>
            <Setter Property="Height" Value="30"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="CB" CornerRadius="8" Background="Transparent">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="CB" Property="Background" Value="#CC2A2A"/>
                                <Setter Property="Foreground" Value="White"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <Style x:Key="MinBtn" TargetType="Button">
            <Setter Property="Foreground" Value="#4A5070"/>
            <Setter Property="Width" Value="30"/>
            <Setter Property="Height" Value="30"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="MB" CornerRadius="8" Background="Transparent">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="MB" Property="Background" Value="#1E2240"/>
                                <Setter Property="Foreground" Value="#7B8CDE"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
    </Window.Resources>

    <!-- OUTER SHADOW WRAPPER -->
    <Border Margin="10" CornerRadius="14" Effect="{StaticResource WindowShadow}">
        <Border CornerRadius="14" ClipToBounds="True" BorderThickness="1" BorderBrush="#22FFFFFF">
            <Border.Background>
                <LinearGradientBrush StartPoint="0,0" EndPoint="1,1">
                    <GradientStop Color="#04091A" Offset="0"/>
                    <GradientStop Color="#091330" Offset="0.6"/>
                    <GradientStop Color="#050A20" Offset="1"/>
                </LinearGradientBrush>
            </Border.Background>
            <Grid>
                <!-- Glassmorphism glow orbs -->
                <Ellipse Width="600" Height="600" HorizontalAlignment="Left" VerticalAlignment="Top" Margin="-150,-150,0,0" IsHitTestVisible="False">
                    <Ellipse.Fill>
                        <RadialGradientBrush>
                            <GradientStop Color="#253B82F6" Offset="0"/>
                            <GradientStop Color="#003B82F6" Offset="0.7"/>
                            <GradientStop Color="Transparent" Offset="1"/>
                        </RadialGradientBrush>
                    </Ellipse.Fill>
                </Ellipse>
                <Ellipse Width="500" Height="500" HorizontalAlignment="Right" VerticalAlignment="Bottom" Margin="0,0,-100,-80" IsHitTestVisible="False">
                    <Ellipse.Fill>
                        <RadialGradientBrush>
                            <GradientStop Color="#20818CF8" Offset="0"/>
                            <GradientStop Color="#086366F1" Offset="0.5"/>
                            <GradientStop Color="Transparent" Offset="1"/>
                        </RadialGradientBrush>
                    </Ellipse.Fill>
                </Ellipse>
            <Grid>
                <Grid.RowDefinitions>
                    <RowDefinition Height="52"/>
                    <RowDefinition Height="*"/>
                    <RowDefinition Height="30"/>
                </Grid.RowDefinitions>

                <!-- HEADER -->
                <Border Grid.Row="0">
                    <Border.Background>
                        <LinearGradientBrush StartPoint="0,0" EndPoint="1,0">
                            <GradientStop Color="#550D1535" Offset="0"/>
                            <GradientStop Color="#40121C4A" Offset="1"/>
                        </LinearGradientBrush>
                    </Border.Background>
                    <Grid>
                        <Border VerticalAlignment="Bottom" Height="1" Opacity="0.5">
                            <Border.Background>
                                <LinearGradientBrush StartPoint="0,0" EndPoint="1,0">
                                    <GradientStop Color="Transparent" Offset="0"/>
                                    <GradientStop Color="#5B6CF9" Offset="0.3"/>
                                    <GradientStop Color="#7A8CFF" Offset="0.7"/>
                                    <GradientStop Color="Transparent" Offset="1"/>
                                </LinearGradientBrush>
                            </Border.Background>
                        </Border>
                        <Grid Margin="18,0,14,0" x:Name="DragBar" Background="Transparent">
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="Auto"/>
                                <ColumnDefinition Width="*"/>
                                <ColumnDefinition Width="Auto"/>
                            </Grid.ColumnDefinitions>
                            <StackPanel Grid.Column="0" Orientation="Horizontal" VerticalAlignment="Center">
                                <Border Width="7" Height="7" CornerRadius="4" Margin="0,0,8,0">
                                    <Border.Background>
                                        <LinearGradientBrush StartPoint="0,0" EndPoint="1,1">
                                            <GradientStop Color="#5B6CF9" Offset="0"/>
                                            <GradientStop Color="#9B6CFF" Offset="1"/>
                                        </LinearGradientBrush>
                                    </Border.Background>
                                </Border>
                                <TextBlock Text="HumanTouch Optimizer" Foreground="White" FontSize="13" FontWeight="SemiBold" VerticalAlignment="Center"/>
                                <Border CornerRadius="12" Padding="8,2,8,2" Margin="10,0,0,0" BorderThickness="1" BorderBrush="#2A3060" VerticalAlignment="Center">
                                    <Border.Background>
                                        <LinearGradientBrush StartPoint="0,0" EndPoint="1,0">
                                            <GradientStop Color="#161C38" Offset="0"/>
                                            <GradientStop Color="#1C2244" Offset="1"/>
                                        </LinearGradientBrush>
                                    </Border.Background>
                                    <TextBlock Text="v2.0" FontSize="10" FontWeight="SemiBold" Foreground="#7B8CFF"/>
                                </Border>
                            </StackPanel>
                            <StackPanel Grid.Column="2" Orientation="Horizontal" VerticalAlignment="Center">
                                <Button x:Name="BtnMinimize" Style="{StaticResource MinBtn}" Content="_" FontSize="16" Margin="0,0,4,0"/>
                                <Button x:Name="BtnClose" Style="{StaticResource CloseBtn}" Content="X" FontSize="11" FontWeight="Bold"/>
                            </StackPanel>
                        </Grid>
                    </Grid>
                </Border>

                <!-- MAIN CONTENT -->
                <Grid Grid.Row="1">
                    <Grid.RowDefinitions>
                        <RowDefinition Height="*"/>
                        <RowDefinition Height="140"/>
                    </Grid.RowDefinitions>

                    <!-- TOP: Responsive wrapping app cards -->
                    <Border Grid.Row="0" Margin="0,0,0,0">
                        <ScrollViewer HorizontalScrollBarVisibility="Disabled" VerticalScrollBarVisibility="Auto" Margin="0,0,0,0">
                            <WrapPanel x:Name="AppListPanel" Orientation="Horizontal" Margin="14,10,14,6"/>
                        </ScrollViewer>
                    </Border>

                    <!-- BOTTOM: Control panel -->
                    <Border Grid.Row="1" BorderThickness="0,1,0,0" BorderBrush="#33243875">
                        <Border.Background>
                            <LinearGradientBrush StartPoint="0,0" EndPoint="0,1">
                                <GradientStop Color="#400A102A" Offset="0"/>
                                <GradientStop Color="#60050818" Offset="1"/>
                            </LinearGradientBrush>
                        </Border.Background>
                        <Grid Margin="16,8,16,6">
                            <Grid.RowDefinitions>
                                <RowDefinition Height="Auto"/>
                                <RowDefinition Height="*"/>
                            </Grid.RowDefinitions>

                            <!-- ROW 0: Organized Grid Layout -->
                            <Grid Grid.Row="0" Margin="0,0,0,12">
                                <Grid.ColumnDefinitions>
                                    <ColumnDefinition Width="Auto"/> <!-- Left: Presets -->
                                    <ColumnDefinition Width="*"/>    <!-- Spacer -->
                                    <ColumnDefinition Width="Auto"/> <!-- Center: Primary Actions -->
                                    <ColumnDefinition Width="*"/>    <!-- Spacer -->
                                    <ColumnDefinition Width="Auto"/> <!-- Right: Selected Count -->
                                </Grid.ColumnDefinitions>

                                <!-- LEFT: Presets -->
                                <StackPanel Grid.Column="0" Orientation="Horizontal" VerticalAlignment="Center">
                                    <TextBlock Text="PRESETS" Foreground="#4A5A9C" FontSize="10" FontWeight="Bold" VerticalAlignment="Center" Margin="0,0,12,0"/>
                                    <Button x:Name="BtnPresetGaming" Style="{StaticResource IconBtn}" Width="36" Height="36" Margin="0,0,6,0" ToolTip="Gaming Preset"/>
                                    <Button x:Name="BtnPresetWork" Style="{StaticResource IconBtn}" Width="36" Height="36" Margin="0,0,6,0" ToolTip="Work Preset"/>
                                    <Button x:Name="BtnPresetMedia" Style="{StaticResource IconBtn}" Width="36" Height="36" Margin="0,0,12,0" ToolTip="Media Preset"/>
                                    
                                    <Border Width="1" Height="20" Background="#24346B" Margin="0,0,12,0"/>
                                    
                                    <Button x:Name="BtnSavePreset" Style="{StaticResource SecondaryBtn}" Content="Save" Width="64" Height="32" Margin="0,0,6,0" ToolTip="Save current selection as preset"/>
                                    <Button x:Name="BtnLoadPreset" Style="{StaticResource SecondaryBtn}" Content="Load" Width="64" Height="32" Margin="0,0,0,0" ToolTip="Load a saved preset"/>
                                </StackPanel>

                                <!-- CENTER: Main Action Buttons -->
                                <StackPanel Grid.Column="2" Orientation="Horizontal" VerticalAlignment="Center">
                                    <Button x:Name="BtnInstall" Style="{StaticResource PrimaryBtn}" Content="Install Selected" Width="160" Height="40" FontSize="13" FontWeight="Bold" IsEnabled="False" Margin="0,0,12,0" ToolTip="Begin installation of selected applications"/>
                                    <Button x:Name="BtnCheckUpdates" Style="{StaticResource SecondaryBtn}" Content="Check Updates" Width="110" Height="34" Margin="0,0,8,0" ToolTip="Check for available updates for installed applications"/>
                                    <Button x:Name="BtnClear" Style="{StaticResource SecondaryBtn}" Content="Clear All" Width="80" Height="34" Margin="0,0,0,0" ToolTip="Deselect all applications"/>
                                </StackPanel>

                                <!-- RIGHT: Selected Counter -->
                                <StackPanel Grid.Column="4" Orientation="Horizontal" VerticalAlignment="Center">
                                    <TextBlock Text="SELECTED" Foreground="#4A5A9C" FontSize="10" FontWeight="Bold" VerticalAlignment="Center" Margin="0,0,10,0"/>
                                    <Border CornerRadius="16" Padding="14,4,14,4">
                                        <Border.Background>
                                            <LinearGradientBrush StartPoint="0,0" EndPoint="1,1">
                                                <GradientStop Color="#3B4BE8" Offset="0"/>
                                                <GradientStop Color="#5360EE" Offset="1"/>
                                            </LinearGradientBrush>
                                        </Border.Background>
                                        <TextBlock x:Name="SelectedCounter" Text="0" FontSize="15" FontWeight="Bold" Foreground="White" VerticalAlignment="Center"/>
                                    </Border>
                                </StackPanel>
                            </Grid>

                            <!-- ROW 1: Status / Progress / Log (stretches full width) -->
                            <Border Grid.Row="1" CornerRadius="8" Padding="10,5,10,5" BorderThickness="1" BorderBrush="#1A1E3A">
                                <Border.Background>
                                    <LinearGradientBrush StartPoint="0,0" EndPoint="0,1">
                                        <GradientStop Color="#111428" Offset="0"/>
                                        <GradientStop Color="#0D1020" Offset="1"/>
                                    </LinearGradientBrush>
                                </Border.Background>
                                <Grid>
                                    <Grid.ColumnDefinitions>
                                        <ColumnDefinition Width="*"/>
                                        <ColumnDefinition Width="Auto"/>
                                    </Grid.ColumnDefinitions>
                                    <Grid.RowDefinitions>
                                        <RowDefinition Height="Auto"/>
                                        <RowDefinition Height="Auto"/>
                                        <RowDefinition Height="*"/>
                                    </Grid.RowDefinitions>
                                    <!-- Status + progress label -->
                                    <TextBlock Grid.Row="0" Grid.Column="0" x:Name="StatusLabel" Text="Ready" Foreground="#7B8CDE" FontSize="10" TextTrimming="CharacterEllipsis" Margin="0,0,0,3"/>
                                    <TextBlock Grid.Row="0" Grid.Column="1" x:Name="ProgressLabel" Text="0 / 0" Foreground="#2E3460" FontSize="10" Margin="8,0,0,3"/>
                                    <!-- Progress bar -->
                                    <Border Grid.Row="1" Grid.ColumnSpan="2" CornerRadius="3" Height="4" Background="#0D1020" BorderThickness="1" BorderBrush="#1A1E38" Margin="0,0,0,3">
                                        <Grid>
                                            <Border x:Name="ProgressGlow" CornerRadius="3" HorizontalAlignment="Left" Width="0" Opacity="0.3">
                                                <Border.Background>
                                                    <LinearGradientBrush StartPoint="0,0" EndPoint="1,0">
                                                        <GradientStop Color="#5B6CF9" Offset="0"/>
                                                        <GradientStop Color="#9B6CFF" Offset="1"/>
                                                    </LinearGradientBrush>
                                                </Border.Background>
                                            </Border>
                                            <Border x:Name="ProgressFill" CornerRadius="3" HorizontalAlignment="Left" Width="0">
                                                <Border.Background>
                                                    <LinearGradientBrush StartPoint="0,0" EndPoint="1,0">
                                                        <GradientStop Color="#5B6CF9" Offset="0"/>
                                                        <GradientStop Color="#9B6CFF" Offset="1"/>
                                                    </LinearGradientBrush>
                                                </Border.Background>
                                            </Border>
                                        </Grid>
                                    </Border>
                                    <!-- Log -->
                                    <TextBox Grid.Row="2" Grid.ColumnSpan="2" x:Name="LogBox" Background="Transparent" Foreground="#4A6090"
                                             FontFamily="Consolas" FontSize="9" BorderThickness="0" IsReadOnly="True"
                                             TextWrapping="Wrap" VerticalScrollBarVisibility="Auto" Padding="2,1,2,1" AcceptsReturn="True"/>
                                </Grid>
                            </Border>
                        </Grid>
                    </Border>
                </Grid>

                <!-- NO INTERNET OVERLAY -->
                <Border x:Name="NoInternetOverlay" Grid.Row="0" Grid.RowSpan="3"
                        Visibility="Collapsed" Background="#E60B0F1E" CornerRadius="14">
                    <StackPanel VerticalAlignment="Center" HorizontalAlignment="Center">
                        <TextBlock Text="!" FontSize="48" Foreground="#FF5555" HorizontalAlignment="Center" Margin="0,0,0,10" FontWeight="Bold"/>
                        <TextBlock Text="No Internet Connection" FontSize="20" FontWeight="Bold" Foreground="#FF6666" HorizontalAlignment="Center"/>
                        <TextBlock Text="Please check your network and try again." FontSize="13" Foreground="#7B8CDE" HorizontalAlignment="Center" Margin="0,8,0,16"/>
                        <Button x:Name="BtnRetryInternet" Style="{StaticResource PrimaryBtn}" Content="Retry" Width="120" HorizontalAlignment="Center"/>
                    </StackPanel>
                </Border>

                <!-- INSTALL/UPDATE SPLASH OVERLAY -->
                <Border x:Name="InstallOverlay" Grid.Row="0" Grid.RowSpan="3"
                        Visibility="Collapsed" CornerRadius="14" ClipToBounds="True">
                    <Border.Background>
                        <LinearGradientBrush StartPoint="0,0" EndPoint="1,1">
                            <GradientStop Color="#F5080C1A" Offset="0"/>
                            <GradientStop Color="#F50A1025" Offset="0.5"/>
                            <GradientStop Color="#F5070A16" Offset="1"/>
                        </LinearGradientBrush>
                    </Border.Background>
                    <Grid>
                        <!-- Background glow orb (top-left) -->
                        <Ellipse Width="500" Height="500" HorizontalAlignment="Center" VerticalAlignment="Center"
                                 Margin="0,-120,0,0" IsHitTestVisible="False">
                            <Ellipse.Fill>
                                <RadialGradientBrush>
                                    <GradientStop Color="#185B6CF9" Offset="0"/>
                                    <GradientStop Color="#089B6CFF" Offset="0.5"/>
                                    <GradientStop Color="Transparent" Offset="1"/>
                                </RadialGradientBrush>
                            </Ellipse.Fill>
                        </Ellipse>
                        <!-- Background glow orb (bottom-right) -->
                        <Ellipse Width="400" Height="400" HorizontalAlignment="Right" VerticalAlignment="Bottom"
                                 Margin="0,0,-60,-40" IsHitTestVisible="False">
                            <Ellipse.Fill>
                                <RadialGradientBrush>
                                    <GradientStop Color="#0C7A8CFF" Offset="0"/>
                                    <GradientStop Color="Transparent" Offset="1"/>
                                </RadialGradientBrush>
                            </Ellipse.Fill>
                        </Ellipse>

                        <!-- Central content -->
                        <StackPanel VerticalAlignment="Center" HorizontalAlignment="Center">
                            <!-- Pulsing ring / icon container -->
                            <Grid Width="100" Height="100" HorizontalAlignment="Center" Margin="0,0,0,24">
                                <!-- Outer pulsing ring -->
                                <Border x:Name="OverlayPulseRing" Width="100" Height="100" CornerRadius="50"
                                        BorderThickness="2" Opacity="0.4"
                                        HorizontalAlignment="Center" VerticalAlignment="Center">
                                    <Border.BorderBrush>
                                        <LinearGradientBrush StartPoint="0,0" EndPoint="1,1">
                                            <GradientStop Color="#5B6CF9" Offset="0"/>
                                            <GradientStop Color="#9B6CFF" Offset="1"/>
                                        </LinearGradientBrush>
                                    </Border.BorderBrush>
                                    <Border.Background>
                                        <RadialGradientBrush>
                                            <GradientStop Color="#155B6CF9" Offset="0"/>
                                            <GradientStop Color="Transparent" Offset="1"/>
                                        </RadialGradientBrush>
                                    </Border.Background>
                                </Border>
                                <!-- Inner icon -->
                                <Border Width="64" Height="64" CornerRadius="16"
                                        HorizontalAlignment="Center" VerticalAlignment="Center">
                                    <Border.Background>
                                        <LinearGradientBrush StartPoint="0,0" EndPoint="1,1">
                                            <GradientStop Color="#1A2050" Offset="0"/>
                                            <GradientStop Color="#141838" Offset="1"/>
                                        </LinearGradientBrush>
                                    </Border.Background>
                                    <Border.BorderBrush>
                                        <LinearGradientBrush StartPoint="0,0" EndPoint="1,1">
                                            <GradientStop Color="#2A3580" Offset="0"/>
                                            <GradientStop Color="#5B6CF9" Offset="1"/>
                                        </LinearGradientBrush>
                                    </Border.BorderBrush>
                                    <Border.BorderThickness>
                                        <Thickness>1.5</Thickness>
                                    </Border.BorderThickness>
                                    <TextBlock x:Name="OverlayIcon" Text="&#xE896;" FontFamily="Segoe MDL2 Assets"
                                               FontSize="26" HorizontalAlignment="Center" VerticalAlignment="Center">
                                        <TextBlock.Foreground>
                                            <LinearGradientBrush StartPoint="0,0" EndPoint="1,1">
                                                <GradientStop Color="#7B8CFF" Offset="0"/>
                                                <GradientStop Color="#9B6CFF" Offset="1"/>
                                            </LinearGradientBrush>
                                        </TextBlock.Foreground>
                                    </TextBlock>
                                </Border>
                            </Grid>

                            <!-- App name (large) -->
                            <TextBlock x:Name="OverlayAppName" Text="" FontSize="26" FontWeight="Bold"
                                       Foreground="White" HorizontalAlignment="Center" Margin="0,0,0,6"
                                       TextAlignment="Center"/>

                            <!-- Operation type: INSTALLING / UPDATING -->
                            <TextBlock x:Name="OverlayAction" Text="I N S T A L L I N G" FontSize="12"
                                       FontWeight="SemiBold" HorizontalAlignment="Center" Margin="0,0,0,24">
                                <TextBlock.Foreground>
                                    <LinearGradientBrush StartPoint="0,0" EndPoint="1,0">
                                        <GradientStop Color="#5B6CF9" Offset="0"/>
                                        <GradientStop Color="#9B6CFF" Offset="1"/>
                                    </LinearGradientBrush>
                                </TextBlock.Foreground>
                            </TextBlock>

                            <!-- Progress bar -->
                            <Border CornerRadius="4" Height="6" Width="280" Background="#0D1020"
                                    BorderThickness="1" BorderBrush="#1A1E38" HorizontalAlignment="Center" Margin="0,0,0,10">
                                <Grid>
                                    <Border x:Name="OverlayProgressGlow" CornerRadius="4" HorizontalAlignment="Left" Width="0" Opacity="0.35">
                                        <Border.Background>
                                            <LinearGradientBrush StartPoint="0,0" EndPoint="1,0">
                                                <GradientStop Color="#5B6CF9" Offset="0"/>
                                                <GradientStop Color="#9B6CFF" Offset="1"/>
                                            </LinearGradientBrush>
                                        </Border.Background>
                                    </Border>
                                    <Border x:Name="OverlayProgressFill" CornerRadius="4" HorizontalAlignment="Left" Width="0">
                                        <Border.Background>
                                            <LinearGradientBrush StartPoint="0,0" EndPoint="1,0">
                                                <GradientStop Color="#5B6CF9" Offset="0"/>
                                                <GradientStop Color="#9B6CFF" Offset="1"/>
                                            </LinearGradientBrush>
                                        </Border.Background>
                                    </Border>
                                </Grid>
                            </Border>

                            <!-- Progress counter -->
                            <TextBlock x:Name="OverlayProgress" Text="0 / 0" FontSize="11"
                                       Foreground="#3A4580" HorizontalAlignment="Center" Margin="0,0,0,4"/>

                            <!-- Sub-status (e.g. "Please wait...") -->
                            <TextBlock x:Name="OverlaySubStatus" Text="Please wait..." FontSize="11"
                                       Foreground="#4A5888" HorizontalAlignment="Center"/>
                        </StackPanel>
                    </Grid>
                </Border>

                <!-- FOOTER -->
                <Border Grid.Row="2" BorderThickness="0,1,0,0" BorderBrush="#221A2855">
                    <Border.Background>
                        <LinearGradientBrush StartPoint="0,0" EndPoint="1,0">
                            <GradientStop Color="#60040816" Offset="0"/>
                            <GradientStop Color="#80060A1D" Offset="0.5"/>
                            <GradientStop Color="#60040816" Offset="1"/>
                        </LinearGradientBrush>
                    </Border.Background>
                    <Grid Margin="18,0,18,0">
                        <Grid.ColumnDefinitions>
                            <ColumnDefinition Width="*"/>
                            <ColumnDefinition Width="Auto"/>
                            <ColumnDefinition Width="*"/>
                        </Grid.ColumnDefinitions>
                        <TextBlock Grid.Column="0" Text="Administrator Mode" Foreground="#1E2440" FontSize="8" VerticalAlignment="Center"/>
                        <TextBlock Grid.Column="1" Text="HumanTouch Optimizer v2.0" FontSize="8" VerticalAlignment="Center" Foreground="#2A3060"/>
                        <TextBlock Grid.Column="2" Text="Windows 10 / 11" Foreground="#1E2440" FontSize="8" VerticalAlignment="Center" HorizontalAlignment="Right"/>
                    </Grid>
                </Border>
            </Grid>
            </Grid>
        </Border>
    </Border>
</Window>
'@

# --- MODULE: XAML.ps1 END ---


# =====================================================================
# INITIALIZE WINDOW
# =====================================================================
$script:Reader = New-Object System.Xml.XmlNodeReader($script:XAML)
try {
    $script:Window = [Windows.Markup.XamlReader]::Load($script:Reader)
} catch {
    [System.Windows.MessageBox]::Show(
        "Failed to load UI:`n$($_.Exception.Message)",
        "UI Load Error",
        [System.Windows.MessageBoxButton]::OK,
        [System.Windows.MessageBoxImage]::Error
    ) | Out-Null
    exit 1
}

# Named control references
$script:AppListPanel      = $script:Window.FindName("AppListPanel")
$script:BtnInstall        = $script:Window.FindName("BtnInstall")
$script:BtnClear          = $script:Window.FindName("BtnClear")
$script:BtnClose          = $script:Window.FindName("BtnClose")
$script:BtnMinimize       = $script:Window.FindName("BtnMinimize")
$script:DragBar           = $script:Window.FindName("DragBar")
$script:StatusLabel       = $script:Window.FindName("StatusLabel")
$script:ProgressFill      = $script:Window.FindName("ProgressFill")
$script:ProgressGlow      = $script:Window.FindName("ProgressGlow")
$script:ProgressLabel     = $script:Window.FindName("ProgressLabel")
$script:LogBox            = $script:Window.FindName("LogBox")
$script:SelectedCounter   = $script:Window.FindName("SelectedCounter")
$script:NoInternetOverlay = $script:Window.FindName("NoInternetOverlay")
$script:BtnRetryInternet  = $script:Window.FindName("BtnRetryInternet")
$script:BtnPresetGaming   = $script:Window.FindName("BtnPresetGaming")
$script:BtnPresetWork     = $script:Window.FindName("BtnPresetWork")
$script:BtnPresetMedia    = $script:Window.FindName("BtnPresetMedia")
$script:BtnSavePreset     = $script:Window.FindName("BtnSavePreset")
$script:BtnLoadPreset     = $script:Window.FindName("BtnLoadPreset")
$script:BtnCheckUpdates  = $script:Window.FindName("BtnCheckUpdates")

# Install/Update overlay references
$script:InstallOverlay      = $script:Window.FindName("InstallOverlay")
$script:OverlayPulseRing    = $script:Window.FindName("OverlayPulseRing")
$script:OverlayIcon         = $script:Window.FindName("OverlayIcon")
$script:OverlayAppName      = $script:Window.FindName("OverlayAppName")
$script:OverlayAction       = $script:Window.FindName("OverlayAction")
$script:OverlayProgressFill = $script:Window.FindName("OverlayProgressFill")
$script:OverlayProgressGlow = $script:Window.FindName("OverlayProgressGlow")
$script:OverlayProgress     = $script:Window.FindName("OverlayProgress")
$script:OverlaySubStatus    = $script:Window.FindName("OverlaySubStatus")

# State maps
$script:CheckBoxMap        = @{}
$script:AppCardMap         = @{}
$script:InstalledBadgeMap  = @{}
$script:UpdateBadgeMap     = @{}
$script:StatusBadgeMap     = @{}
$script:PresetButtons      = @($script:BtnPresetGaming, $script:BtnPresetWork, $script:BtnPresetMedia)

# Load remaining modules (they need Window reference)

# --- MODULE: Helpers.ps1 START ---
# =====================================================================
# HELPERS.PS1 - Utility Functions
# =====================================================================

function Test-InternetConnection {
    try {
        $req = [System.Net.WebRequest]::Create("http://www.msftconnecttest.com/connecttest.txt")
        $req.Timeout = 3000
        $req.Method = "HEAD"
        $resp = $req.GetResponse()
        $resp.Close()
        return $true
    } catch {
        return $false
    }
}

function Write-Log {
    param([string]$Message)
    $ts   = Get-Date -Format "HH:mm:ss"
    $line = "[$ts]  $Message"
    $script:Window.Dispatcher.Invoke([action]{
        $script:LogBox.AppendText("$line`r`n")
        $script:LogBox.ScrollToEnd()
    })
}

function Set-Status {
    param([string]$Message)
    $script:Window.Dispatcher.Invoke([action]{
        $script:StatusLabel.Text = $Message
    })
}

function Set-Progress {
    param([int]$Current, [int]$Total)
    $script:Window.Dispatcher.Invoke([action]{
        $script:ProgressLabel.Text = "$Current / $Total"
        if ($Total -gt 0) {
            $pw = $script:ProgressFill.Parent.ActualWidth
            if ($pw -le 0) { $pw = 200 }
            $fw = [Math]::Round(($Current / $Total) * $pw, 1)
            $script:ProgressFill.Width = $fw
            $script:ProgressGlow.Width = $fw
        }
    })
}

function Set-UIEnabled {
    param([bool]$State)
    $script:Window.Dispatcher.Invoke([action]{
        $script:BtnInstall.IsEnabled      = $State
        $script:BtnCheckUpdates.IsEnabled = $State
        $script:BtnClear.IsEnabled        = $State
        foreach ($btn in $script:PresetButtons) {
            $btn.IsEnabled = $State
        }
    })
}

function Update-Counter {
    $count = 0
    foreach ($id in $script:CheckBoxMap.Keys) {
        if ($script:CheckBoxMap[$id].IsChecked -eq $true) { $count++ }
    }
    $script:SelectedCounter.Text = "$count"
    $script:BtnInstall.IsEnabled = ($count -gt 0)
}

function Set-AppCardInstalled {
    param([string]$AppId)
    $script:Window.Dispatcher.Invoke([action]{
        $card = $script:AppCardMap[$AppId]
        if ($card) {
            # Animate opacity to full
            $anim = New-Object System.Windows.Media.Animation.DoubleAnimation
            $anim.From     = $card.Opacity
            $anim.To       = 1.0
            $anim.Duration = New-Object System.Windows.Duration([TimeSpan]::FromMilliseconds(600))
            $anim.EasingFunction = New-Object System.Windows.Media.Animation.QuadraticEase
            $card.BeginAnimation([System.Windows.UIElement]::OpacityProperty, $anim)

            # Add green check indicator
            $indicator = $card.FindName("InstallIndicator_$($AppId.Replace('.','_'))")
            if ($indicator) {
                $indicator.Visibility = [System.Windows.Visibility]::Visible
            }
        }
    })
}

function Show-NoInternetOverlay {
    $script:Window.Dispatcher.Invoke([action]{
        $script:NoInternetOverlay.Visibility = [System.Windows.Visibility]::Visible
    })
}

function Hide-NoInternetOverlay {
    $script:Window.Dispatcher.Invoke([action]{
        $script:NoInternetOverlay.Visibility = [System.Windows.Visibility]::Collapsed
    })
}

# --- MODULE: Helpers.ps1 END ---


# --- MODULE: Presets.ps1 START ---
# =====================================================================
# PRESETS.PS1 - Save/Load Custom User Presets (File Dialog based)
# =====================================================================

function Import-PresetById {
    param([string[]]$Ids)
    foreach ($id in $script:CheckBoxMap.Keys) {
        $script:CheckBoxMap[$id].IsChecked = ($Ids -contains $id)
    }
    Update-Counter
}

function Show-SavePresetDialog {
    # Check if any apps are selected
    $selectedIds = @()
    foreach ($id in $script:CheckBoxMap.Keys) {
        if ($script:CheckBoxMap[$id].IsChecked -eq $true) {
            $selectedIds += $id
        }
    }

    if ($selectedIds.Count -eq 0) {
        [System.Windows.MessageBox]::Show(
            "Please select at least one application before saving a preset.",
            "No Selection",
            [System.Windows.MessageBoxButton]::OK,
            [System.Windows.MessageBoxImage]::Information
        ) | Out-Null
        return
    }

    # Use Windows SaveFileDialog
    $dlg = New-Object Microsoft.Win32.SaveFileDialog
    $dlg.Title = "Save Preset As"
    $dlg.Filter = "HumanTouch Preset (*.htpreset)|*.htpreset|JSON Files (*.json)|*.json"
    $dlg.DefaultExt = ".htpreset"
    $dlg.FileName = "MyPreset"
    $dlg.InitialDirectory = [Environment]::GetFolderPath("Desktop")

    $result = $dlg.ShowDialog($script:Window)

    if ($result -eq $true) {
        $presetName = [System.IO.Path]::GetFileNameWithoutExtension($dlg.FileName)
        $obj = @{
            Name    = $presetName
            AppIds  = $selectedIds
            Created = (Get-Date -Format "yyyy-MM-dd HH:mm")
            Version = "2.0"
        }
        $obj | ConvertTo-Json | Set-Content -Path $dlg.FileName -Encoding UTF8
        Write-Log "Preset saved: $presetName ($($selectedIds.Count) apps)"
        Set-Status "Preset '$presetName' saved to $($dlg.FileName)"
    }
}

function Show-LoadPresetDialog {
    # Use Windows OpenFileDialog
    $dlg = New-Object Microsoft.Win32.OpenFileDialog
    $dlg.Title = "Load Preset"
    $dlg.Filter = "HumanTouch Preset (*.htpreset)|*.htpreset|JSON Files (*.json)|*.json|All Files (*.*)|*.*"
    $dlg.DefaultExt = ".htpreset"
    $dlg.InitialDirectory = [Environment]::GetFolderPath("Desktop")

    $result = $dlg.ShowDialog($script:Window)

    if ($result -eq $true) {
        try {
            $data = Get-Content $dlg.FileName -Raw | ConvertFrom-Json
            $ids = @($data.AppIds)
            $presetName = if ($data.Name) { $data.Name } else { [System.IO.Path]::GetFileNameWithoutExtension($dlg.FileName) }

            Import-PresetById -Ids $ids
            Write-Log "Preset loaded: $presetName ($($ids.Count) apps)"
            Set-Status "Preset '$presetName' loaded from file."
        } catch {
            [System.Windows.MessageBox]::Show(
                "Failed to load preset file.`n`nError: $($_.Exception.Message)",
                "Load Error",
                [System.Windows.MessageBoxButton]::OK,
                [System.Windows.MessageBoxImage]::Error
            ) | Out-Null
        }
    }
}

# --- MODULE: Presets.ps1 END ---


# --- MODULE: Builder.ps1 START ---
# =====================================================================
# BUILDER.PS1 - Dynamic UI Construction (Responsive App Cards)
# =====================================================================

function Initialize-AppList {
    $catIcons = @{
        "BROWSERS"       = [char]0xE774
        "COMMUNICATION"  = [char]0xE8BD
        "GAMING"         = [char]0xE7FC
        "SYSTEM TOOLS"   = [char]0xE912
        "MEDIA"          = [char]0xE714
        "DEVELOPMENT"    = [char]0xE943
    }

    foreach ($category in $script:AppCategories.Keys) {
        # Each category = vertical card containing header + apps
        $card                  = New-Object System.Windows.Controls.Border
        $card.CornerRadius     = New-Object System.Windows.CornerRadius(12)
        $card.Width            = 240
        $card.Margin           = New-Object System.Windows.Thickness(0, 0, 10, 10)
        $card.Padding          = New-Object System.Windows.Thickness(0, 0, 0, 6)
        $card.BorderThickness  = New-Object System.Windows.Thickness(1)
        $card.BorderBrush      = [System.Windows.Media.SolidColorBrush]([System.Windows.Media.ColorConverter]::ConvertFromString("#2E3A75"))
        $card.VerticalAlignment = [System.Windows.VerticalAlignment]::Top

        $cardBg             = New-Object System.Windows.Media.LinearGradientBrush
        $cardBg.StartPoint  = New-Object System.Windows.Point(0, 0)
        $cardBg.EndPoint    = New-Object System.Windows.Point(0, 1)
        $s1 = New-Object System.Windows.Media.GradientStop
        $s1.Color  = [System.Windows.Media.ColorConverter]::ConvertFromString("#55121B3B")
        $s1.Offset = 0
        $s2 = New-Object System.Windows.Media.GradientStop
        $s2.Color  = [System.Windows.Media.ColorConverter]::ConvertFromString("#440C1229")
        $s2.Offset = 1
        $cardBg.GradientStops.Add($s1) | Out-Null
        $cardBg.GradientStops.Add($s2) | Out-Null
        $card.Background = $cardBg

        $shadow              = New-Object System.Windows.Media.Effects.DropShadowEffect
        $shadow.BlurRadius   = 12
        $shadow.ShadowDepth  = 2
        $shadow.Direction    = 270
        $shadow.Color        = [System.Windows.Media.Colors]::Black
        $shadow.Opacity      = 0.3
        $card.Effect         = $shadow

        # Hover Effects
        $card.Add_MouseEnter({
            $this.BorderBrush = [System.Windows.Media.SolidColorBrush]([System.Windows.Media.ColorConverter]::ConvertFromString("#3B4BE8"))
            $this.Effect.Color = [System.Windows.Media.ColorConverter]::ConvertFromString("#3B4BE8")
            $this.Effect.BlurRadius = 16
            $this.Effect.Opacity = 0.25
        })
        $card.Add_MouseLeave({
            $this.BorderBrush = [System.Windows.Media.SolidColorBrush]([System.Windows.Media.ColorConverter]::ConvertFromString("#1E2858"))
            $this.Effect.Color = [System.Windows.Media.Colors]::Black
            $this.Effect.BlurRadius = 12
            $this.Effect.Opacity = 0.3
        })

        $innerStack = New-Object System.Windows.Controls.StackPanel

        # -- Category Header --
        $headerBorder = New-Object System.Windows.Controls.Border
        $headerBorder.Padding = New-Object System.Windows.Thickness(12, 8, 12, 8)
        $headerBorder.BorderThickness = New-Object System.Windows.Thickness(0, 0, 0, 1)
        $headerBorder.BorderBrush = [System.Windows.Media.SolidColorBrush]([System.Windows.Media.ColorConverter]::ConvertFromString("#141828"))
        $hBg = New-Object System.Windows.Media.LinearGradientBrush
        $hBg.StartPoint = New-Object System.Windows.Point(0, 0)
        $hBg.EndPoint   = New-Object System.Windows.Point(1, 0)
        $hs1 = New-Object System.Windows.Media.GradientStop
        $hs1.Color  = [System.Windows.Media.ColorConverter]::ConvertFromString("#80121B3D")
        $hs1.Offset = 0
        $hs2 = New-Object System.Windows.Media.GradientStop
        $hs2.Color  = [System.Windows.Media.ColorConverter]::ConvertFromString("#600D132D")
        $hs2.Offset = 1
        $hBg.GradientStops.Add($hs1) | Out-Null
        $hBg.GradientStops.Add($hs2) | Out-Null
        $headerBorder.Background = $hBg

        $hGrid = New-Object System.Windows.Controls.Grid
        $c1 = New-Object System.Windows.Controls.ColumnDefinition
        $c1.Width = [System.Windows.GridLength]::Auto
        $c2 = New-Object System.Windows.Controls.ColumnDefinition
        $c2.Width = New-Object System.Windows.GridLength(1, [System.Windows.GridUnitType]::Star)
        $c3 = New-Object System.Windows.Controls.ColumnDefinition
        $c3.Width = [System.Windows.GridLength]::Auto
        $hGrid.ColumnDefinitions.Add($c1) | Out-Null
        $hGrid.ColumnDefinitions.Add($c2) | Out-Null
        $hGrid.ColumnDefinitions.Add($c3) | Out-Null

        # Icon
        $icon = New-Object System.Windows.Controls.TextBlock
        $icon.Text = if ($catIcons.ContainsKey($category)) { "$($catIcons[$category])" } else { [char]0x25CF }
        $icon.FontFamily = New-Object System.Windows.Media.FontFamily("Segoe MDL2 Assets")
        $icon.FontSize = 14
        $icon.Foreground = [System.Windows.Media.SolidColorBrush]([System.Windows.Media.ColorConverter]::ConvertFromString("#5B6CF9"))
        $icon.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
        $icon.Margin = New-Object System.Windows.Thickness(0, 0, 8, 0)
        [System.Windows.Controls.Grid]::SetColumn($icon, 0)

        $catTitle = New-Object System.Windows.Controls.TextBlock
        $catTitle.Text = $category
        $catTitle.FontSize = 10
        $catTitle.FontWeight = [System.Windows.FontWeights]::SemiBold
        $catTitle.Foreground = [System.Windows.Media.SolidColorBrush]([System.Windows.Media.ColorConverter]::ConvertFromString("#8090C8"))
        $catTitle.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
        [System.Windows.Controls.Grid]::SetColumn($catTitle, 1)

        $badge = New-Object System.Windows.Controls.Border
        $badge.CornerRadius = New-Object System.Windows.CornerRadius(8)
        $badge.Padding = New-Object System.Windows.Thickness(6, 1, 6, 1)
        $badge.Background = [System.Windows.Media.SolidColorBrush]([System.Windows.Media.ColorConverter]::ConvertFromString("#141C3C"))
        $badgeTxt = New-Object System.Windows.Controls.TextBlock
        $badgeTxt.Text = "$($script:AppCategories[$category].Count)"
        $badgeTxt.Foreground = [System.Windows.Media.SolidColorBrush]([System.Windows.Media.ColorConverter]::ConvertFromString("#4A5888"))
        $badgeTxt.FontSize = 9
        $badge.Child = $badgeTxt
        [System.Windows.Controls.Grid]::SetColumn($badge, 2)

        $hGrid.Children.Add($icon)     | Out-Null
        $hGrid.Children.Add($catTitle) | Out-Null
        $hGrid.Children.Add($badge)    | Out-Null
        $headerBorder.Child = $hGrid
        $innerStack.Children.Add($headerBorder) | Out-Null

        # -- App Checkboxes --

        $appsPanel = New-Object System.Windows.Controls.StackPanel
        $appsPanel.Margin = New-Object System.Windows.Thickness(6, 4, 6, 0)

        foreach ($app in $script:AppCategories[$category]) {
            # Wrap each checkbox in a border for opacity animation
            $appCard = New-Object System.Windows.Controls.Border
            $appCard.Opacity = 1.0

            # Grid row: checkbox + status badge + installed badge + update badge
            $appGrid = New-Object System.Windows.Controls.Grid
            $col1 = New-Object System.Windows.Controls.ColumnDefinition
            $col1.Width = New-Object System.Windows.GridLength(1, [System.Windows.GridUnitType]::Star)
            $colStatus = New-Object System.Windows.Controls.ColumnDefinition
            $colStatus.Width = [System.Windows.GridLength]::Auto
            $col2 = New-Object System.Windows.Controls.ColumnDefinition
            $col2.Width = [System.Windows.GridLength]::Auto
            $col3 = New-Object System.Windows.Controls.ColumnDefinition
            $col3.Width = [System.Windows.GridLength]::Auto
            $appGrid.ColumnDefinitions.Add($col1) | Out-Null
            $appGrid.ColumnDefinitions.Add($colStatus) | Out-Null
            $appGrid.ColumnDefinitions.Add($col2) | Out-Null
            $appGrid.ColumnDefinitions.Add($col3) | Out-Null

            $cb = New-Object System.Windows.Controls.CheckBox
            $cb.Content = $app.Name
            $cb.Tag     = $app.Id
            $cb.Style   = $script:Window.Resources["ToggleCheckBox"]
            $cb.Add_Checked({ Update-Counter })
            $cb.Add_Unchecked({ Update-Counter })
            [System.Windows.Controls.Grid]::SetColumn($cb, 0)

            # Status badge (shows "Installing...", "Updating...", "[Done]" etc.)
            $statusBadge = New-Object System.Windows.Controls.Border
            $statusBadge.CornerRadius = New-Object System.Windows.CornerRadius(6)
            $statusBadge.Padding = New-Object System.Windows.Thickness(6, 2, 6, 2)
            $statusBadge.Margin = New-Object System.Windows.Thickness(2, 0, 2, 0)
            $statusBadge.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
            $statusBadge.Visibility = [System.Windows.Visibility]::Collapsed
            $statusBadge.Background = [System.Windows.Media.SolidColorBrush]([System.Windows.Media.ColorConverter]::ConvertFromString("#335B6CF9"))
            $statusBadge.BorderThickness = New-Object System.Windows.Thickness(1)
            $statusBadge.BorderBrush = [System.Windows.Media.SolidColorBrush]([System.Windows.Media.ColorConverter]::ConvertFromString("#555B6CF9"))

            $statusText = New-Object System.Windows.Controls.TextBlock
            $statusText.Text = ""
            $statusText.FontSize = 9
            $statusText.FontWeight = [System.Windows.FontWeights]::SemiBold
            $statusText.Foreground = [System.Windows.Media.SolidColorBrush]([System.Windows.Media.ColorConverter]::ConvertFromString("#7B8CFF"))
            $statusText.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
            $statusBadge.Child = $statusText
            [System.Windows.Controls.Grid]::SetColumn($statusBadge, 1)

            # Installed indicator (hidden by default)
            $installedBadge = New-Object System.Windows.Controls.Border
            $installedBadge.CornerRadius = New-Object System.Windows.CornerRadius(6)
            $installedBadge.Padding = New-Object System.Windows.Thickness(6, 2, 6, 2)
            $installedBadge.Margin = New-Object System.Windows.Thickness(4, 0, 6, 0)
            $installedBadge.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
            $installedBadge.Visibility = [System.Windows.Visibility]::Collapsed
            $installedBadge.Background = [System.Windows.Media.SolidColorBrush]([System.Windows.Media.ColorConverter]::ConvertFromString("#3322C55E"))

            $badgeStack = New-Object System.Windows.Controls.StackPanel
            $badgeStack.Orientation = [System.Windows.Controls.Orientation]::Horizontal

            $checkIcon = New-Object System.Windows.Controls.TextBlock
            $checkIcon.Text = "$([char]0xE73E)"
            $checkIcon.FontFamily = New-Object System.Windows.Media.FontFamily("Segoe MDL2 Assets")
            $checkIcon.FontSize = 9
            $checkIcon.Foreground = [System.Windows.Media.SolidColorBrush]([System.Windows.Media.ColorConverter]::ConvertFromString("#22C55E"))
            $checkIcon.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
            $badgeStack.Children.Add($checkIcon) | Out-Null
            $installedBadge.ToolTip = "Installed"
            $installedBadge.Child = $badgeStack
            [System.Windows.Controls.Grid]::SetColumn($installedBadge, 2)

            # Update available indicator (hidden by default) - prominent orange
            $updateBadge = New-Object System.Windows.Controls.Border
            $updateBadge.CornerRadius = New-Object System.Windows.CornerRadius(6)
            $updateBadge.Padding = New-Object System.Windows.Thickness(6, 2, 6, 2)
            $updateBadge.Margin = New-Object System.Windows.Thickness(2, 0, 6, 0)
            $updateBadge.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
            $updateBadge.Visibility = [System.Windows.Visibility]::Collapsed
            $updateBadge.Background = [System.Windows.Media.SolidColorBrush]([System.Windows.Media.ColorConverter]::ConvertFromString("#66F59E0B"))
            $updateBadge.BorderThickness = New-Object System.Windows.Thickness(1)
            $updateBadge.BorderBrush = [System.Windows.Media.SolidColorBrush]([System.Windows.Media.ColorConverter]::ConvertFromString("#99F59E0B"))
            $updateBadge.Cursor = [System.Windows.Input.Cursors]::Hand
            $updateBadge.ToolTip = "Click to update this application"

            $updStack = New-Object System.Windows.Controls.StackPanel
            $updStack.Orientation = [System.Windows.Controls.Orientation]::Horizontal

            $updIcon = New-Object System.Windows.Controls.TextBlock
            $updIcon.Text = "$([char]0xE72C)"
            $updIcon.FontFamily = New-Object System.Windows.Media.FontFamily("Segoe MDL2 Assets")
            $updIcon.FontSize = 9
            $updIcon.Foreground = [System.Windows.Media.SolidColorBrush]([System.Windows.Media.ColorConverter]::ConvertFromString("#F59E0B"))
            $updIcon.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
            $updIcon.Margin = New-Object System.Windows.Thickness(0, 0, 3, 0)

            $updText = New-Object System.Windows.Controls.TextBlock
            $updText.Text = "Update"
            $updText.FontSize = 9
            $updText.FontWeight = [System.Windows.FontWeights]::SemiBold
            $updText.Foreground = [System.Windows.Media.SolidColorBrush]([System.Windows.Media.ColorConverter]::ConvertFromString("#F59E0B"))
            $updText.VerticalAlignment = [System.Windows.VerticalAlignment]::Center

            $updStack.Children.Add($updIcon) | Out-Null
            $updStack.Children.Add($updText) | Out-Null
            $updateBadge.Child = $updStack
            $updateBadge.Tag = $app.Id
            $updateBadge.Add_MouseLeftButtonDown({
                param($s, $e)
                $appObj = $null
                foreach ($cat in $script:AppCategories.Keys) {
                    foreach ($a in $script:AppCategories[$cat]) {
                        if ($a.Id -eq $s.Tag) { $appObj = $a; break }
                    }
                }
                if ($appObj) { Update-App -Id $appObj.Id -Name $appObj.Name }
            })
            [System.Windows.Controls.Grid]::SetColumn($updateBadge, 3)

            $appGrid.Children.Add($cb) | Out-Null
            $appGrid.Children.Add($statusBadge) | Out-Null
            $appGrid.Children.Add($installedBadge) | Out-Null
            $appGrid.Children.Add($updateBadge) | Out-Null

            $script:CheckBoxMap[$app.Id] = $cb
            $script:AppCardMap[$app.Id]  = $appCard
            $script:InstalledBadgeMap[$app.Id] = $installedBadge
            $script:UpdateBadgeMap[$app.Id] = $updateBadge
            $script:StatusBadgeMap[$app.Id] = $statusBadge

            $appCard.Child = $appGrid
            $appsPanel.Children.Add($appCard) | Out-Null
        }

        $innerStack.Children.Add($appsPanel) | Out-Null

        $card.Child = $innerStack
        $script:AppListPanel.Children.Add($card) | Out-Null
    }
}

# --- MODULE: Builder.ps1 END ---


# --- MODULE: Installer.ps1 START ---
# =====================================================================
# INSTALLER.PS1 - Background Installation Engine
# =====================================================================

function Show-InstallOverlay {
    param([string]$Action, [string]$AppName, [string]$SubText, [string]$IconChar, [string]$ProgressText,
          [switch]$ShowProgressBar)

    $script:Window.Dispatcher.Invoke([action]{
        $script:InstallOverlay.Opacity = 0
        $script:InstallOverlay.Visibility = [System.Windows.Visibility]::Visible
        $script:OverlayAction.Text = $Action
        $script:OverlayAppName.Text = $AppName
        $script:OverlayProgress.Text = $ProgressText
        $script:OverlaySubStatus.Text = $SubText
        $script:OverlayIcon.Text = $IconChar

        # Reset overlay progress bar
        $script:OverlayProgressFill.Width = 0
        $script:OverlayProgressGlow.Width = 0

        # Show/hide progress bar based on mode
        $pbParent = $script:OverlayProgressFill.Parent.Parent  # Border containing Grid
        if ($ShowProgressBar) {
            $pbParent.Visibility = [System.Windows.Visibility]::Visible
            $script:OverlayProgress.Visibility = [System.Windows.Visibility]::Visible
        } else {
            $pbParent.Visibility = [System.Windows.Visibility]::Collapsed
            $script:OverlayProgress.Visibility = [System.Windows.Visibility]::Collapsed
        }

        # Fade in animation
        $fadeIn = New-Object System.Windows.Media.Animation.DoubleAnimation
        $fadeIn.From = 0; $fadeIn.To = 1.0
        $fadeIn.Duration = New-Object System.Windows.Duration([TimeSpan]::FromMilliseconds(400))
        $fadeIn.EasingFunction = New-Object System.Windows.Media.Animation.QuadraticEase
        $script:InstallOverlay.BeginAnimation([System.Windows.UIElement]::OpacityProperty, $fadeIn)
    })

    # Start pulse animation timer for the ring
    if ($script:OverlayPulseTimer) {
        try { $script:OverlayPulseTimer.Stop() } catch {}
    }
    $script:OverlayPulseTimer = New-Object System.Windows.Threading.DispatcherTimer
    $script:OverlayPulseTimer.Interval = [TimeSpan]::FromMilliseconds(1200)
    $script:OverlayPulseDirection = $true
    $script:OverlayPulseTimer.Add_Tick({
        $ring = $script:OverlayPulseRing
        if ($ring) {
            $toOpacity = if ($script:OverlayPulseDirection) { 0.8 } else { 0.25 }
            $toScale = if ($script:OverlayPulseDirection) { 110 } else { 100 }
            $script:OverlayPulseDirection = -not $script:OverlayPulseDirection

            $opAnim = New-Object System.Windows.Media.Animation.DoubleAnimation
            $opAnim.To = $toOpacity
            $opAnim.Duration = New-Object System.Windows.Duration([TimeSpan]::FromMilliseconds(1100))
            $opAnim.EasingFunction = New-Object System.Windows.Media.Animation.QuadraticEase
            $ring.BeginAnimation([System.Windows.UIElement]::OpacityProperty, $opAnim)

            $wAnim = New-Object System.Windows.Media.Animation.DoubleAnimation
            $wAnim.To = $toScale
            $wAnim.Duration = New-Object System.Windows.Duration([TimeSpan]::FromMilliseconds(1100))
            $wAnim.EasingFunction = New-Object System.Windows.Media.Animation.QuadraticEase
            $ring.BeginAnimation([System.Windows.FrameworkElement]::WidthProperty, $wAnim)

            $hAnim = New-Object System.Windows.Media.Animation.DoubleAnimation
            $hAnim.To = $toScale
            $hAnim.Duration = New-Object System.Windows.Duration([TimeSpan]::FromMilliseconds(1100))
            $hAnim.EasingFunction = New-Object System.Windows.Media.Animation.QuadraticEase
            $ring.BeginAnimation([System.Windows.FrameworkElement]::HeightProperty, $hAnim)
        }
    })
    $script:OverlayPulseTimer.Start()
}

function Start-OverlayDotsAnimation {
    param([string]$BaseText)
    $script:OverlayDotsBase = $BaseText
    $script:OverlayDotsCount = 0
    if ($script:OverlayDotsTimer) {
        try { $script:OverlayDotsTimer.Stop() } catch {}
    }
    $script:OverlayDotsTimer = New-Object System.Windows.Threading.DispatcherTimer
    $script:OverlayDotsTimer.Interval = [TimeSpan]::FromMilliseconds(500)
    $script:OverlayDotsTimer.Add_Tick({
        $script:OverlayDotsCount = ($script:OverlayDotsCount % 3) + 1
        $dots = "." * $script:OverlayDotsCount
        $script:OverlaySubStatus.Text = "$($script:OverlayDotsBase)$dots"
    })
    $script:OverlayDotsTimer.Start()
}

function Stop-OverlayDotsAnimation {
    if ($script:OverlayDotsTimer) {
        try { $script:OverlayDotsTimer.Stop() } catch {}
    }
}

function Hide-InstallOverlay {
    # Stop all overlay timers
    Stop-OverlayDotsAnimation

    $script:Window.Dispatcher.Invoke([action]{
        # Stop pulse timer
        if ($script:OverlayPulseTimer) {
            try { $script:OverlayPulseTimer.Stop() } catch {}
        }

        # Fade out
        $fadeOut = New-Object System.Windows.Media.Animation.DoubleAnimation
        $fadeOut.To = 0
        $fadeOut.Duration = New-Object System.Windows.Duration([TimeSpan]::FromMilliseconds(500))
        $fadeOut.EasingFunction = New-Object System.Windows.Media.Animation.QuadraticEase
        $script:InstallOverlay.BeginAnimation([System.Windows.UIElement]::OpacityProperty, $fadeOut)
    })

    # Use a DispatcherTimer to hide after the animation completes (500ms)
    $hideTimer = New-Object System.Windows.Threading.DispatcherTimer
    $hideTimer.Interval = [TimeSpan]::FromMilliseconds(550)
    $hideTimer.Add_Tick({
        $script:InstallOverlay.Visibility = [System.Windows.Visibility]::Collapsed
        $script:InstallOverlay.BeginAnimation([System.Windows.UIElement]::OpacityProperty, $null)
        $this.Stop()
    })
    $hideTimer.Start()
}

function Start-Installation {
    $selectedApps = [System.Collections.Generic.List[PSCustomObject]]::new()

    foreach ($id in $script:CheckBoxMap.Keys) {
        if ($script:CheckBoxMap[$id].IsChecked -eq $true) {
            foreach ($cat in $script:AppCategories.Keys) {
                foreach ($a in $script:AppCategories[$cat]) {
                    if ($a.Id -eq $id) {
                        $selectedApps.Add($a)
                        break
                    }
                }
            }
        }
    }

    if ($selectedApps.Count -eq 0) {
        [System.Windows.MessageBox]::Show(
            "Please select at least one application to install.",
            "No Selection",
            [System.Windows.MessageBoxButton]::OK,
            [System.Windows.MessageBoxImage]::Information
        ) | Out-Null
        return
    }

    # Check internet before starting
    if (-not (Test-InternetConnection)) {
        Show-NoInternetOverlay
        return
    }

    Set-UIEnabled -State $false
    Set-Progress -Current 0 -Total $selectedApps.Count
    Write-Log "Starting installation of $($selectedApps.Count) app(s)..."

    # Show the splash overlay with progress bar
    Show-InstallOverlay -Action "I N S T A L L I N G" -AppName "Preparing..." `
        -SubText "Please wait" -IconChar "$([char]0xE896)" `
        -ProgressText "0 / $($selectedApps.Count)" -ShowProgressBar
    Start-OverlayDotsAnimation -BaseText "Please wait"

    # Highlight all selected app cards and show 'Queued'
    $script:Window.Dispatcher.Invoke([action]{
        foreach ($app in $selectedApps) {
            $card = $script:AppCardMap[$app.Id]
            if ($card) { $card.Opacity = 0.8 }

            $sBadge = $script:StatusBadgeMap[$app.Id]
            if ($sBadge) {
                $sBadge.Visibility = [System.Windows.Visibility]::Visible
                $sBadge.Child.Text = "Queued"
                $sBadge.Child.Foreground = [System.Windows.Media.SolidColorBrush]([System.Windows.Media.ColorConverter]::ConvertFromString("#A0ABC0"))
                $sBadge.Background = [System.Windows.Media.SolidColorBrush]([System.Windows.Media.ColorConverter]::ConvertFromString("#333A4560"))
                $sBadge.BorderBrush = [System.Windows.Media.SolidColorBrush]([System.Windows.Media.ColorConverter]::ConvertFromString("#553A4560"))
            }
        }
    })

    $dispRef    = $script:Window.Dispatcher
    $logRef     = $script:LogBox
    $statRef    = $script:StatusLabel
    $pbFill     = $script:ProgressFill
    $pbGlow     = $script:ProgressGlow
    $pbLbl      = $script:ProgressLabel
    $btnInst    = $script:BtnInstall
    $btnClr     = $script:BtnClear
    $cardMap    = $script:AppCardMap
    $appArray   = $selectedApps.ToArray()
    $presBtns   = $script:PresetButtons
    $statusMap  = $script:StatusBadgeMap

    # Overlay refs
    $ovAppName      = $script:OverlayAppName
    $ovAction       = $script:OverlayAction
    $ovProgressFill = $script:OverlayProgressFill
    $ovProgressGlow = $script:OverlayProgressGlow
    $ovProgress     = $script:OverlayProgress
    $ovSubStatus    = $script:OverlaySubStatus
    $ovIcon         = $script:OverlayIcon

    $rs = [RunspaceFactory]::CreateRunspace()
    $rs.ApartmentState = [System.Threading.ApartmentState]::STA
    $rs.ThreadOptions  = [System.Management.Automation.Runspaces.PSThreadOptions]::ReuseThread
    $rs.Open()

    $rs.SessionStateProxy.SetVariable("dispRef",   $dispRef)
    $rs.SessionStateProxy.SetVariable("logRef",    $logRef)
    $rs.SessionStateProxy.SetVariable("statRef",   $statRef)
    $rs.SessionStateProxy.SetVariable("pbFill",    $pbFill)
    $rs.SessionStateProxy.SetVariable("pbGlow",    $pbGlow)
    $rs.SessionStateProxy.SetVariable("pbLbl",     $pbLbl)
    $rs.SessionStateProxy.SetVariable("btnInst",   $btnInst)
    $rs.SessionStateProxy.SetVariable("btnClr",    $btnClr)
    $rs.SessionStateProxy.SetVariable("cardMap",   $cardMap)
    $rs.SessionStateProxy.SetVariable("appArray",  $appArray)
    $rs.SessionStateProxy.SetVariable("presBtns",  $presBtns)
    $rs.SessionStateProxy.SetVariable("statusMap", $statusMap)
    $rs.SessionStateProxy.SetVariable("ovAppName",      $ovAppName)
    $rs.SessionStateProxy.SetVariable("ovAction",       $ovAction)
    $rs.SessionStateProxy.SetVariable("ovProgressFill", $ovProgressFill)
    $rs.SessionStateProxy.SetVariable("ovProgressGlow", $ovProgressGlow)
    $rs.SessionStateProxy.SetVariable("ovProgress",     $ovProgress)
    $rs.SessionStateProxy.SetVariable("ovSubStatus",    $ovSubStatus)
    $rs.SessionStateProxy.SetVariable("ovIcon",         $ovIcon)

    $psCode = {
        function Write-RSLog {
            param([string]$Msg)
            $ts = Get-Date -Format "HH:mm:ss"
            $line = "[$ts]  $Msg"
            $dispRef.Invoke([action]{
                $logRef.AppendText("$line`r`n")
                $logRef.ScrollToEnd()
            })
        }

        function Set-RSStatus {
            param([string]$Msg)
            $dispRef.Invoke([action]{ $statRef.Text = $Msg })
        }

        function Set-RSProgress {
            param([int]$Cur, [int]$Tot)
            $dispRef.Invoke([action]{
                $pbLbl.Text = "$Cur / $Tot"
                if ($Tot -gt 0) {
                    $pw = $pbFill.Parent.ActualWidth
                    if ($pw -le 0) { $pw = 200 }
                    $fw = [Math]::Round(($Cur / $Tot) * $pw, 1)
                    $pbFill.Width = $fw
                    $pbGlow.Width = $fw
                }
            })
        }

        function Set-OverlayProgress {
            param([int]$Cur, [int]$Tot)
            $dispRef.Invoke([action]{
                $ovProgress.Text = "$Cur / $Tot"
                if ($Tot -gt 0) {
                    $fw = [Math]::Round(($Cur / $Tot) * 278, 1)
                    $ovProgressFill.BeginAnimation([System.Windows.FrameworkElement]::WidthProperty, $null)
                    $ovProgressGlow.BeginAnimation([System.Windows.FrameworkElement]::WidthProperty, $null)
                    $ovProgressFill.Width = $fw
                    $ovProgressGlow.Width = $fw
                }
            })
        }

        function Set-OverlayApp {
            param([string]$Name, [string]$SubText)
            $dispRef.Invoke([action]{
                $ovAppName.Text = $Name
                $ovSubStatus.Text = $SubText
            })
        }

        function Invoke-RSCardAnimation {
            param([string]$Id)
            $dispRef.Invoke([action]{
                $card = $cardMap[$Id]
                if ($card) {
                    $anim = New-Object System.Windows.Media.Animation.DoubleAnimation
                    $anim.From     = $card.Opacity
                    $anim.To       = 1.0
                    $anim.Duration = New-Object System.Windows.Duration([TimeSpan]::FromMilliseconds(800))
                    $ease = New-Object System.Windows.Media.Animation.QuadraticEase
                    $ease.EasingMode = [System.Windows.Media.Animation.EasingMode]::EaseOut
                    $anim.EasingFunction = $ease
                    $card.BeginAnimation([System.Windows.UIElement]::OpacityProperty, $anim)
                }
            })
        }

        function Set-RSStatusBadge {
            param([string]$Id, [string]$Text, [string]$Color, [bool]$Visible = $true)
            $dispRef.Invoke([action]{
                $badge = $statusMap[$Id]
                if ($badge) {
                    if ($Visible) {
                        $badge.Visibility = [System.Windows.Visibility]::Visible
                        $badge.Child.Text = $Text
                        $badge.Child.Foreground = [System.Windows.Media.SolidColorBrush]([System.Windows.Media.ColorConverter]::ConvertFromString($Color))
                        $badge.Background = [System.Windows.Media.SolidColorBrush]([System.Windows.Media.ColorConverter]::ConvertFromString("$($Color.Substring(0,1))33$($Color.Substring(1))"))
                        $badge.BorderBrush = [System.Windows.Media.SolidColorBrush]([System.Windows.Media.ColorConverter]::ConvertFromString("$($Color.Substring(0,1))55$($Color.Substring(1))"))
                    } else {
                        $badge.Visibility = [System.Windows.Visibility]::Collapsed
                    }
                }
            })
        }

        function Test-RSInstalled {
            param([string]$Id)
            try {
                $out = & winget list --id $Id --accept-source-agreements 2>&1
                foreach ($line in $out) {
                    if ($line -is [string] -and $line -match [regex]::Escape($Id)) {
                        return $true
                    }
                }
            } catch { }
            return $false
        }

        $total   = $appArray.Count
        $current = 0
        $successCount = 0
        $failCount = 0
        $skipCount = 0

        foreach ($app in $appArray) {
            Set-RSProgress -Cur $current -Tot $total
            Set-OverlayProgress -Cur $current -Tot $total
            Set-OverlayApp -Name $app.Name -SubText "Checking installation status..."
            Write-RSLog "Checking: $($app.Name)..."
            Set-RSStatus "[$($current+1)/$total] Checking: $($app.Name)"

            if (Test-RSInstalled -Id $app.Id) {
                Write-RSLog "Already installed: $($app.Name)"
                Set-RSStatusBadge -Id $app.Id -Text "`u{2713} Installed" -Color "#22C55E"
                Set-OverlayApp -Name $app.Name -SubText "Already installed, skipping..."
                Invoke-RSCardAnimation -Id $app.Id
                $skipCount++
                Start-Sleep -Milliseconds 300
            } else {
                Write-RSLog "Installing: $($app.Name) [$($app.Id)]"
                Set-RSStatus "[$($current+1)/$total] Installing: $($app.Name)..."
                Set-RSStatusBadge -Id $app.Id -Text "Installing..." -Color "#7B8CFF"
                Set-OverlayApp -Name $app.Name -SubText "Downloading and installing via winget..."

                try {
                    $proc = Start-Process -FilePath "winget" `
                        -ArgumentList "install --id $($app.Id) -e --silent --accept-package-agreements --accept-source-agreements" `
                        -Wait -PassThru -WindowStyle Hidden

                    $code = $proc.ExitCode
                    if ($code -eq 0) {
                        Write-RSLog "$([char]0x2713) Successfully installed: $($app.Name)"
                        Set-RSStatusBadge -Id $app.Id -Text "$([char]0x2713) Installed" -Color "#22C55E"
                        Set-OverlayApp -Name $app.Name -SubText "Successfully installed!"
                        $successCount++
                    } elseif ($code -eq -1978335189) {
                        Write-RSLog "Already up to date: $($app.Name)"
                        Set-RSStatusBadge -Id $app.Id -Text "$([char]0x2713) Up to date" -Color "#22C55E"
                        Set-OverlayApp -Name $app.Name -SubText "Already up to date."
                        $skipCount++
                    } else {
                        Write-RSLog "$([char]0x2717) Exit code $code : $($app.Name)"
                        Set-RSStatusBadge -Id $app.Id -Text "$([char]0x2717) Failed ($code)" -Color "#EF4444"
                        Set-OverlayApp -Name $app.Name -SubText "Installation failed (exit code: $code)"
                        $failCount++
                    }
                } catch {
                    Write-RSLog "`u{2717} Error: $($app.Name) - $($_.Exception.Message)"
                    Set-RSStatusBadge -Id $app.Id -Text "`u{2717} Error" -Color "#EF4444"
                    Set-OverlayApp -Name $app.Name -SubText "Error: $($_.Exception.Message)"
                    $failCount++
                }
                Invoke-RSCardAnimation -Id $app.Id
                Start-Sleep -Milliseconds 500
            }

            $current++
            Set-RSProgress -Cur $current -Tot $total
            Set-OverlayProgress -Cur $current -Tot $total
        }

        $summary = "Done: $successCount installed, $skipCount skipped"
        if ($failCount -gt 0) { $summary += ", $failCount failed" }
        Write-RSLog $summary
        Set-RSStatus $summary

        # Show completion on overlay
        $dispRef.Invoke([action]{
            $ovAppName.Text = "All Done!"
            $ovAction.Text = "C O M P L E T E"
            $ovSubStatus.Text = $summary
            $ovIcon.Text = "$([char]0xE73E)"
        })

        Start-Sleep -Milliseconds 2000

        # Re-enable UI from runspace
        $dispRef.Invoke([action]{
            $btnInst.IsEnabled = $true
            $btnClr.IsEnabled  = $true
            foreach ($b in $presBtns) { $b.IsEnabled = $true }
        })
    }

    $ps = [System.Management.Automation.PowerShell]::Create()
    $ps.Runspace = $rs
    $ps.AddScript($psCode) | Out-Null
    $ps.BeginInvoke() | Out-Null

    # Schedule overlay hide after a delay using a DispatcherTimer
    # We estimate completion will trigger the hide from a separate timer
    # that checks if the runspace has finished
    $checkTimer = New-Object System.Windows.Threading.DispatcherTimer
    $checkTimer.Interval = [TimeSpan]::FromMilliseconds(500)
    $script:InstallPS = $ps
    $checkTimer.Add_Tick({
        if ($script:InstallPS.InvocationStateInfo.State -ne 'Running') {
            Hide-InstallOverlay
            $this.Stop()
        }
    })
    $checkTimer.Start()
}

function Start-UpdateCheck {
    Set-UIEnabled -State $false
    Set-Status "Checking for updates..."
    Write-Log "Searching for available updates using winget..."

    $rs = [RunspaceFactory]::CreateRunspace()
    $rs.ApartmentState = [System.Threading.ApartmentState]::STA
    $rs.Open()

    $rs.SessionStateProxy.SetVariable("dispRef",    $script:Window.Dispatcher)
    $rs.SessionStateProxy.SetVariable("updMap",     $script:UpdateBadgeMap)
    $rs.SessionStateProxy.SetVariable("cardMap",    $script:AppCardMap)
    $rs.SessionStateProxy.SetVariable("logRef",     $script:LogBox)
    $rs.SessionStateProxy.SetVariable("statRef",    $script:StatusLabel)
    $rs.SessionStateProxy.SetVariable("btnInst",    $script:BtnInstall)
    $rs.SessionStateProxy.SetVariable("btnUpd",     $script:BtnCheckUpdates)
    $rs.SessionStateProxy.SetVariable("btnClr",     $script:BtnClear)
    $rs.SessionStateProxy.SetVariable("presBtns",   $script:PresetButtons)
    $rs.SessionStateProxy.SetVariable("appCategories", $script:AppCategories)

    $checkCode = {
        function Write-RSLog {
            param([string]$Msg)
            $ts = Get-Date -Format "HH:mm:ss"
            $line = "[$ts]  $Msg"
            $dispRef.Invoke([action]{
                $logRef.AppendText("$line`r`n")
                $logRef.ScrollToEnd()
            })
        }

        $out = ""
        try {
            $tmpFile = New-TemporaryFile
            $proc = Start-Process -FilePath "winget" -ArgumentList "list --upgrade-available --accept-source-agreements" -Wait -WindowStyle Hidden -PassThru -RedirectStandardOutput $tmpFile.FullName
            $out = Get-Content $tmpFile.FullName -Raw
            Remove-Item $tmpFile.FullName -Force -ErrorAction SilentlyContinue
        } catch {}

        $foundAny = $false
        $updIds = [System.Collections.Generic.List[string]]::new()
        foreach ($cat in $appCategories.Keys) {
            foreach ($app in $appCategories[$cat]) {
                if ($out -match [regex]::Escape($app.Id)) {
                    $foundAny = $true
                    $updIds.Add($app.Id)
                }
            }
        }

        if ($updIds.Count -gt 0) {
            $dispRef.Invoke([action]{
                foreach ($id in $updIds) {
                    # Show update badge
                    if ($updMap[$id]) {
                        $updMap[$id].Visibility = [System.Windows.Visibility]::Visible
                    }
                    # Highlight card with orange background
                    $card = $cardMap[$id]
                    if ($card) {
                        $card.Background = [System.Windows.Media.SolidColorBrush](
                            [System.Windows.Media.ColorConverter]::ConvertFromString("#18F59E0B"))
                        $card.BorderThickness = New-Object System.Windows.Thickness(2, 0, 0, 0)
                        $card.BorderBrush = [System.Windows.Media.SolidColorBrush](
                            [System.Windows.Media.ColorConverter]::ConvertFromString("#55F59E0B"))
                        $card.CornerRadius = New-Object System.Windows.CornerRadius(4)
                        $card.Padding = New-Object System.Windows.Thickness(6, 2, 4, 2)
                        $card.Margin = New-Object System.Windows.Thickness(0, 1, 0, 1)
                    }
                }
            })
        }

        if ($foundAny) {
            Write-RSLog "Updates found! Look for the orange 'Update' badges next to apps."
        } else {
            Write-RSLog "No updates found for your selected apps."
        }

        $dispRef.Invoke([action]{
            $statRef.Text = "Update check complete."
            $btnInst.IsEnabled = $true
            $btnUpd.IsEnabled  = $true
            $btnClr.IsEnabled  = $true
            foreach ($b in $presBtns) { $b.IsEnabled = $true }
        })
    }

    $ps = [System.Management.Automation.PowerShell]::Create().AddScript($checkCode)
    $ps.Runspace = $rs
    $ps.BeginInvoke() | Out-Null
}

function Update-App {
    param([string]$Id, [string]$Name)

    Set-UIEnabled -State $false
    Set-Status "Updating: $Name..."
    Write-Log "Starting update for $Name [$Id]..."

    # Show the splash overlay for update (Progress bar hidden, will use dots instead)
    Show-InstallOverlay -Action "U P D A T I N G" -AppName $Name `
        -SubText "Upgrading" -IconChar "$([char]0xE72C)" `
        -ProgressText ""
    Start-OverlayDotsAnimation -BaseText "Upgrading"

    $script:Window.Dispatcher.Invoke([action]{
        # Show status badge on the card
        $sBadge = $script:StatusBadgeMap[$Id]
        if ($sBadge) {
            $sBadge.Visibility = [System.Windows.Visibility]::Visible
            $sBadge.Child.Text = "Updating..."
            $sBadge.Child.Foreground = [System.Windows.Media.SolidColorBrush]([System.Windows.Media.ColorConverter]::ConvertFromString("#F59E0B"))
            $sBadge.Background = [System.Windows.Media.SolidColorBrush]([System.Windows.Media.ColorConverter]::ConvertFromString("#33F59E0B"))
            $sBadge.BorderBrush = [System.Windows.Media.SolidColorBrush]([System.Windows.Media.ColorConverter]::ConvertFromString("#55F59E0B"))
        }

        # Hide update badge while updating
        $uBadge = $script:UpdateBadgeMap[$Id]
        if ($uBadge) { $uBadge.Visibility = [System.Windows.Visibility]::Collapsed }

        # Keep card visible (overlay is already covering the screen)
    })

    $rs = [RunspaceFactory]::CreateRunspace()
    $rs.ApartmentState = [System.Threading.ApartmentState]::STA
    $rs.Open()

    $rs.SessionStateProxy.SetVariable("dispRef",    $script:Window.Dispatcher)
    $rs.SessionStateProxy.SetVariable("logRef",     $script:LogBox)
    $rs.SessionStateProxy.SetVariable("statRef",    $script:StatusLabel)
    $rs.SessionStateProxy.SetVariable("updMap",     $script:UpdateBadgeMap)
    $rs.SessionStateProxy.SetVariable("statusMap",  $script:StatusBadgeMap)
    $rs.SessionStateProxy.SetVariable("cardMap",    $script:AppCardMap)
    $rs.SessionStateProxy.SetVariable("id",         $Id)
    $rs.SessionStateProxy.SetVariable("name",       $Name)
    $rs.SessionStateProxy.SetVariable("btnInst",    $script:BtnInstall)
    $rs.SessionStateProxy.SetVariable("btnUpd",     $script:BtnCheckUpdates)
    $rs.SessionStateProxy.SetVariable("btnClr",     $script:BtnClear)
    $rs.SessionStateProxy.SetVariable("presBtns",   $script:PresetButtons)
    $rs.SessionStateProxy.SetVariable("ovAppName",      $script:OverlayAppName)
    $rs.SessionStateProxy.SetVariable("ovAction",       $script:OverlayAction)
    $rs.SessionStateProxy.SetVariable("ovSubStatus",    $script:OverlaySubStatus)
    $rs.SessionStateProxy.SetVariable("ovIcon",         $script:OverlayIcon)
    $rs.SessionStateProxy.SetVariable("ovProgressFill", $script:OverlayProgressFill)
    $rs.SessionStateProxy.SetVariable("ovProgressGlow", $script:OverlayProgressGlow)

    $updCode = {
        function Write-RSLog {
            param([string]$Msg)
            $ts = Get-Date -Format "HH:mm:ss"
            $line = "[$ts]  $Msg"
            $dispRef.Invoke([action]{
                $logRef.AppendText("$line`r`n")
                $logRef.ScrollToEnd()
            })
        }

        try {
            $proc = Start-Process -FilePath "winget" `
                -ArgumentList "upgrade --id $id -e --silent --accept-package-agreements --accept-source-agreements" `
                -Wait -PassThru -WindowStyle Hidden
            
            if ($proc.ExitCode -eq 0) {
                Write-RSLog "$([char]0x2713) Successfully updated: $name"
                $dispRef.Invoke([action]{
                    if ($updMap[$id]) { $updMap[$id].Visibility = [System.Windows.Visibility]::Collapsed }
                    $sBadge = $statusMap[$id]
                    if ($sBadge) {
                        $sBadge.Visibility = [System.Windows.Visibility]::Visible
                        $sBadge.Child.Text = "$([char]0x2713) Updated"
                        $sBadge.Child.Foreground = [System.Windows.Media.SolidColorBrush]([System.Windows.Media.ColorConverter]::ConvertFromString("#22C55E"))
                        $sBadge.Background = [System.Windows.Media.SolidColorBrush]([System.Windows.Media.ColorConverter]::ConvertFromString("#3322C55E"))
                        $sBadge.BorderBrush = [System.Windows.Media.SolidColorBrush]([System.Windows.Media.ColorConverter]::ConvertFromString("#5522C55E"))
                    }
                    $card = $cardMap[$id]
                    if ($card) {
                        $card.Opacity = 1.0
                        $card.Background = [System.Windows.Media.Brushes]::Transparent
                        $card.BorderThickness = New-Object System.Windows.Thickness(0)
                        $card.BorderBrush = $null
                        $card.Padding = New-Object System.Windows.Thickness(0)
                        $card.Margin = New-Object System.Windows.Thickness(0)
                    }
                    # Update overlay to show success
                    $ovAppName.Text = $name
                    $ovAction.Text = "C O M P L E T E"
                    $ovSubStatus.Text = "Successfully updated!"
                    $ovIcon.Text = "$([char]0xE73E)"
                    Stop-OverlayDotsAnimation
                })
            } else {
                Write-RSLog "`u{2717} Update failed (exit code $($proc.ExitCode)): ${name}"
                $dispRef.Invoke([action]{
                    $sBadge = $statusMap[$id]
                    if ($sBadge) {
                        $sBadge.Visibility = [System.Windows.Visibility]::Visible
                        $sBadge.Child.Text = "`u{2717} Failed"
                        $sBadge.Child.Foreground = [System.Windows.Media.SolidColorBrush]([System.Windows.Media.ColorConverter]::ConvertFromString("#EF4444"))
                        $sBadge.Background = [System.Windows.Media.SolidColorBrush]([System.Windows.Media.ColorConverter]::ConvertFromString("#33EF4444"))
                        $sBadge.BorderBrush = [System.Windows.Media.SolidColorBrush]([System.Windows.Media.ColorConverter]::ConvertFromString("#55EF4444"))
                    }
                    if ($updMap[$id]) { $updMap[$id].Visibility = [System.Windows.Visibility]::Visible }
                    $card = $cardMap[$id]
                    if ($card) {
                        $anim = New-Object System.Windows.Media.Animation.DoubleAnimation
                        $anim.From = $card.Opacity; $anim.To = 1.0
                        $anim.Duration = New-Object System.Windows.Duration([TimeSpan]::FromMilliseconds(600))
                        $card.BeginAnimation([System.Windows.UIElement]::OpacityProperty, $anim)
                    }
                    $ovAppName.Text = $name
                    $ovAction.Text = "F A I L E D"
                    $ovSubStatus.Text = "Update failed (exit code: $($proc.ExitCode))"
                    $ovIcon.Text = "$([char]0xE711)"
                    Stop-OverlayDotsAnimation
                })
            }
        } catch {
            Write-RSLog "$([char]0x2717) Error updating ${name}: $($_.Exception.Message)"
            $dispRef.Invoke([action]{
                $sBadge = $statusMap[$id]
                if ($sBadge) {
                    $sBadge.Visibility = [System.Windows.Visibility]::Visible
                    $sBadge.Child.Text = "$([char]0x2717) Error"
                    $sBadge.Child.Foreground = [System.Windows.Media.SolidColorBrush]([System.Windows.Media.ColorConverter]::ConvertFromString("#EF4444"))
                    $sBadge.Background = [System.Windows.Media.SolidColorBrush]([System.Windows.Media.ColorConverter]::ConvertFromString("#33EF4444"))
                }
                if ($updMap[$id]) { $updMap[$id].Visibility = [System.Windows.Visibility]::Visible }
                $card = $cardMap[$id]
                if ($card) {
                    $anim = New-Object System.Windows.Media.Animation.DoubleAnimation
                    $anim.From = $card.Opacity; $anim.To = 1.0
                    $anim.Duration = New-Object System.Windows.Duration([TimeSpan]::FromMilliseconds(600))
                    $card.BeginAnimation([System.Windows.UIElement]::OpacityProperty, $anim)
                }
                $ovAppName.Text = $name
                $ovAction.Text = "E R R O R"
                $ovSubStatus.Text = "An error occurred during update"
                $ovIcon.Text = "$([char]0xE711)"
                Stop-OverlayDotsAnimation
            })
        }

        Start-Sleep -Milliseconds 2000

        $dispRef.Invoke([action]{
            $statRef.Text = "Update complete."
            $btnInst.IsEnabled = $true
            $btnUpd.IsEnabled  = $true
            $btnClr.IsEnabled  = $true
            foreach ($b in $presBtns) { $b.IsEnabled = $true }
        })
    }

    $ps = [System.Management.Automation.PowerShell]::Create().AddScript($updCode)
    $ps.Runspace = $rs
    $ps.BeginInvoke() | Out-Null

    # Monitor runspace completion and hide overlay
    $script:UpdatePS = $ps
    $checkTimer = New-Object System.Windows.Threading.DispatcherTimer
    $checkTimer.Interval = [TimeSpan]::FromMilliseconds(500)
    $checkTimer.Add_Tick({
        if ($script:UpdatePS.InvocationStateInfo.State -ne 'Running') {
            Hide-InstallOverlay
            $this.Stop()
        }
    })
    $checkTimer.Start()
}

# --- MODULE: Installer.ps1 END ---


# =====================================================================
# WINDOW CHROME
# =====================================================================
$script:BtnClose.Add_Click({ $script:Window.Close() })
$script:BtnMinimize.Add_Click({ $script:Window.WindowState = [System.Windows.WindowState]::Minimized })
$script:DragBar.Add_MouseLeftButtonDown({ $script:Window.DragMove() })

# =====================================================================
# SET PRESET ICON CONTENT (Segoe MDL2 Assets)
# =====================================================================
$script:BtnPresetGaming.Content = "$([char]0xE7FC)"
$script:BtnPresetWork.Content   = "$([char]0xE821)"
$script:BtnPresetMedia.Content  = "$([char]0xE714)"

# =====================================================================
# BUILD UI
# =====================================================================
Initialize-AppList

# =====================================================================
# PRESET BUTTON HANDLERS
# =====================================================================
$script:BtnPresetGaming.Add_Click({
    Import-PresetById -Ids $script:BuiltInPresets["Gaming"]
    Write-Log "Gaming preset applied."
    Set-Status "Gaming preset loaded."
})

$script:BtnPresetWork.Add_Click({
    Import-PresetById -Ids $script:BuiltInPresets["Work"]
    Write-Log "Work preset applied."
    Set-Status "Work preset loaded."
})

$script:BtnPresetMedia.Add_Click({
    Import-PresetById -Ids $script:BuiltInPresets["Media"]
    Write-Log "Media preset applied."
    Set-Status "Media preset loaded."
})

# =====================================================================
# CUSTOM PRESET HANDLERS
# =====================================================================
$script:BtnSavePreset.Add_Click({ Show-SavePresetDialog })
$script:BtnLoadPreset.Add_Click({ Show-LoadPresetDialog })

# =====================================================================
# CLEAR ALL BUTTON
# =====================================================================
$script:BtnClear.Add_Click({
    foreach ($id in $script:CheckBoxMap.Keys) {
        $script:CheckBoxMap[$id].IsChecked = $false
    }
    Update-Counter
    Write-Log "Selection cleared."
    Set-Status "All selections cleared."
})

# =====================================================================
# INSTALL BUTTON
# =====================================================================
$script:BtnInstall.Add_Click({ Start-Installation })

# =====================================================================
# CHECK UPDATES BUTTON
# =====================================================================
$script:BtnCheckUpdates.Add_Click({ Start-UpdateCheck })

# =====================================================================
# INTERNET RETRY BUTTON
# =====================================================================
$script:BtnRetryInternet.Add_Click({
    if (Test-InternetConnection) {
        Hide-NoInternetOverlay
        Write-Log "Internet connection restored."
        Set-Status "Online. Ready to install."
    } else {
        Write-Log "Still no internet connection."
    }
})

# =====================================================================
# STARTUP: Internet check + initial log
# =====================================================================
$ts = Get-Date -Format 'HH:mm:ss'
$script:LogBox.AppendText("[$ts]  HumanTouch Optimizer v2.0 initialized.`r`n")
$script:LogBox.AppendText("[$ts]  Administrator context confirmed.`r`n")
$script:LogBox.AppendText("[$ts]  winget package manager detected.`r`n")

if (-not (Test-InternetConnection)) {
    $script:NoInternetOverlay.Visibility = [System.Windows.Visibility]::Visible
    $script:LogBox.AppendText("[$ts]  WARNING: No internet connection detected.`r`n")
} else {
    $script:LogBox.AppendText("[$ts]  Internet connection verified.`r`n")
}

$script:LogBox.AppendText("[$ts]  Select applications and click Install Selected.`r`n")
$script:LogBox.AppendText("[$ts]  Scanning installed applications...`r`n")
Set-Status "Scanning installed applications..."

# Background scan for already installed apps
$scanRS = [RunspaceFactory]::CreateRunspace()
$scanRS.ApartmentState = "STA"
$scanRS.Open()
$scanRS.SessionStateProxy.SetVariable("dispRef",   $script:Window.Dispatcher)
$scanRS.SessionStateProxy.SetVariable("badgeMap",   $script:InstalledBadgeMap)
$scanRS.SessionStateProxy.SetVariable("cardMap",    $script:AppCardMap)
$scanRS.SessionStateProxy.SetVariable("statusRef",  $script:StatusLabel)
$scanRS.SessionStateProxy.SetVariable("logRef",     $script:LogBox)
$scanRS.SessionStateProxy.SetVariable("appCategories", $script:AppCategories)

$scanCode = {
    $dispRef.Invoke([action]{ $statusRef.Text = "Scanning installed applications..." })

    $installedNames = [System.Collections.Generic.List[string]]::new()

    # 1. Registry Check (Fast, catches externally installed apps)
    try {
        $paths = @(
            "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
            "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
            "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"
        )
        $regApps = Get-ItemProperty $paths -ErrorAction SilentlyContinue | Select-Object -ExpandProperty DisplayName | Where-Object { $_ -ne $null }
        if ($regApps) { foreach ($r in $regApps) { $installedNames.Add($r) } }
    } catch {}

    # 2. Appx Check (For Store apps like WhatsApp, Spotify)
    try {
        $appxApps = Get-AppxPackage -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name | Where-Object { $_ -ne $null }
        if ($appxApps) { foreach ($a in $appxApps) { $installedNames.Add($a) } }
    } catch {}

    $installedString = $installedNames -join "`n"

    # 3. Winget Check (Hidden Start-Process prevents UI freeze)
    $wingetOut = ""
    try {
        $tmpFile = New-TemporaryFile
        $proc = Start-Process -FilePath "winget" -ArgumentList "list --accept-source-agreements" -Wait -WindowStyle Hidden -PassThru -RedirectStandardOutput $tmpFile.FullName
        $wingetOut = Get-Content $tmpFile.FullName -Raw
        Remove-Item $tmpFile.FullName -Force -ErrorAction SilentlyContinue
    } catch {}

    $allApps = @()
    foreach ($cat in $appCategories.Keys) {
        foreach ($app in $appCategories[$cat]) {
            $allApps += $app
        }
    }

    $installedCount = 0
    $foundIds = [System.Collections.Generic.List[string]]::new()

    foreach ($app in $allApps) {
        $found = $false
        
        # Method A: Check via Winget output
        if ($wingetOut -and $wingetOut -match [regex]::Escape($app.Id)) {
            $found = $true
        } else {
            # Method B: Smart Name Match (Registry/Appx)
            $searchName = $app.Name
            # Normalize common mismatches
            if ($searchName -match "Node\.js") { $searchName = "Node.js" }
            elseif ($searchName -eq "GOG Galaxy") { $searchName = "GOG Galaxy" }
            elseif ($searchName -eq "EA App") { $searchName = "EA app" }
            elseif ($searchName -eq "Battle.net") { $searchName = "Battle.net" }
            elseif ($searchName -eq "Python 3") { $searchName = "Python 3" }

            # Safe regex check
            if ($searchName.Length -gt 3 -and $installedString -match "(?i)" + [regex]::Escape($searchName)) {
                $found = $true
            }
        }

        if ($found) {
            $installedCount++
            $foundIds.Add($app.Id)
        }
    }

    if ($foundIds.Count -gt 0) {
        $dispRef.Invoke([action]{
            foreach ($id in $foundIds) {
                # Show badge
                $badge = $badgeMap[$id]
                if ($badge) {
                    $badge.Visibility = [System.Windows.Visibility]::Visible
                }
                # Slightly highlight the card row to show it's already installed
                $card = $cardMap[$id]
                if ($card) {
                    $card.Opacity = 1.0
                    $card.Background = [System.Windows.Media.SolidColorBrush]([System.Windows.Media.ColorConverter]::ConvertFromString("#0A22C55E"))
                }
            }
        }.GetNewClosure())
    }

    $ts = Get-Date -Format 'HH:mm:ss'
    $dispRef.Invoke([action]{
        $logRef.AppendText("[$ts]  Scan complete: $installedCount of $($allApps.Count) app(s) already installed.`r`n")
        $logRef.ScrollToEnd()
        $statusRef.Text = "Ready - $installedCount app(s) already installed."
    })
}

$scanPS = [PowerShell]::Create().AddScript($scanCode)
$scanPS.Runspace = $scanRS
$scanPS.BeginInvoke() | Out-Null

# =====================================================================
# SHOW WINDOW
# =====================================================================
$script:Window.ShowDialog() | Out-Null
