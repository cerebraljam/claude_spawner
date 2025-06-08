/**
 * TR-808 Rhythm Composer Audio Synthesis Engine
 * Authentic analog-style drum machine sounds using Web Audio API
 */

class TR808 {
    constructor() {
        try {
            this.audioContext = new (window.AudioContext || window.webkitAudioContext)();
            this.masterGain = this.audioContext.createGain();
            this.masterGain.connect(this.audioContext.destination);
            this.masterGain.gain.value = 0.8;
        } catch (e) {
            console.error('Web Audio API not supported:', e);
            this.audioContext = null;
            this.masterGain = null;
        }

        this.accentLevel = 0.5;
        this.activeOscillators = new Map();
        this.openHiHatSource = null;

        this.instruments = {
            'BD': this.createBassDrum.bind(this),
            'SD': this.createSnareDrum.bind(this),
            'LC': this.createLowConga.bind(this),
            'LT': this.createLowTom.bind(this),
            'MC': this.createMidConga.bind(this),
            'MT': this.createMidTom.bind(this),
            'HC': this.createHiConga.bind(this),
            'HT': this.createHiTom.bind(this),
            'CL': this.createClaves.bind(this),
            'RS': this.createRimShot.bind(this),
            'MA': this.createMaracas.bind(this),
            'CP': this.createHandClap.bind(this),
            'CB': this.createCowBell.bind(this),
            'CY': this.createCymbal.bind(this),
            'OH': this.createOpenHiHat.bind(this),
            'CH': this.createClosedHiHat.bind(this)
        };
    }

    playInstrument(instrumentName, params = {}, withAccent = false) {
        if (!this.audioContext || !this.instruments[instrumentName]) {
            return false;
        }

        const instrument = this.instruments[instrumentName];
        const accentMultiplier = withAccent ? 1 + this.accentLevel : 1;
        
        try {
            instrument(params, accentMultiplier);
            return true;
        } catch (e) {
            console.error(`Error playing ${instrumentName}:`, e);
            return false;
        }
    }

    createBassDrum(params = {}, accentMultiplier = 1) {
        const { level = 80, tone = 50, decay = 50 } = params;
        const now = this.audioContext.currentTime;

        const osc = this.audioContext.createOscillator();
        const gain = this.audioContext.createGain();
        const filter = this.audioContext.createBiquadFilter();

        osc.type = 'sine';
        osc.frequency.setValueAtTime(60, now);
        osc.frequency.exponentialRampToValueAtTime(35, now + 0.1);

        filter.type = 'lowpass';
        filter.frequency.setValueAtTime(80 + (tone * 2), now);
        filter.Q.setValueAtTime(1, now);

        const finalLevel = (level / 100) * accentMultiplier * 0.8;
        gain.gain.setValueAtTime(finalLevel, now);
        
        const decayTime = 0.3 + (decay / 100) * 0.7;
        gain.gain.exponentialRampToValueAtTime(0.001, now + decayTime);

        osc.connect(filter);
        filter.connect(gain);
        gain.connect(this.masterGain);

        osc.start(now);
        osc.stop(now + decayTime + 0.1);
    }

    createSnareDrum(params = {}, accentMultiplier = 1) {
        const { level = 80, tone = 50, snappy = 50 } = params;
        const now = this.audioContext.currentTime;

        const buffer = this.createNoiseBuffer(0.2);
        const source = this.audioContext.createBufferSource();
        const gain = this.audioContext.createGain();
        const filter = this.audioContext.createBiquadFilter();

        source.buffer = buffer;

        filter.type = 'bandpass';
        filter.frequency.setValueAtTime(200 + (tone * 6), now);
        filter.Q.setValueAtTime(1 + (snappy / 50), now);

        const finalLevel = (level / 100) * accentMultiplier * 0.6;
        gain.gain.setValueAtTime(finalLevel, now);
        gain.gain.exponentialRampToValueAtTime(0.001, now + 0.15);

        source.connect(filter);
        filter.connect(gain);
        gain.connect(this.masterGain);

        source.start(now);
        source.stop(now + 0.2);
    }

