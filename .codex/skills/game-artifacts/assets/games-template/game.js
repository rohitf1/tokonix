import { zzfx, ZZFX } from "./zzfx.js";

const PALETTE = {
  backgroundTop: 0x05060b,
  backgroundBottom: 0x081634,
  horizonGlow: 0x1b6cff,
  roadDark: 0x0f1422,
  roadLight: 0x141c2f,
  rumbleDark: 0x18283f,
  rumbleLight: 0x223655,
  grassDark: 0x08151b,
  grassLight: 0x0b1a22,
  laneBright: 0x6ad6ff,
  laneDim: 0x3aa9ff,
  glow: 0x4cc3ff,
  magenta: 0xff4fd8,
  cyan: 0x74e4ff,
};

class NeonRacer extends Phaser.Scene {
  constructor() {
    super("neon-racer");
    this.segmentLength = 200;
    this.roadWidth = 2200;
    this.rumbleLength = 3;
    this.laneCount = 3;
    this.drawDistance = 180;
    this.cameraHeight = 1000;
    this.fov = 75;
    this.cameraDepth = 1 / Math.tan((this.fov * 0.5 * Math.PI) / 180);
    this.segments = [];
    this.position = 0;
    this.distance = 0;
    this.speed = 0;
    this.playerX = 0;
    this.maxSpeed = this.segmentLength * 70;
    this.boostSpeed = this.maxSpeed * 1.18;
    this.accel = this.maxSpeed * 0.55;
    this.brake = this.maxSpeed * 0.8;
    this.decel = this.maxSpeed * 0.35;
    this.offRoadDecel = this.maxSpeed * 0.85;
    this.steerSpeed = 2.4;
    this.boostEnergy = 1;
    this.boostDrain = 0.35;
    this.boostRecover = 0.18;
    this.engineTimer = 0;
    this.collisionTimer = 0;
    this.audioReady = false;
    this.wasBoosting = false;
    this.roadGraphics = null;
    this.glowGraphics = null;
    this.background = null;
    this.horizonGlow = null;
    this.horizonLine = null;
    this.sweep = null;
    this.car = null;
    this.carGlow = null;
    this.boostHalo = null;
    this.brakeLight = null;
    this.speedText = null;
    this.boostBarFill = null;
    this.boostBarWidth = 120;
    this.starEmitter = null;
    this.dustEmitter = null;
    this.speedEmitter = null;
    this.traffic = [];
    this.sfx = {
      unlock: [0.08, 0.01, 220, 0.01, 0.02, 0.04, 1, 0, 0, 0, 0, 0, 0.05],
      boost: [0.5, 0.02, 260, 0.01, 0.12, 0.2, 1, 0.6, -0.12, 0, 0, 0, 0.1],
      brake: [0.35, 0.02, 140, 0.01, 0.08, 0.2, 2, 0.1, -0.2, 0, 0, 0, 0.06],
      crash: [0.6, 0.02, 90, 0.01, 0.1, 0.35, 0, 1.6, -0.4, 0, 0, 0, 0.2],
    };
  }

  create() {
    ZZFX.volume = 0.24;
    this.createTextures();
    this.buildTrack();
    this.createBackground();
    this.createRoadGraphics();
    this.createCar();
    this.createHud();
    this.createParticles();
    this.createInput();
    this.createTraffic();
    this.layout();

    this.scale.on("resize", () => {
      this.layout();
    });
  }

