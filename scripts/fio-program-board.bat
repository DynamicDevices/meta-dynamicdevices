@echo off
REM
REM Foundries.io Board Programming Tool for Dynamic Devices (Windows Batch)
REM
REM Copyright (c) 2024 Dynamic Devices Ltd.
REM Licensed under the GNU General Public License v3.0
REM
REM This script downloads target build files from Foundries.io and optionally
REM programs Dynamic Devices boards using fioctl and UUU manufacturing tools.
REM
REM Author: Dynamic Devices Engineering Team
REM Version: 2.0.0
REM Repository: https://github.com/dynamic-devices/meta-dynamicdevices
REM
REM CHANGELOG:
REM v2.0.0 (2024-12-19)
REM   - Windows batch file version for maximum compatibility
REM   - Added basic timing for download performance tracking
REM   - Added /program flag for automatic board programming after download
REM   - Added intelligent caching to avoid re-downloading existing files
REM   - Added /force flag to override caching when needed
REM   - Added automatic latest target selection when no target specified
REM   - Added support for fioctl default factory configuration
REM   - Added /continuous flag for batch programming multiple boards
REM   - Fixed i.MX93 bootloader size issue by using correct production bootloader
REM   - Improved error handling and user feedback
REM   - Enhanced logging with clear output messages
REM   - Added configuration management for factory/machine defaults
REM
REM v1.0.0 (2024-12-18)
REM   - Initial bash version with basic download functionality
REM   - Support for imx8mm-jaguar-sentai, imx93-jaguar-eink, imx8mm-jaguar-phasora
REM   - Automatic MFGTools extraction and programming script generation
REM   - fioctl authentication and factory validation
REM   - Comprehensive artifact downloading (bootloader, U-Boot, DTB, system image, manifest)
REM
REM Requirements:
REM   - fioctl installed and authenticated (run 'fioctl login' first)
REM   - Factory access configured
REM   - Valid target number and machine name
REM   - Administrator privileges for board programming (when using /program)
REM   - tar or 7-Zip for extracting mfgtool archives
REM

setlocal enabledelayedexpansion

REM Script configuration
set "SCRIPT_NAME=%~nx0"
set "SCRIPT_VERSION=2.0.0"
set "SCRIPT_DIR=%~dp0"

REM Configuration file path
set "CONFIG_FILE=%USERPROFILE%\.config\dd-target-downloader.conf"

REM Default configuration
set "DEFAULT_FACTORY="
set "DEFAULT_MACHINE="

REM Supported machines
set "SUPPORTED_MACHINES=imx8mm-jaguar-sentai imx93-jaguar-eink imx8mm-jaguar-phasora imx8mm-jaguar-inst imx93-11x11-lpddr4x-evk"

REM Command line variables
set "TARGET_NUMBER="
set "MACHINE="
set "OUTPUT_DIR="
set "FACTORY="
set "FORCE_DOWNLOAD=0"
set "PROGRAM_FLAG=0"
set "CONTINUOUS_FLAG=0"
set "LIST_TARGETS=0"
set "CONFIGURE=0"
set "SHOW_VERSION=0"
set "SHOW_HELP=0"

REM Timing variables
set "TIMER_START="

REM Parse command line arguments
:parse_args
if "%~1"=="" goto args_done
if /i "%~1"=="/factory" (
    set "FACTORY=%~2"
    shift
    shift
    goto parse_args
)
if /i "%~1"=="/machine" (
    set "MACHINE=%~2"
    shift
    shift
    goto parse_args
)
if /i "%~1"=="/output" (
    set "OUTPUT_DIR=%~2"
    shift
    shift
    goto parse_args
)
if /i "%~1"=="/list" (
    set "LIST_TARGETS=1"
    shift
    goto parse_args
)
if /i "%~1"=="/configure" (
    set "CONFIGURE=1"
    shift
    goto parse_args
)
if /i "%~1"=="/force" (
    set "FORCE_DOWNLOAD=1"
    shift
    goto parse_args
)
if /i "%~1"=="/program" (
    set "PROGRAM_FLAG=1"
    shift
    goto parse_args
)
if /i "%~1"=="/continuous" (
    set "CONTINUOUS_FLAG=1"
    set "PROGRAM_FLAG=1"
    shift
    goto parse_args
)
if /i "%~1"=="/version" (
    set "SHOW_VERSION=1"
    shift
    goto parse_args
)
if /i "%~1"=="/help" (
    set "SHOW_HELP=1"
    shift
    goto parse_args
)
if /i "%~1"=="/?" (
    set "SHOW_HELP=1"
    shift
    goto parse_args
)
REM Positional arguments
if "%TARGET_NUMBER%"=="" (
    set "TARGET_NUMBER=%~1"
    shift
    goto parse_args
)
if "%MACHINE%"=="" (
    set "MACHINE=%~1"
    shift
    goto parse_args
)
if "%OUTPUT_DIR%"=="" (
    set "OUTPUT_DIR=%~1"
    shift
    goto parse_args
)
shift
goto parse_args

:args_done

REM Show version if requested
if "%SHOW_VERSION%"=="1" (
    echo %SCRIPT_NAME% version %SCRIPT_VERSION%
    echo.
    echo Foundries.io Board Programming Tool for Dynamic Devices
    echo Copyright ^(c^) 2024 Dynamic Devices Ltd.
    echo Licensed under the GNU General Public License v3.0
    echo.
    echo Repository: https://github.com/dynamic-devices/meta-dynamicdevices
    exit /b 0
)

REM Show help if requested
if "%SHOW_HELP%"=="1" goto show_usage

REM Check if no meaningful arguments provided - show help by default
if "%TARGET_NUMBER%"=="" if "%MACHINE%"=="" if "%LIST_TARGETS%"=="0" if "%CONFIGURE%"=="0" if "%PROGRAM_FLAG%"=="0" if "%CONTINUOUS_FLAG%"=="0" (
    call :log_info "No arguments provided. Showing help..."
    echo.
    goto show_usage
)

REM Check all dependencies first
call :check_all_dependencies
if errorlevel 1 exit /b 1

REM Load configuration
call :load_config

REM Use defaults if not specified
if "%FACTORY%"=="" set "FACTORY=%DEFAULT_FACTORY%"
if "%MACHINE%"=="" set "MACHINE=%DEFAULT_MACHINE%"

REM Handle configuration setup
if "%CONFIGURE%"=="1" (
    call :interactive_config
    exit /b !errorlevel!
)

