#Requires -Version 5.1
<#
.SYNOPSIS
    HumanTouch Optimizer - Modern Windows Application Installer
.VERSION
    1.0
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
            "winget (Windows Package Manager) was not found on this system.`n`nPlease install App Installer from the Microsoft Store and try again.",
            "winget Not Found",
            [System.Windows.MessageBoxButton]::OK,
            [System.Windows.MessageBoxImage]::Error
        ) | Out-Null
        exit 1
    }
}

Test-Winget

# =====================================================================
# APPLICATION DEFINITIONS
# =====================================================================
$script:AppCategories = [ordered]@{
    "BROWSERS" = @(
        [PSCustomObject]@{ Name = "Google Chrome";       Id = "Google.Chrome" }
        [PSCustomObject]@{ Name = "Mozilla Firefox";     Id = "Mozilla.Firefox" }
        [PSCustomObject]@{ Name = "Brave";               Id = "Brave.Brave" }
        [PSCustomObject]@{ Name = "Opera";               Id = "Opera.Opera" }
        [PSCustomObject]@{ Name = "Vivaldi";             Id = "Vivaldi.Vivaldi" }
        [PSCustomObject]@{ Name = "Zen Browser";         Id = "Zen-Team.Zen-Browser" }
    )
    "COMMUNICATION" = @(
        [PSCustomObject]@{ Name = "Discord";             Id = "Discord.Discord" }
        [PSCustomObject]@{ Name = "TeamSpeak 3 Client";  Id = "TeamSpeakSystems.TeamSpeakClient" }
        [PSCustomObject]@{ Name = "TeamSpeak 5";         Id = "TeamSpeakSystems.TeamSpeak" }
    )
    "GAMING PLATFORMS" = @(
        [PSCustomObject]@{ Name = "Steam";               Id = "Valve.Steam" }
        [PSCustomObject]@{ Name = "Epic Games Launcher"; Id = "EpicGames.EpicGamesLauncher" }
        [PSCustomObject]@{ Name = "EA App";              Id = "ElectronicArts.EADesktop" }
        [PSCustomObject]@{ Name = "Ubisoft Connect";     Id = "Ubisoft.Connect" }
        [PSCustomObject]@{ Name = "Battle.net";          Id = "Blizzard.BattleNet" }
    )
    "SYSTEM TOOLS" = @(
        [PSCustomObject]@{ Name = "7-Zip";               Id = "7zip.7zip" }
        [PSCustomObject]@{ Name = "WinRAR";              Id = "RARLab.WinRAR" }
        [PSCustomObject]@{ Name = "Everything Search";   Id = "voidtools.Everything" }
        [PSCustomObject]@{ Name = "Notepad++";           Id = "Notepad++.Notepad++" }
        [PSCustomObject]@{ Name = "Visual Studio Code";  Id = "Microsoft.VisualStudioCode" }
        [PSCustomObject]@{ Name = "Git";                 Id = "Git.Git" }
        [PSCustomObject]@{ Name = "PowerToys";           Id = "Microsoft.PowerToys" }
    )
    "MEDIA" = @(
        [PSCustomObject]@{ Name = "VLC";                 Id = "VideoLAN.VLC" }
        [PSCustomObject]@{ Name = "Spotify";             Id = "Spotify.Spotify" }
        [PSCustomObject]@{ Name = "Audacity";            Id = "Audacity.Audacity" }
    )
}

$script:RecommendedIds = @(
    "Google.Chrome",
    "Discord.Discord",
    "Valve.Steam",
    "7zip.7zip",
    "VideoLAN.VLC"
)