  createTextures() {
    if (!this.textures.exists("star")) {
      const star = this.make.graphics({ x: 0, y: 0, add: false });
      star.fillStyle(0xffffff, 1);
      star.fillCircle(3, 3, 3);
      star.generateTexture("star", 6, 6);
      star.destroy();
    }

    if (!this.textures.exists("spark")) {
      const spark = this.make.graphics({ x: 0, y: 0, add: false });
      spark.fillStyle(0x74e4ff, 1);
      spark.fillCircle(4, 4, 4);
      spark.generateTexture("spark", 8, 8);
      spark.destroy();
    }

    if (!this.textures.exists("racer-car")) {
      const car = this.make.graphics({ x: 0, y: 0, add: false });
      car.fillStyle(0x10182b, 1);
      car.fillRoundedRect(10, 8, 44, 112, 16);
      car.lineStyle(2, 0x6bb4ff, 0.7);
      car.strokeRoundedRect(10, 8, 44, 112, 16);

      car.fillStyle(0x2d6fff, 0.95);
      car.fillRoundedRect(16, 18, 32, 76, 12);
      car.fillStyle(0x9be6ff, 0.6);
      car.fillRoundedRect(18, 24, 28, 38, 10);
      car.fillStyle(PALETTE.magenta, 0.7);
      car.fillRect(30, 20, 4, 74);

      car.fillStyle(0x0b1324, 1);
      car.fillRect(6, 22, 6, 24);
      car.fillRect(6, 76, 6, 26);
      car.fillRect(52, 22, 6, 24);
      car.fillRect(52, 76, 6, 26);

      car.fillStyle(PALETTE.cyan, 0.85);
      car.fillRect(18, 10, 28, 6);
      car.fillStyle(0xff5c5c, 0.85);
      car.fillRect(18, 112, 28, 6);

      car.generateTexture("racer-car", 64, 128);
      car.destroy();
    }

    if (!this.textures.exists("traffic-car")) {
      const car = this.make.graphics({ x: 0, y: 0, add: false });
      car.fillStyle(0x131c2f, 1);
      car.fillRoundedRect(9, 10, 38, 96, 14);
      car.lineStyle(2, 0x5fa6ff, 0.5);
      car.strokeRoundedRect(9, 10, 38, 96, 14);
      car.fillStyle(0x2460d8, 0.85);
      car.fillRoundedRect(14, 18, 28, 62, 10);
      car.fillStyle(0x7fd8ff, 0.5);
      car.fillRoundedRect(16, 24, 24, 30, 8);
      car.fillStyle(PALETTE.magenta, 0.6);
      car.fillRect(27, 20, 3, 66);
      car.fillStyle(0x0b1324, 1);
      car.fillRect(5, 26, 5, 20);
      car.fillRect(5, 70, 5, 20);
      car.fillRect(47, 26, 5, 20);
      car.fillRect(47, 70, 5, 20);
      car.fillStyle(0xff5c5c, 0.7);
      car.fillRect(16, 100, 24, 5);
      car.generateTexture("traffic-car", 56, 112);
      car.destroy();
    }
  }

  createBackground() {
    if (!this.background) {
      this.background = this.add.graphics();
    }
    this.background.clear();
    this.background.fillGradientStyle(
      PALETTE.backgroundTop,
      PALETTE.backgroundTop,
      PALETTE.backgroundBottom,
      0x04070f,
      1
    );
    this.background.fillRect(0, 0, this.scale.width, this.scale.height);

    if (!this.horizonGlow) {
      this.horizonGlow = this.add.ellipse(0, 0, 600, 140, PALETTE.horizonGlow, 0.18);
      this.horizonGlow.setBlendMode(Phaser.BlendModes.ADD);
    }
    if (!this.horizonLine) {
      this.horizonLine = this.add.rectangle(0, 0, 420, 2, PALETTE.glow, 0.5);
      this.horizonLine.setBlendMode(Phaser.BlendModes.ADD);
    }
    if (!this.sweep) {
      this.sweep = this.add.rectangle(0, 0, 260, 8, PALETTE.glow, 0.18);
      this.sweep.setBlendMode(Phaser.BlendModes.ADD);
      this.tweens.add({
        targets: this.sweep,
        y: { from: 40, to: 220 },
        alpha: { from: 0.08, to: 0.22 },
        duration: 2400,
        yoyo: true,
        repeat: -1,
        ease: "Sine.inOut",
      });
    }
  }