REM Handle list targets
if "%LIST_TARGETS%"=="1" (
    if "%FACTORY%"=="" (
        call :log_error "Factory name required for listing targets"
        call :log_info "Use: %SCRIPT_NAME% /factory factory-name /list"
        exit /b 1
    )
    call :list_targets "%FACTORY%"
    exit /b !errorlevel!
)

REM Validate required parameters - try fioctl default factory if none specified
if "%FACTORY%"=="" (
    call :log_info "No factory specified, checking if fioctl has a default factory configured..."
    
    REM Test if fioctl can work without explicit factory
    fioctl targets list >nul 2>&1
    if !errorlevel! equ 0 (
        call :log_success "Using fioctl's default factory configuration"
        set "FACTORY=<default>"
    ) else (
        call :log_error "Factory name is required"
        call :log_info "Options to specify factory:"
        call :log_info "  1. Use /factory factory-name"
        call :log_info "  2. Run /configure to set default factory in this script"
        call :log_info "  3. Set default factory in fioctl: Add 'factory: your-factory-name' to ~/.config/fioctl.yaml"
        call :log_info "  4. Set DEFAULT_FACTORY in config file: %CONFIG_FILE%"
        exit /b 1
    )
)

REM Get latest target if none specified
if "%TARGET_NUMBER%"=="" (
    call :log_info "No target specified, finding latest target for machine: %MACHINE%"
    call :get_latest_target "%FACTORY%" "%MACHINE%"
    if "!TARGET_NUMBER!"=="" (
        call :log_error "Could not find any targets for machine: %MACHINE%"
        if "%FACTORY%"=="<default>" (
            call :log_info "Use 'fioctl targets list' to see available targets"
        ) else (
            call :log_info "Use 'fioctl targets list --factory %FACTORY%' to see available targets"
        )
        call :log_info "Or specify a target number explicitly:"
        call :log_info "  %SCRIPT_NAME% /machine %MACHINE% target-number"
        exit /b 1
    )
    call :log_success "Using latest target: !TARGET_NUMBER!"
)

if "%MACHINE%"=="" (
    call :log_error "Machine name is required"
    call :log_info "Use /machine machine-name or run /configure to set defaults"
    exit /b 1
)

REM Set default output directory if not specified
if "%OUTPUT_DIR%"=="" (
    set "OUTPUT_DIR=.\downloads\target-%TARGET_NUMBER%-%MACHINE%"
)

REM Validate target number is numeric
echo %TARGET_NUMBER%| findstr /r "^[0-9][0-9]*$" >nul
if errorlevel 1 (
    call :log_error "Target number must be a positive integer"
    exit /b 1
)

call :log_info "Dynamic Devices Board Programming Tool v%SCRIPT_VERSION%"
call :log_info "Factory: %FACTORY%"
call :log_info "Target: %TARGET_NUMBER%"
call :log_info "Machine: %MACHINE%"
call :log_info "Output: %OUTPUT_DIR%"
if "%FORCE_DOWNLOAD%"=="1" (
    call :log_warning "Force download enabled - will re-download existing files"
)
echo.

REM Validation steps
REM Dependencies already checked - just validate factory access
call :fioctl_with_factory "%FACTORY%" "targets list" >nul 2>&1
if errorlevel 1 (
    if "%FACTORY%"=="<default>" (
        call :log_error "Cannot access default factory"
        call :log_info "Please check:"
        call :log_info "  1. Run 'fioctl login' to authenticate"
        call :log_info "  2. Set default factory: Add 'factory: your-factory-name' to ~/.config/fioctl.yaml"
        call :log_info "  3. Or use /factory factory-name explicitly"
    ) else (
        call :log_error "Cannot access factory '%FACTORY%'"
        call :log_info "Please check:"
        call :log_info "  1. Run 'fioctl login' to authenticate"
        call :log_info "  2. Verify factory name is correct"
        call :log_info "  3. Ensure you have access to this factory"
    )
    exit /b 1
)

call :validate_target "%TARGET_NUMBER%" "%FACTORY%"
if errorlevel 1 exit /b 1

call :validate_machine "%MACHINE%"
if errorlevel 1 exit /b 1

REM Download artifacts
call :download_target_artifacts "%TARGET_NUMBER%" "%FACTORY%" "%MACHINE%" "%OUTPUT_DIR%"
if errorlevel 1 (
    echo.
    call :log_error "Failed to download required artifacts"
    exit /b 1
)

echo.
call :log_success "All artifacts downloaded successfully!"
call :log_info "Output directory: %OUTPUT_DIR%"
call :log_info "Programming script: %OUTPUT_DIR%\program-%MACHINE%.bat"
echo.

REM Check if auto-programming is requested
if "%PROGRAM_FLAG%"=="1" (
    echo.
    if "%CONTINUOUS_FLAG%"=="1" (
        call :continuous_programming "%OUTPUT_DIR%" "%MACHINE%"
    ) else (
        call :single_programming "%OUTPUT_DIR%" "%MACHINE%"
    )
) else (
    call :log_info "Next steps:"
    call :log_info "  1. Put your board in download/recovery mode"
    call :log_info "  2. Connect USB cable"
    call :log_info "  3. Run as Administrator: %OUTPUT_DIR%\program-%MACHINE%.bat /flash"
    echo.
    call :log_info "Note: Administrator privileges are required for USB device access during programming"
)

exit /b 0

REM ============================================================================
REM Functions
REM ============================================================================

:check_all_dependencies
call :log_info "Checking system dependencies..."
echo.

set /a missing_deps=0
set /a optional_deps=0

REM Check critical dependencies
call :log_info "=== Critical Dependencies ==="

REM Check fioctl
fioctl version >nul 2>&1
if errorlevel 1 (
    REM Try the direct path in case it's installed but not in PATH
    "C:\tools\fioctl\fioctl.exe" version >nul 2>&1
    if errorlevel 1 (
        call :log_error "fioctl - NOT FOUND"
        set /a missing_deps+=1
        set "need_fioctl=1"
    ) else (
        call :log_success "fioctl - Available (C:\tools\fioctl\fioctl.exe)"
        call :log_info "  Note: fioctl not in PATH, but found in C:\tools\fioctl"
    )
) else (
    call :log_success "fioctl - Available"
)

REM Check PowerShell (needed for downloads)
powershell -Command "Get-Host" >nul 2>&1
if errorlevel 1 (
    call :log_error "PowerShell - NOT FOUND (required for downloads)"
    set /a missing_deps+=1
    set "need_powershell=1"
) else (
    call :log_success "PowerShell - Available"
)