    createLowTom(params = {}, accentMultiplier = 1) {
        const { level = 80, tuning = 50 } = params;
        this.createTom(65 + (tuning * 0.8), level, accentMultiplier, 0.4);
    }

    createLowConga(params = {}, accentMultiplier = 1) {
        const { tuning = 50 } = params;
        this.createConga(120 + (tuning * 1.2), 80, accentMultiplier, 0.25);
    }

    createMidTom(params = {}, accentMultiplier = 1) {
        const { level = 80, tuning = 50 } = params;
        this.createTom(85 + (tuning * 1.0), level, accentMultiplier, 0.35);
    }

    createMidConga(params = {}, accentMultiplier = 1) {
        const { tuning = 50 } = params;
        this.createConga(160 + (tuning * 1.5), 80, accentMultiplier, 0.2);
    }

    createHiTom(params = {}, accentMultiplier = 1) {
        const { level = 80, tuning = 50 } = params;
        this.createTom(110 + (tuning * 1.2), level, accentMultiplier, 0.3);
    }

    createHiConga(params = {}, accentMultiplier = 1) {
        const { tuning = 50 } = params;
        this.createConga(200 + (tuning * 2.0), 80, accentMultiplier, 0.18);
    }

    createTom(frequency, level, accentMultiplier, duration) {
        const now = this.audioContext.currentTime;

        const osc = this.audioContext.createOscillator();
        const gain = this.audioContext.createGain();
        const filter = this.audioContext.createBiquadFilter();

        osc.type = 'sine';
        osc.frequency.setValueAtTime(frequency, now);
        osc.frequency.exponentialRampToValueAtTime(frequency * 0.5, now + duration);

        filter.type = 'lowpass';
        filter.frequency.setValueAtTime(frequency * 4, now);
        filter.Q.setValueAtTime(2, now);

        const finalLevel = (level / 100) * accentMultiplier * 0.7;
        gain.gain.setValueAtTime(finalLevel, now);
        gain.gain.exponentialRampToValueAtTime(0.001, now + duration);

        osc.connect(filter);
        filter.connect(gain);
        gain.connect(this.masterGain);

        osc.start(now);
        osc.stop(now + duration + 0.1);
    }

    createConga(frequency, level, accentMultiplier, duration) {
        const now = this.audioContext.currentTime;

        const osc1 = this.audioContext.createOscillator();
        const osc2 = this.audioContext.createOscillator();
        const gain = this.audioContext.createGain();
        const filter = this.audioContext.createBiquadFilter();

        osc1.type = 'sine';
        osc1.frequency.setValueAtTime(frequency, now);
        osc1.frequency.exponentialRampToValueAtTime(frequency * 0.7, now + duration);

        osc2.type = 'square';
        osc2.frequency.setValueAtTime(frequency * 1.5, now);
        osc2.frequency.exponentialRampToValueAtTime(frequency * 0.8, now + duration);

        const osc2Gain = this.audioContext.createGain();
        osc2Gain.gain.setValueAtTime(0.3, now);

        filter.type = 'bandpass';
        filter.frequency.setValueAtTime(frequency * 2, now);
        filter.Q.setValueAtTime(3, now);

        const finalLevel = (level / 100) * accentMultiplier * 0.6;
        gain.gain.setValueAtTime(finalLevel, now);
        gain.gain.exponentialRampToValueAtTime(0.001, now + duration);

        osc1.connect(filter);
        osc2.connect(osc2Gain);
        osc2Gain.connect(filter);
        filter.connect(gain);
        gain.connect(this.masterGain);

        osc1.start(now);
        osc2.start(now);
        osc1.stop(now + duration + 0.1);
        osc2.stop(now + duration + 0.1);
    }

    createClaves(params = {}, accentMultiplier = 1) {
        const now = this.audioContext.currentTime;

        const osc = this.audioContext.createOscillator();
        const gain = this.audioContext.createGain();
        const filter = this.audioContext.createBiquadFilter();

        osc.type = 'square';
        osc.frequency.setValueAtTime(2500, now);

        filter.type = 'highpass';
        filter.frequency.setValueAtTime(1000, now);
        filter.Q.setValueAtTime(0.5, now);

        const finalLevel = 0.8 * accentMultiplier * 0.4;
        gain.gain.setValueAtTime(finalLevel, now);
        gain.gain.exponentialRampToValueAtTime(0.001, now + 0.05);

        osc.connect(filter);
        filter.connect(gain);
        gain.connect(this.masterGain);

        osc.start(now);
        osc.stop(now + 0.1);
    }