# =====================================================================
# XAML - Premium Fluent / Glassmorphism Design
# Single-quoted to prevent PowerShell string interpolation
# =====================================================================
[xml]$script:XAML = @'
<Window
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    Title="HumanTouch Optimizer"
    Width="820"
    Height="860"
    WindowStartupLocation="CenterScreen"
    ResizeMode="NoResize"
    WindowStyle="None"
    AllowsTransparency="True"
    Background="Transparent"
    FontFamily="Segoe UI">

    <Window.Resources>

        <!-- GRADIENT BRUSHES -->
        <LinearGradientBrush x:Key="AccentGradient" StartPoint="0,0" EndPoint="1,0">
            <GradientStop Color="#5B6CF9" Offset="0"/>
            <GradientStop Color="#7A8CFF" Offset="1"/>
        </LinearGradientBrush>

        <LinearGradientBrush x:Key="AccentGradientHover" StartPoint="0,0" EndPoint="1,0">
            <GradientStop Color="#6B7CFF" Offset="0"/>
            <GradientStop Color="#8A9CFF" Offset="1"/>
        </LinearGradientBrush>

        <LinearGradientBrush x:Key="AccentGradientPressed" StartPoint="0,0" EndPoint="1,0">
            <GradientStop Color="#4A5BE8" Offset="0"/>
            <GradientStop Color="#6070EE" Offset="1"/>
        </LinearGradientBrush>

        <LinearGradientBrush x:Key="WindowBackground" StartPoint="0,0" EndPoint="1,1">
            <GradientStop Color="#0B0F1E" Offset="0"/>
            <GradientStop Color="#0E1328" Offset="0.5"/>
            <GradientStop Color="#0A0D1C" Offset="1"/>
        </LinearGradientBrush>

        <LinearGradientBrush x:Key="CardGradient" StartPoint="0,0" EndPoint="0,1">
            <GradientStop Color="#161B30" Offset="0"/>
            <GradientStop Color="#111628" Offset="1"/>
        </LinearGradientBrush>

        <LinearGradientBrush x:Key="HeaderGradient" StartPoint="0,0" EndPoint="1,0">
            <GradientStop Color="#0F1428" Offset="0"/>
            <GradientStop Color="#141932" Offset="1"/>
        </LinearGradientBrush>

        <LinearGradientBrush x:Key="ProgressGradient" StartPoint="0,0" EndPoint="1,0">
            <GradientStop Color="#5B6CF9" Offset="0"/>
            <GradientStop Color="#9B6CFF" Offset="1"/>
        </LinearGradientBrush>

        <!-- DROP SHADOW EFFECTS -->
        <DropShadowEffect x:Key="CardShadow"
                          BlurRadius="20"
                          ShadowDepth="4"
                          Direction="270"
                          Color="#000000"
                          Opacity="0.4"/>

        <DropShadowEffect x:Key="ButtonShadow"
                          BlurRadius="16"
                          ShadowDepth="2"
                          Direction="270"
                          Color="#5B6CF9"
                          Opacity="0.4"/>

        <DropShadowEffect x:Key="HeaderShadow"
                          BlurRadius="24"
                          ShadowDepth="6"
                          Direction="270"
                          Color="#000000"
                          Opacity="0.5"/>

        <DropShadowEffect x:Key="WindowShadow"
                          BlurRadius="40"
                          ShadowDepth="10"
                          Direction="270"
                          Color="#000000"
                          Opacity="0.7"/>

        <!-- SCROLLBAR STYLE -->
        <Style x:Key="ModernScrollBar" TargetType="ScrollBar">
            <Setter Property="Background" Value="Transparent"/>
            <Setter Property="Width" Value="5"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="ScrollBar">
                        <Grid Background="Transparent">
                            <Track x:Name="PART_Track" IsDirectionReversed="True">
                                <Track.Thumb>
                                    <Thumb>
                                        <Thumb.Template>
                                            <ControlTemplate TargetType="Thumb">
                                                <Border CornerRadius="3"
                                                        Background="#2A2F52"
                                                        Margin="1,2,1,2"/>
                                            </ControlTemplate>
                                        </Thumb.Template>
                                    </Thumb>
                                </Track.Thumb>
                            </Track>
                        </Grid>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <Style x:Key="ModernScrollViewer" TargetType="ScrollViewer">
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="ScrollViewer">
                        <Grid>
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="*"/>
                                <ColumnDefinition Width="Auto"/>
                            </Grid.ColumnDefinitions>
                            <ScrollContentPresenter Grid.Column="0"/>
                            <ScrollBar Grid.Column="1"
                                       x:Name="PART_VerticalScrollBar"
                                       Style="{StaticResource ModernScrollBar}"
                                       Value="{TemplateBinding VerticalOffset}"
                                       Maximum="{TemplateBinding ScrollableHeight}"
                                       ViewportSize="{TemplateBinding ViewportHeight}"
                                       Visibility="{TemplateBinding ComputedVerticalScrollBarVisibility}"/>
                        </Grid>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <!-- CHECKBOX STYLE (TOGGLE) -->
        <Style x:Key="ToggleCheckBox" TargetType="CheckBox">
            <Setter Property="Foreground" Value="#B8C4E8"/>
            <Setter Property="FontSize" Value="13"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Margin" Value="0,2,0,2"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="CheckBox">
                        <Border x:Name="RootBorder"
                                Background="Transparent"
                                CornerRadius="8"
                                Padding="10,8,10,8"
                                Margin="0,1,0,1">
                            <Grid>
                                <Grid.ColumnDefinitions>
                                    <ColumnDefinition Width="36"/>
                                    <ColumnDefinition Width="*"/>
                                </Grid.ColumnDefinitions>

                                <!-- Toggle Track -->
                                <Border x:Name="ToggleTrack"
                                        Grid.Column="0"
                                        Width="34"
                                        Height="18"
                                        CornerRadius="9"
                                        Background="#1E2240"
                                        BorderBrush="#2A3060"
                                        BorderThickness="1"
                                        VerticalAlignment="Center">
                                    <!-- Toggle Thumb -->
                                    <Border x:Name="ToggleThumb"
                                            Width="12"
                                            Height="12"
                                            CornerRadius="6"
                                            Background="#3A4070"
                                            HorizontalAlignment="Left"
                                            VerticalAlignment="Center"
                                            Margin="2,0,0,0"/>
                                </Border>

                                <!-- App Label -->
                                <ContentPresenter Grid.Column="1"
                                                  VerticalAlignment="Center"
                                                  Margin="10,0,0,0"/>
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
                                <Setter TargetName="RootBorder" Property="Background" Value="#131830"/>
                            </Trigger>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="RootBorder" Property="Background" Value="#141928"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <!-- PRIMARY BUTTON STYLE -->
        <Style x:Key="PrimaryBtn" TargetType="Button">
            <Setter Property="Foreground" Value="White"/>
            <Setter Property="FontSize" Value="13"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="Height" Value="46"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="BtnBorder"
                                CornerRadius="12"
                                Effect="{StaticResource ButtonShadow}">
                            <Border.Background>
                                <LinearGradientBrush StartPoint="0,0" EndPoint="1,0">
                                    <GradientStop Color="#5B6CF9" Offset="0"/>
                                    <GradientStop Color="#7A8CFF" Offset="1"/>
                                </LinearGradientBrush>
                            </Border.Background>
                            <Grid>
                                <Border x:Name="HoverOverlay"
                                        CornerRadius="12"
                                        Background="White"
                                        Opacity="0"/>
                                <ContentPresenter HorizontalAlignment="Center"
                                                  VerticalAlignment="Center"
                                                  Margin="0,0,0,0"/>
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

        <!-- SECONDARY BUTTON STYLE -->
        <Style x:Key="SecondaryBtn" TargetType="Button">
            <Setter Property="Foreground" Value="#7B8CDE"/>
            <Setter Property="FontSize" Value="12"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="Height" Value="42"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="BtnBorder"
                                CornerRadius="12"
                                Background="#141830"
                                BorderBrush="#2A3060"
                                BorderThickness="1">
                            <Grid>
                                <Border x:Name="HoverOverlay"
                                        CornerRadius="12"
                                        Opacity="0">
                                    <Border.Background>
                                        <LinearGradientBrush StartPoint="0,0" EndPoint="1,0">
                                            <GradientStop Color="#1E2448" Offset="0"/>
                                            <GradientStop Color="#1A2040" Offset="1"/>
                                        </LinearGradientBrush>
                                    </Border.Background>
                                </Border>
                                <ContentPresenter HorizontalAlignment="Center"
                                                  VerticalAlignment="Center"/>
                            </Grid>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="HoverOverlay" Property="Opacity" Value="1"/>
                                <Setter TargetName="BtnBorder" Property="BorderBrush" Value="#4A5AE0"/>
                            </Trigger>
                            <Trigger Property="IsPressed" Value="True">
                                <Setter TargetName="BtnBorder" Property="BorderBrush" Value="#5B6CF9"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <!-- CLOSE BUTTON -->
        <Style x:Key="CloseBtn" TargetType="Button">
            <Setter Property="Foreground" Value="#4A5070"/>
            <Setter Property="FontSize" Value="14"/>
            <Setter Property="Width" Value="32"/>
            <Setter Property="Height" Value="32"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="CloseBorder"
                                CornerRadius="8"
                                Background="Transparent">
                            <ContentPresenter HorizontalAlignment="Center"
                                              VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="CloseBorder" Property="Background" Value="#CC2A2A"/>
                                <Setter Property="Foreground" Value="White"/>
                            </Trigger>
                            <Trigger Property="IsPressed" Value="True">
                                <Setter TargetName="CloseBorder" Property="Background" Value="#AA2222"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <!-- MINIMIZE BUTTON -->
        <Style x:Key="MinBtn" TargetType="Button">
            <Setter Property="Foreground" Value="#4A5070"/>
            <Setter Property="FontSize" Value="14"/>
            <Setter Property="Width" Value="32"/>
            <Setter Property="Height" Value="32"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="MinBorder"
                                CornerRadius="8"
                                Background="Transparent">
                            <ContentPresenter HorizontalAlignment="Center"
                                              VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="MinBorder" Property="Background" Value="#1E2240"/>
                                <Setter Property="Foreground" Value="#7B8CDE"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

    </Window.Resources>

    <!-- OUTER WRAPPER with shadow -->
    <Border Margin="14"
            CornerRadius="16"
            Effect="{StaticResource WindowShadow}">

        <!-- MAIN WINDOW FRAME -->
        <Border CornerRadius="16"
                ClipToBounds="True">
            <Border.Background>
                <LinearGradientBrush StartPoint="0,0" EndPoint="1,1">
                    <GradientStop Color="#0B0F1E" Offset="0"/>
                    <GradientStop Color="#0E1328" Offset="0.6"/>
                    <GradientStop Color="#0A0D1C" Offset="1"/>
                </LinearGradientBrush>
            </Border.Background>

            <Grid>
                <Grid.RowDefinitions>
                    <RowDefinition Height="64"/>
                    <RowDefinition Height="*"/>
                    <RowDefinition Height="36"/>
                </Grid.RowDefinitions>

                <!-- HEADER -->
                <Border Grid.Row="0"
                        Effect="{StaticResource HeaderShadow}">
                    <Border.Background>
                        <LinearGradientBrush StartPoint="0,0" EndPoint="1,0">
                            <GradientStop Color="#0F1428" Offset="0"/>
                            <GradientStop Color="#141932" Offset="1"/>
                        </LinearGradientBrush>
                    </Border.Background>

                    <!-- Subtle bottom accent line -->
                    <Grid>
                        <Border VerticalAlignment="Bottom"
                                Height="1"
                                Opacity="0.6">
                            <Border.Background>
                                <LinearGradientBrush StartPoint="0,0" EndPoint="1,0">
                                    <GradientStop Color="Transparent" Offset="0"/>
                                    <GradientStop Color="#5B6CF9" Offset="0.3"/>
                                    <GradientStop Color="#7A8CFF" Offset="0.7"/>
                                    <GradientStop Color="Transparent" Offset="1"/>
                                </LinearGradientBrush>
                            </Border.Background>
                        </Border>

                        <Grid Margin="22,0,16,0"
                              x:Name="DragBar">
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="Auto"/>
                                <ColumnDefinition Width="*"/>
                                <ColumnDefinition Width="Auto"/>
                            </Grid.ColumnDefinitions>

                            <!-- LOGO MARK + TITLE -->
                            <StackPanel Grid.Column="0"
                                        Orientation="Horizontal"
                                        VerticalAlignment="Center">
                                <!-- Logo dot accent -->
                                <Border Width="8"
                                        Height="8"
                                        CornerRadius="4"
                                        Margin="0,0,10,0"
                                        VerticalAlignment="Center">
                                    <Border.Background>
                                        <LinearGradientBrush StartPoint="0,0" EndPoint="1,1">
                                            <GradientStop Color="#5B6CF9" Offset="0"/>
                                            <GradientStop Color="#9B6CFF" Offset="1"/>
                                        </LinearGradientBrush>
                                    </Border.Background>
                                </Border>
                                <StackPanel VerticalAlignment="Center">
                                    <TextBlock Text="HumanTouch Optimizer"
                                               Foreground="White"
                                               FontSize="15"
                                               FontWeight="SemiBold"/>
                                    <TextBlock Text="Modern Windows Application Installer"
                                               FontSize="10"
                                               Margin="0,1,0,0">
                                        <TextBlock.Foreground>
                                            <LinearGradientBrush StartPoint="0,0" EndPoint="1,0">
                                                <GradientStop Color="#4A5580" Offset="0"/>
                                                <GradientStop Color="#5B6CF9" Offset="1"/>
                                            </LinearGradientBrush>
                                        </TextBlock.Foreground>
                                    </TextBlock>
                                </StackPanel>
                            </StackPanel>

                            <!-- VERSION PILL + WINDOW CONTROLS -->
                            <StackPanel Grid.Column="2"
                                        Orientation="Horizontal"
                                        VerticalAlignment="Center">
                                <!-- Version pill -->
                                <Border CornerRadius="20"
                                        Padding="12,4,12,4"
                                        Margin="0,0,16,0"
                                        BorderThickness="1"
                                        BorderBrush="#2A3060">
                                    <Border.Background>
                                        <LinearGradientBrush StartPoint="0,0" EndPoint="1,0">
                                            <GradientStop Color="#161C38" Offset="0"/>
                                            <GradientStop Color="#1C2244" Offset="1"/>
                                        </LinearGradientBrush>
                                    </Border.Background>
                                    <TextBlock Text="v 1.0"
                                               FontSize="11"
                                               FontWeight="SemiBold">
                                        <TextBlock.Foreground>
                                            <LinearGradientBrush StartPoint="0,0" EndPoint="1,0">
                                                <GradientStop Color="#7B8CFF" Offset="0"/>
                                                <GradientStop Color="#9B8CFF" Offset="1"/>
                                            </LinearGradientBrush>
                                        </TextBlock.Foreground>
                                    </TextBlock>
                                </Border>

                                <!-- Minimize -->
                                <Button x:Name="BtnMinimize"
                                        Style="{StaticResource MinBtn}"
                                        Content="_"
                                        FontSize="16"
                                        Margin="0,0,4,0"/>

                                <!-- Close -->
                                <Button x:Name="BtnClose"
                                        Style="{StaticResource CloseBtn}"
                                        Content="X"
                                        FontSize="11"
                                        FontWeight="Bold"/>
                            </StackPanel>
                        </Grid>
                    </Grid>
                </Border>

                <!-- MAIN CONTENT -->
                <Grid Grid.Row="1">
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="250"/>
                    </Grid.ColumnDefinitions>

                    <!-- LEFT: APP SELECTION -->
                    <Border Grid.Column="0"
                            BorderThickness="0,0,1,0"
                            BorderBrush="#141828">
                        <ScrollViewer Style="{StaticResource ModernScrollViewer}"
                                      VerticalScrollBarVisibility="Auto"
                                      HorizontalScrollBarVisibility="Disabled">
                            <StackPanel x:Name="AppListPanel"
                                        Margin="18,14,14,18"/>
                        </ScrollViewer>
                    </Border>

                    <!-- RIGHT: ACTION PANEL -->
                    <Border Grid.Column="1">
                        <Border.Background>
                            <LinearGradientBrush StartPoint="0,0" EndPoint="0,1">
                                <GradientStop Color="#0C1020" Offset="0"/>
                                <GradientStop Color="#0A0D1C" Offset="1"/>
                            </LinearGradientBrush>
                        </Border.Background>

                        <Grid>
                            <Grid.RowDefinitions>
                                <RowDefinition Height="Auto"/>
                                <RowDefinition Height="*"/>
                            </Grid.RowDefinitions>

                            <StackPanel Grid.Row="0" Margin="14,16,14,0">

                                <!-- COUNTER CARD -->
                                <Border CornerRadius="12"
                                        Padding="14,10,14,10"
                                        Margin="0,0,0,12"
                                        BorderThickness="1"
                                        BorderBrush="#1E2448">
                                    <Border.Background>
                                        <LinearGradientBrush StartPoint="0,0" EndPoint="1,1">
                                            <GradientStop Color="#141830" Offset="0"/>
                                            <GradientStop Color="#111428" Offset="1"/>
                                        </LinearGradientBrush>
                                    </Border.Background>
                                    <Grid>
                                        <Grid.ColumnDefinitions>
                                            <ColumnDefinition Width="*"/>
                                            <ColumnDefinition Width="Auto"/>
                                        </Grid.ColumnDefinitions>
                                        <StackPanel Grid.Column="0" VerticalAlignment="Center">
                                            <TextBlock Text="SELECTED"
                                                       Foreground="#3A4070"
                                                       FontSize="9"
                                                       FontWeight="Bold"
                                                       Margin="0,0,0,2"/>
                                            <TextBlock Text="Applications"
                                                       Foreground="#6070A0"
                                                       FontSize="11"/>
                                        </StackPanel>
                                        <Border Grid.Column="1"
                                                CornerRadius="20"
                                                Padding="12,4,12,4">
                                            <Border.Background>
                                                <LinearGradientBrush StartPoint="0,0" EndPoint="1,0">
                                                    <GradientStop Color="#1E2C70" Offset="0"/>
                                                    <GradientStop Color="#253480" Offset="1"/>
                                                </LinearGradientBrush>
                                            </Border.Background>
                                            <TextBlock x:Name="SelectedCounter"
                                                       Text="0"
                                                       FontSize="18"
                                                       FontWeight="Bold"
                                                       HorizontalAlignment="Center">
                                                <TextBlock.Foreground>
                                                    <LinearGradientBrush StartPoint="0,0" EndPoint="1,0">
                                                        <GradientStop Color="#7B8CFF" Offset="0"/>
                                                        <GradientStop Color="#9B8CFF" Offset="1"/>
                                                    </LinearGradientBrush>
                                                </TextBlock.Foreground>
                                            </TextBlock>
                                        </Border>
                                    </Grid>
                                </Border>

                                <!-- INSTALL BUTTON -->
                                <Button x:Name="BtnInstall"
                                        Style="{StaticResource PrimaryBtn}"
                                        Content="Install Selected"
                                        Margin="0,0,0,8"
                                        IsEnabled="False"/>

                                <!-- PRESET BUTTON -->
                                <Button x:Name="BtnPreset"
                                        Style="{StaticResource SecondaryBtn}"
                                        Content="Recommended Preset"
                                        Margin="0,0,0,14"/>

                                <!-- STATUS CARD -->
                                <Border CornerRadius="12"
                                        Padding="14,12,14,14"
                                        Margin="0,0,0,0"
                                        BorderThickness="1"
                                        BorderBrush="#1A1E3A"
                                        Effect="{StaticResource CardShadow}">
                                    <Border.Background>
                                        <LinearGradientBrush StartPoint="0,0" EndPoint="0,1">
                                            <GradientStop Color="#141830" Offset="0"/>
                                            <GradientStop Color="#0F1224" Offset="1"/>
                                        </LinearGradientBrush>
                                    </Border.Background>
                                    <StackPanel>

                                        <!-- Status label row -->
                                        <Grid Margin="0,0,0,10">
                                            <Grid.ColumnDefinitions>
                                                <ColumnDefinition Width="*"/>
                                                <ColumnDefinition Width="Auto"/>
                                            </Grid.ColumnDefinitions>
                                            <TextBlock Text="STATUS"
                                                       Foreground="#2E3460"
                                                       FontSize="9"
                                                       FontWeight="Bold"
                                                       VerticalAlignment="Center"/>
                                            <!-- Online indicator dot -->
                                            <Border Grid.Column="1"
                                                    Width="6"
                                                    Height="6"
                                                    CornerRadius="3"
                                                    Background="#4AFF8C"
                                                    VerticalAlignment="Center"/>
                                        </Grid>

                                        <TextBlock x:Name="StatusLabel"
                                                   Text="Ready"
                                                   Foreground="#7B8CDE"
                                                   FontSize="11"
                                                   TextWrapping="Wrap"
                                                   Margin="0,0,0,12"/>

                                        <!-- Progress Track -->
                                        <Border CornerRadius="4"
                                                Height="8"
                                                Background="#0D1020"
                                                Margin="0,0,0,6"
                                                BorderThickness="1"
                                                BorderBrush="#1A1E38">
                                            <Grid>
                                                <!-- Glow backdrop -->
                                                <Border x:Name="ProgressGlow"
                                                        CornerRadius="4"
                                                        HorizontalAlignment="Left"
                                                        Width="0"
                                                        Opacity="0.3">
                                                    <Border.Background>
                                                        <LinearGradientBrush StartPoint="0,0" EndPoint="1,0">
                                                            <GradientStop Color="#5B6CF9" Offset="0"/>
                                                            <GradientStop Color="#9B6CFF" Offset="1"/>
                                                        </LinearGradientBrush>
                                                    </Border.Background>
                                                    <Border.Effect>
                                                        <BlurEffect Radius="4"/>
                                                    </Border.Effect>
                                                </Border>
                                                <!-- Main fill -->
                                                <Border x:Name="ProgressFill"
                                                        CornerRadius="4"
                                                        HorizontalAlignment="Left"
                                                        Width="0">
                                                    <Border.Background>
                                                        <LinearGradientBrush StartPoint="0,0" EndPoint="1,0">
                                                            <GradientStop Color="#5B6CF9" Offset="0"/>
                                                            <GradientStop Color="#9B6CFF" Offset="1"/>
                                                        </LinearGradientBrush>
                                                    </Border.Background>
                                                </Border>
                                            </Grid>
                                        </Border>

                                        <TextBlock x:Name="ProgressLabel"
                                                   Text="0 / 0"
                                                   Foreground="#2E3460"
                                                   FontSize="10"
                                                   HorizontalAlignment="Right"/>
                                    </StackPanel>
                                </Border>

                                <!-- LOG HEADER -->
                                <Grid Margin="0,14,0,6">
                                    <Grid.ColumnDefinitions>
                                        <ColumnDefinition Width="*"/>
                                        <ColumnDefinition Width="Auto"/>
                                    </Grid.ColumnDefinitions>
                                    <TextBlock Text="TERMINAL LOG"
                                               Foreground="#2E3460"
                                               FontSize="9"
                                               FontWeight="Bold"
                                               VerticalAlignment="Center"/>
                                    <Border Grid.Column="1"
                                            CornerRadius="4"
                                            Padding="6,2,6,2"
                                            Background="#0D1020">
                                        <TextBlock Text="LIVE"
                                                   Foreground="#4AFF8C"
                                                   FontSize="8"
                                                   FontWeight="Bold"/>
                                    </Border>
                                </Grid>

                            </StackPanel>

                            <!-- LOG TERMINAL BOX -->
                            <Border Grid.Row="1"
                                    CornerRadius="12"
                                    Margin="14,0,14,14"
                                    BorderThickness="1"
                                    BorderBrush="#141828"
                                    ClipToBounds="True">
                                <Border.Background>
                                    <LinearGradientBrush StartPoint="0,0" EndPoint="0,1">
                                        <GradientStop Color="#060810" Offset="0"/>
                                        <GradientStop Color="#080A16" Offset="1"/>
                                    </LinearGradientBrush>
                                </Border.Background>
                                <!-- Terminal top bar -->
                                <Grid>
                                    <Grid.RowDefinitions>
                                        <RowDefinition Height="24"/>
                                        <RowDefinition Height="*"/>
                                    </Grid.RowDefinitions>
                                    <Border Grid.Row="0"
                                            Background="#0C0E1C"
                                            BorderThickness="0,0,0,1"
                                            BorderBrush="#141828">
                                        <StackPanel Orientation="Horizontal"
                                                    Margin="8,0,0,0"
                                                    VerticalAlignment="Center">
                                            <Border Width="7" Height="7" CornerRadius="4"
                                                    Background="#FF5F57" Margin="0,0,5,0"/>
                                            <Border Width="7" Height="7" CornerRadius="4"
                                                    Background="#FFBD2E" Margin="0,0,5,0"/>
                                            <Border Width="7" Height="7" CornerRadius="4"
                                                    Background="#28C840"/>
                                        </StackPanel>
                                    </Border>
                                    <TextBox Grid.Row="1"
                                             x:Name="LogBox"
                                             Background="Transparent"
                                             Foreground="#4A6090"
                                             FontFamily="Consolas"
                                             FontSize="10"
                                             BorderThickness="0"
                                             IsReadOnly="True"
                                             TextWrapping="Wrap"
                                             VerticalScrollBarVisibility="Auto"
                                             Padding="10,8,10,8"
                                             AcceptsReturn="True"/>
                                </Grid>
                            </Border>
                        </Grid>
                    </Border>
                </Grid>

                <!-- FOOTER -->
                <Border Grid.Row="2"
                        BorderThickness="0,1,0,0"
                        BorderBrush="#0E1220">
                    <Border.Background>
                        <LinearGradientBrush StartPoint="0,0" EndPoint="1,0">
                            <GradientStop Color="#080B18" Offset="0"/>
                            <GradientStop Color="#0A0D1E" Offset="0.5"/>
                            <GradientStop Color="#080B18" Offset="1"/>
                        </LinearGradientBrush>
                    </Border.Background>
                    <Grid Margin="22,0,22,0">
                        <Grid.ColumnDefinitions>
                            <ColumnDefinition Width="*"/>
                            <ColumnDefinition Width="Auto"/>
                            <ColumnDefinition Width="*"/>
                        </Grid.ColumnDefinitions>
                        <TextBlock Grid.Column="0"
                                   Text="Administrator Mode"
                                   Foreground="#1E2440"
                                   FontSize="9"
                                   VerticalAlignment="Center"/>
                        <TextBlock Grid.Column="1"
                                   Text="HumanTouch Optimizer"
                                   FontSize="9"
                                   VerticalAlignment="Center"
                                   HorizontalAlignment="Center">
                            <TextBlock.Foreground>
                                <LinearGradientBrush StartPoint="0,0" EndPoint="1,0">
                                    <GradientStop Color="#2A3060" Offset="0"/>
                                    <GradientStop Color="#3A4080" Offset="1"/>
                                </LinearGradientBrush>
                            </TextBlock.Foreground>
                        </TextBlock>
                        <TextBlock Grid.Column="2"
                                   Text="Windows 10 / 11"
                                   Foreground="#1E2440"
                                   FontSize="9"
                                   VerticalAlignment="Center"
                                   HorizontalAlignment="Right"/>
                    </Grid>
                </Border>

            </Grid>
        </Border>
    </Border>