echo.
call :log_info "=== Archive Extraction Tools ==="

REM Check for extraction tools (at least one needed)
set "extraction_available=0"

tar --version >nul 2>&1
if not errorlevel 1 (
    call :log_success "tar - Available"
    set "extraction_available=1"
) else (
    call :log_warning "tar - NOT FOUND"
)

7z --help >nul 2>&1
if not errorlevel 1 (
    call :log_success "7-Zip - Available"
    set "extraction_available=1"
) else (
    call :log_warning "7-Zip - NOT FOUND"
)

if "%extraction_available%"=="0" (
    call :log_error "No archive extraction tool found (need tar or 7-Zip)"
    set /a missing_deps+=1
    set "need_extraction=1"
)

echo.
call :log_info "=== Optional Package Managers ==="

REM Check optional package managers
choco --version >nul 2>&1
if not errorlevel 1 (
    call :log_success "Chocolatey - Available"
) else (
    call :log_info "Chocolatey - Not installed (optional)"
    set /a optional_deps+=1
)

scoop --version >nul 2>&1
if not errorlevel 1 (
    call :log_success "Scoop - Available"
) else (
    call :log_info "Scoop - Not installed (optional)"
    set /a optional_deps+=1
)

echo.
call :log_info "=== Programming Tools (for /program mode) ==="

REM Check if running as Administrator (needed for programming)
net session >nul 2>&1
if not errorlevel 1 (
    call :log_success "Administrator privileges - Available"
) else (
    call :log_warning "Administrator privileges - NOT AVAILABLE"
    call :log_info "  Note: Administrator privileges required for USB programming"
    call :log_info "  Run as Administrator when using /program mode"
)

echo.
REM Summary
if %missing_deps% gtr 0 (
    call :log_error "Found %missing_deps% missing critical dependencies"
    echo.
    
    if defined need_fioctl (
        call :log_info "Would you like to install missing dependencies automatically?"
        set /p "install_deps=Install dependencies? (y/N): "
        
        if /i "!install_deps!"=="y" (
            call :install_missing_dependencies
            if errorlevel 1 (
                call :log_error "Dependency installation failed"
                exit /b 1
            )
        ) else (
            call :log_error "Cannot continue without required dependencies"
            call :show_dependency_install_instructions
            exit /b 1
        )
    ) else (
        call :log_error "Cannot continue without required dependencies"
        call :show_dependency_install_instructions
        exit /b 1
    )
) else (
    call :log_success "All critical dependencies are available!"
    if %optional_deps% gtr 0 (
        call :log_info "Optional dependencies missing: %optional_deps% (package managers for easier installation)"
    )
)

echo.
exit /b 0

:install_missing_dependencies
call :log_info "Installing missing dependencies..."

if defined need_fioctl (
    call :log_info "Installing fioctl from GitHub releases..."
    call :install_fioctl_from_github
    if errorlevel 1 exit /b 1
)

if defined need_extraction (
    call :log_info "Installing 7-Zip for archive extraction..."
    
    choco --version >nul 2>&1
    if not errorlevel 1 (
        call :log_info "Using Chocolatey to install 7-Zip..."
        choco install 7zip -y
        if not errorlevel 1 (
            call :log_success "7-Zip installed successfully via Chocolatey"
        ) else (
            call :log_warning "Could not install 7-Zip automatically"
            call :log_info "Please install 7-Zip manually from: https://www.7-zip.org/"
        )
    ) else (
        call :log_warning "Could not install 7-Zip automatically (no package manager)"
        call :log_info "Please install 7-Zip manually from: https://www.7-zip.org/"
        call :log_info "Or install tar via Git for Windows or WSL"
    )
)

REM Verify installations
call :log_info "Verifying installations..."

REM Try fioctl in PATH first, then try the direct path
fioctl version >nul 2>&1
if errorlevel 1 (
    REM Try the direct path if PATH doesn't work yet
    "C:\tools\fioctl\fioctl.exe" version >nul 2>&1
    if errorlevel 1 (
        call :log_error "fioctl installation verification failed"
        exit /b 1
    ) else (
        call :log_success "fioctl is available at C:\tools\fioctl\fioctl.exe"
        call :log_info "You may need to restart Command Prompt for PATH to take effect"
    )
) else (
    call :log_success "fioctl is now available in PATH"
)

exit /b 0

:show_dependency_install_instructions
call :log_info "=== Manual Installation Instructions ==="
echo.

if defined need_fioctl (
    call :log_info "fioctl (Required):"
    call :log_info "  Method 1: Chocolatey - choco install fioctl"
    call :log_info "  Method 2: Scoop - scoop bucket add extras && scoop install fioctl"
    call :log_info "  Method 3: Manual - Download from https://github.com/foundriesio/fioctl/releases"
    echo.
)

if defined need_extraction (
    call :log_info "Archive Extraction Tool (Required - choose one):"
    call :log_info "  Option 1: 7-Zip - Download from https://www.7-zip.org/"
    call :log_info "  Option 2: tar - Install Git for Windows (includes tar)"
    call :log_info "  Option 3: WSL - Use Windows Subsystem for Linux"
    echo.
)

if defined need_powershell (
    call :log_info "PowerShell (Required):"
    call :log_info "  PowerShell should be pre-installed on Windows 7+ and Windows Server 2008+"
    call :log_info "  If missing, download from: https://github.com/PowerShell/PowerShell/releases"
    echo.
)

call :log_info "After installing dependencies, run this script again."
exit /b 0

