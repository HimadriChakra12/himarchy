package main

import (
    "bufio"
    "fmt"
    "image/color"
    "os"
    "os/exec"
    "path/filepath"
    "time"

    "fyne.io/fyne/v2"
    "fyne.io/fyne/v2/app"
    "fyne.io/fyne/v2/container"
    "fyne.io/fyne/v2/theme"
    "fyne.io/fyne/v2/widget"
)

//
// ---------------------
//   GRUVBOX THEME (IMPROVED)
// ---------------------
//

type GruvboxTheme struct{}

func (GruvboxTheme) Color(n fyne.ThemeColorName, v fyne.ThemeVariant) color.Color {
    // Gruvbox Dark palette
    dark0_hard  := color.RGBA{29, 32, 33, 255}    // #1d2021
    dark0       := color.RGBA{40, 40, 40, 255}    // #282828
    dark0_soft  := color.RGBA{50, 48, 47, 255}    // #32302f
    dark1       := color.RGBA{60, 56, 54, 255}    // #3c3836
    dark2       := color.RGBA{80, 73, 69, 255}    // #504945
    dark3       := color.RGBA{102, 92, 84, 255}   // #665c54
    dark4       := color.RGBA{124, 111, 100, 255} // #7c6f64
    
    light1      := color.RGBA{235, 219, 178, 255} // #ebdbb2
    // Accent colors
    red         := color.RGBA{204, 36, 29, 255}   // #cc241d
    yellow      := color.RGBA{215, 153, 33, 255}  // #d79921
    blue        := color.RGBA{69, 133, 136, 255}  // #458588
    gray        := color.RGBA{146, 131, 116, 255} // #928374

    switch n {
    case theme.ColorNameBackground:
        return dark0
    case theme.ColorNameButton:
        return dark1
    case theme.ColorNameDisabled:
        return dark3
    case theme.ColorNameDisabledButton:
        return dark2
    case theme.ColorNameError:
        return red
    case theme.ColorNameFocus:
        return yellow
    case theme.ColorNameForeground:
        return light1
    case theme.ColorNameHover:
        return dark2
    case theme.ColorNameInputBackground:
        return dark0_hard
    case theme.ColorNameInputBorder:
        return dark4
    case theme.ColorNameMenuBackground:
        return dark0_soft
    case theme.ColorNameOverlayBackground:
        return dark0_hard
    case theme.ColorNamePlaceHolder:
        return gray
    case theme.ColorNamePressed:
        return dark3
    case theme.ColorNamePrimary:
        return yellow
    case theme.ColorNameScrollBar:
        return dark2
    case theme.ColorNameSelection:
        return blue
    case theme.ColorNameShadow:
        return color.RGBA{0, 0, 0, 128}
    }

    return theme.DefaultTheme().Color(n, v)
}

func (GruvboxTheme) Font(s fyne.TextStyle) fyne.Resource {
    return theme.DefaultTheme().Font(s)
}

func (GruvboxTheme) Icon(n fyne.ThemeIconName) fyne.Resource {
    return theme.DefaultTheme().Icon(n)
}

func (GruvboxTheme) Size(n fyne.ThemeSizeName) float32 {
    switch n {
    case theme.SizeNamePadding:
        return 8
    case theme.SizeNameInlineIcon:
        return 20
    case theme.SizeNameScrollBar:
        return 16
    case theme.SizeNameScrollBarSmall:
        return 8
    case theme.SizeNameSeparatorThickness:
        return 2
    case theme.SizeNameText:
        return 14
    }
    return theme.DefaultTheme().Size(n)
}

//
// ---------------------------------------------------
//  GUI + INSTALLER LOGIC
// ---------------------------------------------------
//

type Stage struct {
    Name     string
    Label    *widget.Label
    Status   string
    Selected *widget.Check
}

var stopChan chan struct{}

