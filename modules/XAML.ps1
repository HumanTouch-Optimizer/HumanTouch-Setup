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