  createRoadGraphics() {
    if (!this.roadGraphics) {
      this.roadGraphics = this.add.graphics();
      this.roadGraphics.setDepth(1);
    }
    if (!this.glowGraphics) {
      this.glowGraphics = this.add.graphics();
      this.glowGraphics.setDepth(2);
      this.glowGraphics.setBlendMode(Phaser.BlendModes.ADD);
    }
  }

  createCar() {
    if (this.car) {
      this.car.destroy();
    }

    const car = this.add.container(0, 0);
    const shadow = this.add.ellipse(0, 16, 96, 42, 0x0a1220, 0.45);
    const glow = this.add.ellipse(0, 12, 120, 52, PALETTE.cyan, 0.12);
    glow.setBlendMode(Phaser.BlendModes.ADD);
    const boostHalo = this.add.ellipse(0, 6, 140, 62, PALETTE.magenta, 0.08);
    boostHalo.setBlendMode(Phaser.BlendModes.ADD);

    const carSprite = this.add.image(0, 0, "racer-car").setOrigin(0.5, 1);
    carSprite.setScale(0.9);
    const brakeLight = this.add.rectangle(0, -10, 30, 6, 0xff5c5c, 0.35).setOrigin(0.5, 1);

    car.add([shadow, glow, boostHalo, carSprite, brakeLight]);
    car.setDepth(5);

    this.car = car;
    this.carGlow = glow;
    this.boostHalo = boostHalo;
    this.brakeLight = brakeLight;
  }

  createHud() {
    if (this.speedText) {
      this.speedText.destroy();
    }
    if (this.boostBarFill) {
      this.boostBarFill.destroy();
    }
    if (this.boostLabel) {
      this.boostLabel.destroy();
    }
    if (this.speedPanel) {
      this.speedPanel.destroy();
    }

    this.speedPanel = this.add.rectangle(0, 0, 240, 84, 0x0b1020, 0.68).setOrigin(1, 0);
    this.speedPanel.setStrokeStyle(1, PALETTE.glow, 0.32);

    this.speedText = this.add.text(0, 0, "0 km/h", {
      fontFamily: "Space Grotesk, Segoe UI, sans-serif",
      fontSize: "24px",
      color: "#e6f3ff",
    });

    this.boostLabel = this.add.text(0, 0, "BOOST", {
      fontFamily: "Space Grotesk, Segoe UI, sans-serif",
      fontSize: "12px",
      color: "#7fb8ff",
    });

    this.boostBarFill = this.add.rectangle(0, 0, this.boostBarWidth, 6, PALETTE.magenta, 0.75);
    this.boostBarFill.setOrigin(0, 0.5);
  }

  createParticles() {
    if (!this.starEmitter) {
      this.starEmitter = this.add.particles(0, 0, "star", {
        x: { min: 0, max: this.scale.width },
        y: { min: 0, max: this.scale.height * 0.6 },
        lifespan: { min: 6000, max: 9000 },
        speedY: { min: 8, max: 20 },
        scale: { start: 0.7, end: 0 },
        alpha: { start: 0.35, end: 0 },
        quantity: 2,
        blendMode: "ADD",
      });
      this.starEmitter.setDepth(0);
    }

    if (!this.dustEmitter) {
      this.dustEmitter = this.add.particles(0, 0, "spark", {
        x: { min: 0, max: this.scale.width },
        y: { min: this.scale.height * 0.2, max: this.scale.height },
        lifespan: { min: 2600, max: 4200 },
        speedY: { min: 40, max: 90 },
        scale: { start: 0.5, end: 0 },
        alpha: { start: 0.18, end: 0 },
        quantity: 1,
        blendMode: "ADD",
      });
      this.dustEmitter.setDepth(1);
    }

    if (!this.speedEmitter) {
      this.speedEmitter = this.add.particles(0, 0, "spark", {
        lifespan: { min: 380, max: 720 },
        speedY: { min: -220, max: -360 },
        speedX: { min: -40, max: 40 },
        scale: { start: 0.6, end: 0 },
        alpha: { start: 0.45, end: 0 },
        quantity: 2,
        blendMode: "ADD",
      });
      this.speedEmitter.startFollow(this.car, 0, 8);
      this.speedEmitter.setDepth(4);
    }
  }