:show_usage
echo Usage: %SCRIPT_NAME% [OPTIONS] [target-number] [machine] [output-dir]
echo.
echo Download target build files from Foundries.io and program Dynamic Devices boards.
echo.
echo Arguments:
echo   target-number    Target number from Foundries.io CI (optional - uses latest if not specified)
echo   machine          Machine name (optional if /machine or default configured)
echo   output-dir       Output directory (default: .\downloads\target-^<number^>-^<machine^>)
echo.
echo Options:
echo   /factory FACTORY     Foundries.io factory name (required unless configured)
echo   /machine MACHINE     Machine/hardware type to download
echo   /output DIR          Output directory
echo   /list                List available targets and exit
echo   /configure           Interactive configuration setup
echo   /force               Force re-download even if files exist locally
echo   /program             Automatically run programming script after download
echo   /continuous          Continuous programming mode for multiple boards
echo   /version             Show version information
echo   /help                Show this help message
echo.
echo Supported Machines:
for %%m in (%SUPPORTED_MACHINES%) do echo   - %%m
echo.
echo Examples:
echo   # First time setup (interactive configuration)
echo   %SCRIPT_NAME% /configure
echo.
echo   # Download with explicit factory and machine
echo   %SCRIPT_NAME% /factory my-factory /machine imx8mm-jaguar-sentai 1451
echo.
echo   # Use configured defaults (factory and machine)
echo   %SCRIPT_NAME% 1451
echo.
echo   # Use latest target (no target number specified)
echo   %SCRIPT_NAME% /machine imx93-jaguar-eink
echo.
echo   # Force re-download even if files exist
echo   %SCRIPT_NAME% /factory my-factory /machine imx93-jaguar-eink 1451 /force
echo.
echo   # Download and automatically program board
echo   %SCRIPT_NAME% /factory my-factory /machine imx93-jaguar-eink 1451 /program
echo.
echo   # Continuous programming mode for multiple boards
echo   %SCRIPT_NAME% /machine imx93-jaguar-eink /continuous
echo.
echo   # List available targets
echo   %SCRIPT_NAME% /factory my-factory /list
echo.
echo Requirements:
echo   - fioctl installed and authenticated (run 'fioctl login' first)
echo   - Access to the Foundries.io factory
echo   - Valid target number (check with 'fioctl targets list')
echo   - Administrator privileges for board programming (when using /program)
echo   - tar or 7-Zip for extracting mfgtool archives
exit /b 0

:log_info
echo [INFO] %~1
exit /b 0

:log_success
echo [SUCCESS] %~1
exit /b 0

:log_warning
echo [WARN] %~1
exit /b 0

:log_error
echo [ERROR] %~1
exit /b 0

:start_timer
for /f "tokens=1-4 delims=:.," %%a in ("%time%") do (
    set /a "TIMER_START=(((%%a*60)+1%%b %% 100)*60+1%%c %% 100)*100+1%%d %% 100"
)
exit /b 0

:end_timer
for /f "tokens=1-4 delims=:.," %%a in ("%time%") do (
    set /a "timer_end=(((%%a*60)+1%%b %% 100)*60+1%%c %% 100)*100+1%%d %% 100"
)
set /a "timer_duration=(!timer_end! - !TIMER_START!) / 100"
if !timer_duration! lss 0 set /a "timer_duration+=86400"
exit /b 0

:format_duration
set "duration_seconds=%~1"
if !duration_seconds! lss 60 (
    set "formatted_duration=!duration_seconds!s"
) else if !duration_seconds! lss 3600 (
    set /a "minutes=!duration_seconds! / 60"
    set /a "seconds=!duration_seconds! %% 60"
    set "formatted_duration=!minutes!m !seconds!s"
) else (
    set /a "hours=!duration_seconds! / 3600"
    set /a "remaining=!duration_seconds! %% 3600"
    set /a "minutes=!remaining! / 60"
    set /a "seconds=!remaining! %% 60"
    set "formatted_duration=!hours!h !minutes!m !seconds!s"
)
exit /b 0

:load_config
if exist "%CONFIG_FILE%" (
    for /f "usebackq tokens=1,2 delims==" %%a in ("%CONFIG_FILE%") do (
        if "%%a"=="DEFAULT_FACTORY" set "DEFAULT_FACTORY=%%b"
        if "%%a"=="DEFAULT_MACHINE" set "DEFAULT_MACHINE=%%b"
    )
)
exit /b 0

:save_config
set "config_factory=%~1"
set "config_machine=%~2"

if not exist "%USERPROFILE%\.config" mkdir "%USERPROFILE%\.config"

(
echo # Dynamic Devices Target Downloader Configuration
echo # This file is automatically generated and updated
echo.
echo # Default factory name ^(can be overridden with /factory^)
echo DEFAULT_FACTORY=%config_factory%
echo.
echo # Default machine name ^(can be overridden with /machine or positional argument^)
echo DEFAULT_MACHINE=%config_machine%
echo.
echo # Last updated: %date% %time%
) > "%CONFIG_FILE%"

call :log_info "Configuration saved to %CONFIG_FILE%"
exit /b 0

:interactive_config
call :log_info "=== Dynamic Devices Target Downloader Configuration ==="
echo.

set /p "factory=Enter your Foundries.io factory name: "
if "%factory%"=="" (
    call :log_error "Factory name is required"
    exit /b 1
)

call :log_info "Testing factory access..."
call :check_fioctl "%factory%"
if errorlevel 1 exit /b 1

echo.
call :log_info "Select your default machine type:"
set "machine_count=0"
for %%m in (%SUPPORTED_MACHINES%) do (
    set /a "machine_count+=1"
    echo   !machine_count!. %%m
    set "machine_!machine_count!=%%m"
)

:machine_selection
set /p "selection=Enter selection (1-%machine_count%): "
if "%selection%"=="" goto machine_selection
if %selection% lss 1 goto invalid_selection
if %selection% gtr %machine_count% goto invalid_selection

set "machine=!machine_%selection%!"
goto config_save

:invalid_selection
call :log_warning "Invalid selection. Please enter a number between 1 and %machine_count%"
goto machine_selection

:config_save
call :save_config "%factory%" "%machine%"

echo.
call :log_success "Configuration completed successfully!"
call :log_info "Factory: %factory%"
call :log_info "Default Machine: %machine%"
echo.
call :log_info "You can now use the script without specifying factory and machine:"
call :log_info "  %SCRIPT_NAME%"
call :log_info "  %SCRIPT_NAME% 1451"
call :log_info "  %SCRIPT_NAME% /program"

exit /b 0

:get_fioctl_command
REM Return the correct fioctl command (either in PATH or direct path)
fioctl version >nul 2>&1
if not errorlevel 1 (
    echo fioctl
) else (
    "C:\tools\fioctl\fioctl.exe" version >nul 2>&1
    if not errorlevel 1 (
        echo "C:\tools\fioctl\fioctl.exe"
    ) else (
        echo fioctl
    )
)
exit /b 0

:fioctl_with_factory
set "fio_factory=%~1"
set "fio_command=%~2"

REM Get the correct fioctl command
for /f "tokens=*" %%c in ('call :get_fioctl_command') do set "fioctl_cmd=%%c"