</Window>
'@

# =====================================================================
# LOAD WINDOW
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
$script:AppListPanel     = $script:Window.FindName("AppListPanel")
$script:BtnInstall       = $script:Window.FindName("BtnInstall")
$script:BtnPreset        = $script:Window.FindName("BtnPreset")
$script:BtnClose         = $script:Window.FindName("BtnClose")
$script:BtnMinimize      = $script:Window.FindName("BtnMinimize")
$script:DragBar          = $script:Window.FindName("DragBar")
$script:StatusLabel      = $script:Window.FindName("StatusLabel")
$script:ProgressFill     = $script:Window.FindName("ProgressFill")
$script:ProgressGlow     = $script:Window.FindName("ProgressGlow")
$script:ProgressLabel    = $script:Window.FindName("ProgressLabel")
$script:LogBox           = $script:Window.FindName("LogBox")
$script:SelectedCounter  = $script:Window.FindName("SelectedCounter")

# CheckBox reference map: AppId -> CheckBox
$script:CheckBoxMap = @{}

# =====================================================================
# WINDOW CHROME CONTROLS (Custom title bar)
# =====================================================================
$script:BtnClose.Add_Click({ $script:Window.Close() })
$script:BtnMinimize.Add_Click({ $script:Window.WindowState = [System.Windows.WindowState]::Minimized })
$script:DragBar.Add_MouseLeftButtonDown({
    $script:Window.DragMove()
})