func main() {
    a := app.New()
    a.Settings().SetTheme(&GruvboxTheme{})

    w := a.NewWindow("Winetimate - Wine Supercharger GUI")
    w.Resize(fyne.NewSize(1200, 800))

    // Channels
    stageUpdates := make(chan struct {
        stage *Stage
        text  string
    }, 100)
    logsChan := make(chan string, 100)
    progressChan := make(chan float64, 10)

    // Stage names
    stageNames := []string{
        "Install system dependencies",
        "Fix .desktop files",
        "Create WINEPREFIX",
        "Run core winetricks",
        "Install DXVK + VKD3D",
        "Optional dotnet48 installation",
        "Apply registry tweaks",
        "Fix services for RpcSs",
    }

    stages := make([]*Stage, 0, len(stageNames))
    stageContainer := container.NewVBox()

    for _, name := range stageNames {
        check := widget.NewCheck(name, nil)
        label := widget.NewLabel("⏳ " + name)
        stage := &Stage{Name: name, Label: label, Status: "pending", Selected: check}
        stages = append(stages, stage)
        stageContainer.Add(container.NewVBox(check))
    }

    // Options panel
    fastInstall := widget.NewCheck("Fast Installation (skip optional heavy steps)", nil)
    autoDotnet := widget.NewCheck("Install dotnet48 automatically", nil)

    optionsBox := container.NewVBox(
        widget.NewLabelWithStyle("Options", fyne.TextAlignLeading, fyne.TextStyle{Bold: true}),
        fastInstall,
        autoDotnet,
    )

    // Progress bar
    progress := widget.NewProgressBar()

    // Buttons
    var startButton, fullButton, cancelButton *widget.Button

    startButton = widget.NewButtonWithIcon("Start Installation", theme.MediaPlayIcon(), func() {
        startButton.Disable()
        stopChan = make(chan struct{})
        go runInstallation(stages, fastInstall.Checked, autoDotnet.Checked,
            stopChan, stageUpdates, logsChan, progressChan, startButton)
    })

    fullButton = widget.NewButtonWithIcon("Full Install", theme.ContentAddIcon(), func() {
        for _, s := range stages {
            s.Selected.SetChecked(true)
        }
        startButton.Disable()
        stopChan = make(chan struct{})
        go runInstallation(stages, fastInstall.Checked, autoDotnet.Checked,
            stopChan, stageUpdates, logsChan, progressChan, startButton)
    })

    cancelButton = widget.NewButtonWithIcon("Cancel", theme.MediaStopIcon(), func() {
        if stopChan != nil {
            close(stopChan)
        }
    })

    buttons := container.NewHBox(startButton, fullButton, cancelButton)

    // Logs
    logs := widget.NewMultiLineEntry()
    logs.Wrapping = fyne.TextWrapWord

    logsScroll := container.NewVScroll(logs)
    logsScroll.SetMinSize(fyne.NewSize(800, 120))

    clearLogs := widget.NewButtonWithIcon("Clear Logs", theme.DeleteIcon(), func() {
        logs.SetText("")
    })

    logsHeader := container.NewHBox(
        widget.NewLabelWithStyle("Installation Logs", fyne.TextAlignLeading, fyne.TextStyle{Bold: true}),
        clearLogs,
    )

    // Layout with margins
    left := container.NewVBox(
        widget.NewLabelWithStyle("Stages", fyne.TextAlignLeading, fyne.TextStyle{Bold: true}),
        stageContainer,
        container.NewVBox(optionsBox),
        buttons,
        progress,
    )

    paddedLeft := container.NewPadded(left)

    // Profiles
    profilesBox := container.NewVBox(
        widget.NewLabelWithStyle("Profiles", fyne.TextAlignLeading, fyne.TextStyle{Bold: true}),
    )
    profilesDir := filepath.Join(os.Getenv("HOME"), "wineutil/scripts")
    if entries, err := os.ReadDir(profilesDir); err == nil {
        for _, e := range entries {
            if e.IsDir() {
                continue
            }
            full := filepath.Join(profilesDir, e.Name())
            btn := widget.NewButton(e.Name(), func(p string) func() {
                return func() { go runProfile(p, logsChan) }
            }(full))
            profilesBox.Add(btn)
        }
    } else {
        profilesBox.Add(widget.NewLabel("No profiles found"))
    }

    paddedRight := container.NewPadded(profilesBox)

    // Top split
    top := container.NewHSplit(paddedLeft, paddedRight)
    top.SetOffset(0.70)

    // Whole app split with logs
    mainSplit := container.NewVSplit(
        top,
        container.NewBorder(logsHeader, nil, nil, nil, logsScroll),
    )
    mainSplit.SetOffset(0.62)

    w.SetContent(container.NewPadded(mainSplit))

    //
    // UI Update Goroutine
    //
    go func() {
        for {
            select {
            case update := <-stageUpdates:
                update.stage.Label.SetText(update.text)
                update.stage.Label.Refresh()

            case l := <-logsChan:
                logs.SetText(logs.Text + l + "\n")
                logs.Refresh()
                logsScroll.ScrollToBottom()

            case p := <-progressChan:
                progress.SetValue(p)
            }
        }
    }()

    w.ShowAndRun()
}

