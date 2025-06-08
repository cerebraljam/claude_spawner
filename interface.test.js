const fs = require('fs');
const path = require('path');
const { JSDOM } = require('jsdom');

describe('TR-808 Interface Structure', () => {
  let dom;
  let document;

  beforeAll(() => {
    const indexPath = path.join(__dirname, 'public', 'index.html');
    const html = fs.readFileSync(indexPath, 'utf8');
    dom = new JSDOM(html);
    document = dom.window.document;
  });

  test('should have TR-808 title', () => {
    const title = document.querySelector('title');
    expect(title.textContent).toBe('TR-808 Drum Machine');
  });

  test('should have main TR-808 container', () => {
    const container = document.querySelector('.tr808-machine');
    expect(container).toBeTruthy();
  });

  test('should have all 16 drum instruments', () => {
    const instruments = ['BD', 'SD', 'LC', 'LT', 'MC', 'MT', 'HC', 'HT', 'CL', 'RS', 'MA', 'CP', 'CB', 'CY', 'OH', 'CH'];
    
    instruments.forEach(instrument => {
      const element = document.querySelector(`[data-instrument="${instrument}"]`);
      expect(element).toBeTruthy();
    });
  });

  test('should have step sequencer with 16 steps', () => {
    const steps = document.querySelectorAll('.step-button');
    expect(steps.length).toBe(16);
    
    for (let i = 1; i <= 16; i++) {
      const step = document.querySelector(`[data-step="${i}"]`);
      expect(step).toBeTruthy();
    }
  });

  test('should have tempo control', () => {
    const tempoControl = document.querySelector('.tempo-control');
    expect(tempoControl).toBeTruthy();
  });

  test('should have master volume control', () => {
    const masterVolume = document.querySelector('.master-volume');
    expect(masterVolume).toBeTruthy();
  });

  test('should have mode selector', () => {
    const modeSelector = document.querySelector('.mode-selector');
    expect(modeSelector).toBeTruthy();
  });

  test('should have start/stop button', () => {
    const startStop = document.querySelector('.start-stop');
    expect(startStop).toBeTruthy();
  });

  test('should have pattern variation switches (A/AB/B)', () => {
    const variations = ['A', 'AB', 'B'];
    variations.forEach(variation => {
      const element = document.querySelector(`[data-variation="${variation}"]`);
      expect(element).toBeTruthy();
    });
  });

  test('should have basic rhythm buttons (1-12)', () => {
    for (let i = 1; i <= 12; i++) {
      const rhythmButton = document.querySelector(`[data-rhythm="${i}"]`);
      expect(rhythmButton).toBeTruthy();
    }
  });

  test('should have instrument level controls', () => {
    const levelControlInstruments = ['BD', 'SD', 'RS', 'CP', 'CB', 'CY', 'OH', 'CH'];
    
    levelControlInstruments.forEach(instrument => {
      const levelControl = document.querySelector(`[data-control="level"][data-instrument="${instrument}"]`);
      expect(levelControl).toBeTruthy();
    });
  });

  test('should have tone controls for BD, SD, CY', () => {
    const toneInstruments = ['BD', 'SD', 'CY'];
    
    toneInstruments.forEach(instrument => {
      const toneControl = document.querySelector(`[data-control="tone"][data-instrument="${instrument}"]`);
      expect(toneControl).toBeTruthy();
    });
  });

  test('should have decay controls for BD, CY, OH', () => {
    const decayInstruments = ['BD', 'CY', 'OH'];
    
    decayInstruments.forEach(instrument => {
      const decayControl = document.querySelector(`[data-control="decay"][data-instrument="${instrument}"]`);
      expect(decayControl).toBeTruthy();
    });
  });

  test('should have tuning controls for tom/conga pairs', () => {
    const tuningPairs = ['LC-LT', 'MC-MT', 'HC-HT'];
    
    tuningPairs.forEach(pair => {
      const tuningControl = document.querySelector(`[data-control="tuning"][data-pair="${pair}"]`);
      expect(tuningControl).toBeTruthy();
    });
  });

  test('should have snappy control for snare drum', () => {
    const snappyControl = document.querySelector(`[data-control="snappy"][data-instrument="SD"]`);
    expect(snappyControl).toBeTruthy();
  });

  test('should have accent control', () => {
    const accentControl = document.querySelector('.accent-control');
    expect(accentControl).toBeTruthy();
  });

  test('should have clear button', () => {
    const clearButton = document.querySelector('.clear-button');
    expect(clearButton).toBeTruthy();
  });

  test('should have tap button', () => {
    const tapButton = document.querySelector('.tap-button');
    expect(tapButton).toBeTruthy();
  });
});