# =====================================================================
# UPDATE SELECTED COUNTER
# =====================================================================
function Update-Counter {
    $count = 0
    foreach ($id in $script:CheckBoxMap.Keys) {
        if ($script:CheckBoxMap[$id].IsChecked -eq $true) { $count++ }
    }
    $script:SelectedCounter.Text  = "$count"
    $script:BtnInstall.IsEnabled  = ($count -gt 0)
}

# =====================================================================
# BUILD APP LIST DYNAMICALLY WITH PREMIUM CARD STYLE
# =====================================================================
function Build-AppList {

    $catIcons = @{
        "BROWSERS"         = "[ B ]"
        "COMMUNICATION"    = "[ C ]"
        "GAMING PLATFORMS" = "[ G ]"
        "SYSTEM TOOLS"     = "[ S ]"
        "MEDIA"            = "[ M ]"
    }

    $firstCat = $true

    foreach ($category in $script:AppCategories.Keys) {

        if (-not $firstCat) {
            $spacer        = New-Object System.Windows.Controls.Border
            $spacer.Height = 8
            $script:AppListPanel.Children.Add($spacer) | Out-Null
        }
        $firstCat = $false

        # Category Card
        $card                  = New-Object System.Windows.Controls.Border
        $card.CornerRadius     = New-Object System.Windows.CornerRadius(12)
        $card.Margin           = New-Object System.Windows.Thickness(0, 0, 0, 0)
        $card.Padding          = New-Object System.Windows.Thickness(0, 0, 0, 8)
        $card.BorderThickness  = New-Object System.Windows.Thickness(1)
        $card.BorderBrush      = [System.Windows.Media.SolidColorBrush][System.Windows.Media.ColorConverter]::ConvertFromString("#141828")

        $cardBg               = New-Object System.Windows.Media.LinearGradientBrush
        $cardBg.StartPoint    = New-Object System.Windows.Point(0, 0)
        $cardBg.EndPoint      = New-Object System.Windows.Point(0, 1)
        $stop1                = New-Object System.Windows.Media.GradientStop
        $stop1.Color          = [System.Windows.Media.ColorConverter]::ConvertFromString("#161B30")
        $stop1.Offset         = 0
        $stop2                = New-Object System.Windows.Media.GradientStop
        $stop2.Color          = [System.Windows.Media.ColorConverter]::ConvertFromString("#111628")
        $stop2.Offset         = 1
        $cardBg.GradientStops.Add($stop1) | Out-Null
        $cardBg.GradientStops.Add($stop2) | Out-Null
        $card.Background      = $cardBg

        $shadowFx              = New-Object System.Windows.Media.Effects.DropShadowEffect
        $shadowFx.BlurRadius   = 14
        $shadowFx.ShadowDepth  = 3
        $shadowFx.Direction    = 270
        $shadowFx.Color        = [System.Windows.Media.Colors]::Black
        $shadowFx.Opacity      = 0.35
        $card.Effect           = $shadowFx

        $innerStack            = New-Object System.Windows.Controls.StackPanel

        # Category Header Row
        $headerBorder          = New-Object System.Windows.Controls.Border
        $headerBorder.Padding  = New-Object System.Windows.Thickness(14, 10, 14, 10)
        $headerBorder.BorderThickness = New-Object System.Windows.Thickness(0, 0, 0, 1)
        $headerBorder.BorderBrush = [System.Windows.Media.SolidColorBrush][System.Windows.Media.ColorConverter]::ConvertFromString("#141828")

        $hdrBg                 = New-Object System.Windows.Media.LinearGradientBrush
        $hdrBg.StartPoint      = New-Object System.Windows.Point(0, 0)
        $hdrBg.EndPoint        = New-Object System.Windows.Point(1, 0)
        $hs1                   = New-Object System.Windows.Media.GradientStop
        $hs1.Color             = [System.Windows.Media.ColorConverter]::ConvertFromString("#13182E")
        $hs1.Offset            = 0
        $hs2                   = New-Object System.Windows.Media.GradientStop
        $hs2.Color             = [System.Windows.Media.ColorConverter]::ConvertFromString("#0F1424")
        $hs2.Offset            = 1
        $hdrBg.GradientStops.Add($hs1) | Out-Null
        $hdrBg.GradientStops.Add($hs2) | Out-Null
        $headerBorder.Background = $hdrBg

        $headerGrid            = New-Object System.Windows.Controls.Grid
        $col1                  = New-Object System.Windows.Controls.ColumnDefinition
        $col1.Width            = [System.Windows.GridLength]::Auto
        $col2                  = New-Object System.Windows.Controls.ColumnDefinition
        $col2.Width            = New-Object System.Windows.GridLength(1, [System.Windows.GridUnitType]::Star)
        $col3                  = New-Object System.Windows.Controls.ColumnDefinition
        $col3.Width            = [System.Windows.GridLength]::Auto
        $headerGrid.ColumnDefinitions.Add($col1) | Out-Null
        $headerGrid.ColumnDefinitions.Add($col2) | Out-Null
        $headerGrid.ColumnDefinitions.Add($col3) | Out-Null

        # Accent left bar
        $accentBar             = New-Object System.Windows.Controls.Border
        $accentBar.Width       = 3
        $accentBar.Height      = 16
        $accentBar.CornerRadius = New-Object System.Windows.CornerRadius(2)
        $accentBar.Margin      = New-Object System.Windows.Thickness(0, 0, 10, 0)
        $accentBrush           = New-Object System.Windows.Media.LinearGradientBrush
        $accentBrush.StartPoint = New-Object System.Windows.Point(0, 0)
        $accentBrush.EndPoint   = New-Object System.Windows.Point(0, 1)
        $as1 = New-Object System.Windows.Media.GradientStop
        $as1.Color = [System.Windows.Media.ColorConverter]::ConvertFromString("#5B6CF9")
        $as1.Offset = 0
        $as2 = New-Object System.Windows.Media.GradientStop
        $as2.Color = [System.Windows.Media.ColorConverter]::ConvertFromString("#9B6CFF")
        $as2.Offset = 1
        $accentBrush.GradientStops.Add($as1) | Out-Null
        $accentBrush.GradientStops.Add($as2) | Out-Null
        $accentBar.Background = $accentBrush
        [System.Windows.Controls.Grid]::SetColumn($accentBar, 0)

        # Category title
        $catTitle              = New-Object System.Windows.Controls.TextBlock
        $catTitle.Text         = $category
        $catTitle.FontSize     = 11
        $catTitle.FontWeight   = [System.Windows.FontWeights]::SemiBold
        $catTitle.Foreground   = [System.Windows.Media.SolidColorBrush][System.Windows.Media.ColorConverter]::ConvertFromString("#8090C8")
        $catTitle.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
        [System.Windows.Controls.Grid]::SetColumn($catTitle, 1)

        # App count badge
        $countBadge            = New-Object System.Windows.Controls.Border
        $countBadge.CornerRadius = New-Object System.Windows.CornerRadius(10)
        $countBadge.Padding    = New-Object System.Windows.Thickness(8, 2, 8, 2)
        $countBadge.Background = [System.Windows.Media.SolidColorBrush][System.Windows.Media.ColorConverter]::ConvertFromString("#141C3C")
        $countBadge.BorderBrush = [System.Windows.Media.SolidColorBrush][System.Windows.Media.ColorConverter]::ConvertFromString("#1E2850")
        $countBadge.BorderThickness = New-Object System.Windows.Thickness(1)
        $badgeTxt              = New-Object System.Windows.Controls.TextBlock
        $badgeTxt.Text         = "$($script:AppCategories[$category].Count)"
        $badgeTxt.Foreground   = [System.Windows.Media.SolidColorBrush][System.Windows.Media.ColorConverter]::ConvertFromString("#4A5888")
        $badgeTxt.FontSize     = 10
        $countBadge.Child      = $badgeTxt
        [System.Windows.Controls.Grid]::SetColumn($countBadge, 2)

        $headerGrid.Children.Add($accentBar) | Out-Null
        $headerGrid.Children.Add($catTitle)  | Out-Null
        $headerGrid.Children.Add($countBadge) | Out-Null
        $headerBorder.Child = $headerGrid
        $innerStack.Children.Add($headerBorder) | Out-Null

        # App entries container
        $appsPanel             = New-Object System.Windows.Controls.StackPanel
        $appsPanel.Margin      = New-Object System.Windows.Thickness(8, 4, 8, 0)

        foreach ($app in $script:AppCategories[$category]) {
            $cb                = New-Object System.Windows.Controls.CheckBox
            $cb.Content        = $app.Name
            $cb.Tag            = $app.Id
            $cb.Style          = $script:Window.Resources["ToggleCheckBox"]

            # Wire counter update
            $cb.Add_Checked({ Update-Counter })
            $cb.Add_Unchecked({ Update-Counter })

            $script:CheckBoxMap[$app.Id] = $cb
            $appsPanel.Children.Add($cb) | Out-Null
        }

        $innerStack.Children.Add($appsPanel) | Out-Null
        $card.Child = $innerStack
        $script:AppListPanel.Children.Add($card) | Out-Null
    }
}