if "%fio_factory%"=="<default>" (
    %fioctl_cmd% %fio_command%
) else (
    %fioctl_cmd% %fio_command% --factory "%fio_factory%"
)
exit /b !errorlevel!

:check_fioctl
set "factory=%~1"

REM Check if fioctl is installed
fioctl version >nul 2>&1
if errorlevel 1 (
    call :log_error "fioctl is not installed or not in PATH"
    echo.
    call :log_info "=== fioctl Installation ==="
    echo.
    call :log_info "fioctl is required to download Foundries.io target artifacts."
    echo.
    set /p "install_fioctl=Would you like to install fioctl automatically? (y/N): "
    
    if /i "!install_fioctl!"=="y" (
        call :log_info "Installing fioctl..."
        
        REM Try different installation methods
        choco --version >nul 2>&1
        if not errorlevel 1 (
            call :log_info "Using Chocolatey to install fioctl..."
            choco install fioctl -y
            if not errorlevel 1 (
                call :log_success "fioctl installed successfully via Chocolatey"
                goto check_install_success
            ) else (
                call :log_warning "Chocolatey installation failed, trying manual installation..."
                call :install_fioctl_manual
            )
        ) else (
            scoop --version >nul 2>&1
            if not errorlevel 1 (
                call :log_info "Using Scoop to install fioctl..."
                scoop bucket add extras
                scoop install fioctl
                if not errorlevel 1 (
                    call :log_success "fioctl installed successfully via Scoop"
                    goto check_install_success
                ) else (
                    call :log_warning "Scoop installation failed, trying manual installation..."
                    call :install_fioctl_manual
                )
            ) else (
                call :log_info "No package manager found, using manual installation..."
                call :install_fioctl_manual
            )
        )
        
        :check_install_success
        REM Verify installation
        fioctl version >nul 2>&1
        if not errorlevel 1 (
            call :log_success "fioctl is now available!"
            call :log_info "Next step: Run 'fioctl login' to authenticate"
            goto fioctl_check_done
        ) else (
            call :log_error "Installation failed. Please install manually."
            call :show_manual_install_instructions
            exit /b 1
        )
    ) else (
        call :show_manual_install_instructions
        exit /b 1
    )
)

:fioctl_check_done

for /f "tokens=*" %%v in ('fioctl version 2^>nul') do (
    call :log_info "Using fioctl version: %%v"
    goto version_done
)
call :log_info "Using fioctl version: unknown"
:version_done

call :log_info "Checking fioctl authentication..."

if "%factory%"=="<default>" (
    call :log_info "Testing default factory access..."
    fioctl targets list >nul 2>&1
    if errorlevel 1 (
        call :log_error "Cannot access default factory"
        call :log_info "Please check:"
        call :log_info "  1. Run 'fioctl login' to authenticate"
        call :log_info "  2. Set default factory: Add 'factory: your-factory-name' to ~/.config/fioctl.yaml"
        call :log_info "  3. Or use /factory factory-name explicitly"
        exit /b 1
    )
    call :log_success "Default factory is accessible"
) else (
    call :log_info "Testing factory access: %factory%"
    fioctl targets list --factory "%factory%" >nul 2>&1
    if errorlevel 1 (
        call :log_error "Cannot access factory '%factory%'"
        call :log_info "Please check:"
        call :log_info "  1. Run 'fioctl login' to authenticate"
        call :log_info "  2. Verify factory name is correct"
        call :log_info "  3. Ensure you have access to this factory"
        exit /b 1
    )
    call :log_success "Factory '%factory%' is accessible"
)
exit /b 0

:list_targets
set "factory=%~1"
call :log_info "Listing targets for factory: %factory%"
echo.
call :fioctl_with_factory "%factory%" "targets list"
exit /b !errorlevel!

:get_latest_target
set "factory=%~1"
set "machine=%~2"
set "TARGET_NUMBER="

REM Get the latest target for the machine
REM First get all targets, filter for lines starting with numbers, then filter for machine name
for /f "tokens=1,2*" %%a in ('call :fioctl_with_factory "%factory%" "targets list" 2^>nul') do (
    REM Check if first token is a number and second token contains machine name
    echo %%a | findstr /r "^[0-9][0-9]*$" >nul
    if not errorlevel 1 (
        echo %%b | findstr /i "%machine%" >nul
        if not errorlevel 1 (
            set "TARGET_NUMBER=%%a"
        )
    )
)
exit /b 0

:validate_target
set "target=%~1"
set "factory=%~2"

call :log_info "Validating target %target% exists in factory %factory%..."

call :fioctl_with_factory "%factory%" "targets show %target%" >nul 2>&1
if errorlevel 1 (
    call :log_error "Target %target% not found in factory %factory%"
    if "%factory%"=="<default>" (
        call :log_info "Use 'fioctl targets list' to see available targets"
    ) else (
        call :log_info "Use 'fioctl targets list --factory %factory%' to see available targets"
    )
    exit /b 1
)
call :log_success "Target %target% found in factory %factory%"
exit /b 0

:validate_machine
set "machine=%~1"

for %%m in (%SUPPORTED_MACHINES%) do (
    if /i "%%m"=="%machine%" (
        call :log_success "Machine %machine% is supported"
        exit /b 0
    )
)
call :log_error "Unsupported machine: %machine%"
call :log_info "Supported machines: %SUPPORTED_MACHINES%"
exit /b 1

:file_exists_and_valid
set "file_path=%~1"
if not exist "%file_path%" exit /b 1
for %%f in ("%file_path%") do if %%~zf equ 0 exit /b 1
exit /b 0

:download_artifact
set "target=%~1"
set "factory=%~2"
set "artifact_path=%~3"
set "output_file=%~4"
set "description=%~5"

REM Check if file already exists and is valid (unless force flag is set)
if "%FORCE_DOWNLOAD%"=="0" (
    call :file_exists_and_valid "%output_file%"
    if not errorlevel 1 (
        for %%f in ("%output_file%") do (
            set /a "size_mb=%%~zf / 1048576"
            call :log_info "%description% already exists (!size_mb!MB) - skipping download"
        )
        exit /b 0
    )
)

call :log_info "Downloading %description%..."
call :log_info "  Artifact: %artifact_path%"
call :log_info "  Output: %output_file%"

call :start_timer
call :fioctl_with_factory "%factory%" "targets artifacts %target% %artifact_path%" > "%output_file%"
if errorlevel 1 (
    call :log_warning "Failed to download %description% (artifact may not exist)"
    if exist "%output_file%" del "%output_file%"
    exit /b 1
)

