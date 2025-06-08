/**
 * TR-808 Drum Machine Application
 * Connects the HTML interface to the TR-808 audio synthesis engine
 */

class TR808App {
    constructor() {
        this.tr808 = new TR808();
        this.currentInstrument = 'BD';
        this.isPlaying = false;
        this.tempo = 120;
        this.currentStep = 0;
        this.sequenceInterval = null;
        
        this.pattern = {};
        this.initializePattern();
        this.bindEvents();
        this.updateDisplay();
    }

    initializePattern() {
        const instruments = ['BD', 'SD', 'LC', 'LT', 'MC', 'MT', 'HC', 'HT', 'CL', 'RS', 'MA', 'CP', 'CB', 'CY', 'OH', 'CH'];
        instruments.forEach(instrument => {
            this.pattern[instrument] = new Array(16).fill(false);
        });
    }

    bindEvents() {
        this.bindInstrumentControls();
        this.bindStepSequencer();
        this.bindMasterControls();
        this.bindTransportControls();
    }

    bindInstrumentControls() {
        document.querySelectorAll('.instrument-group').forEach(group => {
            const instrument = group.dataset.instrument;
            
            group.addEventListener('click', (e) => {
                if (e.target === group || e.target.tagName === 'LABEL') {
                    this.currentInstrument = instrument;
                    this.playInstrument(instrument);
                    this.updateDisplay();
                }
            });

            group.querySelectorAll('input[type="range"]').forEach(control => {
                control.addEventListener('input', () => {
                    this.updateInstrumentControls();
                });
            });
        });
    }

    bindStepSequencer() {
        document.querySelectorAll('.step-button').forEach(button => {
            button.addEventListener('click', () => {
                const step = parseInt(button.dataset.step) - 1;
                this.toggleStep(this.currentInstrument, step);
                this.updateDisplay();
            });
        });
    }

    bindMasterControls() {
        const tempoControl = document.querySelector('.tempo-control');
        if (tempoControl) {
            tempoControl.addEventListener('input', (e) => {
                this.tempo = parseInt(e.target.value);
                if (this.isPlaying) {
                    this.stopSequence();
                    this.startSequence();
                }
            });
        }

        const masterVolumeControl = document.querySelector('.master-volume');
        if (masterVolumeControl) {
            masterVolumeControl.addEventListener('input', (e) => {
                this.tr808.setMasterVolume(parseInt(e.target.value));
            });
        }

        const accentControl = document.querySelector('.accent-control');
        if (accentControl) {
            accentControl.addEventListener('input', (e) => {
                this.tr808.setAccent(parseInt(e.target.value));
            });
        }
    }

    bindTransportControls() {
        const startStopButton = document.querySelector('.start-stop');
        if (startStopButton) {
            startStopButton.addEventListener('click', () => {
                this.togglePlayback();
            });
        }

        const tapButton = document.querySelector('.tap-button');
        if (tapButton) {
            tapButton.addEventListener('click', () => {
                this.playInstrument(this.currentInstrument);
            });
        }

        const clearButton = document.querySelector('.clear-button');
        if (clearButton) {
            clearButton.addEventListener('click', () => {
                this.clearPattern();
            });
        }
    }

    playInstrument(instrumentName, withAccent = false) {
        const params = this.getInstrumentParams(instrumentName);
        this.tr808.playInstrument(instrumentName, params, withAccent);
    }

    getInstrumentParams(instrumentName) {
        const group = document.querySelector(`[data-instrument="${instrumentName}"]`);
        if (!group) return {};

        const params = {};
        group.querySelectorAll('input[type="range"]').forEach(control => {
            const controlType = control.dataset.control;
            if (controlType) {
                params[controlType] = parseInt(control.value);
            }
        });

        if (instrumentName === 'LC' || instrumentName === 'MC' || instrumentName === 'HC') {
            const pair = control.dataset.pair;
            if (pair) {
                const tuningControl = document.querySelector(`[data-pair="${pair}"]`);
                if (tuningControl) {
                    params.tuning = parseInt(tuningControl.value);
                }
            }
        }

        return params;
    }

    toggleStep(instrument, step) {
        this.pattern[instrument][step] = !this.pattern[instrument][step];
    }

    togglePlayback() {
        if (this.isPlaying) {
            this.stopSequence();
        } else {
            this.startSequence();
        }
    }

    startSequence() {
        this.isPlaying = true;
        this.currentStep = 0;
        const stepDuration = (60 / this.tempo / 4) * 1000; 

        this.sequenceInterval = setInterval(() => {
            this.playStep();
            this.currentStep = (this.currentStep + 1) % 16;
        }, stepDuration);

        this.updateDisplay();
    }

    stopSequence() {
        this.isPlaying = false;
        if (this.sequenceInterval) {
            clearInterval(this.sequenceInterval);
            this.sequenceInterval = null;
        }
        this.updateDisplay();
    }

    playStep() {
        Object.keys(this.pattern).forEach(instrument => {
            if (this.pattern[instrument][this.currentStep]) {
                const withAccent = this.hasAccent(this.currentStep);
                this.playInstrument(instrument, withAccent);
            }
        });
    }

    hasAccent(step) {
        return step % 4 === 0;
    }

    clearPattern() {
        this.initializePattern();
        this.updateDisplay();
    }

    updateInstrumentControls() {
        const params = this.getInstrumentParams(this.currentInstrument);
        console.log(`${this.currentInstrument} controls:`, params);
    }

    updateDisplay() {
        this.updateInstrumentSelection();
        this.updateStepDisplay();
        this.updateTransportDisplay();
    }

    updateInstrumentSelection() {
        document.querySelectorAll('.instrument-group').forEach(group => {
            group.classList.toggle('selected', group.dataset.instrument === this.currentInstrument);
        });
    }

    updateStepDisplay() {
        document.querySelectorAll('.step-button').forEach((button, index) => {
            const isActive = this.pattern[this.currentInstrument][index];
            const isCurrent = this.isPlaying && index === this.currentStep;
            
            button.classList.toggle('active', isActive);
            button.classList.toggle('current', isCurrent);
        });
    }

    updateTransportDisplay() {
        const startStopButton = document.querySelector('.start-stop');
        if (startStopButton) {
            startStopButton.textContent = this.isPlaying ? 'Stop' : 'Start';
            startStopButton.classList.toggle('playing', this.isPlaying);
        }
    }
}

document.addEventListener('DOMContentLoaded', () => {
    window.tr808App = new TR808App();
});