    createRimShot(params = {}, accentMultiplier = 1) {
        const { level = 80 } = params;
        const now = this.audioContext.currentTime;

        const buffer = this.createNoiseBuffer(0.1);
        const source = this.audioContext.createBufferSource();
        const gain = this.audioContext.createGain();
        const filter = this.audioContext.createBiquadFilter();

        source.buffer = buffer;

        filter.type = 'highpass';
        filter.frequency.setValueAtTime(800, now);
        filter.Q.setValueAtTime(1, now);

        const finalLevel = (level / 100) * accentMultiplier * 0.5;
        gain.gain.setValueAtTime(finalLevel, now);
        gain.gain.exponentialRampToValueAtTime(0.001, now + 0.08);

        source.connect(filter);
        filter.connect(gain);
        gain.connect(this.masterGain);

        source.start(now);
        source.stop(now + 0.1);
    }

    createMaracas(params = {}, accentMultiplier = 1) {
        const now = this.audioContext.currentTime;

        const buffer = this.createNoiseBuffer(0.15);
        const source = this.audioContext.createBufferSource();
        const gain = this.audioContext.createGain();
        const filter = this.audioContext.createBiquadFilter();

        source.buffer = buffer;

        filter.type = 'highpass';
        filter.frequency.setValueAtTime(6000, now);
        filter.Q.setValueAtTime(0.8, now);

        const finalLevel = 0.8 * accentMultiplier * 0.3;
        gain.gain.setValueAtTime(finalLevel, now);
        gain.gain.exponentialRampToValueAtTime(0.001, now + 0.12);

        source.connect(filter);
        filter.connect(gain);
        gain.connect(this.masterGain);

        source.start(now);
        source.stop(now + 0.15);
    }

    createHandClap(params = {}, accentMultiplier = 1) {
        const { level = 80 } = params;
        const now = this.audioContext.currentTime;

        for (let i = 0; i < 3; i++) {
            const delay = i * 0.01;
            const buffer = this.createNoiseBuffer(0.1);
            const source = this.audioContext.createBufferSource();
            const gain = this.audioContext.createGain();
            const filter = this.audioContext.createBiquadFilter();

            source.buffer = buffer;

            filter.type = 'bandpass';
            filter.frequency.setValueAtTime(1000, now + delay);
            filter.Q.setValueAtTime(5, now + delay);

            const finalLevel = (level / 100) * accentMultiplier * 0.4 * (1 - i * 0.2);
            gain.gain.setValueAtTime(finalLevel, now + delay);
            gain.gain.exponentialRampToValueAtTime(0.001, now + delay + 0.08);

            source.connect(filter);
            filter.connect(gain);
            gain.connect(this.masterGain);

            source.start(now + delay);
            source.stop(now + delay + 0.1);
        }
    }

    createCowBell(params = {}, accentMultiplier = 1) {
        const { level = 80 } = params;
        const now = this.audioContext.currentTime;

        const osc1 = this.audioContext.createOscillator();
        const osc2 = this.audioContext.createOscillator();
        const gain = this.audioContext.createGain();

        osc1.type = 'square';
        osc1.frequency.setValueAtTime(800, now);

        osc2.type = 'square';
        osc2.frequency.setValueAtTime(540, now);

        const osc2Gain = this.audioContext.createGain();
        osc2Gain.gain.setValueAtTime(0.7, now);

        const finalLevel = (level / 100) * accentMultiplier * 0.6;
        gain.gain.setValueAtTime(finalLevel, now);
        gain.gain.exponentialRampToValueAtTime(0.001, now + 0.3);

        osc1.connect(gain);
        osc2.connect(osc2Gain);
        osc2Gain.connect(gain);
        gain.connect(this.masterGain);

        osc1.start(now);
        osc2.start(now);
        osc1.stop(now + 0.35);
        osc2.stop(now + 0.35);
    }

