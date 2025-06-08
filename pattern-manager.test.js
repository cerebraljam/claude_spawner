// Mock localStorage for Node.js environment
global.localStorage = {
  data: {},
  getItem: function(key) {
    return this.data[key] || null;
  },
  setItem: function(key, value) {
    this.data[key] = value;
  },
  removeItem: function(key) {
    delete this.data[key];
  },
  clear: function() {
    this.data = {};
  }
};

// Mock document for Node.js environment  
global.document = {
  addEventListener: function() {}
};

// Load PatternManager class
const PatternManager = require('./PatternManager');

describe('TR-808 Pattern Manager', () => {
  let patternManager;

  beforeEach(() => {
    patternManager = new PatternManager();
    // Clear localStorage before each test
    global.localStorage.clear();
  });

  describe('Pattern Storage', () => {
    test('should save a pattern to localStorage', () => {
      const result = patternManager.savePattern('Test Pattern 1');
      expect(result).toBe(true);
      
      const saved = JSON.parse(global.localStorage.getItem('tr808-patterns'));
      expect(saved['Test Pattern 1']).toBeDefined();
      expect(saved['Test Pattern 1'].name).toBe('Test Pattern 1');
    });

    test('should throw error when saving pattern without name', () => {
      expect(() => {
        patternManager.savePattern();
      }).toThrow('Pattern name is required');
    });

    test('should load a saved pattern', () => {
      // Save a pattern first
      patternManager.setStep('BD', 0, true);
      patternManager.setStep('SD', 4, true);
      patternManager.setTempo(140);
      patternManager.savePattern('Test Load Pattern');
      
      // Create new manager and load pattern
      const newManager = new PatternManager();
      const loadedPattern = newManager.loadPattern('Test Load Pattern');
      
      expect(loadedPattern.name).toBe('Test Load Pattern');
      expect(loadedPattern.tempo).toBe(140);
      expect(loadedPattern.steps.BD[0]).toBe(true);
      expect(loadedPattern.steps.SD[4]).toBe(true);
    });

    test('should throw error when loading non-existent pattern', () => {
      expect(() => {
        patternManager.loadPattern('Non-existent Pattern');
      }).toThrow('Pattern not found');
    });

    test('should get list of saved patterns', () => {
      patternManager.savePattern('Pattern A');
      patternManager.savePattern('Pattern B');
      
      const patterns = patternManager.getPatternList();
      expect(patterns).toContain('Pattern A');
      expect(patterns).toContain('Pattern B');
      expect(patterns.length).toBe(2);
    });

    test('should delete a pattern', () => {
      patternManager.savePattern('Delete Me');
      expect(patternManager.getPatternList()).toContain('Delete Me');
      
      const result = patternManager.deletePattern('Delete Me');
      expect(result).toBe(true);
      expect(patternManager.getPatternList()).not.toContain('Delete Me');
    });

    test('should throw error when deleting non-existent pattern', () => {
      expect(() => {
        patternManager.deletePattern('Non-existent Pattern');
      }).toThrow('Pattern not found');
    });
  });

  describe('Pattern Variation System', () => {
    test('should set pattern variation to A', () => {
      const result = patternManager.setVariation('A');
      expect(result).toBe('A');
      expect(patternManager.getVariation()).toBe('A');
    });

    test('should set pattern variation to AB', () => {
      const result = patternManager.setVariation('AB');
      expect(result).toBe('AB');
      expect(patternManager.getVariation()).toBe('AB');
    });

    test('should set pattern variation to B', () => {
      const result = patternManager.setVariation('B');
      expect(result).toBe('B');
      expect(patternManager.getVariation()).toBe('B');
    });

    test('should throw error for invalid variation', () => {
      expect(() => {
        patternManager.setVariation('C');
      }).toThrow('Invalid variation. Must be A, AB, or B');
    });

    test('should default to variation A', () => {
      expect(patternManager.getVariation()).toBe('A');
    });

    test('should save variation with pattern', () => {
      patternManager.setVariation('B');
      patternManager.savePattern('Variation Test');
      
      const newManager = new PatternManager();
      const loadedPattern = newManager.loadPattern('Variation Test');
      
      expect(loadedPattern.variation).toBe('B');
      expect(newManager.getVariation()).toBe('B');
    });
  });

  describe('Step Sequencer Integration', () => {
    test('should set step active for instrument', () => {
      const result = patternManager.setStep('BD', 0, true);
      expect(result).toBe(true);
      expect(patternManager.getStep('BD', 0)).toBe(true);
    });

    test('should set step inactive for instrument', () => {
      patternManager.setStep('SD', 7, true);
      const result = patternManager.setStep('SD', 7, false);
      expect(result).toBe(false);
      expect(patternManager.getStep('SD', 7)).toBe(false);
    });

    test('should throw error for invalid instrument', () => {
      expect(() => {
        patternManager.setStep('INVALID', 0, true);
      }).toThrow('Invalid instrument');
    });

    test('should throw error for invalid step number', () => {
      expect(() => {
        patternManager.setStep('BD', 16, true);
      }).toThrow('Step must be between 0 and 15');
      
      expect(() => {
        patternManager.setStep('BD', -1, true);
      }).toThrow('Step must be between 0 and 15');
    });

    test('should clear all pattern steps', () => {
      patternManager.setStep('BD', 0, true);
      patternManager.setStep('SD', 4, true);
      patternManager.setStep('CH', 15, true);
      
      const result = patternManager.clearPattern();
      expect(result).toBe(true);
      
      expect(patternManager.getStep('BD', 0)).toBe(false);
      expect(patternManager.getStep('SD', 4)).toBe(false);
      expect(patternManager.getStep('CH', 15)).toBe(false);
    });
  });

  describe('Tempo Control', () => {
    test('should set valid tempo', () => {
      const result = patternManager.setTempo(140);
      expect(result).toBe(140);
      expect(patternManager.getTempo()).toBe(140);
    });

    test('should default to 120 BPM', () => {
      expect(patternManager.getTempo()).toBe(120);
    });

    test('should throw error for tempo below 40 BPM', () => {
      expect(() => {
        patternManager.setTempo(39);
      }).toThrow('Tempo must be between 40 and 300 BPM');
    });

    test('should throw error for tempo above 300 BPM', () => {
      expect(() => {
        patternManager.setTempo(301);
      }).toThrow('Tempo must be between 40 and 300 BPM');
    });

    test('should save tempo with pattern', () => {
      patternManager.setTempo(180);
      patternManager.savePattern('Tempo Test');
      
      const newManager = new PatternManager();
      const loadedPattern = newManager.loadPattern('Tempo Test');
      
      expect(loadedPattern.tempo).toBe(180);
      expect(newManager.getTempo()).toBe(180);
    });
  });

  describe('Instrument Level Control', () => {
    test('should set instrument level', () => {
      const result = patternManager.setInstrumentLevel('BD', 90);
      expect(result).toBe(90);
      expect(patternManager.getInstrumentLevel('BD')).toBe(90);
    });

    test('should throw error for invalid instrument', () => {
      expect(() => {
        patternManager.setInstrumentLevel('INVALID', 50);
      }).toThrow('Invalid instrument');
    });

    test('should throw error for level below 0', () => {
      expect(() => {
        patternManager.setInstrumentLevel('BD', -1);
      }).toThrow('Level must be between 0 and 100');
    });

    test('should throw error for level above 100', () => {
      expect(() => {
        patternManager.setInstrumentLevel('BD', 101);
      }).toThrow('Level must be between 0 and 100');
    });

    test('should save instrument levels with pattern', () => {
      patternManager.setInstrumentLevel('BD', 95);
      patternManager.setInstrumentLevel('SD', 75);
      patternManager.savePattern('Level Test');
      
      const newManager = new PatternManager();
      const loadedPattern = newManager.loadPattern('Level Test');
      
      expect(loadedPattern.instruments.BD.level).toBe(95);
      expect(loadedPattern.instruments.SD.level).toBe(75);
      expect(newManager.getInstrumentLevel('BD')).toBe(95);
      expect(newManager.getInstrumentLevel('SD')).toBe(75);
    });
  });

  describe('Basic Rhythm Patterns', () => {
    test('should have method to load basic rhythm pattern', () => {
      expect(typeof patternManager.loadBasicRhythm).toBe('function');
    });

    test('should load basic rhythm pattern 1 (Rock)', () => {
      patternManager.loadBasicRhythm(1);
      
      // Check rock pattern from implementation
      expect(patternManager.getStep('BD', 0)).toBe(true);  // Step 1
      expect(patternManager.getStep('BD', 4)).toBe(true);  // Step 5  
      expect(patternManager.getStep('BD', 8)).toBe(true);  // Step 9
      expect(patternManager.getStep('BD', 12)).toBe(true); // Step 13
      expect(patternManager.getStep('SD', 4)).toBe(true);  // Step 5
      expect(patternManager.getStep('SD', 12)).toBe(true); // Step 13
      expect(patternManager.getStep('CH', 0)).toBe(true);  // Continuous hi-hat
    });

    test('should load basic rhythm pattern 2 (Disco)', () => {
      patternManager.loadBasicRhythm(2);
      
      // Check disco pattern from implementation
      expect(patternManager.getStep('BD', 0)).toBe(true);  // Step 1
      expect(patternManager.getStep('BD', 4)).toBe(true);  // Step 5
      expect(patternManager.getStep('BD', 8)).toBe(true);  // Step 9
      expect(patternManager.getStep('BD', 12)).toBe(true); // Step 13
      expect(patternManager.getStep('CH', 1)).toBe(true);  // Step 2
      expect(patternManager.getStep('CH', 3)).toBe(true);  // Step 4
    });

    test('should throw error for invalid rhythm number', () => {
      expect(() => {
        patternManager.loadBasicRhythm(13);
      }).toThrow('Invalid rhythm number. Must be between 1 and 12');
      
      expect(() => {
        patternManager.loadBasicRhythm(0);
      }).toThrow('Invalid rhythm number. Must be between 1 and 12');
    });

    test('should clear pattern before loading basic rhythm', () => {
      // Set some steps first
      patternManager.setStep('CY', 7, true);
      patternManager.setStep('MA', 3, true);
      
      // Load a basic rhythm
      patternManager.loadBasicRhythm(1);
      
      // Check that the previous steps were cleared
      expect(patternManager.getStep('CY', 7)).toBe(false);
      expect(patternManager.getStep('MA', 3)).toBe(false);
    });
  });
});