const { TR808Sequencer } = require('./public/sequencer.js');

describe('TR-808 Step Sequencer Core Functionality', () => {
  let sequencer;

  beforeEach(() => {
    sequencer = new TR808Sequencer();
  });

  test('should initialize with 16 steps', () => {
    expect(sequencer.getStepCount()).toBe(16);
  });

  test('should initialize with all steps empty', () => {
    for (let i = 0; i < 16; i++) {
      expect(sequencer.isStepActive(i)).toBe(false);
    }
  });

  test('should toggle step on/off', () => {
    expect(sequencer.isStepActive(0)).toBe(false);
    sequencer.toggleStep(0);
    expect(sequencer.isStepActive(0)).toBe(true);
    sequencer.toggleStep(0);
    expect(sequencer.isStepActive(0)).toBe(false);
  });

  test('should get current step position', () => {
    expect(sequencer.getCurrentStep()).toBe(0);
  });

  test('should advance to next step', () => {
    sequencer.nextStep();
    expect(sequencer.getCurrentStep()).toBe(1);
  });

  test('should wrap around after step 16', () => {
    for (let i = 0; i < 16; i++) {
      sequencer.nextStep();
    }
    expect(sequencer.getCurrentStep()).toBe(0);
  });

  test('should support 16 different instruments', () => {
    const instruments = ['BD', 'SD', 'LC', 'LT', 'MC', 'MT', 'HC', 'HT', 'CL', 'RS', 'MA', 'CP', 'CB', 'CY', 'OH', 'CH'];
    
    instruments.forEach(instrument => {
      expect(sequencer.hasInstrument(instrument)).toBe(true);
    });
  });

  test('should program instrument at specific step', () => {
    sequencer.programStep(0, 'BD', true);
    expect(sequencer.isInstrumentActiveAtStep(0, 'BD')).toBe(true);
    
    sequencer.programStep(0, 'BD', false);
    expect(sequencer.isInstrumentActiveAtStep(0, 'BD')).toBe(false);
  });

  test('should get all active instruments at current step', () => {
    sequencer.programStep(0, 'BD', true);
    sequencer.programStep(0, 'SD', true);
    sequencer.setCurrentStep(0);
    
    const activeInstruments = sequencer.getActiveInstrumentsAtCurrentStep();
    expect(activeInstruments).toContain('BD');
    expect(activeInstruments).toContain('SD');
    expect(activeInstruments.length).toBe(2);
  });
});

describe('TR-808 Tempo Control and Timing Logic', () => {
  let sequencer;

  beforeEach(() => {
    sequencer = new TR808Sequencer();
  });

  test('should initialize with 120 BPM', () => {
    expect(sequencer.getTempo()).toBe(120);
  });

  test('should set tempo within valid range (40-300 BPM)', () => {
    sequencer.setTempo(90);
    expect(sequencer.getTempo()).toBe(90);
    
    sequencer.setTempo(240);
    expect(sequencer.getTempo()).toBe(240);
  });

  test('should reject tempo below 40 BPM', () => {
    sequencer.setTempo(30);
    expect(sequencer.getTempo()).toBe(120); // Should remain at default
  });

  test('should reject tempo above 300 BPM', () => {
    sequencer.setTempo(350);
    expect(sequencer.getTempo()).toBe(120); // Should remain at default
  });

  test('should calculate correct step interval from tempo', () => {
    sequencer.setTempo(120); // 120 BPM = 0.5 seconds per beat, 16th notes = 0.125s
    expect(sequencer.getStepInterval()).toBe(125); // milliseconds
    
    sequencer.setTempo(60); // 60 BPM = 1 second per beat, 16th notes = 0.25s
    expect(sequencer.getStepInterval()).toBe(250); // milliseconds
  });

  test('should start and stop playback', () => {
    expect(sequencer.isPlaying()).toBe(false);
    
    sequencer.start();
    expect(sequencer.isPlaying()).toBe(true);
    
    sequencer.stop();
    expect(sequencer.isPlaying()).toBe(false);
  });

  test('should reset to step 0 when stopped', () => {
    sequencer.start();
    sequencer.nextStep();
    sequencer.nextStep();
    expect(sequencer.getCurrentStep()).toBe(2);
    
    sequencer.stop();
    expect(sequencer.getCurrentStep()).toBe(0);
  });
});

