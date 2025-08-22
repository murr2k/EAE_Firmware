#!/bin/bash
# Script to copy MATLAB project to Windows MATLAB Drive via WSL mount

# Windows path through WSL mount
MATLAB_DRIVE="/mnt/c/Users/murr2/MATLAB Drive"
PROJECT_NAME="EAE_ThermalControl"
SOURCE_DIR="matlab_project/EAE_ThermalControl"

echo "========================================="
echo "  Copying MATLAB Project to Windows"
echo "========================================="

# Check if source exists
if [ ! -d "$SOURCE_DIR" ]; then
    echo "❌ Error: Source directory $SOURCE_DIR not found"
    echo "Please run this script from the eae-firmware directory"
    exit 1
fi

# Check if WSL mount exists
if [ ! -d "/mnt/c" ]; then
    echo "❌ Error: WSL mount /mnt/c not found"
    echo "This script must be run from WSL (Windows Subsystem for Linux)"
    exit 1
fi

# Check if MATLAB Drive exists
if [ ! -d "$MATLAB_DRIVE" ]; then
    echo "⚠️  Warning: MATLAB Drive not found at expected location"
    echo "Expected: $MATLAB_DRIVE"
    echo ""
    echo "Alternative locations to try:"
    echo "1. /mnt/c/Users/murr2/OneDrive/Documents/MATLAB"
    echo "2. /mnt/c/Users/murr2/Documents/MATLAB"
    echo ""
    read -p "Enter the correct path to your MATLAB folder (or press Enter to create at default): " CUSTOM_PATH
    
    if [ -n "$CUSTOM_PATH" ]; then
        MATLAB_DRIVE="$CUSTOM_PATH"
    else
        # Try to create the directory
        echo "Creating directory: $MATLAB_DRIVE"
        mkdir -p "$MATLAB_DRIVE"
    fi
fi

# Create destination directory
DEST_DIR="$MATLAB_DRIVE/$PROJECT_NAME"
echo ""
echo "📁 Source: $SOURCE_DIR"
echo "📁 Destination: $DEST_DIR"
echo ""

# Ask for confirmation
read -p "Copy MATLAB project to Windows? (y/n): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    # Create destination if it doesn't exist
    mkdir -p "$DEST_DIR"
    
    # Copy all files
    echo "Copying files..."
    cp -r "$SOURCE_DIR"/* "$DEST_DIR/"
    
    # Check if copy was successful
    if [ $? -eq 0 ]; then
        echo "✅ Successfully copied to: $DEST_DIR"
        echo ""
        echo "Next steps:"
        echo "1. Open MATLAB"
        echo "2. Navigate to: $PROJECT_NAME"
        echo "3. Run: startup"
        echo "4. Run: thermal_system_analysis"
    else
        echo "❌ Error occurred during copy"
        exit 1
    fi
else
    echo "Copy cancelled"
    exit 0
fi

echo ""
echo "========================================="
echo "Optional: Create Windows shortcut"
echo "========================================="
echo "You can also access the files from Windows Explorer at:"
echo "C:\\Users\\murr2\\MATLAB Drive\\$PROJECT_NAME"

# Optional: Create a Windows .bat file to open MATLAB in the right directory
BAT_FILE="$DEST_DIR/open_project.bat"
cat > "$BAT_FILE" << 'EOF'
@echo off
echo Starting MATLAB with EAE Thermal Control Project...
cd /d "%~dp0"
matlab -sd "%~dp0" -r "startup"
EOF

echo ""
echo "✅ Created open_project.bat to quickly start MATLAB with this project"