  createInput() {
    this.cursors = this.input.keyboard.createCursorKeys();
    this.keys = this.input.keyboard.addKeys({
      w: "W",
      a: "A",
      s: "S",
      d: "D",
      space: "SPACE",
      shift: "SHIFT",
      r: "R",
    });

    const unlock = () => this.unlockAudio();
    this.input.once("pointerdown", unlock);
    this.input.keyboard.on("keydown", unlock);
  }

  createTraffic() {
    this.traffic.forEach((car) => car.container.destroy());
    this.traffic = [];

    for (let i = 0; i < 9; i += 1) {
      const lane = Phaser.Math.RND.pick([-0.7, 0, 0.7]);
      const z = Phaser.Math.Between(8, this.drawDistance - 12) * this.segmentLength;
      const speed = Phaser.Math.Between(0.45, 0.75) * this.maxSpeed;
      const container = this.buildTrafficCar();
      container.setVisible(false);
      this.traffic.push({
        container,
        x: lane,
        z,
        speed,
        baseScale: Phaser.Math.FloatBetween(0.75, 0.95),
        point: { world: { x: 0, y: 0, z: 0 }, screen: {} },
      });
    }
  }

  buildTrafficCar() {
    const container = this.add.container(0, 0);
    const shadow = this.add.ellipse(0, 12, 80, 36, 0x0b1322, 0.55);
    const glow = this.add.ellipse(0, 8, 96, 42, PALETTE.glow, 0.18);
    glow.setBlendMode(Phaser.BlendModes.ADD);

    const carSprite = this.add.image(0, 0, "traffic-car").setOrigin(0.5, 1);
    carSprite.setScale(0.88);

    container.add([shadow, glow, carSprite]);
    container.setDepth(3);
    return container;
  }

  buildTrack() {
    this.segments = [];
    const addSegment = (curve) => {
      const index = this.segments.length;
      const segment = {
        index,
        curve,
        p1: { world: { x: 0, y: 0, z: index * this.segmentLength }, screen: {} },
        p2: { world: { x: 0, y: 0, z: (index + 1) * this.segmentLength }, screen: {} },
        color:
          Math.floor(index / this.rumbleLength) % 2 === 0
            ? {
                road: PALETTE.roadLight,
                rumble: PALETTE.rumbleLight,
                grass: PALETTE.grassLight,
                lane: PALETTE.laneBright,
              }
            : {
                road: PALETTE.roadDark,
                rumble: PALETTE.rumbleDark,
                grass: PALETTE.grassDark,
                lane: PALETTE.laneDim,
              },
        x: 0,
        dx: 0,
      };
      this.segments.push(segment);
    };

    const addStraight = (count) => {
      for (let i = 0; i < count; i += 1) {
        addSegment(0);
      }
    };

    const addCurve = (count, curve) => {
      for (let i = 0; i < count; i += 1) {
        addSegment(curve);
      }
    };

    const addSine = (count, curve) => {
      for (let i = 0; i < count; i += 1) {
        addSegment(curve * Math.sin((i / count) * Math.PI));
      }
    };

    addStraight(30);
    addSine(40, 0.8);
    addStraight(24);
    addSine(50, -1.0);
    addStraight(30);
    addSine(40, 0.9);
    addStraight(26);
    addCurve(30, -0.6);
    addStraight(36);
    addSine(42, 0.7);
    addStraight(22);
    addCurve(28, -0.8);
    addStraight(36);

    this.trackLength = this.segments.length * this.segmentLength;
  }

