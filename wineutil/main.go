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
	w.Resize(fyne.NewSize(1200, 800)) // Increased window size for better layout

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

	// Logs panel - now as a bottom pane
	logs := widget.NewMultiLineEntry()
	logs.Wrapping = fyne.TextWrapWord
	logs.SetMinRowsVisible(15) // Increased visible rows
	logsScroll := container.NewVScroll(logs)
	logsScroll.SetMinSize(fyne.NewSize(800, 100)) // Larger minimum size for logs

	// Logs header with clear button
	clearLogsButton := widget.NewButtonWithIcon("Clear Logs", theme.DeleteIcon(), func() {
		logs.SetText("")
	})
	logsHeader := container.NewHBox(
		widget.NewLabelWithStyle("Installation Logs", fyne.TextAlignLeading, fyne.TextStyle{Bold: true}),
		layout.NewSpacer(),
		clearLogsButton,
	)

	// Main content area (stages + options + profiles)
	mainContent := container.NewVBox(
		widget.NewLabelWithStyle("Stages", fyne.TextAlignLeading, fyne.TextStyle{Bold: true}),
		stageContainer,
		optionsBox,
		buttons,
		progress,
	)

	// Profiles panel
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

	// Left panel with main content
	leftPanel := container.NewVBox(mainContent)

	// Right panel with profiles
	rightPanel := container.NewVBox(profilesBox)

	// Top content area (stages + profiles)
	topContent := container.New(layout.NewHBoxLayout(),
		container.NewMax(leftPanel),
		container.NewMax(rightPanel),
	)

	// Logs pane at the bottom
	logsPane := container.NewBorder(
		logsHeader,
		nil,
		nil,
		nil,
		logsScroll,
	)

	// Main layout using Border to pin logs to bottom
	content := container.NewBorder(
		container.NewVBox(
			widget.NewLabelWithStyle("Winetimate - Wine Supercharger GUI", fyne.TextAlignCenter, fyne.TextStyle{Bold: true}),
			widget.NewSeparator(),
		),
		nil,
		nil,
		nil,
		container.NewVSplit(
			topContent,
			logsPane,
		),
	)

	// Set the split position to give more space to logs
	content.Objects[0].(*container.Split).SetOffset(0.6) // 60% top, 40% bottom logs

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