    createCymbal(params = {}, accentMultiplier = 1) {
        const { level = 80, tone = 50, decay = 50 } = params;
        const now = this.audioContext.currentTime;

        const buffer = this.createNoiseBuffer(2.0);
        const source = this.audioContext.createBufferSource();
        const gain = this.audioContext.createGain();
        const filter = this.audioContext.createBiquadFilter();

        source.buffer = buffer;

        filter.type = 'bandpass';
        filter.frequency.setValueAtTime(8000 + (tone * 40), now);
        filter.Q.setValueAtTime(0.3, now);

        const finalLevel = (level / 100) * accentMultiplier * 0.5;
        const decayTime = 0.5 + (decay / 100) * 1.5;
        
        gain.gain.setValueAtTime(finalLevel, now);
        gain.gain.exponentialRampToValueAtTime(0.001, now + decayTime);

        source.connect(filter);
        filter.connect(gain);
        gain.connect(this.masterGain);

        source.start(now);
        source.stop(now + decayTime + 0.1);
    }

    createOpenHiHat(params = {}, accentMultiplier = 1) {
        const { level = 80, decay = 50 } = params;
        const now = this.audioContext.currentTime;

        if (this.openHiHatSource) {
            this.openHiHatSource.stop(now);
        }

        const buffer = this.createNoiseBuffer(1.0);
        const source = this.audioContext.createBufferSource();
        const gain = this.audioContext.createGain();
        const filter = this.audioContext.createBiquadFilter();

        source.buffer = buffer;
        this.openHiHatSource = source;

        filter.type = 'highpass';
        filter.frequency.setValueAtTime(7000, now);
        filter.Q.setValueAtTime(1, now);

        const finalLevel = (level / 100) * accentMultiplier * 0.4;
        const decayTime = 0.2 + (decay / 100) * 0.8;
        
        gain.gain.setValueAtTime(finalLevel, now);
        gain.gain.exponentialRampToValueAtTime(0.001, now + decayTime);

        source.connect(filter);
        filter.connect(gain);
        gain.connect(this.masterGain);

        source.start(now);
        source.stop(now + decayTime + 0.1);

        source.onended = () => {
            if (this.openHiHatSource === source) {
                this.openHiHatSource = null;
            }
        };
    }

    createClosedHiHat(params = {}, accentMultiplier = 1) {
        const { level = 80 } = params;
        const now = this.audioContext.currentTime;

        if (this.openHiHatSource) {
            this.openHiHatSource.stop(now);
            this.openHiHatSource = null;
        }

        const buffer = this.createNoiseBuffer(0.1);
        const source = this.audioContext.createBufferSource();
        const gain = this.audioContext.createGain();
        const filter = this.audioContext.createBiquadFilter();

        source.buffer = buffer;

        filter.type = 'highpass';
        filter.frequency.setValueAtTime(9000, now);
        filter.Q.setValueAtTime(1, now);

        const finalLevel = (level / 100) * accentMultiplier * 0.3;
        gain.gain.setValueAtTime(finalLevel, now);
        gain.gain.exponentialRampToValueAtTime(0.001, now + 0.08);

        source.connect(filter);
        filter.connect(gain);
        gain.connect(this.masterGain);

        source.start(now);
        source.stop(now + 0.1);
    }

    createNoiseBuffer(duration) {
        const sampleRate = this.audioContext.sampleRate;
        const buffer = this.audioContext.createBuffer(1, sampleRate * duration, sampleRate);
        const data = buffer.getChannelData(0);

        for (let i = 0; i < data.length; i++) {
            data[i] = Math.random() * 2 - 1;
        }

        return buffer;
    }

    setMasterVolume(volume) {
        if (this.masterGain) {
            this.masterGain.gain.value = volume / 100;
        }
    }

    setAccent(level) {
        this.accentLevel = level / 100;
    }
}

if (typeof module !== 'undefined' && module.exports) {
    module.exports = TR808;
}

if (typeof window !== 'undefined') {
    window.TR808 = TR808;
}