  layout() {
    this.createBackground();

    const { width, height } = this.scale;
    if (this.horizonGlow) {
      this.horizonGlow.setPosition(width / 2, height * 0.26);
      this.horizonGlow.setSize(width * 0.7, height * 0.18);
    }
    if (this.horizonLine) {
      this.horizonLine.setPosition(width / 2, height * 0.3);
      this.horizonLine.setSize(width * 0.5, 2);
    }
    if (this.sweep) {
      this.sweep.setPosition(width / 2, height * 0.18);
    }

    if (this.car) {
      this.car.setPosition(width / 2, height * 0.82);
    }

    if (this.speedPanel) {
      this.speedPanel.setPosition(width - 24, 20);
    }
    if (this.speedText) {
      this.speedText.setPosition(width - 48, 30);
      this.speedText.setOrigin(1, 0);
    }
    if (this.boostLabel) {
      this.boostLabel.setPosition(width - 180, 64);
    }
    if (this.boostBarFill) {
      this.boostBarFill.setPosition(width - 180, 86);
    }
  }

  unlockAudio() {
    if (this.audioReady) {
      return;
    }
    this.audioReady = true;
    zzfx(...this.sfx.unlock);
  }

  playSfx(preset) {
    if (!this.audioReady) {
      return;
    }
    zzfx(...preset);
  }

  playEngine(speedFactor) {
    if (!this.audioReady) {
      return;
    }
    const pitch = Phaser.Math.Linear(140, 260, speedFactor);
    zzfx(0.18, 0.01, pitch, 0.02, 0.05, 0.08, 2, 0.2, 0.02, 0, 0, 0, 0.1);
  }

  project(point, cameraX, cameraY, cameraZ) {
    const dz = point.world.z - cameraZ;
    if (dz <= 0) {
      point.screen.scale = 0;
      return;
    }
    const scale = this.cameraDepth / dz;
    point.screen.scale = scale;
    point.screen.x = Math.round(this.scale.width * 0.5 + scale * (point.world.x - cameraX) * this.scale.width * 0.5);
    point.screen.y = Math.round(this.scale.height * 0.5 - scale * (point.world.y - cameraY) * this.scale.height * 0.5);
    point.screen.w = scale * this.roadWidth * this.scale.width * 0.5;
  }

  drawQuad(graphics, color, x1, y1, w1, x2, y2, w2) {
    graphics.fillStyle(color, 1);
    graphics.beginPath();
    graphics.moveTo(x1 - w1, y1);
    graphics.lineTo(x2 - w2, y2);
    graphics.lineTo(x2 + w2, y2);
    graphics.lineTo(x1 + w1, y1);
    graphics.closePath();
    graphics.fillPath();
  }