call :end_timer
for %%f in ("%output_file%") do (
    set /a "size_mb=%%~zf / 1048576"
)
call :format_duration %timer_duration%
call :log_success "Downloaded %description% (!size_mb!MB in !formatted_duration!)"
exit /b 0

:download_target_artifacts
set "target=%~1"
set "factory=%~2"
set "machine=%~3"
set "output_dir=%~4"

call :log_info "Starting download for target %target%, machine %machine%"
call :log_info "Factory: %factory%"
call :log_info "Output directory: %output_dir%"

call :start_timer

REM Create output directory
if not exist "%output_dir%" mkdir "%output_dir%"

set "artifacts_downloaded=0"
set "artifacts_failed=0"

REM Download mfgtool-files archive
set "mfgtools_archive=%output_dir%\mfgtool-files-%machine%.tar.gz"
set "mfgtools_dir=%output_dir%\mfgtool-files-%machine%"

REM Check if MFGTools are already extracted
if "%FORCE_DOWNLOAD%"=="0" (
    if exist "%mfgtools_dir%\uuu.exe" if exist "%mfgtools_dir%\full_image.uuu" (
        call :log_info "MFGTools programming package already extracted - skipping"
        set /a "artifacts_downloaded+=1"
        goto download_bootloader
    )
)

call :download_artifact "%target%" "%factory%" "%machine%-mfgtools/mfgtool-files-%machine%.tar.gz" "%mfgtools_archive%" "MFGTools programming package"
if errorlevel 1 (
    set /a "artifacts_failed+=1"
    call :log_error "MFGTools programming package is required for programming"
    goto download_summary
)
set /a "artifacts_downloaded+=1"

REM Extract mfgtool-files archive
call :log_info "Extracting MFGTools programming package..."
REM Try tar first, then 7-Zip
tar --version >nul 2>&1
if not errorlevel 1 (
    tar -xzf "%mfgtools_archive%" -C "%output_dir%"
) else (
    7z --help >nul 2>&1
    if not errorlevel 1 (
        7z x "%mfgtools_archive%" -o"%output_dir%"
    ) else (
        call :log_warning "tar or 7-Zip not found. Please extract %mfgtools_archive% manually"
        set /a "artifacts_failed+=1"
        goto download_summary
    )
)

if exist "%mfgtools_dir%" (
    call :log_success "Extracted MFGTools programming package"
    del "%mfgtools_archive%"
) else (
    call :log_error "Failed to extract MFGTools programming package"
    set /a "artifacts_failed+=1"
)

:download_bootloader
REM Production bootloader (required)
REM For i.MX93 boards, download the correct production bootloader
echo %machine% | findstr /i "imx93" >nul
if not errorlevel 1 (
    call :download_artifact "%target%" "%factory%" "%machine%/imx-boot" "%output_dir%\imx-boot-%machine%" "Production bootloader (i.MX93)"
) else (
    call :download_artifact "%target%" "%factory%" "%machine%/imx-boot-%machine%" "%output_dir%\imx-boot-%machine%" "Production bootloader"
)
if errorlevel 1 (
    set /a "artifacts_failed+=1"
    call :log_error "Production bootloader is required for programming"
) else (
    set /a "artifacts_downloaded+=1"
)

REM Production U-Boot (required)
call :download_artifact "%target%" "%factory%" "%machine%/u-boot-%machine%.itb" "%output_dir%\u-boot-%machine%.itb" "Production U-Boot image"
if errorlevel 1 (
    set /a "artifacts_failed+=1"
) else (
    set /a "artifacts_downloaded+=1"
)

REM Device tree blob (optional)
call :download_artifact "%target%" "%factory%" "%machine%-mfgtools/devicetree/%machine%.dtb" "%output_dir%\%machine%.dtb" "Device tree blob"
if errorlevel 1 (
    set /a "artifacts_failed+=1"
) else (
    set /a "artifacts_downloaded+=1"
)

REM Main system image (required)
call :download_artifact "%target%" "%factory%" "%machine%/lmp-factory-image-%machine%.wic.gz" "%output_dir%\lmp-factory-image-%machine%.wic.gz" "Main system image"
if errorlevel 1 (
    set /a "artifacts_failed+=1"
) else (
    set /a "artifacts_downloaded+=1"
)

REM Build manifest (optional)
call :download_artifact "%target%" "%factory%" "%machine%-mfgtools/manifest.xml" "%output_dir%\manifest.xml" "Build manifest"
if errorlevel 1 (
    set /a "artifacts_failed+=1"
) else (
    set /a "artifacts_downloaded+=1"
)

:download_summary
call :end_timer
call :format_duration %timer_duration%

echo.
call :log_info "Download Summary:"
call :log_info "  Artifacts downloaded: %artifacts_downloaded%"
call :log_info "  Artifacts failed: %artifacts_failed%"
call :log_info "  Total time: !formatted_duration!"

if %artifacts_downloaded% geq 2 (
    call :log_success "Required artifacts downloaded successfully"
    
    REM Create programming script
    set "programming_script=%output_dir%\program-%machine%.bat"
    call :log_info "Creating programming script: !programming_script!"
    call :create_programming_script "%output_dir%" "%machine%" "%target%" "!programming_script!"
    call :log_success "Created programming script: !programming_script!"
    echo.
    exit /b 0
) else (
    call :log_error "Failed to download required artifacts"
    exit /b 1
)

:create_programming_script
set "output_dir=%~1"
set "machine=%~2"
set "target=%~3"
set "script_path=%~4"

