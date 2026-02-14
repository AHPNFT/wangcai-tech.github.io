# Screen Automation Script
# For automatic screen recognition and mouse control

# Import required assemblies
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Global variables
$global:screenWidth = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds.Width
$global:screenHeight = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds.Height
$global:mouseSpeed = 1  # Mouse movement speed (1-10)

# Function: Capture screen screenshot
function Capture-Screen {
    param(
        [string]$outputPath = "C:\Users\Administrator\.openclaw\workspace\screenshot.png"
    )
    
    try {
        # Create bitmap object
        $bitmap = New-Object System.Drawing.Bitmap $screenWidth, $screenHeight
        $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
        
        # Capture screen
        $graphics.CopyFromScreen(0, 0, 0, 0, $bitmap.Size)
        
        # Save screenshot
        $bitmap.Save($outputPath, [System.Drawing.Imaging.ImageFormat]::Png)
        
        # Clean up resources
        $graphics.Dispose()
        $bitmap.Dispose()
        
        Write-Host "Screenshot saved to: $outputPath" -ForegroundColor Green
        return $outputPath
    }
    catch {
        Write-Host "Error capturing screen: $_" -ForegroundColor Red
        return $null
    }
}

# Function: Move mouse to specified position
function Move-MouseTo {
    param(
        [int]$x,
        [int]$y,
        [int]$duration = 100  # Movement duration in milliseconds
    )
    
    try {
        # Get current mouse position
        $currentPos = [System.Windows.Forms.Cursor]::Position
        
        # Calculate movement steps
        $steps = [math]::Max(10, [math]::Ceiling($duration / 10))
        $stepX = ($x - $currentPos.X) / $steps
        $stepY = ($y - $currentPos.Y) / $steps
        
        # Smooth mouse movement
        for ($i = 1; $i -le $steps; $i++) {
            $newX = [math]::Round($currentPos.X + ($stepX * $i))
            $newY = [math]::Round($currentPos.Y + ($stepY * $i))
            [System.Windows.Forms.Cursor]::Position = New-Object System.Drawing.Point($newX, $newY)
            Start-Sleep -Milliseconds ($duration / $steps)
        }
        
        Write-Host "Mouse moved to position: ($x, $y)" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "Error moving mouse: $_" -ForegroundColor Red
        return $false
    }
}

# Function: Click mouse
function Click-Mouse {
    param(
        [string]$button = "left",  # left, right, middle
        [int]$x = -1,
        [int]$y = -1,
        [int]$clicks = 1
    )
    
    try {
        # Move mouse first if needed
        if ($x -ne -1 -and $y -ne -1) {
            Move-MouseTo -x $x -y $y
        }
        
        # Import Windows API
        Add-Type @"
            using System;
            using System.Runtime.InteropServices;
            public class MouseClick {
                [DllImport("user32.dll", CharSet=CharSet.Auto, CallingConvention=CallingConvention.StdCall)]
                public static extern void mouse_event(uint dwFlags, uint dx, uint dy, uint cButtons, uint dwExtraInfo);
                
                private const uint MOUSEEVENTF_LEFTDOWN = 0x02;
                private const uint MOUSEEVENTF_LEFTUP = 0x04;
                private const uint MOUSEEVENTF_RIGHTDOWN = 0x08;
                private const uint MOUSEEVENTF_RIGHTUP = 0x10;
                private const uint MOUSEEVENTF_MIDDLEDOWN = 0x20;
                private const uint MOUSEEVENTF_MIDDLEUP = 0x40;
                
                public static void Click(string button, int clicks) {
                    uint downFlag = 0;
                    uint upFlag = 0;
                    
                    switch(button.ToLower()) {
                        case "left":
                            downFlag = MOUSEEVENTF_LEFTDOWN;
                            upFlag = MOUSEEVENTF_LEFTUP;
                            break;
                        case "right":
                            downFlag = MOUSEEVENTF_RIGHTDOWN;
                            upFlag = MOUSEEVENTF_RIGHTUP;
                            break;
                        case "middle":
                            downFlag = MOUSEEVENTF_MIDDLEDOWN;
                            upFlag = MOUSEEVENTF_MIDDLEUP;
                            break;
                    }
                    
                    for(int i = 0; i < clicks; i++) {
                        mouse_event(downFlag, 0, 0, 0, 0);
                        mouse_event(upFlag, 0, 0, 0, 0);
                        System.Threading.Thread.Sleep(50);
                    }
                }
            }
"@
        
        # Execute click
        [MouseClick]::Click($button, $clicks)
        
        Write-Host "Mouse click completed: $button button, $clicks times" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "Error clicking mouse: $_" -ForegroundColor Red
        return $false
    }
}