//
// Exec Logic
//

func runInstallation(
    stages []*Stage,
    fast, dotnet bool,
    stopChan chan struct{},
    stageUpdates chan struct{ stage *Stage; text string },
    logsChan chan string,
    progressChan chan float64,
    startButton *widget.Button,
) {
    total := 0
    for _, s := range stages {
        if s.Selected.Checked {
            total++
        }
    }
    if total == 0 {
        logsChan <- "⚠ No stages selected"
        startButton.Enable()
        return
    }

    done := 0
    for _, s := range stages {
        if !s.Selected.Checked {
            continue
        }

        select {
        case <-stopChan:
            logsChan <- "❌ Cancelled by user"
            startButton.Enable()
            return
        default:
        }

        stageUpdates <- struct{ stage *Stage; text string }{s, "⏳ " + s.Name}
        logsChan <- "➡ " + s.Name

        err := runStage(s.Name, fast, dotnet)
        if err != nil {
            stageUpdates <- struct{ stage *Stage; text string }{s, "❌ " + s.Name}
            s.Status = "error"
            logsChan <- fmt.Sprintf("❌ Stage failed: %v", err)
        } else {
            stageUpdates <- struct{ stage *Stage; text string }{s, "✅ " + s.Name}
            s.Status = "success"
        }

        done++
        progressChan <- float64(done) / float64(total)
        time.Sleep(200 * time.Millisecond)
    }

    logsChan <- "🎉 Installation complete!"
    startButton.Enable()
}

func runStage(name string, fast, dotnet bool) error {
    script := "./winetimate.sh"
    args := []string{}

    switch name {
    case "Install system dependencies":
        args = []string{"--no-deps"}

    case "Optional dotnet48 installation":
        if !dotnet || fast {
            return nil
        }
    }

    cmd := exec.Command("bash", append([]string{script}, args...)...)
    cmd.Env = os.Environ()

    return cmd.Run()
}

func runProfile(path string, logsChan chan string) {
    cmd := exec.Command("bash", path)
    stdout, _ := cmd.StdoutPipe()
    stderr, _ := cmd.StderrPipe()

    if err := cmd.Start(); err != nil {
        logsChan <- fmt.Sprintf("❌ Failed to run profile %s: %v", path, err)
        return
    }

    go func() {
        s := bufio.NewScanner(stdout)
        for s.Scan() {
            logsChan <- s.Text()
        }
    }()
    go func() {
        s := bufio.NewScanner(stderr)
        for s.Scan() {
            logsChan <- s.Text()
        }
    }()

    cmd.Wait()
    logsChan <- fmt.Sprintf("✅ Profile %s finished", filepath.Base(path))
}