(
echo @echo off
echo REM
echo REM Programming script for %machine% ^(Target %target%^)
echo REM Generated by fio-program-board.bat
echo REM
echo REM Usage: program-%machine%.bat [/flash] [/bootloader]
echo REM
echo.
echo setlocal enabledelayedexpansion
echo.
echo set "SCRIPT_DIR=%%~dp0"
echo set "MACHINE=%machine%"
echo set "TARGET=%target%"
echo.
echo set "FLASH_MODE=0"
echo set "BOOTLOADER_MODE=0"
echo set "SHOW_HELP=0"
echo.
echo REM Parse arguments
echo :parse_args
echo if "%%~1"=="" goto args_done
echo if /i "%%~1"=="/flash" ^(
echo     set "FLASH_MODE=1"
echo     shift
echo     goto parse_args
echo ^)
echo if /i "%%~1"=="/bootloader" ^(
echo     set "BOOTLOADER_MODE=1"
echo     shift
echo     goto parse_args
echo ^)
echo if /i "%%~1"=="/help" ^(
echo     set "SHOW_HELP=1"
echo     shift
echo     goto parse_args
echo ^)
echo if /i "%%~1"=="/?" ^(
echo     set "SHOW_HELP=1"
echo     shift
echo     goto parse_args
echo ^)
echo shift
echo goto parse_args
echo.
echo :args_done
echo.
echo if "%%SHOW_HELP%%"=="1" goto show_usage
echo.
echo REM Default to full image programming
echo if "%%FLASH_MODE%%"=="0" if "%%BOOTLOADER_MODE%%"=="0" set "FLASH_MODE=1"
echo.
echo echo [INFO] Programming mode: %%^(if "%%FLASH_MODE%%"=="1" ^(echo flash^) else ^(echo bootloader^)^)%%
echo echo [INFO] Target: %%TARGET%%
echo echo [INFO] Machine: %%MACHINE%%
echo echo.
echo.
echo REM Check for Administrator privileges
echo net session ^>nul 2^>^&1
echo if errorlevel 1 ^(
echo     echo [WARN] Not running as Administrator - USB device access may fail
echo     echo [INFO] If programming fails, try running as Administrator:
echo     echo [INFO]   Right-click Command Prompt -^> 'Run as Administrator'
echo     echo.
echo     set /p "continue=Continue anyway? ^(y/N^): "
echo     if /i not "%%continue%%"=="y" ^(
echo         echo [INFO] Exiting. Run as Administrator for reliable USB access.
echo         exit /b 1
echo     ^)
echo ^)
echo.
echo REM Check for UUU tool
echo set "UUU_CMD="
echo if exist "%%SCRIPT_DIR%%mfgtool-files-%%MACHINE%%\uuu.exe" ^(
echo     set "UUU_CMD=%%SCRIPT_DIR%%mfgtool-files-%%MACHINE%%\uuu.exe"
echo     echo [INFO] Using extracted MFGTools UUU tool
echo ^) else if exist "%%SCRIPT_DIR%%mfgtool-files\uuu.exe" ^(
echo     set "UUU_CMD=%%SCRIPT_DIR%%mfgtool-files\uuu.exe"
echo     echo [INFO] Using extracted MFGTools UUU tool
echo ^) else ^(
echo     uuu --help ^>nul 2^>^&1
echo     if not errorlevel 1 ^(
echo         set "UUU_CMD=uuu"
echo         echo [INFO] Using system UUU tool
echo     ^) else ^(
echo         echo [ERROR] UUU tool not found. Install UUU or use programming package with included UUU.
echo         exit /b 1
echo     ^)
echo ^)
echo.
echo if "%%FLASH_MODE%%"=="1" ^(
echo     call :program_full_image
echo ^) else ^(
echo     call :program_bootloader
echo ^)
echo exit /b %%errorlevel%%
echo.
echo :program_full_image
echo echo [INFO] Programming complete image for %%MACHINE%%...
echo.
echo REM Check for UUU script
echo set "UUU_SCRIPT="
echo if exist "%%SCRIPT_DIR%%mfgtool-files-%%MACHINE%%\full_image.uuu" ^(
echo     set "UUU_SCRIPT=%%SCRIPT_DIR%%mfgtool-files-%%MACHINE%%\full_image.uuu"
echo ^) else if exist "%%SCRIPT_DIR%%mfgtool-files\full_image.uuu" ^(
echo     set "UUU_SCRIPT=%%SCRIPT_DIR%%mfgtool-files\full_image.uuu"
echo ^) else ^(
echo     echo [ERROR] MFGTools full_image.uuu not found
echo     exit /b 1
echo ^)
echo.
echo echo [INFO] Using MFGTools full_image.uuu script: %%UUU_SCRIPT%%
echo echo [INFO] Starting UUU programming with MFGTools script...
echo.
echo "%%UUU_CMD%%" "%%UUU_SCRIPT%%"
echo if errorlevel 1 ^(
echo     echo [ERROR] Programming failed
echo     exit /b 1
echo ^)
echo.
echo echo [SUCCESS] Programming completed successfully!
echo echo [INFO] Set board to normal boot mode and power cycle
echo exit /b 0
echo.
echo :program_bootloader
echo echo [INFO] Programming bootloader only for %%MACHINE%%...
echo.
echo REM Check for UUU script
echo set "UUU_SCRIPT="
echo if exist "%%SCRIPT_DIR%%mfgtool-files-%%MACHINE%%\bootloader.uuu" ^(
echo     set "UUU_SCRIPT=%%SCRIPT_DIR%%mfgtool-files-%%MACHINE%%\bootloader.uuu"
echo ^) else if exist "%%SCRIPT_DIR%%mfgtool-files\bootloader.uuu" ^(
echo     set "UUU_SCRIPT=%%SCRIPT_DIR%%mfgtool-files\bootloader.uuu"
echo ^) else ^(
echo     echo [ERROR] MFGTools bootloader.uuu not found
echo     exit /b 1
echo ^)
echo.
echo echo [INFO] Using MFGTools bootloader.uuu script: %%UUU_SCRIPT%%
echo echo [INFO] Starting UUU bootloader programming with MFGTools script...
echo.
echo "%%UUU_CMD%%" "%%UUU_SCRIPT%%"
echo if errorlevel 1 ^(
echo     echo [ERROR] Bootloader programming failed
echo     exit /b 1
echo ^)
echo.
echo echo [SUCCESS] Bootloader programming completed successfully!
echo echo [INFO] Set board to normal boot mode and power cycle
echo exit /b 0
echo.
echo :show_usage
echo echo Usage: %%~nx0 [/flash] [/bootloader]
echo echo.
echo echo Program %machine% board with Target %target% artifacts.
echo echo.
echo echo Options:
echo echo   /flash        Program complete image ^(bootloader + filesystem^) [default]
echo echo   /bootloader   Program bootloader only
echo echo   /help         Show this help message
echo echo.
echo echo Prerequisites:
echo echo   1. Board in download/recovery mode
echo echo   2. USB cable connected
echo echo   3. UUU tool available in PATH or use included version
echo echo   4. Run as Administrator for USB device access
echo echo.
echo exit /b 0
) > "%script_path%"

exit /b 0

:single_programming
set "output_dir=%~1"
set "machine=%~2"

