package main

import (
	"encoding/json"
	"flag"
	"log"
	"net/http"
	"os"
	"os/exec"
	"sync"
	"time"
)

// main is in charge
func main() {
	if err := run(); err != nil {
		log.Fatal(err)
	}
}

// run does all the work
func run() error {
	var (
		httpAddr  = flag.String("http.addr", ":80", "HTTP addr to listen on")
		assetsDir = flag.String("assets.dir", "./public", "Directory to serve assets from")
		soundCmd  = flag.String("sound.cmd", "omxplayer ./public/alarm.mp3", "Command for playing alarm sound")
		logLevel  = flag.Int("log.level", 1, "0 = off, 1 = normal, 2 = debug")
	)
	flag.Parse()
	LogStart(os.Args, *logLevel)
	sound := NewCmdSound(*soundCmd)
	sound = LoggedSound(sound, *logLevel)
	clock := NewClock(sound)
	clock = LoggedClock(clock, *logLevel)
	handler := http.FileServer(http.Dir(*assetsDir))
	handler = NewAlarmHandler(clock, handler)
	handler = LoggedHandler(handler, *logLevel)
	return http.ListenAndServe(*httpAddr, handler)
}

// NewClock returns a new Clock that plays the given sound when the alarm goes
// off.
func NewClock(sound Sound) Clock {
	return &clock{sound: sound}
}

// Clock defines the capabilities of an alarm clock.
type Clock interface {
	// Get returns the Alarm that is currently set.
	Get() Alarm
	// Set sets the current alarm, returns time to alarm.
	Set(Alarm) time.Duration
}

// Alarm holds the settings that make up an alarm.
type Alarm struct {
	Hour    int  `json:"hour"`
	Minute  int  `json:"minute"`
	Zone    int  `json:"zone"`
	Enabled bool `json:"enabled"`
}

// clock implements the Clock interface.
type clock struct {
	lock  sync.Mutex
	sound Sound
	alarm Alarm
	timer *time.Timer
}

// Get is part of the Clock interface.
func (c *clock) Get() Alarm {
	c.lock.Lock()
	defer c.lock.Unlock()
	return c.alarm
}

// Set is part of the clock interface.
func (c *clock) Set(alarm Alarm) time.Duration {
	c.lock.Lock()
	defer c.lock.Unlock()
	// stop active alarm, if any
	if c.timer != nil {
		c.timer.Stop()
		c.timer = nil
	}
	// determine the time the alarm should go off
	now := time.Now()
	zone := time.FixedZone("", alarm.Zone)
	when := time.Date(now.Year(), now.Month(), now.Day(), alarm.Hour, alarm.Minute, 0, 0, zone)
	// if the time is in the past, this means the next day is meant
	if when.Before(now) {
		when = when.AddDate(0, 0, 1)
	}
	duration := when.Sub(now)
	// start new alarm, if needed
	if alarm.Enabled {
		c.timer = time.AfterFunc(duration, func() {
			for {
				c.sound.Play()
			}
		})
	}
	// update the alarm
	c.alarm = alarm
	return duration
}

// NewAlarmHandler returns a new http handler that allows setting/getting the
// alarm of the given clock at /alarm. Calls the next handler for any other
// path.
func NewAlarmHandler(clock Clock, next http.Handler) http.Handler {
	const prefix = "/alarm"
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Path != prefix {
			next.ServeHTTP(w, r)
			return
		}
		switch r.Method {
		case http.MethodPut:
			var alarm Alarm
			if err := json.NewDecoder(r.Body).Decode(&alarm); err != nil {
				http.Error(w, err.Error(), http.StatusBadRequest)
				return
			}
			clock.Set(alarm)
			w.Header().Set("Content-Type", "application/json")
			json.NewEncoder(w).Encode(alarm)
		case http.MethodGet:
			w.Header().Set("Content-Type", "application/json")
			json.NewEncoder(w).Encode(clock.Get())
		default:
			http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		}
	})
}

// Sound defines an alarm sound that can be played.
type Sound interface {
	// Play plays the alarm sound or returns an error.
	Play() error
}

// NewCmdSound returns a sound that is played by invoking the given shell cmd.
func NewCmdSound(cmd string) Sound {
	return cmdSound(cmd)
}

// cmdSound implements the Sound interface.
type cmdSound string

// Play is part of the Sound interface.
func (c cmdSound) Play() error {
	return exec.Command("/bin/sh", "-c", string(c)).Run()
}
