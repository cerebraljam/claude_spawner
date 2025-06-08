class PatternManager {
  constructor() {
    this.currentPattern = {
      name: 'Pattern 1',
      variation: 'A',
      steps: this.initializeSteps(),
      tempo: 120,
      instruments: this.initializeInstruments()
    };
    this.patterns = {};
    this.currentVariation = 'A';
    this.basicRhythms = this.initializeBasicRhythms();
  }

  initializeSteps() {
    const instruments = ['BD', 'SD', 'LC', 'LT', 'MC', 'MT', 'HC', 'HT', 'CL', 'RS', 'MA', 'CP', 'CB', 'CY', 'OH', 'CH'];
    const steps = {};
    instruments.forEach(instrument => {
      steps[instrument] = Array(16).fill(false);
    });
    return steps;
  }

  initializeInstruments() {
    return {
      BD: { level: 80, tone: 50, decay: 50 },
      SD: { level: 80, tone: 50, snappy: 50 },
      LC: { tuning: 50 },
      LT: { level: 80 },
      MC: { tuning: 50 },
      MT: { level: 80 },
      HC: { tuning: 50 },
      HT: { level: 80 },
      CL: {},
      RS: { level: 80 },
      MA: {},
      CP: { level: 80 },
      CB: { level: 80 },
      CY: { level: 80, tone: 50, decay: 50 },
      OH: { level: 80, decay: 50 },
      CH: { level: 80 }
    };
  }

  initializeBasicRhythms() {
    return {
      1: { // Rock
        BD: [true, false, false, false, true, false, false, false, true, false, false, false, true, false, false, false],
        SD: [false, false, false, false, true, false, false, false, false, false, false, false, true, false, false, false],
        CH: [true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true]
      },
      2: { // Disco
        BD: [true, false, false, false, true, false, false, false, true, false, false, false, true, false, false, false],
        CH: [false, true, false, true, false, true, false, true, false, true, false, true, false, true, false, true],
        OH: [false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, true]
      },
      3: { // Funk
        BD: [true, false, false, true, false, false, true, false, false, true, false, false, true, false, false, false],
        SD: [false, false, false, false, true, false, false, true, false, false, false, false, true, false, false, false],
        CH: [true, false, true, false, true, false, true, false, true, false, true, false, true, false, true, false]
      },
      4: { // Latin
        BD: [true, false, false, false, false, false, true, false, false, false, true, false, false, false, false, false],
        SD: [false, false, true, false, false, false, false, false, true, false, false, false, false, false, true, false],
        CB: [true, false, true, false, true, false, true, false, true, false, true, false, true, false, true, false]
      },
      5: { // Shuffle
        BD: [true, false, false, true, false, false, true, false, false, true, false, false, true, false, false, false],
        SD: [false, false, true, false, false, false, false, false, true, false, false, false, false, false, true, false],
        CH: [true, false, true, true, false, true, true, false, true, true, false, true, true, false, true, false]
      },
      6: { // Reggae
        BD: [false, false, false, false, true, false, false, false, false, false, false, false, true, false, false, false],
        SD: [false, false, true, false, false, false, false, false, false, false, true, false, false, false, false, false],
        CH: [true, true, false, true, true, true, false, true, true, true, false, true, true, true, false, true]
      },
      7: { // Hip-Hop
        BD: [true, false, false, false, false, false, true, false, false, true, false, false, false, false, true, false],
        SD: [false, false, false, false, true, false, false, false, false, false, false, false, true, false, false, false],
        CH: [true, true, false, true, false, true, true, false, true, false, true, true, false, true, false, true]
      },
      8: { // Techno
        BD: [true, false, false, false, true, false, false, false, true, false, false, false, true, false, false, false],
        CH: [false, false, true, false, false, false, true, false, false, false, true, false, false, false, true, false],
        CY: [false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, true]
      },
      9: { // House
        BD: [true, false, false, false, true, false, false, false, true, false, false, false, true, false, false, false],
        CH: [false, true, false, true, false, true, false, true, false, true, false, true, false, true, false, true],
        OH: [false, false, false, false, false, false, false, true, false, false, false, false, false, false, false, true]
      },
      10: { // Breakbeat
        BD: [true, false, false, false, false, false, true, false, true, false, false, false, false, false, false, false],
        SD: [false, false, false, false, true, false, false, false, false, false, true, false, false, false, false, false],
        CH: [true, false, true, true, false, true, false, true, false, true, false, true, true, false, true, false]
      },
      11: { // Samba
        BD: [true, false, false, true, false, false, false, true, false, false, true, false, false, false, true, false],
        SD: [false, false, true, false, false, true, false, false, false, true, false, false, true, false, false, false],
        CB: [true, true, false, true, true, false, true, true, false, true, true, false, true, true, false, true]
      },
      12: { // Jazz
        BD: [true, false, false, false, false, false, true, false, false, false, false, false, true, false, false, false],
        SD: [false, false, true, false, false, false, false, true, false, false, true, false, false, false, false, true],
        CH: [true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true]
      }
    };
  }

  savePattern(name) {
    if (!name) throw new Error('Pattern name is required');
    const pattern = JSON.parse(JSON.stringify(this.currentPattern));
    pattern.name = name;
    this.patterns[name] = pattern;
    
    // Use localStorage if available, otherwise store in memory
    if (typeof localStorage !== 'undefined') {
      localStorage.setItem('tr808-patterns', JSON.stringify(this.patterns));
    }
    return true;
  }

  loadPattern(name) {
    // Use localStorage if available
    if (typeof localStorage !== 'undefined') {
      const savedPatterns = localStorage.getItem('tr808-patterns');
      if (savedPatterns) {
        this.patterns = JSON.parse(savedPatterns);
      }
    }
    
    if (!this.patterns[name]) {
      throw new Error('Pattern not found');
    }
    
    this.currentPattern = JSON.parse(JSON.stringify(this.patterns[name]));
    this.currentVariation = this.currentPattern.variation || 'A';
    return this.currentPattern;
  }

  getPatternList() {
    // Use localStorage if available
    if (typeof localStorage !== 'undefined') {
      const savedPatterns = localStorage.getItem('tr808-patterns');
      if (savedPatterns) {
        this.patterns = JSON.parse(savedPatterns);
      }
    }
    return Object.keys(this.patterns);
  }

  deletePattern(name) {
    if (!this.patterns[name]) {
      throw new Error('Pattern not found');
    }
    delete this.patterns[name];
    
    // Use localStorage if available
    if (typeof localStorage !== 'undefined') {
      localStorage.setItem('tr808-patterns', JSON.stringify(this.patterns));
    }
    return true;
  }

  setVariation(variation) {
    if (!['A', 'AB', 'B'].includes(variation)) {
      throw new Error('Invalid variation. Must be A, AB, or B');
    }
    this.currentVariation = variation;
    this.currentPattern.variation = variation;
    return variation;
  }

  getVariation() {
    return this.currentVariation;
  }

  setStep(instrument, step, active) {
    if (!this.currentPattern.steps[instrument]) {
      throw new Error('Invalid instrument');
    }
    if (step < 0 || step > 15) {
      throw new Error('Step must be between 0 and 15');
    }
    this.currentPattern.steps[instrument][step] = active;
    return this.currentPattern.steps[instrument][step];
  }

  getStep(instrument, step) {
    if (!this.currentPattern.steps[instrument]) {
      throw new Error('Invalid instrument');
    }
    if (step < 0 || step > 15) {
      throw new Error('Step must be between 0 and 15');
    }
    return this.currentPattern.steps[instrument][step];
  }

  clearPattern() {
    this.currentPattern.steps = this.initializeSteps();
    return true;
  }

  setTempo(tempo) {
    if (tempo < 40 || tempo > 300) {
      throw new Error('Tempo must be between 40 and 300 BPM');
    }
    this.currentPattern.tempo = tempo;
    return tempo;
  }

  getTempo() {
    return this.currentPattern.tempo;
  }

  setInstrumentLevel(instrument, level) {
    if (!this.currentPattern.instruments[instrument]) {
      throw new Error('Invalid instrument');
    }
    if (level < 0 || level > 100) {
      throw new Error('Level must be between 0 and 100');
    }
    this.currentPattern.instruments[instrument].level = level;
    return level;
  }

  getInstrumentLevel(instrument) {
    if (!this.currentPattern.instruments[instrument]) {
      throw new Error('Invalid instrument');
    }
    return this.currentPattern.instruments[instrument].level || 0;
  }

  loadBasicRhythm(rhythmNumber) {
    if (rhythmNumber < 1 || rhythmNumber > 12) {
      throw new Error('Invalid rhythm number. Must be between 1 and 12');
    }
    
    // Clear current pattern
    this.clearPattern();
    
    // Load the basic rhythm
    const rhythm = this.basicRhythms[rhythmNumber];
    Object.keys(rhythm).forEach(instrument => {
      if (this.currentPattern.steps[instrument]) {
        this.currentPattern.steps[instrument] = [...rhythm[instrument]];
      }
    });
    
    return true;
  }
}

module.exports = PatternManager;