describe('TR-808 Pattern Variations and Storage', () => {
  let sequencer;

  beforeEach(() => {
    sequencer = new TR808Sequencer();
  });

  test('should initialize with variation A', () => {
    expect(sequencer.getCurrentVariation()).toBe('A');
  });

  test('should switch between variations A, AB, B', () => {
    sequencer.setVariation('AB');
    expect(sequencer.getCurrentVariation()).toBe('AB');
    
    sequencer.setVariation('B');
    expect(sequencer.getCurrentVariation()).toBe('B');
    
    sequencer.setVariation('A');
    expect(sequencer.getCurrentVariation()).toBe('A');
  });

  test('should store separate patterns for each variation', () => {
    // Program pattern A
    sequencer.setVariation('A');
    sequencer.programStep(0, 'BD', true);
    sequencer.programStep(4, 'SD', true);
    
    // Program pattern B
    sequencer.setVariation('B');
    sequencer.programStep(2, 'BD', true);
    sequencer.programStep(6, 'SD', true);
    
    // Verify pattern A
    sequencer.setVariation('A');
    expect(sequencer.isInstrumentActiveAtStep(0, 'BD')).toBe(true);
    expect(sequencer.isInstrumentActiveAtStep(4, 'SD')).toBe(true);
    expect(sequencer.isInstrumentActiveAtStep(2, 'BD')).toBe(false);
    
    // Verify pattern B
    sequencer.setVariation('B');
    expect(sequencer.isInstrumentActiveAtStep(2, 'BD')).toBe(true);
    expect(sequencer.isInstrumentActiveAtStep(6, 'SD')).toBe(true);
    expect(sequencer.isInstrumentActiveAtStep(0, 'BD')).toBe(false);
  });

  test('should clear current pattern', () => {
    sequencer.programStep(0, 'BD', true);
    sequencer.programStep(4, 'SD', true);
    
    sequencer.clearPattern();
    
    expect(sequencer.isInstrumentActiveAtStep(0, 'BD')).toBe(false);
    expect(sequencer.isInstrumentActiveAtStep(4, 'SD')).toBe(false);
  });

  test('should clear all patterns', () => {
    // Program patterns A and B
    sequencer.setVariation('A');
    sequencer.programStep(0, 'BD', true);
    
    sequencer.setVariation('B');
    sequencer.programStep(2, 'SD', true);
    
    sequencer.clearAllPatterns();
    
    // Verify all patterns are cleared
    sequencer.setVariation('A');
    expect(sequencer.isInstrumentActiveAtStep(0, 'BD')).toBe(false);
    
    sequencer.setVariation('B');
    expect(sequencer.isInstrumentActiveAtStep(2, 'SD')).toBe(false);
  });
});

describe('TR-808 Start/Stop/Clear Functionality', () => {
  let sequencer;

  beforeEach(() => {
    sequencer = new TR808Sequencer();
  });

  test('should start playback from current position', () => {
    sequencer.setCurrentStep(5);
    sequencer.start();
    
    expect(sequencer.isPlaying()).toBe(true);
    expect(sequencer.getCurrentStep()).toBe(5);
  });

  test('should toggle start/stop with single method', () => {
    expect(sequencer.isPlaying()).toBe(false);
    
    sequencer.startStop();
    expect(sequencer.isPlaying()).toBe(true);
    
    sequencer.startStop();
    expect(sequencer.isPlaying()).toBe(false);
  });

  test('should clear current step', () => {
    sequencer.programStep(0, 'BD', true);
    sequencer.programStep(0, 'SD', true);
    
    sequencer.clearStep(0);
    
    expect(sequencer.isInstrumentActiveAtStep(0, 'BD')).toBe(false);
    expect(sequencer.isInstrumentActiveAtStep(0, 'SD')).toBe(false);
  });

  test('should have accent functionality', () => {
    sequencer.setAccent(0, true);
    expect(sequencer.hasAccent(0)).toBe(true);
    
    sequencer.setAccent(0, false);
    expect(sequencer.hasAccent(0)).toBe(false);
  });

  test('should get accent level', () => {
    expect(sequencer.getAccentLevel()).toBe(50); // Default
    
    sequencer.setAccentLevel(75);
    expect(sequencer.getAccentLevel()).toBe(75);
  });
});

describe('TR-808 Step Button Interaction and Programming', () => {
  let sequencer;

  beforeEach(() => {
    sequencer = new TR808Sequencer();
  });

  test('should select instrument for programming', () => {
    sequencer.selectInstrument('BD');
    expect(sequencer.getSelectedInstrument()).toBe('BD');
  });

  test('should program selected instrument when step is pressed', () => {
    sequencer.selectInstrument('SD');
    sequencer.pressStep(4);
    
    expect(sequencer.isInstrumentActiveAtStep(4, 'SD')).toBe(true);
  });

  test('should toggle off selected instrument if already active', () => {
    sequencer.selectInstrument('BD');
    sequencer.pressStep(0);
    expect(sequencer.isInstrumentActiveAtStep(0, 'BD')).toBe(true);
    
    sequencer.pressStep(0);
    expect(sequencer.isInstrumentActiveAtStep(0, 'BD')).toBe(false);
  });

  test('should indicate which steps have active instruments', () => {
    sequencer.programStep(0, 'BD', true);
    sequencer.programStep(0, 'SD', true);
    sequencer.programStep(8, 'BD', true);
    
    expect(sequencer.hasActiveInstruments(0)).toBe(true);
    expect(sequencer.hasActiveInstruments(8)).toBe(true);
    expect(sequencer.hasActiveInstruments(4)).toBe(false);
  });

  test('should provide step programming state for UI', () => {
    sequencer.selectInstrument('BD');
    sequencer.programStep(0, 'BD', true);
    
    const stepState = sequencer.getStepState(0);
    expect(stepState.hasActiveInstruments).toBe(true);
    expect(stepState.instruments).toContain('BD');
    expect(stepState.isCurrentStep).toBe(true); // Step 0 is current by default
  });
});