class TR808Sequencer {
  constructor() {
    this.instruments = ['BD', 'SD', 'LC', 'LT', 'MC', 'MT', 'HC', 'HT', 'CL', 'RS', 'MA', 'CP', 'CB', 'CY', 'OH', 'CH'];
    this.stepCount = 16;
    this.currentStep = 0;
    this.tempo = 120;
    this.currentVariation = 'A';
    this.selectedInstrument = 'BD';
    this.accentLevel = 50;
    this.playing = false;
    this.intervalId = null;
    
    // Pattern storage: variation -> step -> instrument -> boolean
    this.patterns = {
      'A': this.createEmptyPattern(),
      'AB': this.createEmptyPattern(),
      'B': this.createEmptyPattern()
    };
    
    // Accent storage: variation -> step -> boolean
    this.accents = {
      'A': new Array(16).fill(false),
      'AB': new Array(16).fill(false),
      'B': new Array(16).fill(false)
    };
  }
  
  createEmptyPattern() {
    const pattern = {};
    for (let step = 0; step < this.stepCount; step++) {
      pattern[step] = {};
      this.instruments.forEach(instrument => {
        pattern[step][instrument] = false;
      });
    }
    return pattern;
  }
  
  // Core functionality
  getStepCount() {
    return this.stepCount;
  }
  
  getCurrentStep() {
    return this.currentStep;
  }
  
  setCurrentStep(step) {
    if (step >= 0 && step < this.stepCount) {
      this.currentStep = step;
    }
  }
  
  nextStep() {
    this.currentStep = (this.currentStep + 1) % this.stepCount;
  }
  
  isStepActive(step) {
    const pattern = this.patterns[this.currentVariation];
    return Object.values(pattern[step]).some(active => active);
  }
  
  toggleStep(step) {
    // This toggles all instruments at a step - not typically used in TR-808
    // but included for test compatibility
    const pattern = this.patterns[this.currentVariation];
    const hasAnyActive = Object.values(pattern[step]).some(active => active);
    
    this.instruments.forEach(instrument => {
      pattern[step][instrument] = !hasAnyActive;
    });
  }
  
  // Instrument management
  hasInstrument(instrument) {
    return this.instruments.includes(instrument);
  }
  
  selectInstrument(instrument) {
    if (this.hasInstrument(instrument)) {
      this.selectedInstrument = instrument;
    }
  }
  
  getSelectedInstrument() {
    return this.selectedInstrument;
  }
  
  // Pattern programming
  programStep(step, instrument, active) {
    if (step >= 0 && step < this.stepCount && this.hasInstrument(instrument)) {
      this.patterns[this.currentVariation][step][instrument] = active;
    }
  }
  
  isInstrumentActiveAtStep(step, instrument) {
    if (step >= 0 && step < this.stepCount && this.hasInstrument(instrument)) {
      return this.patterns[this.currentVariation][step][instrument];
    }
    return false;
  }
  
  getActiveInstrumentsAtCurrentStep() {
    const pattern = this.patterns[this.currentVariation];
    const activeInstruments = [];
    
    this.instruments.forEach(instrument => {
      if (pattern[this.currentStep][instrument]) {
        activeInstruments.push(instrument);
      }
    });
    
    return activeInstruments;
  }
  
  hasActiveInstruments(step) {
    const pattern = this.patterns[this.currentVariation];
    return Object.values(pattern[step]).some(active => active);
  }
  
  // Step interaction
  pressStep(step) {
    if (step >= 0 && step < this.stepCount) {
      const currentValue = this.isInstrumentActiveAtStep(step, this.selectedInstrument);
      this.programStep(step, this.selectedInstrument, !currentValue);
    }
  }
  
  clearStep(step) {
    if (step >= 0 && step < this.stepCount) {
      this.instruments.forEach(instrument => {
        this.patterns[this.currentVariation][step][instrument] = false;
      });
    }
  }
  
  getStepState(step) {
    const pattern = this.patterns[this.currentVariation];
    const activeInstruments = [];
    
    this.instruments.forEach(instrument => {
      if (pattern[step][instrument]) {
        activeInstruments.push(instrument);
      }
    });
    
    return {
      hasActiveInstruments: activeInstruments.length > 0,
      instruments: activeInstruments,
      isCurrentStep: step === this.currentStep,
      hasAccent: this.accents[this.currentVariation][step]
    };
  }
  
  // Tempo control
  getTempo() {
    return this.tempo;
  }
  
  setTempo(tempo) {
    if (tempo >= 40 && tempo <= 300) {
      this.tempo = tempo;
      
      // Restart timing if playing
      if (this.playing) {
        this.stop();
        this.start();
      }
    }
  }
  
  getStepInterval() {
    // TR-808 uses 16th notes as steps
    // At 120 BPM: 1 beat = 0.5 seconds, 16th note = 0.125 seconds = 125ms
    const beatsPerSecond = this.tempo / 60;
    const sixteenthNoteInterval = 1 / (beatsPerSecond * 4);
    return Math.round(sixteenthNoteInterval * 1000);
  }
  
  // Playback control
  isPlaying() {
    return this.playing;
  }
  
  start() {
    if (!this.playing) {
      this.playing = true;
      this.intervalId = setInterval(() => {
        this.nextStep();
      }, this.getStepInterval());
    }
  }
  
  stop() {
    if (this.playing) {
      this.playing = false;
      if (this.intervalId) {
        clearInterval(this.intervalId);
        this.intervalId = null;
      }
      this.currentStep = 0;
    }
  }
  
  startStop() {
    if (this.playing) {
      this.stop();
    } else {
      this.start();
    }
  }
  
  // Pattern variations
  getCurrentVariation() {
    return this.currentVariation;
  }
  
  setVariation(variation) {
    if (['A', 'AB', 'B'].includes(variation)) {
      this.currentVariation = variation;
    }
  }
  
  clearPattern() {
    this.patterns[this.currentVariation] = this.createEmptyPattern();
    this.accents[this.currentVariation] = new Array(16).fill(false);
  }
  
  clearAllPatterns() {
    this.patterns = {
      'A': this.createEmptyPattern(),
      'AB': this.createEmptyPattern(),
      'B': this.createEmptyPattern()
    };
    this.accents = {
      'A': new Array(16).fill(false),
      'AB': new Array(16).fill(false),
      'B': new Array(16).fill(false)
    };
  }
  
  // Accent functionality
  setAccent(step, active) {
    if (step >= 0 && step < this.stepCount) {
      this.accents[this.currentVariation][step] = active;
    }
  }
  
  hasAccent(step) {
    if (step >= 0 && step < this.stepCount) {
      return this.accents[this.currentVariation][step];
    }
    return false;
  }
  
  getAccentLevel() {
    return this.accentLevel;
  }
  
  setAccentLevel(level) {
    if (level >= 0 && level <= 100) {
      this.accentLevel = level;
    }
  }
}

// Export for Node.js (tests) and browser
if (typeof module !== 'undefined' && module.exports) {
  module.exports = { TR808Sequencer };
}