Build-AppList

# =====================================================================
# UI HELPER FUNCTIONS
# =====================================================================
function Append-Log {
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
        $script:BtnInstall.IsEnabled = $State
        $script:BtnPreset.IsEnabled  = $State
    })
}

# =====================================================================
# RECOMMENDED PRESET BUTTON
# =====================================================================
$script:BtnPreset.Add_Click({
    foreach ($id in $script:CheckBoxMap.Keys) {
        $script:CheckBoxMap[$id].IsChecked = ($script:RecommendedIds -contains $id)
    }
    Update-Counter
    Append-Log "Recommended preset applied: Chrome, Discord, Steam, 7-Zip, VLC"
    Set-Status "Preset loaded. Click Install Selected to begin."
})

# =====================================================================
# INSTALL SELECTED BUTTON
# =====================================================================
$script:BtnInstall.Add_Click({

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

    Set-UIEnabled -State $false
    Set-Progress -Current 0 -Total $selectedApps.Count
    Append-Log "Starting installation of $($selectedApps.Count) app(s)..."

    $dispRef  = $script:Window.Dispatcher
    $logRef   = $script:LogBox
    $statRef  = $script:StatusLabel
    $pbFill   = $script:ProgressFill
    $pbGlow   = $script:ProgressGlow
    $pbLbl    = $script:ProgressLabel
    $btnInst  = $script:BtnInstall
    $btnPre   = $script:BtnPreset
    $appArray = $selectedApps.ToArray()

    $rs = [RunspaceFactory]::CreateRunspace()
    $rs.ApartmentState = [System.Threading.ApartmentState]::STA
    $rs.ThreadOptions  = [System.Management.Automation.Runspaces.PSThreadOptions]::ReuseThread
    $rs.Open()

    $rs.SessionStateProxy.SetVariable("dispRef",  $dispRef)
    $rs.SessionStateProxy.SetVariable("logRef",   $logRef)
    $rs.SessionStateProxy.SetVariable("statRef",  $statRef)
    $rs.SessionStateProxy.SetVariable("pbFill",   $pbFill)
    $rs.SessionStateProxy.SetVariable("pbGlow",   $pbGlow)
    $rs.SessionStateProxy.SetVariable("pbLbl",    $pbLbl)
    $rs.SessionStateProxy.SetVariable("btnInst",  $btnInst)
    $rs.SessionStateProxy.SetVariable("btnPre",   $btnPre)
    $rs.SessionStateProxy.SetVariable("appArray", $appArray)

    $psCode = {
        function RS-Log {
            param([string]$Msg)
            $ts   = Get-Date -Format "HH:mm:ss"
            $line = "[$ts]  $Msg"
            $dispRef.Invoke([action]{
                $logRef.AppendText("$line`r`n")
                $logRef.ScrollToEnd()
            })
        }

        function RS-Status {
            param([string]$Msg)
            $dispRef.Invoke([action]{ $statRef.Text = $Msg })
        }

        function RS-Progress {
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

        function RS-IsInstalled {
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

        foreach ($app in $appArray) {
            RS-Progress -Cur $current -Tot $total
            RS-Log "Checking: $($app.Name)..."
            RS-Status "Checking: $($app.Name)"

            if (RS-IsInstalled -Id $app.Id) {
                RS-Log "Already installed, skipping: $($app.Name)"
            } else {
                RS-Log "Installing: $($app.Name) [$($app.Id)]"
                RS-Status "Installing: $($app.Name)..."
                try {
                    $proc = Start-Process -FilePath "winget" `
                        -ArgumentList "install --id $($app.Id) -e --silent --accept-package-agreements --accept-source-agreements" `
                        -Wait -PassThru -WindowStyle Hidden

                    $code = $proc.ExitCode
                    if ($code -eq 0) {
                        RS-Log "Successfully installed: $($app.Name)"
                    } elseif ($code -eq -1978335189) {
                        RS-Log "Already up to date: $($app.Name)"
                    } else {
                        RS-Log "Completed with exit code $code`: $($app.Name)"
                    }
                } catch {
                    RS-Log "Error installing $($app.Name)`: $($_.Exception.Message)"
                }
            }

            $current++
            RS-Progress -Cur $current -Tot $total
        }

        RS-Log "All done. $total app(s) processed."
        RS-Status "Finished."
        $dispRef.Invoke([action]{
            $btnInst.IsEnabled = $true
            $btnPre.IsEnabled  = $true
        })
    }

    $ps = [System.Management.Automation.PowerShell]::Create()
    $ps.Runspace = $rs
    $ps.AddScript($psCode) | Out-Null
    $ps.BeginInvoke() | Out-Null
})

# =====================================================================
# STARTUP LOG + SHOW WINDOW
# =====================================================================
$script:LogBox.AppendText("[$(Get-Date -Format 'HH:mm:ss')]  HumanTouch Optimizer v1.0 initialized.`r`n")
$script:LogBox.AppendText("[$(Get-Date -Format 'HH:mm:ss')]  Administrator context confirmed.`r`n")
$script:LogBox.AppendText("[$(Get-Date -Format 'HH:mm:ss')]  winget package manager detected.`r`n")
$script:LogBox.AppendText("[$(Get-Date -Format 'HH:mm:ss')]  Select applications and click Install Selected.`r`n")

$script:Window.ShowDialog() | Out-Null
