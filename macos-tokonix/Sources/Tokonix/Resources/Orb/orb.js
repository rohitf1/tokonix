(() => {
  const paletteHex = {
    idle: ["#55e7ff", "#3d8bff", "#ff4fd8"],
    listening: ["#7af7ff", "#5bb7ff", "#ff5cf4"],
    busy: ["#3ee6ff", "#4a78ff", "#ff3fbf"],
    speaking: ["#66f2ff", "#6a4cff", "#ff7bff"]
  };

  const state = { mode: "idle", hover: false, level: 0, silence: 0, enabled: true };
  let smoothedLevel = 0;

  const paletteToColors = (palette) => palette.map((hex) => new THREE.Color(hex));
  const rand = (min, max) => min + Math.random() * (max - min);
  const baseScale = 0.8;

  const current = {
    colors: paletteToColors(paletteHex.idle),
    intensity: 1.0,
    spin: 1.0,
    freqBoost: 1.0
  };

  const target = {
    colors: paletteToColors(paletteHex.idle),
    intensity: 1.0,
    spin: 1.0,
    freqBoost: 1.0
  };

  window.setOrbState = (next) => {
    if (!next) return;
    if (next.mode) state.mode = next.mode;
    state.hover = Boolean(next.hover);
    if (typeof next.enabled === "boolean") {
      state.enabled = next.enabled;
    }
    if (typeof next.level === "number" && Number.isFinite(next.level)) {
      state.level = Math.max(0, Math.min(1, next.level));
    }
    if (typeof next.silence === "number" && Number.isFinite(next.silence)) {
      state.silence = Math.max(0, Math.min(1, next.silence));
    }
    const palette = paletteHex[state.mode] || paletteHex.idle;
    target.colors = paletteToColors(palette);

    const baseIntensity =
      state.mode === "listening" ? 1.02 :
      state.mode === "busy" ? 1.18 :
      state.mode === "speaking" ? 1.12 :
      1.0;

    target.intensity = baseIntensity + (state.hover ? 0.12 : 0.0);

    target.spin =
      state.mode === "listening" ? 1.08 :
      state.mode === "busy" ? 3.4 :
      state.mode === "speaking" ? 1.15 :
      1.0;

    target.freqBoost =
      state.mode === "listening" ? 1.05 :
      state.mode === "busy" ? 1.2 :
      state.mode === "speaking" ? 1.1 :
      1.0;
  };

  const scene = new THREE.Scene();
  const camera = new THREE.PerspectiveCamera(45, 1, 0.1, 20);
  camera.position.set(0, 0.1, 2.7);

  const renderer = new THREE.WebGLRenderer({
    alpha: true,
    antialias: true,
    premultipliedAlpha: false
  });
  renderer.setClearColor(0x000000, 0);
  renderer.setPixelRatio(Math.min(window.devicePixelRatio || 1, 2));
  renderer.outputColorSpace = THREE.SRGBColorSpace;
  document.body.appendChild(renderer.domElement);

  const group = new THREE.Group();
  scene.add(group);

  const noiseFunctions = `
    vec3 mod289(vec3 x) {
      return x - floor(x * (1.0 / 289.0)) * 289.0;
    }
    vec4 mod289(vec4 x) {
      return x - floor(x * (1.0 / 289.0)) * 289.0;
    }
    vec4 permute(vec4 x) {
      return mod289(((x * 34.0) + 10.0) * x);
    }
    vec4 taylorInvSqrt(vec4 r) {
      return 1.79284291400159 - 0.85373472095314 * r;
    }
    vec3 fade(vec3 t) {
      return t * t * t * (t * (t * 6.0 - 15.0) + 10.0);
    }
    float pnoise(vec3 P, vec3 rep) {
      vec3 Pi0 = mod(floor(P), rep);
      vec3 Pi1 = mod(Pi0 + vec3(1.0), rep);
      Pi0 = mod289(Pi0);
      Pi1 = mod289(Pi1);
      vec3 Pf0 = fract(P);
      vec3 Pf1 = Pf0 - vec3(1.0);
      vec4 ix = vec4(Pi0.x, Pi1.x, Pi0.x, Pi1.x);
      vec4 iy = vec4(Pi0.yy, Pi1.yy);
      vec4 iz0 = Pi0.zzzz;
      vec4 iz1 = Pi1.zzzz;

      vec4 ixy = permute(permute(ix) + iy);
      vec4 ixy0 = permute(ixy + iz0);
      vec4 ixy1 = permute(ixy + iz1);

      vec4 gx0 = ixy0 * (1.0 / 7.0);
      vec4 gy0 = fract(floor(gx0) * (1.0 / 7.0)) - 0.5;
      gx0 = fract(gx0);
      vec4 gz0 = vec4(0.5) - abs(gx0) - abs(gy0);
      vec4 sz0 = step(gz0, vec4(0.0));
      gx0 -= sz0 * (step(0.0, gx0) - 0.5);
      gy0 -= sz0 * (step(0.0, gy0) - 0.5);

      vec4 gx1 = ixy1 * (1.0 / 7.0);
      vec4 gy1 = fract(floor(gx1) * (1.0 / 7.0)) - 0.5;
      gx1 = fract(gx1);
      vec4 gz1 = vec4(0.5) - abs(gx1) - abs(gy1);
      vec4 sz1 = step(gz1, vec4(0.0));
      gx1 -= sz1 * (step(0.0, gx1) - 0.5);
      gy1 -= sz1 * (step(0.0, gy1) - 0.5);

      vec3 g000 = vec3(gx0.x, gy0.x, gz0.x);
      vec3 g100 = vec3(gx0.y, gy0.y, gz0.y);
      vec3 g010 = vec3(gx0.z, gy0.z, gz0.z);
      vec3 g110 = vec3(gx0.w, gy0.w, gz0.w);
      vec3 g001 = vec3(gx1.x, gy1.x, gz1.x);
      vec3 g101 = vec3(gx1.y, gy1.y, gz1.y);
      vec3 g011 = vec3(gx1.z, gy1.z, gz1.z);
      vec3 g111 = vec3(gx1.w, gy1.w, gz1.w);

      vec4 norm0 = taylorInvSqrt(vec4(dot(g000, g000), dot(g010, g010), dot(g100, g100), dot(g110, g110)));
      g000 *= norm0.x;
      g010 *= norm0.y;
      g100 *= norm0.z;
      g110 *= norm0.w;
      vec4 norm1 = taylorInvSqrt(vec4(dot(g001, g001), dot(g011, g011), dot(g101, g101), dot(g111, g111)));
      g001 *= norm1.x;
      g011 *= norm1.y;
      g101 *= norm1.z;
      g111 *= norm1.w;

      float n000 = dot(g000, Pf0);
      float n100 = dot(g100, vec3(Pf1.x, Pf0.yz));
      float n010 = dot(g010, vec3(Pf0.x, Pf1.y, Pf0.z));
      float n110 = dot(g110, vec3(Pf1.xy, Pf0.z));
      float n001 = dot(g001, vec3(Pf0.xy, Pf1.z));
      float n101 = dot(g101, vec3(Pf1.x, Pf0.y, Pf1.z));
      float n011 = dot(g011, vec3(Pf0.x, Pf1.yz));
      float n111 = dot(g111, Pf1);

      vec3 fade_xyz = fade(Pf0);
      vec4 n_z = mix(vec4(n000, n100, n010, n110), vec4(n001, n101, n011, n111), fade_xyz.z);
      vec2 n_yz = mix(n_z.xy, n_z.zw, fade_xyz.y);
      float n_xyz = mix(n_yz.x, n_yz.y, fade_xyz.x);
      return 2.2 * n_xyz;
    }
  `;

  const vertexShader = `
    ${noiseFunctions}
    uniform float u_time;
    uniform float u_frequency;
    uniform float u_intensity;
    varying float vNoise;
    varying vec3 vNormal;
    varying vec3 vPosition;

    void main() {
      vNormal = normal;
      float noise = 2.6 * pnoise(position * 1.7 + vec3(u_time * 0.45), vec3(10.0));
      float warp = 0.8 * pnoise(normal * 2.3 + vec3(u_time * 0.18), vec3(4.0));
      float freq = 0.35 + u_frequency * 1.6;
      float displacement = (noise * 0.12 + warp * 0.06) * freq * u_intensity;
      vec3 newPosition = position + normal * displacement;
      vNoise = noise;
      vPosition = newPosition;
      gl_Position = projectionMatrix * modelViewMatrix * vec4(newPosition, 1.0);
    }
  `;

  const fragmentWire = `
    uniform float u_time;
    uniform float u_frequency;
    uniform vec3 u_colorA;
    uniform vec3 u_colorB;
    uniform vec3 u_colorC;
    uniform float u_glow;
    uniform float u_listen;
    varying float vNoise;
    varying vec3 vNormal;
    varying vec3 vPosition;

    void main() {
      float fresnel = pow(1.0 - abs(dot(normalize(vNormal), vec3(0.0, 0.0, 1.0))), 1.4);
      float pulse = 0.65 + 0.35 * sin(u_time * 1.4 + vPosition.y * 6.0);
      float mixVal = clamp(vNoise * 0.5 + 0.5, 0.0, 1.0);
      vec3 color = mix(u_colorA, u_colorB, mixVal);
      color = mix(color, u_colorC, fresnel);
      vec3 rimColor = mix(u_colorA, u_colorC, 0.5);
      color += rimColor * fresnel * (0.25 + u_listen * 0.12);
      float alpha = (0.3 + fresnel * 0.6) * pulse * (0.6 + u_frequency * 0.6) * u_glow;
      alpha += u_listen * fresnel * 0.05;
      gl_FragColor = vec4(color * u_glow, alpha);
    }
  `;

  const fragmentSolid = `
    uniform float u_time;
    uniform float u_frequency;
    uniform vec3 u_colorA;
    uniform vec3 u_colorB;
    uniform vec3 u_colorC;
    uniform float u_glow;
    uniform float u_listen;
    varying float vNoise;
    varying vec3 vNormal;
    varying vec3 vPosition;

    void main() {
      float fresnel = pow(1.0 - abs(dot(normalize(vNormal), vec3(0.0, 0.0, 1.0))), 2.4);
      float core = smoothstep(0.7, 0.0, length(vPosition));
      float pulse = 0.6 + 0.4 * sin(u_time * 1.1 + vNoise * 2.0);
      vec3 color = mix(u_colorB, u_colorA, core);
      color = mix(color, u_colorC, fresnel);
      color += u_colorA * fresnel * u_listen * 0.12;
      float alpha = (0.35 + core * 0.45 + fresnel * 0.4) * pulse * (0.7 + u_frequency * 0.4) * u_glow;
      alpha *= 1.0 + u_listen * 0.08;
      gl_FragColor = vec4(color * u_glow, alpha);
    }
  `;

  const sharedUniforms = {
    u_time: { value: 0 },
    u_frequency: { value: 0 },
    u_intensity: { value: 1.0 },
    u_listen: { value: 0.0 },
    u_colorA: { value: current.colors[0].clone() },
    u_colorB: { value: current.colors[1].clone() },
    u_colorC: { value: current.colors[2].clone() }
  };

  const wireMaterial = new THREE.ShaderMaterial({
    uniforms: { ...sharedUniforms, u_glow: { value: 0.8 } },
    vertexShader,
    fragmentShader: fragmentWire,
    wireframe: true,
    transparent: true,
    blending: THREE.AdditiveBlending,
    depthWrite: false
  });

  const solidMaterial = new THREE.ShaderMaterial({
    uniforms: { ...sharedUniforms, u_glow: { value: 0.85 } },
    vertexShader,
    fragmentShader: fragmentSolid,
    transparent: true,
    blending: THREE.AdditiveBlending,
    depthWrite: false
  });

  const geometry = new THREE.IcosahedronGeometry(0.62, 24);
  const wireMesh = new THREE.Mesh(geometry, wireMaterial);
  const solidMesh = new THREE.Mesh(geometry, solidMaterial);
 
  group.add(solidMesh);
  group.add(wireMesh);

  const thinkingGroup = new THREE.Group();
  const thinkingRingRadius = 0.72;
  const thinkingGeometry = new THREE.TorusGeometry(thinkingRingRadius, 0.008, 10, 140);
  const thinkingMaterialA = new THREE.MeshBasicMaterial({
    color: current.colors[0],
    transparent: true,
    opacity: 0,
    blending: THREE.AdditiveBlending,
    depthWrite: false
  });
  const thinkingMaterialB = new THREE.MeshBasicMaterial({
    color: current.colors[2],
    transparent: true,
    opacity: 0,
    blending: THREE.AdditiveBlending,
    depthWrite: false
  });
  const ringA = new THREE.Mesh(thinkingGeometry, thinkingMaterialA);
  const ringB = new THREE.Mesh(thinkingGeometry, thinkingMaterialB);
  ringB.rotation.x = Math.PI / 2;
  const markerGeometry = new THREE.SphereGeometry(0.03, 16, 16);
  const markerMaterialA = new THREE.MeshBasicMaterial({
    color: current.colors[0],
    transparent: true,
    opacity: 0,
    blending: THREE.AdditiveBlending,
    depthWrite: false
  });
  const markerMaterialB = new THREE.MeshBasicMaterial({
    color: current.colors[2],
    transparent: true,
    opacity: 0,
    blending: THREE.AdditiveBlending,
    depthWrite: false
  });
  const markerA = new THREE.Mesh(markerGeometry, markerMaterialA);
  const markerB = new THREE.Mesh(markerGeometry, markerMaterialB);
  markerA.position.set(thinkingRingRadius, 0, 0);
  markerB.position.set(thinkingRingRadius, 0, 0);
  ringA.add(markerA);
  ringB.add(markerB);
  thinkingGroup.add(ringA);
  thinkingGroup.add(ringB);
  thinkingGroup.visible = false;
  group.add(thinkingGroup);

  const haloGroup = new THREE.Group();
  const haloRingRadius = 0.82;
  const haloArcInner = 0.8;
  const haloArcOuter = 0.82;
  const haloRingGeometry = new THREE.TorusGeometry(haloRingRadius, 0.006, 10, 180);
  const haloRingMaterial = new THREE.MeshBasicMaterial({
    color: current.colors[0],
    transparent: true,
    opacity: 0,
    blending: THREE.AdditiveBlending,
    depthWrite: false
  });
  const haloRing = new THREE.Mesh(haloRingGeometry, haloRingMaterial);
  const haloArcMaterial = new THREE.MeshBasicMaterial({
    color: current.colors[2],
    transparent: true,
    opacity: 0,
    blending: THREE.AdditiveBlending,
    side: THREE.DoubleSide,
    depthWrite: false
  });
  let haloArcGeometry = new THREE.RingGeometry(haloArcInner, haloArcOuter, 140, 1, -Math.PI / 2, Math.PI * 2);
  const haloArc = new THREE.Mesh(haloArcGeometry, haloArcMaterial);
  haloGroup.add(haloRing);
  haloGroup.add(haloArc);
  haloGroup.visible = false;
  group.add(haloGroup);
  let lastHaloProgress = -1;

  const dustCount = 850;
  const dustParticles = [];
  const dustGeometry = new THREE.DodecahedronGeometry(0.012, 0);
  const dustMaterial = new THREE.MeshBasicMaterial({
    color: current.colors[1],
    transparent: true,
    opacity: 0.32,
    blending: THREE.AdditiveBlending,
    depthWrite: false
  });
  const dustMesh = new THREE.InstancedMesh(dustGeometry, dustMaterial, dustCount);
  dustMesh.instanceMatrix.setUsage(THREE.DynamicDrawUsage);
  const dustDummy = new THREE.Object3D();
  for (let i = 0; i < dustCount; i += 1) {
    dustParticles.push({
      time: rand(0, 100),
      factor: rand(0.6, 1.4),
      speed: rand(0.003, 0.008),
      theta: rand(0, Math.PI * 2),
      phi: rand(0, Math.PI),
      radius: rand(0.85, 1.35),
      offset: rand(0.04, 0.12),
      scale: rand(0.5, 1.3)
    });
  }
  group.add(dustMesh);

  const lineGroup = new THREE.Group();
  const lineData = [];
  const lineCount = 9;
  for (let i = 0; i < lineCount; i += 1) {
    const radius = rand(0.65, 1.05);
    const points = [];
    for (let j = 0; j < 40; j += 1) {
      const angle = (j / 39) * Math.PI * 2.0;
      const variance = rand(0.7, 1.15);
      points.push(new THREE.Vector3(
        Math.sin(angle) * radius * variance,
        Math.cos(angle) * radius * variance,
        Math.sin(angle * 2.0) * radius * 0.22 * variance
      ));
    }
    const curvePoints = new THREE.CatmullRomCurve3(points).getPoints(260);
    const curveGeometry = new THREE.BufferGeometry().setFromPoints(curvePoints);
    const material = new THREE.LineDashedMaterial({
      color: current.colors[i % 3],
      transparent: true,
      opacity: 0.55,
      blending: THREE.AdditiveBlending,
      depthWrite: false,
      dashSize: 0.08,
      gapSize: 0.16
    });
    const line = new THREE.Line(curveGeometry, material);
    line.computeLineDistances();
    line.rotation.set(rand(-1.2, 1.2), rand(-1.2, 1.2), rand(-1.2, 1.2));
    lineGroup.add(line);
    lineData.push({ line, material, speed: rand(0.001, 0.004) });
  }
  group.add(lineGroup);

  const stormGroup = new THREE.Group();
  const stormLines = [];
  const stormLineCount = 12;
  const stormSegments = 70;
  const attractorStep = (pos, dt) => {
    const a = 10.0;
    const b = 28.0;
    const c = 2.667;
    const dx = a * (pos.y - pos.x);
    const dy = pos.x * (b - pos.z) - pos.y;
    const dz = pos.x * pos.y - c * pos.z;
    return new THREE.Vector3(
      pos.x + dx * dt,
      pos.y + dy * dt,
      pos.z + dz * dt
    );
  };

  const createStormLine = () => {
    const positions = new Float32Array(stormSegments * 3);
    let currentPos = new THREE.Vector3(rand(-1, 1), rand(-1, 1), rand(-1, 1));
    const scale = rand(0.7, 1.05);
    for (let i = 0; i < stormSegments; i += 1) {
      currentPos = attractorStep(currentPos, 0.006);
      const mapped = currentPos.clone().normalize().multiplyScalar(scale);
      positions[i * 3] = mapped.x;
      positions[i * 3 + 1] = mapped.y;
      positions[i * 3 + 2] = mapped.z;
    }
    const geometry = new THREE.BufferGeometry();
    geometry.setAttribute("position", new THREE.BufferAttribute(positions, 3));
    const material = new THREE.LineBasicMaterial({
      color: current.colors[2],
      transparent: true,
      opacity: 0.45,
      blending: THREE.AdditiveBlending,
      depthWrite: false
    });
    const line = new THREE.Line(geometry, material);
    stormGroup.add(line);
    return {
      line,
      material,
      positions,
      currentPos,
      scale,
      speed: rand(0.004, 0.008)
    };
  };

  for (let i = 0; i < stormLineCount; i += 1) {
    stormLines.push(createStormLine());
  }
  group.add(stormGroup);

  const sparkCount = 800;
  const sparkPositions = new Float32Array(sparkCount * 3);
  for (let i = 0; i < sparkCount; i += 1) {
    const u = Math.random();
    const v = Math.random();
    const theta = u * Math.PI * 2.0;
    const phi = Math.acos(2.0 * v - 1.0);
    const radius = 0.35 + Math.random() * 0.55;
    sparkPositions[i * 3] = radius * Math.sin(phi) * Math.cos(theta);
    sparkPositions[i * 3 + 1] = radius * Math.sin(phi) * Math.sin(theta);
    sparkPositions[i * 3 + 2] = radius * Math.cos(phi);
  }
  const sparkGeometry = new THREE.BufferGeometry();
  sparkGeometry.setAttribute("position", new THREE.BufferAttribute(sparkPositions, 3));
  const sparkMaterial = new THREE.PointsMaterial({
    color: current.colors[0],
    size: 0.018,
    transparent: true,
    opacity: 0.75,
    blending: THREE.AdditiveBlending,
    depthWrite: false
  });
  const sparks = new THREE.Points(sparkGeometry, sparkMaterial);
  group.add(sparks);

  const audio = {
    analyser: null,
    data: null,
    ready: false
  };

  // Mic capture is disabled; native speech pipeline drives the listening state.
  const initAudio = async () => {
    if (!navigator.mediaDevices || !navigator.mediaDevices.getUserMedia) {
      return;
    }
    try {
      const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
      const ctx = new (window.AudioContext || window.webkitAudioContext)();
      const source = ctx.createMediaStreamSource(stream);
      const analyser = ctx.createAnalyser();
      analyser.fftSize = 256;
      analyser.smoothingTimeConstant = 0.8;
      source.connect(analyser);
      audio.analyser = analyser;
      audio.data = new Uint8Array(analyser.frequencyBinCount);
      audio.ready = true;
    } catch (err) {
      audio.ready = false;
    }
  };


  const clock = new THREE.Clock();

  const resize = () => {
    const width = window.innerWidth || 1;
    const height = window.innerHeight || 1;
    renderer.setSize(width, height, false);
    camera.aspect = width / height;
    camera.updateProjectionMatrix();
  };

  window.addEventListener("resize", resize);
  resize();
  window.setOrbState({ mode: "idle", hover: false });

  const updateColors = () => {
    current.colors[0].lerp(target.colors[0], 0.05);
    current.colors[1].lerp(target.colors[1], 0.05);
    current.colors[2].lerp(target.colors[2], 0.05);
    sharedUniforms.u_colorA.value.copy(current.colors[0]);
    sharedUniforms.u_colorB.value.copy(current.colors[1]);
    sharedUniforms.u_colorC.value.copy(current.colors[2]);
    sparkMaterial.color.copy(current.colors[0]);
    dustMaterial.color.copy(current.colors[1]);
    lineData.forEach((line, index) => {
      line.material.color.copy(current.colors[index % 3]);
    });
    stormLines.forEach((storm) => {
      storm.material.color.copy(current.colors[2]);
    });
    thinkingMaterialA.color.copy(current.colors[0]);
    thinkingMaterialB.color.copy(current.colors[2]);
    markerMaterialA.color.copy(current.colors[0]);
    markerMaterialB.color.copy(current.colors[2]);
    haloRingMaterial.color.copy(current.colors[0]);
    haloArcMaterial.color.copy(current.colors[2]);
  };

  const sampleFrequency = (time) => {
    const idleBase = 0.18 + 0.08 * Math.sin(time * 1.4);
    const shouldUseAudio = state.mode === "listening" || state.mode === "speaking";
    const boosted = Math.min(1, state.level * 1.5);
    const target = shouldUseAudio ? Math.max(0.05, boosted) : idleBase;
    smoothedLevel += (target - smoothedLevel) * 0.18;
    return smoothedLevel;
  };

  const animate = () => {
    requestAnimationFrame(animate);
    const time = clock.getElapsedTime();

    current.intensity += (target.intensity - current.intensity) * 0.04;
    current.spin += (target.spin - current.spin) * 0.04;
    current.freqBoost += (target.freqBoost - current.freqBoost) * 0.04;

    const listenFactor = state.mode === "listening" ? 0.2 : 0.0;
    const enabledFactor = state.enabled ? 1.0 : 0.55;
    const isThinking = state.mode === "busy";
    const silenceFactor = state.mode === "listening" ? state.silence : 0;
    const freq = Math.min(1, sampleFrequency(time) * current.freqBoost);
    sharedUniforms.u_time.value = time;
    sharedUniforms.u_frequency.value = freq;
    sharedUniforms.u_intensity.value = current.intensity * enabledFactor;
    sharedUniforms.u_listen.value = listenFactor;

    updateColors();

    wireMaterial.uniforms.u_glow.value = (0.8 + listenFactor * 0.08) * enabledFactor;
    solidMaterial.uniforms.u_glow.value = (0.85 + listenFactor * 0.05) * enabledFactor;
    sparkMaterial.opacity = (0.75 + listenFactor * 0.04) * enabledFactor;
    sparkMaterial.size = 0.018 + listenFactor * 0.0015;
    dustMaterial.opacity = (0.32 + listenFactor * 0.03) * enabledFactor;

    const pulse = 1.0 + Math.sin(time * 1.1) * (0.05 + listenFactor * 0.03) * current.intensity;
    group.scale.setScalar(baseScale * pulse);

    const thinkingSpin = isThinking ? 2.6 : 1.0;
    group.rotation.y = time * 0.18 * current.spin * thinkingSpin;
    group.rotation.x = Math.sin(time * 0.18) * 0.12;
    sparks.rotation.y = time * 0.22 * thinkingSpin;
    sparks.rotation.x = time * 0.12;
    lineGroup.rotation.y = time * 0.08 * thinkingSpin;
    lineGroup.rotation.x = time * 0.06;
    stormGroup.rotation.y = time * 0.12 * thinkingSpin;

    if (isThinking) {
      thinkingGroup.visible = true;
      const pulse = 0.28 + 0.18 * Math.sin(time * 2.1);
      thinkingMaterialA.opacity = pulse * enabledFactor;
      thinkingMaterialB.opacity = pulse * 0.8 * enabledFactor;
      markerMaterialA.opacity = (0.5 + 0.3 * Math.sin(time * 3.1)) * enabledFactor;
      markerMaterialB.opacity = (0.45 + 0.25 * Math.cos(time * 2.7)) * enabledFactor;
      ringA.rotation.z = time * 0.6;
      ringB.rotation.y = time * -0.5;
      thinkingGroup.rotation.z = Math.sin(time * 0.6) * 0.2;
      const scale = 1.0 + 0.04 * Math.sin(time * 2.0);
      thinkingGroup.scale.setScalar(scale);
    } else {
      thinkingGroup.visible = false;
      thinkingMaterialA.opacity = 0;
      thinkingMaterialB.opacity = 0;
      markerMaterialA.opacity = 0;
      markerMaterialB.opacity = 0;
    }

    if (silenceFactor > 0.01) {
      haloGroup.visible = true;
      const haloOpacity = 0.18 + silenceFactor * 0.55;
      haloRingMaterial.opacity = haloOpacity * enabledFactor;
      haloArcMaterial.opacity = haloOpacity * 0.9 * enabledFactor;
      const scale = 1.06 - silenceFactor * 0.08;
      haloGroup.scale.setScalar(scale);
      const haloSpin = 0.08 + (1 - silenceFactor) * 0.12;
      haloGroup.rotation.z = time * haloSpin;
      if (Math.abs(silenceFactor - lastHaloProgress) > 0.02) {
        const thetaLength = Math.max(0.05, (1 - silenceFactor) * Math.PI * 2);
        haloArcGeometry.dispose();
        haloArcGeometry = new THREE.RingGeometry(haloArcInner, haloArcOuter, 140, 1, -Math.PI / 2, thetaLength);
        haloArc.geometry = haloArcGeometry;
        lastHaloProgress = silenceFactor;
      }
    } else {
      haloGroup.visible = false;
      haloRingMaterial.opacity = 0;
      haloArcMaterial.opacity = 0;
      lastHaloProgress = -1;
    }

    for (let i = 0; i < dustCount; i += 1) {
      const particle = dustParticles[i];
      particle.time += particle.speed;
      const t = particle.time;
      const theta = particle.theta + t * particle.factor * 0.2;
      const phi = particle.phi + Math.sin(t * 0.5) * 0.05;
      const radius = particle.radius + Math.sin(t * 1.1) * particle.offset;
      const sinPhi = Math.sin(phi);
      dustDummy.position.set(
        Math.cos(theta) * sinPhi * radius,
        Math.cos(phi) * radius,
        Math.sin(theta) * sinPhi * radius
      );
      const wobble = Math.cos(t * 1.2) * 0.18;
      const scale = (0.45 + wobble) * particle.scale;
      dustDummy.scale.setScalar(scale);
      dustDummy.rotation.set(wobble * 2.2, wobble * 1.6, wobble * 1.1);
      dustDummy.updateMatrix();
      dustMesh.setMatrixAt(i, dustDummy.matrix);
    }
    dustMesh.instanceMatrix.needsUpdate = true;

    lineData.forEach((line) => {
      line.material.opacity = (0.55 + listenFactor * 0.25) * enabledFactor;
      line.material.dashOffset -= line.speed * (0.6 + freq * 0.8 + listenFactor * 0.6);
    });

    stormLines.forEach((storm) => {
      storm.material.opacity = (0.45 + listenFactor * 0.2) * enabledFactor;
      storm.currentPos = attractorStep(storm.currentPos, storm.speed);
      const mapped = storm.currentPos.clone().normalize().multiplyScalar(storm.scale);
      storm.positions.copyWithin(0, 3);
      const lastIndex = storm.positions.length - 3;
      storm.positions[lastIndex] = mapped.x;
      storm.positions[lastIndex + 1] = mapped.y;
      storm.positions[lastIndex + 2] = mapped.z;
      storm.line.geometry.attributes.position.needsUpdate = true;
    });

    renderer.render(scene, camera);
  };

  animate();
})();