# Function: Type text
function Type-Text {
    param(
        [string]$text,
        [int]$delay = 50  # Delay between characters in milliseconds
    )
    
    try {
        Add-Type -AssemblyName System.Windows.Forms
        
        foreach ($char in $text.ToCharArray()) {
            [System.Windows.Forms.SendKeys]::SendWait($char)
            Start-Sleep -Milliseconds $delay
        }
        
        Write-Host "Text typed: $text" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "Error typing text: $_" -ForegroundColor Red
        return $false
    }
}

# Function: Find color on screen
function Find-ColorOnScreen {
    param(
        [string]$colorHex,  # Format: "#RRGGBB"
        [int]$tolerance = 10  # Color tolerance
    )
    
    try {
        # Capture screen
        $screenshotPath = Capture-Screen
        if (-not $screenshotPath) { return $null }
        
        # Load image
        $bitmap = [System.Drawing.Bitmap]::FromFile($screenshotPath)
        
        # Parse color
        $targetColor = [System.Drawing.ColorTranslator]::FromHtml($colorHex)
        
        # Search for color
        $foundPoints = @()
        for ($x = 0; $x -lt $bitmap.Width; $x += 5) {  # Sample every 5 pixels
            for ($y = 0; $y -lt $bitmap.Height; $y += 5) {
                $pixelColor = $bitmap.GetPixel($x, $y)
                
                # Calculate color difference
                $diff = [math]::Abs($pixelColor.R - $targetColor.R) +
                        [math]::Abs($pixelColor.G - $targetColor.G) +
                        [math]::Abs($pixelColor.B - $targetColor.B)
                
                if ($diff -le $tolerance) {
                    $foundPoints += @{X = $x; Y = $y}
                }
            }
        }
        
        $bitmap.Dispose()
        
        if ($foundPoints.Count -gt 0) {
            Write-Host "Found color $colorHex at: $($foundPoints.Count) points" -ForegroundColor Green
            return $foundPoints
        }
        else {
            Write-Host "Color $colorHex not found" -ForegroundColor Yellow
            return $null
        }
    }
    catch {
        Write-Host "Error finding color: $_" -ForegroundColor Red
        return $null
    }
}

# Function: Simple test - capture and move
function Test-BasicFunctions {
    Write-Host "Testing basic functions..." -ForegroundColor Cyan
    
    # Test 1: Capture screen
    Write-Host "1. Capturing screen..." -ForegroundColor Yellow
    $screenshot = Capture-Screen
    
    # Test 2: Move mouse
    Write-Host "2. Moving mouse..." -ForegroundColor Yellow
    Move-MouseTo -x 100 -y 100
    Start-Sleep -Milliseconds 500
    Move-MouseTo -x 200 -y 200
    
    # Test 3: Click mouse
    Write-Host "3. Clicking mouse..." -ForegroundColor Yellow
    Click-Mouse -x 300 -y 300
    
    # Test 4: Type text
    Write-Host "4. Typing text..." -ForegroundColor Yellow
    Type-Text -text "Test" -delay 30
    
    Write-Host "All tests completed!" -ForegroundColor Green
}

# Function: Auto GitHub push
function Auto-GitHubPush {
    Write-Host "Starting auto GitHub push..." -ForegroundColor Cyan
    
    # 1. Open command prompt or PowerShell
    [System.Windows.Forms.SendKeys]::SendWait("^{ESC}")  # Win key
    Start-Sleep -Milliseconds 500
    Type-Text -text "powershell" -delay 100
    Start-Sleep -Milliseconds 500
    [System.Windows.Forms.SendKeys]::SendWait("{ENTER}")
    Start-Sleep -Seconds 2
    
    # 2. Navigate to workspace
    Type-Text -text "cd 'C:\Users\Administrator\.openclaw\workspace'" -delay 50
    [System.Windows.Forms.SendKeys]::SendWait("{ENTER}")
    Start-Sleep -Milliseconds 500
    
    # 3. Execute Git push command
    Type-Text -text "git push -u origin main" -delay 50
    [System.Windows.Forms.SendKeys]::SendWait("{ENTER}")
    
    Write-Host "GitHub push command executed" -ForegroundColor Green
}

# Main execution
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "      Screen Automation Tool" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# Display screen info
Write-Host "Screen Resolution: $screenWidth x $screenHeight" -ForegroundColor Yellow
Write-Host ""

# Ask user what to do
Write-Host "Options:" -ForegroundColor Yellow
Write-Host "1. Test basic functions" -ForegroundColor Green
Write-Host "2. Auto GitHub push" -ForegroundColor Green
Write-Host "3. Capture screenshot only" -ForegroundColor Green
Write-Host "4. Exit" -ForegroundColor Red
Write-Host ""

$choice = Read-Host "Enter choice (1-4)"

switch ($choice) {
    "1" {
        Test-BasicFunctions
    }
    "2" {
        Auto-GitHubPush
    }
    "3" {
        Capture-Screen
    }
    "4" {
        Write-Host "Exiting..." -ForegroundColor Cyan
        exit
    }
    default {
        Write-Host "Invalid choice" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Script completed" -ForegroundColor Green
Pause