call :log_info "Auto-programming requested - starting board programming..."
call :log_warning "Make sure your board is in download/recovery mode and USB is connected"

call :log_info "Starting programming process..."
call :start_timer
call "%output_dir%\program-%machine%.bat" /flash
if errorlevel 1 (
    call :log_error "Board programming failed"
    exit /b 1
)
call :end_timer
call :format_duration %timer_duration%
call :log_success "Board programming completed successfully! (took !formatted_duration!)"
call :log_info "Set board to normal boot mode and power cycle"
exit /b 0

:continuous_programming
set "output_dir=%~1"
set "machine=%~2"

call :log_info "Continuous programming mode - programming boards in sequence"
call :log_warning "Make sure each board is in download/recovery mode before connecting USB"

set "board_count=1"
:continuous_loop
echo.
call :log_info "=== Programming Board #%board_count% ==="
call :log_info "1. Set board to download/recovery mode"
call :log_info "2. Connect USB cable"
call :log_info "3. Programming will start automatically..."

call :start_timer
call "%output_dir%\program-%machine%.bat" /flash
if errorlevel 1 (
    call :log_error "Board #%board_count% programming failed"
    set /p "continue=Continue with next board? (y/N): "
    if /i not "!continue!"=="y" exit /b 1
) else (
    call :end_timer
    call :format_duration %timer_duration%
    call :log_success "Board #%board_count% programming completed! (took !formatted_duration!)"
    call :log_info "Set board to normal boot mode and power cycle"
    set /a "board_count+=1"
    echo.
    set /p "continue=Program another board? (y/N): "
    if /i not "!continue!"=="y" (
        set /a "total_boards=%board_count%-1"
        call :log_info "Continuous programming completed. Total boards programmed: !total_boards!"
        exit /b 0
    )
)
goto continuous_loop

:install_fioctl_from_github
call :log_info "Downloading fioctl from GitHub releases..."
call :log_info "Source: https://github.com/foundriesio/fioctl/releases"

REM Create tools directory
if not exist "C:\tools\fioctl" mkdir "C:\tools\fioctl"

REM Download the latest fioctl release for Windows
call :log_info "Downloading latest fioctl-windows-amd64.exe..."
powershell -Command "& {[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; try { Invoke-WebRequest -Uri 'https://github.com/foundriesio/fioctl/releases/latest/download/fioctl-windows-amd64.exe' -OutFile 'C:\tools\fioctl\fioctl.exe' -UseBasicParsing; Write-Host 'Download completed successfully' } catch { Write-Host 'Download failed:' $_.Exception.Message; exit 1 }}"

if errorlevel 1 (
    call :log_error "Failed to download fioctl from GitHub releases"
    call :log_info "Please try:"
    call :log_info "  1. Check your internet connection"
    call :log_info "  2. Visit https://github.com/foundriesio/fioctl/releases manually"
    call :log_info "  3. Download fioctl-windows-amd64.exe to C:\tools\fioctl\fioctl.exe"
    exit /b 1
)

if exist "C:\tools\fioctl\fioctl.exe" (
    REM Verify the download worked by checking file size
    for %%f in ("C:\tools\fioctl\fioctl.exe") do (
        if %%~zf lss 1000000 (
            call :log_error "Downloaded file is too small (%%~zf bytes) - download may have failed"
            del "C:\tools\fioctl\fioctl.exe"
            exit /b 1
        )
    )
    
    call :log_success "fioctl downloaded successfully to C:\tools\fioctl\fioctl.exe"
    
    REM Add to PATH for current session
    set "PATH=C:\tools\fioctl;%PATH%"
    
    REM Try to add to user PATH permanently
    call :log_info "Adding C:\tools\fioctl to user PATH..."
    powershell -Command "& {try { $userPath = [Environment]::GetEnvironmentVariable('Path', 'User'); if ($userPath -notlike '*C:\tools\fioctl*') { [Environment]::SetEnvironmentVariable('Path', $userPath + ';C:\tools\fioctl', 'User'); Write-Host 'PATH updated successfully' } else { Write-Host 'PATH already contains fioctl directory' } } catch { Write-Host 'Failed to update PATH:' $_.Exception.Message; exit 1 }}"
    
    if not errorlevel 1 (
        call :log_success "Added C:\tools\fioctl to user PATH"
        call :log_info "fioctl will be available in new Command Prompt windows"
    ) else (
        call :log_warning "Could not automatically update PATH"
        call :log_info "Please manually add C:\tools\fioctl to your PATH environment variable"
    )
    
    REM Test the installation
    call :log_info "Testing fioctl installation..."
    "C:\tools\fioctl\fioctl.exe" version >nul 2>&1
    if not errorlevel 1 (
        call :log_success "fioctl installation verified successfully"
    ) else (
        call :log_warning "fioctl downloaded but may not be working correctly"
    )
    
    exit /b 0
) else (
    call :log_error "Download failed - fioctl.exe not found after download"
    exit /b 1
)

:show_manual_install_instructions
call :log_info "Manual Installation Instructions:"
echo.
call :log_info "fioctl (Required) - Install from GitHub Releases:"
call :log_info "  1. Visit: https://github.com/foundriesio/fioctl/releases"
call :log_info "  2. Download the latest 'fioctl-windows-amd64.exe'"
call :log_info "  3. Create directory: C:\tools\fioctl"
call :log_info "  4. Save the file as: C:\tools\fioctl\fioctl.exe"
call :log_info "  5. Add C:\tools\fioctl to your PATH environment variable"
echo.
call :log_info "Quick PATH setup:"
call :log_info "  1. Press Win+R, type 'sysdm.cpl', press Enter"
call :log_info "  2. Click 'Environment Variables'"
call :log_info "  3. Under 'User variables', select 'Path', click 'Edit'"
call :log_info "  4. Click 'New', add: C:\tools\fioctl"
call :log_info "  5. Click OK to save"
echo.
if defined need_extraction (
    call :log_info "Archive Extraction Tool (Required - choose one):"
    call :log_info "  Option 1: 7-Zip - Download from https://www.7-zip.org/"
    call :log_info "  Option 2: Git for Windows - Includes tar command"
    echo.
)
call :log_info "After installation:"
call :log_info "  1. Open a new Command Prompt"
call :log_info "  2. Run: fioctl login"
call :log_info "  3. Follow the authentication prompts"
call :log_info "  4. Run this script again"
echo.
call :log_info "For more help, visit: https://docs.foundries.io/latest/getting-started/install-fioctl/"
exit /b 0