  renderRoad() {
    const baseSegment = this.findSegment(this.position);
    const baseIndex = baseSegment.index;
    const basePercent = (this.position % this.segmentLength) / this.segmentLength;
    const cameraY = this.cameraHeight + this.speed * 0.02;
    const segments = [];
    let x = 0;
    let dx = -baseSegment.curve * basePercent;

    for (let n = 0; n < this.drawDistance; n += 1) {
      const segment = this.segments[(baseIndex + n) % this.segments.length];
      const looped = segment.index < baseIndex;
      const cameraZ = this.position - (looped ? this.trackLength : 0);
      segment.x = x;
      segment.dx = dx;
      const cameraX1 = this.playerX * this.roadWidth - x;
      const cameraX2 = this.playerX * this.roadWidth - (x + dx);
      this.project(segment.p1, cameraX1, cameraY, cameraZ);
      this.project(segment.p2, cameraX2, cameraY, cameraZ);
      x += dx;
      dx += segment.curve;
      segments.push(segment);
    }

    this.roadGraphics.clear();
    this.glowGraphics.clear();

    let maxY = this.scale.height;
    for (let i = 0; i < segments.length; i += 1) {
      const segment = segments[i];
      const { p1, p2, color } = segment;
      if (p1.screen.scale <= 0 || p2.screen.scale <= 0) {
        continue;
      }
      if (p1.screen.y >= maxY) {
        continue;
      }

      const roadW1 = p1.screen.w;
      const roadW2 = p2.screen.w;
      const rumbleW1 = roadW1 * 1.14;
      const rumbleW2 = roadW2 * 1.14;
      const grassW1 = roadW1 * 2.6;
      const grassW2 = roadW2 * 2.6;

      this.drawQuad(this.roadGraphics, color.grass, p1.screen.x, p1.screen.y, grassW1, p2.screen.x, p2.screen.y, grassW2);
      this.drawQuad(this.roadGraphics, color.rumble, p1.screen.x, p1.screen.y, rumbleW1, p2.screen.x, p2.screen.y, rumbleW2);
      this.drawQuad(this.roadGraphics, color.road, p1.screen.x, p1.screen.y, roadW1, p2.screen.x, p2.screen.y, roadW2);

      if (Math.floor(segment.index / 2) % 2 === 0) {
        const laneWidth1 = roadW1 / this.laneCount;
        const laneWidth2 = roadW2 / this.laneCount;
        for (let lane = 1; lane < this.laneCount; lane += 1) {
          const laneX1 = p1.screen.x - roadW1 + laneWidth1 * lane * 2;
          const laneX2 = p2.screen.x - roadW2 + laneWidth2 * lane * 2;
          this.drawQuad(this.roadGraphics, color.lane, laneX1, p1.screen.y, 1.5, laneX2, p2.screen.y, 1.2);
        }
      }

      if (i < 30) {
        this.drawQuad(
          this.glowGraphics,
          PALETTE.glow,
          p1.screen.x,
          p1.screen.y,
          roadW1 * 0.58,
          p2.screen.x,
          p2.screen.y,
          roadW2 * 0.58
        );
      }

      maxY = p1.screen.y;
    }
  }

  findSegment(z) {
    return this.segments[Math.floor(z / this.segmentLength) % this.segments.length];
  }

  updateTraffic(delta) {
    const dt = delta / 1000;
    const cameraY = this.cameraHeight + this.speed * 0.02;

    this.traffic.forEach((car) => {
      car.z = (car.z + car.speed * dt) % this.trackLength;
      let dz = car.z - this.position;
      if (dz < 0) {
        dz += this.trackLength;
      }

      if (dz > this.drawDistance * this.segmentLength) {
        car.container.setVisible(false);
        return;
      }

      const segment = this.findSegment(car.z);
      const percent = (car.z % this.segmentLength) / this.segmentLength;
      const roadOffset = segment.x + segment.dx * percent;
      car.point.world.x = car.x * this.roadWidth;
      car.point.world.y = 0;
      car.point.world.z = car.z;

      const looped = car.z < this.position;
      const cameraZ = this.position - (looped ? this.trackLength : 0);
      const cameraX = this.playerX * this.roadWidth - roadOffset;
      this.project(car.point, cameraX, cameraY, cameraZ);

      if (car.point.screen.scale <= 0) {
        car.container.setVisible(false);
        return;
      }

      car.container.setVisible(true);
      car.container.setPosition(car.point.screen.x, car.point.screen.y);
      car.container.setScale(car.point.screen.scale * car.baseScale);
      car.container.setDepth(car.point.screen.y);

      if (dz < this.segmentLength * 1.2 && Math.abs(car.x - this.playerX) < 0.18) {
        if (this.collisionTimer <= 0) {
          this.collisionTimer = 0.6;
          this.speed = Math.max(this.speed * 0.4, this.maxSpeed * 0.2);
          this.playSfx(this.sfx.crash);
        }
      }
    });
  }

  resetRace() {
    this.position = 0;
    this.speed = 0;
    this.playerX = 0;
    this.boostEnergy = 1;
    this.wasBoosting = false;
    this.createTraffic();
  }

