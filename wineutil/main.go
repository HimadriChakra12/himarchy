package main

import (
	"bufio"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"time"

	"fyne.io/fyne/v2"
	"fyne.io/fyne/v2/app"
	"fyne.io/fyne/v2/container"
	"fyne.io/fyne/v2/layout"
	"fyne.io/fyne/v2/theme"
	"fyne.io/fyne/v2/widget"
)

// Stage represents each installation step
type Stage struct {
	Name     string
	Label    *widget.Label
	Status   string
	Selected *widget.Check
}

var stopChan chan struct{}

func main() {
	a := app.New()
	w := a.NewWindow("Winetimate - Wine Supercharger GUI")
	w.Resize(fyne.NewSize(1000, 600))

	// Channels for UI updates
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
		stages = append(stages, &Stage{Name: name, Label: label, Status: "pending", Selected: check})
		stageContainer.Add(check)
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
	progress.Min = 0
	progress.Max = 1

	// Buttons
	var startButton, fullButton, cancelButton *widget.Button
	startButton = widget.NewButtonWithIcon("Start Installation", theme.MediaPlayIcon(), func() {
		startButton.Disable()
		stopChan = make(chan struct{})
		go runInstallation(stages, fastInstall.Checked, autoDotnet.Checked, stopChan, stageUpdates, logsChan, progressChan, startButton)
	})

	fullButton = widget.NewButtonWithIcon("Full Install", theme.ContentAddIcon(), func() {
		for _, stage := range stages {
			stage.Selected.SetChecked(true)
		}
		startButton.Disable()
		stopChan = make(chan struct{})
		go runInstallation(stages, fastInstall.Checked, autoDotnet.Checked, stopChan, stageUpdates, logsChan, progressChan, startButton)
	})

	cancelButton = widget.NewButtonWithIcon("Cancel", theme.MediaStopIcon(), func() {
		if stopChan != nil {
			close(stopChan)
		}
	})

	buttons := container.NewHBox(startButton, fullButton, cancelButton)

	// Logs panel (below buttons)
	logs := widget.NewMultiLineEntry()
	logs.Wrapping = fyne.TextWrapWord
	logs.SetMinRowsVisible(150)
	logsScroll := container.NewVScroll(logs)

	// Profiles panel (dynamic)
	profilesBox := container.NewVBox(
		widget.NewLabelWithStyle("Profiles", fyne.TextAlignLeading, fyne.TextStyle{Bold: true}),
	)
	profilesDir := filepath.Join(os.Getenv("HOME"), "wine_profiles")
	if entries, err := os.ReadDir(profilesDir); err == nil {
		for _, entry := range entries {
			if entry.IsDir() {
				continue
			}
			profilePath := filepath.Join(profilesDir, entry.Name())
			btn := widget.NewButton(entry.Name(), func(path string) func() {
				return func() {
					go runProfile(path, logsChan)
				}
			}(profilePath))
			profilesBox.Add(btn)
		}
	} else {
		profilesBox.Add(widget.NewLabel("No profiles found in ~/wine_profiles"))
	}

	// Left sidebar for stages + options + buttons + logs
	leftPanel := container.NewVBox(
		widget.NewLabelWithStyle("Stages", fyne.TextAlignLeading, fyne.TextStyle{Bold: true}),
		stageContainer,
		widget.NewSeparator(),
		optionsBox,
		widget.NewSeparator(),
		buttons,
		widget.NewSeparator(),
		widget.NewLabelWithStyle("Logs:", fyne.TextAlignLeading, fyne.TextStyle{Bold: true}),
		logsScroll,
		widget.NewSeparator(),
		progress,
	)

	// Main layout: left panel + profiles panel
	mainContent := container.New(layout.NewHBoxLayout(),
		container.NewMax(leftPanel),
		container.NewMax(profilesBox),
	)

	// Add padding and title
	content := container.New(layout.NewVBoxLayout(),
		widget.NewLabelWithStyle("Winetimate - Wine Supercharger GUI", fyne.TextAlignCenter, fyne.TextStyle{Bold: true}),
		widget.NewSeparator(),
		mainContent,
	)

	// UI update goroutine
	go func() {
		for {
			select {
			case update := <-stageUpdates:
				update.stage.Label.SetText(update.text)
				update.stage.Label.Refresh()
			case log := <-logsChan:
				logs.SetText(logs.Text + log + "\n")
				logs.Refresh()
				logsScroll.ScrollToBottom()
			case prog := <-progressChan:
				progress.SetValue(prog)
			}
		}
	}()

	w.SetContent(content)
	w.ShowAndRun()
}

// runInstallation executes winetimate stages in background safely
func runInstallation(stages []*Stage, fast, dotnet bool, stopChan chan struct{},
	stageUpdates chan struct{ stage *Stage; text string },
	logsChan chan string,
	progressChan chan float64,
	startButton *widget.Button) {

	total := 0
	for _, stage := range stages {
		if stage.Selected.Checked {
			total++
		}
	}

	if total == 0 {
		logsChan <- "⚠ No stages selected"
		startButton.Enable()
		return
	}

	done := 0
	for _, stage := range stages {
		if !stage.Selected.Checked {
			continue
		}

		select {
		case <-stopChan:
			logsChan <- "❌ Installation cancelled by user."
			startButton.Enable()
			return
		default:
		}

		stageUpdates <- struct{ stage *Stage; text string }{stage, "⏳ " + stage.Name}
		logsChan <- "➡ " + stage.Name

		err := runStage(stage.Name, fast, dotnet)
		if err != nil {
			stageUpdates <- struct{ stage *Stage; text string }{stage, "❌ " + stage.Name}
			stage.Status = "error"
			logsChan <- fmt.Sprintf("❌ Stage failed: %v", err)
		} else {
			stageUpdates <- struct{ stage *Stage; text string }{stage, "✅ " + stage.Name}
			stage.Status = "success"
		}

		done++
		progressChan <- float64(done) / float64(total)
		time.Sleep(200 * time.Millisecond)
	}

	logsChan <- "🎉 Wine Supercharger installation complete!"
	startButton.Enable()
}

// runStage executes the winetimate script with appropriate args
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

// runProfile executes a profile script and streams output to logsChan
func runProfile(path string, logsChan chan string) {
	cmd := exec.Command("bash", path)
	stdout, _ := cmd.StdoutPipe()
	stderr, _ := cmd.StderrPipe()
	if err := cmd.Start(); err != nil {
		logsChan <- fmt.Sprintf("❌ Failed to start profile %s: %v", path, err)
		return
	}

	scannerOut := bufio.NewScanner(stdout)
	scannerErr := bufio.NewScanner(stderr)

	go func() {
		for scannerOut.Scan() {
			logsChan <- scannerOut.Text()
		}
	}()

	go func() {
		for scannerErr.Scan() {
			logsChan <- scannerErr.Text()
		}
	}()

	cmd.Wait()
	logsChan <- fmt.Sprintf("✅ Profile %s finished", filepath.Base(path))
}
