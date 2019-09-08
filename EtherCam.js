const five = require('johnny-five');
const raspi = require('raspi-io');
const RaspiCam = require('raspicam');

const Cleanup = require('./utils/cleanup');
const { p } = require('./utils/pins');
const shutdown = require('./utils/shutdown');

const Modes = {
  INTRO: 'INTRO',
  CAMERA: 'CAMERA',
};

const greetings = {
  [Modes.INTRO]: ['* * EtherCam * *', ' Press for info'],
  [Modes.CAMERA]: ['Take a picture', 'Hold for info.'],
};

module.exports = class EtherCam {
  constructor() {
    this.mode = Modes.INTRO;
    this.switchingModes = false;
    this.lcdWidth = 16;
    this.currentIntroStep = 0;
    this.pictureTakenTimer = 0;
    this.buttonDown = 0;

    this.clearLcd = this.clearLcd.bind(this);
    this.exit = this.exit.bind(this);
    this.greet = this.greet.bind(this);
    this.handleButtonDown = this.handleButtonDown.bind(this);
    this.handleButtonHold = this.handleButtonHold.bind(this);
    this.handleButtonRelease = this.handleButtonRelease.bind(this);
    this.handleSavePhoto = this.handleSavePhoto.bind(this);
    this.playIntro = this.playIntro.bind(this);
    this.printLcd = this.printLcd.bind(this);
    this.setupHardware = this.setupHardware.bind(this);
    this.start = this.start.bind(this);
    this.startListeners = this.startListeners.bind(this);
    this.takePhoto = this.takePhoto.bind(this);
    this.toggleMode = this.toggleMode.bind(this);
    this.trimAndFill = this.trimAndFill.bind(this);

    this.cleanup = Cleanup(this.exit);
  }

  clearLcd() {
    this.lcd.clear();
  }

  exit() {
    this.camera.stop();
    this.clearLcd();
    this.led.off();
    this.lcd.off().noBacklight();
  }

  greet() {
    this.printLcd(...greetings[this.mode]);
  }

  handleButtonDown() {
    clearTimeout(this.pictureTakenTimer);
    this.buttonDown = new Date().getTime()
  }

  handleButtonHold() {
    this.switchingModes = true;
    this.toggleMode();
  }

  handleButtonRelease() {
    if (new Date().getTime() - this.buttonDown > 10000) {
      return shutdown();
    }

    if (this.switchingModes) {
      return this.switchingModes = false;
    }

    if (this.mode === Modes.INTRO) {
      return this.playIntro();
    }

    if (this.mode === Modes.CAMERA) {
      return this.takePhoto();
    }
  }

  handleSavePhoto(err, timestamp, filename) {
    this.camera.stop();
    this.led.off();

    if (err) {
      this.printLcd('Error taking photo', '');
    }

    this.printLcd('Photo posted. Thanks');
  };

  playIntro() {
    switch (this.currentIntroStep++) {
      case 0:
        this.printLcd('Click shutter to', 'cycle options');
        break;
      case 1:
        this.printLcd('Hold shutter to', 'switch modes');
        break;
      case 2:
        this.printLcd('  Have fun B-)  ', '   Be safe <3   ');
        break;
      case 3:
        this.toggleMode();
        break;
      default:
        return;
    }
  }

  printLcd(line1, line2) {
    if (line1) {
      this.lcd.cursor(0, 0).print(
        this.trimAndFill(line1.toString())
      );
    }
    if (line2) {
      this.lcd.cursor(1, 0).print(
        this.trimAndFill(line2.toString())
      );
    }
  };

  setupHardware() {
    this.button = new five.Button({
      holdtime: 1500,
      isPullup: true,
      pin: p(18),
    });
    this.camera = new RaspiCam({
      awb: 'auto',
      brightness: 55,
      encoding: 'jpg',
      exposure: 'auto',
      ISO: 800,
      mode: 'photo',
      output: 'eth-snap.jpg',
      sharpness: 20,
      timeout: 1,
    });
    this.lcd = new five.LCD({
      // LCD pin name  RS  EN  DB4 DB5 DB6 DBe/
      // Arduino pin # 7    8   9   10  11  12
      pins: [p(29), p(31), p(33), p(32), p(12), p(37)],
      backlight: 6,
      rows: 2,
      cols: 16,
    });
    this.led = new five.Led(p(13));
  }

  start() {
    this.board = new five.Board({
      debug: false,
      io: new raspi(),
      repl: false,
    });

    this.board.on('ready', () => {
      this.setupHardware();
      this.startListeners();
      this.greet();
    });
  }

  startListeners() {
    this.board.on('exit', this.exit);
    this.camera.on('read', this.handleSavePhoto);
    this.button.on('down', this.handleButtonDown);
    this.button.on('release', this.handleButtonRelease);
    this.button.on('hold', this.handleButtonHold);
  };

  takePhoto() {
    this.led.on();
    this.camera.start();
  }

  toggleMode() {
    switch (this.mode) {
      case Modes.INTRO:
        this.mode = Modes.CAMERA;
      case Modes.CAMERA:
        this.mode = Modes.INTRO;
        break;
      default:
        return;
    }

    this.greet();
  }

  trimAndFill(input, total = this.lcdWidth) {
    return input.length >= total
      ? input.slice(0, total)
      : input.concat(' '.repeat(total - input.length))
  }
};