  update(time, delta) {
    const dt = Math.min(delta / 1000, 0.034);
    const left = this.cursors.left.isDown || this.keys.a.isDown;
    const right = this.cursors.right.isDown || this.keys.d.isDown;
    const accel = this.cursors.up.isDown || this.keys.w.isDown;
    const brake = this.cursors.down.isDown || this.keys.s.isDown;
    const boost = this.keys.space.isDown || this.keys.shift.isDown;

    if (Phaser.Input.Keyboard.JustDown(this.keys.r)) {
      this.resetRace();
      this.playSfx(this.sfx.brake);
    }

    if (accel) {
      this.speed += this.accel * dt;
    } else {
      this.speed -= this.decel * dt;
    }

    if (brake) {
      this.speed -= this.brake * dt;
    }

    const boosting = boost && this.boostEnergy > 0.08;
    if (boosting) {
      this.speed += this.accel * 0.35 * dt;
      this.boostEnergy = Math.max(0, this.boostEnergy - this.boostDrain * dt);
    } else {
      this.boostEnergy = Math.min(1, this.boostEnergy + this.boostRecover * dt);
    }

    if (boosting && !this.wasBoosting) {
      this.playSfx(this.sfx.boost);
    }
    this.wasBoosting = boosting;

    this.speed = Phaser.Math.Clamp(this.speed, 0, boosting ? this.boostSpeed : this.maxSpeed);

    const speedFactor = Phaser.Math.Clamp(this.speed / this.maxSpeed, 0, 1);
    const steer = (left ? -1 : 0) + (right ? 1 : 0);
    this.playerX += steer * this.steerSpeed * dt * (0.6 + speedFactor);
    this.playerX = Phaser.Math.Clamp(this.playerX, -1.3, 1.3);

    if (Math.abs(this.playerX) > 1.02) {
      this.speed -= this.offRoadDecel * dt;
    }

    this.speed = Phaser.Math.Clamp(this.speed, 0, this.boostSpeed);
    this.position = (this.position + this.speed * dt) % this.trackLength;
    this.distance += this.speed * dt;

    this.engineTimer += dt;
    const engineInterval = Phaser.Math.Linear(0.26, 0.08, speedFactor);
    if (this.engineTimer > engineInterval && this.speed > this.maxSpeed * 0.12) {
      this.playEngine(speedFactor);
      this.engineTimer = 0;
    }

    if (this.collisionTimer > 0) {
      this.collisionTimer -= dt;
    }

    this.renderRoad();
    this.updateTraffic(delta);

    const bounce = Math.sin(time * 0.002) * 2.2;
    this.car.setPosition(this.scale.width / 2, this.scale.height * 0.82 + bounce);
    this.car.setRotation(steer * 0.12);
    this.carGlow.setAlpha(Phaser.Math.Linear(0.12, 0.32, speedFactor));
    this.boostHalo.setAlpha(boosting ? 0.2 + 0.2 * speedFactor : 0.08);
    this.brakeLight.setAlpha(brake ? 0.85 : 0.35);

    if (this.speedEmitter) {
      this.speedEmitter.speedY = -220 - speedFactor * 220;
      this.speedEmitter.setAlpha(0.2 + speedFactor * 0.4);
    }

    const speedKmh = Math.round(Phaser.Math.Linear(0, 320, speedFactor));
    this.speedText.setText(`${speedKmh} km/h`);
    this.boostBarFill.setDisplaySize(this.boostBarWidth * this.boostEnergy, 6);

    if (this.horizonGlow) {
      this.horizonGlow.setAlpha(0.12 + speedFactor * 0.2);
    }
  }
}

const config = {
  type: Phaser.AUTO,
  parent: "game-root",
  width: 960,
  height: 720,
  backgroundColor: "#05060b",
  scene: NeonRacer,
  scale: {
    mode: Phaser.Scale.RESIZE,
    autoCenter: Phaser.Scale.CENTER_BOTH,
  },
};

new Phaser.Game(config);