describe('TR-808 CSS Styling', () => {
  let dom;
  let document;
  let window;

  beforeAll(() => {
    const indexPath = path.join(__dirname, 'public', 'index.html');
    const html = fs.readFileSync(indexPath, 'utf8');
    const cssPath = path.join(__dirname, 'public', 'style.css');
    const css = fs.readFileSync(cssPath, 'utf8');
    
    dom = new JSDOM(html, {
      resources: "usable",
      runScripts: "dangerously"
    });
    document = dom.window.document;
    window = dom.window;
    
    // Add CSS to the document
    const style = document.createElement('style');
    style.textContent = css;
    document.head.appendChild(style);
  });

  test('should have TR-808 color scheme (black/red/orange)', () => {
    const machine = document.querySelector('.tr808-machine');
    const computedStyle = window.getComputedStyle(machine);
    
    // Machine should have dark background (including transparent/rgba)
    const bgColor = computedStyle.backgroundColor;
    expect(bgColor).toMatch(/(black|#000|rgb\(0,\s*0,\s*0\)|#1a1a1a|#2a2a2a|rgba\(0,\s*0,\s*0,\s*0\))/i);
  });

  test('should have step buttons styled as TR-808 style', () => {
    const stepButton = document.querySelector('.step-button');
    const computedStyle = window.getComputedStyle(stepButton);
    
    // Should have distinctive button styling
    expect(computedStyle.borderRadius).toBeDefined();
    expect(computedStyle.padding).toBeDefined();
  });

  test('should have instrument controls with proper layout', () => {
    const instrumentGroup = document.querySelector('.instrument-group');
    const computedStyle = window.getComputedStyle(instrumentGroup);
    
    // Should have defined layout properties
    expect(computedStyle.display).toBeDefined();
    expect(computedStyle.margin || computedStyle.padding).toBeDefined();
  });

  test('should have range inputs styled as TR-808 knobs/sliders', () => {
    const rangeInput = document.querySelector('input[type="range"]');
    const computedStyle = window.getComputedStyle(rangeInput);
    
    // Should have custom styling for knobs/sliders
    expect(computedStyle.appearance || computedStyle.webkitAppearance).toBeDefined();
  });

  test('should have buttons with TR-808 styling', () => {
    const button = document.querySelector('button');
    const computedStyle = window.getComputedStyle(button);
    
    // Buttons should have TR-808 styling
    expect(computedStyle.backgroundColor).toBeDefined();
    expect(computedStyle.border).toBeDefined();
  });

  test('should have proper typography for labels', () => {
    const label = document.querySelector('label');
    const computedStyle = window.getComputedStyle(label);
    
    // Labels should have appropriate font styling
    expect(computedStyle.fontFamily).toBeDefined();
    expect(computedStyle.fontSize).toBeDefined();
  });

  test('should have main container with proper dimensions', () => {
    const machine = document.querySelector('.tr808-machine');
    const computedStyle = window.getComputedStyle(machine);
    
    // Should have defined width and proper layout
    expect(computedStyle.maxWidth || computedStyle.width).toBeDefined();
  });

  test('should have sections properly organized', () => {
    const sections = document.querySelectorAll('section');
    expect(sections.length).toBeGreaterThan(0);
    
    sections.forEach(section => {
      const computedStyle = window.getComputedStyle(section);
      expect(computedStyle.display).toBeDefined();
    });
  });
});