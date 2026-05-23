(function () {
  "use strict";

  const canvas = document.getElementById("game");
  const ctx = canvas.getContext("2d");
  const playerHealthEl = document.getElementById("playerHealth");
  const playerHealthTextEl = document.getElementById("playerHealthText");
  const bossHealthEl = document.getElementById("bossHealth");
  const bossHealthTextEl = document.getElementById("bossHealthText");
  const enemyCountEl = document.getElementById("enemyCount");
  const weaponNameEl = document.getElementById("weaponName");
  const endActionsEl = document.getElementById("endActions");
  const againButton = document.getElementById("againButton");
  const byeButton = document.getElementById("byeButton");
  const restartButton = document.getElementById("restartButton");
  const touchControls = document.getElementById("touchControls");
  const touchStick = document.getElementById("touchStick");
  const touchKnob = document.getElementById("touchKnob");
  const attackButton = document.getElementById("attackButton");

  const WORLD = {
    width: 2200,
    height: 1300,
    tile: 72,
  };

  const PLAYER_SPEED = 220;
  const ENEMY_TARGET_COUNT = 5;
  const TAU = Math.PI * 2;

  const WARD = {
    x: WORLD.width - 265,
    y: WORLD.height / 2,
    radius: 126,
    burnDps: 18,
  };

  const TORCHES = [
    { x: 220, y: 110, radius: 18 },
    { x: 220, y: WORLD.height - 110, radius: 18 },
    { x: 960, y: 610, radius: 18 },
    { x: 1350, y: 1050, radius: 18 },
    { x: 1985, y: 180, radius: 18 },
    { x: 1985, y: WORLD.height - 180, radius: 18 },
  ];

  const WEAPONS = {
    dildo: {
      name: "Dildo",
      cooldown: 0.35,
      slashTimer: 0.16,
      range: 112,
      spread: 0.95,
      reach: 42,
      enemyDamage: 34,
      bossDamage: 24,
      arcRadius: 58,
      outerArcRadius: 74,
      color: "#f0b4ca",
      accent: "#d77aa3",
    },
    crossbow: {
      name: "Crossbow",
      cooldown: 0.58,
      slashTimer: 0.14,
      range: 720,
      spread: 0,
      reach: 30,
      enemyDamage: 28,
      bossDamage: 24,
      burnDps: 9,
      burnSeconds: 3.2,
      projectileSpeed: 430,
      color: "#cfa36a",
      accent: "#d85e44",
    },
  };

  const state = {
    width: 0,
    height: 0,
    dpr: 1,
    now: 0,
    shake: 0,
    camera: { x: 0, y: 0 },
    keys: new Set(),
    pointer: { x: 0, y: 0, down: false, active: false },
    touchMove: { x: 0, y: 0, id: null },
    touchAttack: false,
    gameOver: false,
    won: false,
    messageTimer: 0,
    bye: false,
    tooBadTimer: 0,
  };

  const player = {
    x: 150,
    y: WORLD.height / 2,
    radius: 18,
    hp: 100,
    maxHp: 100,
    angle: 0,
    attackCooldown: 0,
    slashTimer: 0,
    invulnerable: 0,
    burnFeedback: 0,
    isWalking: false,
    walkTimer: 0,
    weapon: "dildo",
  };

  const boss = {
    x: WARD.x + WARD.radius + 58,
    y: WORLD.height / 2,
    radius: 48,
    hp: 360,
    maxHp: 360,
    speed: 86,
    attackCooldown: 0,
    shotCooldown: 1.3,
    invulnerable: 0,
    burnTimer: 0,
    burnTick: 0,
    alive: true,
  };

  const obstacles = [
    { x: 355, y: 130, w: 80, h: 280 },
    { x: 355, y: 890, w: 80, h: 280 },
    { x: 620, y: 470, w: 130, h: 90 },
    { x: 720, y: 735, w: 260, h: 82 },
    { x: 970, y: 165, w: 84, h: 275 },
    { x: 1095, y: 915, w: 90, h: 260 },
    { x: 1270, y: 475, w: 300, h: 82 },
    { x: 1510, y: 700, w: 120, h: 240 },
    { x: 1710, y: 182, w: 92, h: 310 },
  ];

  const spawnPoints = [
    { x: 580, y: 250 },
    { x: 760, y: 1020 },
    { x: 1130, y: 650 },
    { x: 1455, y: 270 },
    { x: 1660, y: 1030 },
    { x: 1880, y: 380 },
    { x: 1860, y: 920 },
  ];

  const enemies = [];
  const healthPickups = [];
  const particles = [];
  const projectiles = [];
  const floatingText = [];

  const healthPickupSpawns = [
    { x: 500, y: 760 },
    { x: 1090, y: 280 },
    { x: 1500, y: 1040 },
  ];

  const weaponPickup = {
    x: WARD.x - 54,
    y: WARD.y + 50,
    radius: 24,
    weapon: "crossbow",
    collected: false,
  };

  const sprites = createSprites();

  function createSprites() {
    return {
      player: makeSprite(58, 58, (g) => {
        g.translate(29, 29);
        g.fillStyle = "#263443";
        g.beginPath();
        g.ellipse(0, 5, 15, 20, 0, 0, TAU);
        g.fill();
        g.fillStyle = "#ead7a8";
        g.beginPath();
        g.arc(0, -12, 13, 0, TAU);
        g.fill();
        g.fillStyle = "#668fc4";
        g.beginPath();
        g.moveTo(0, -28);
        g.lineTo(12, -12);
        g.lineTo(-12, -12);
        g.closePath();
        g.fill();
      }),
      enemy: makeSprite(48, 48, (g) => {
        g.translate(24, 24);
        g.fillStyle = "#243123";
        g.beginPath();
        g.ellipse(0, 3, 16, 18, 0, 0, TAU);
        g.fill();
        g.fillStyle = "#5e8c5a";
        g.beginPath();
        g.arc(-7, -6, 5, 0, TAU);
        g.arc(7, -6, 5, 0, TAU);
        g.fill();
        g.strokeStyle = "#0d1014";
        g.lineWidth = 3;
        g.beginPath();
        g.moveTo(-9, 8);
        g.quadraticCurveTo(0, 15, 9, 8);
        g.stroke();
      }),
      boss: makeSprite(122, 122, (g) => {
        g.translate(61, 61);
        g.fillStyle = "#2b1018";
        g.beginPath();
        g.arc(0, 5, 43, 0, TAU);
        g.fill();
        g.fillStyle = "#b7354c";
        g.beginPath();
        g.arc(0, -5, 38, 0, TAU);
        g.fill();
        g.fillStyle = "#d85e44";
        g.beginPath();
        g.moveTo(-37, -28);
        g.lineTo(-58, -51);
        g.lineTo(-25, -42);
        g.moveTo(37, -28);
        g.lineTo(58, -51);
        g.lineTo(25, -42);
        g.fill();
        g.fillStyle = "#ead7a8";
        g.beginPath();
        g.arc(-14, -12, 6, 0, TAU);
        g.arc(14, -12, 6, 0, TAU);
        g.fill();
        g.strokeStyle = "#0d1014";
        g.lineWidth = 5;
        g.beginPath();
        g.moveTo(-22, 18);
        g.quadraticCurveTo(0, 35, 22, 18);
        g.stroke();
      }),
    };
  }

  function makeSprite(width, height, draw) {
    const sprite = document.createElement("canvas");
    sprite.width = width;
    sprite.height = height;
    const g = sprite.getContext("2d");
    draw(g);
    return sprite;
  }

  function resize() {
    state.dpr = Math.max(1, Math.min(window.devicePixelRatio || 1, 2));
    state.width = Math.floor(window.innerWidth);
    state.height = Math.floor(window.innerHeight);
    canvas.width = Math.floor(state.width * state.dpr);
    canvas.height = Math.floor(state.height * state.dpr);
    canvas.style.width = `${state.width}px`;
    canvas.style.height = `${state.height}px`;
    ctx.setTransform(state.dpr, 0, 0, state.dpr, 0, 0);
  }

  function resetGame() {
    player.x = 150;
    player.y = WORLD.height / 2;
    player.maxHp = 100;
    player.hp = player.maxHp;
    player.angle = 0;
    player.attackCooldown = 0;
    player.slashTimer = 0;
    player.invulnerable = 0;
    player.burnFeedback = 0;
    player.isWalking = false;
    player.walkTimer = 0;
    player.weapon = "dildo";

    boss.x = WARD.x + WARD.radius + 58;
    boss.y = WORLD.height / 2;
    boss.hp = boss.maxHp;
    boss.alive = true;
    boss.attackCooldown = 0;
    boss.shotCooldown = 1.3;
    boss.invulnerable = 0;
    boss.burnTimer = 0;
    boss.burnTick = 0;

    enemies.length = 0;
    particles.length = 0;
    projectiles.length = 0;
    floatingText.length = 0;
    state.gameOver = false;
    state.won = false;
    state.messageTimer = 0;
    state.shake = 0;
    state.bye = false;
    state.tooBadTimer = 0;
    resetPickups();
    syncEndActions();

    for (let i = 0; i < ENEMY_TARGET_COUNT; i += 1) {
      spawnEnemy();
    }
  }

  function resetPickups() {
    healthPickups.length = 0;
    for (const point of healthPickupSpawns) {
      healthPickups.push({
        x: point.x,
        y: point.y,
        radius: 18,
        heal: 25,
        maxBoost: 10,
        collected: false,
      });
    }

    weaponPickup.collected = false;
  }

  function spawnEnemy(delay = 0) {
    const point = bestSpawnPoint();
    enemies.push({
      x: point.x,
      y: point.y,
      radius: 17,
      hp: 70,
      maxHp: 70,
      speed: 118 + Math.random() * 14,
      attackCooldown: 0,
      invulnerable: 0,
      burnTimer: 0,
      burnTick: 0,
      spawnDelay: delay,
      wander: Math.random() * TAU,
    });
  }

  function bestSpawnPoint() {
    const sorted = spawnPoints
      .map((point) => ({
        point,
        distance: distance(point.x, point.y, player.x, player.y),
      }))
      .sort((a, b) => b.distance - a.distance);
    const pick = sorted[Math.floor(Math.random() * Math.min(3, sorted.length))];
    return pick.point;
  }

  function update(dt) {
    if (dt > 0.05) dt = 0.05;
    state.now += dt;
    state.shake = Math.max(0, state.shake - dt * 28);

    if (state.gameOver) {
      if (state.bye) {
        state.tooBadTimer = Math.max(0, state.tooBadTimer - dt);
        if (state.tooBadTimer <= 0) {
          resetGame();
          return;
        }
      }
      if (!state.won && state.keys.has("Enter")) {
        resetGame();
      }
      updateCamera(dt);
      updateHud();
      return;
    }

    player.attackCooldown = Math.max(0, player.attackCooldown - dt);
    player.slashTimer = Math.max(0, player.slashTimer - dt);
    player.invulnerable = Math.max(0, player.invulnerable - dt);
    boss.invulnerable = Math.max(0, boss.invulnerable - dt);

    movePlayer(dt);
    updateHazards(dt);
    if (state.gameOver) {
      updateCamera(dt);
      updateHud();
      return;
    }
    updatePickups();

    if (state.pointer.down || state.touchAttack || state.keys.has(" ")) {
      attack();
    }

    updateEnemies(dt);
    updateBoss(dt);
    updateProjectiles(dt);
    updateParticles(dt);
    updateFloatingText(dt);
    updateCamera(dt);
    updateHud();
  }

  function movePlayer(dt) {
    const input = movementInput();
    player.isWalking = false;
    if (input.x !== 0 || input.y !== 0) {
      const length = Math.hypot(input.x, input.y);
      const nx = input.x / length;
      const ny = input.y / length;
      player.angle = Math.atan2(ny, nx);
      player.isWalking = true;
      player.walkTimer += dt * 12.5;
      moveCircle(player, nx * PLAYER_SPEED * dt, ny * PLAYER_SPEED * dt);
    }

    if (state.pointer.active) {
      const worldPointer = screenToWorld(state.pointer.x, state.pointer.y);
      player.angle = Math.atan2(worldPointer.y - player.y, worldPointer.x - player.x);
    }
  }

  function movementInput() {
    const keyboard = {
      x:
        (state.keys.has("ArrowRight") || state.keys.has("d") ? 1 : 0) -
        (state.keys.has("ArrowLeft") || state.keys.has("a") ? 1 : 0),
      y:
        (state.keys.has("ArrowDown") || state.keys.has("s") ? 1 : 0) -
        (state.keys.has("ArrowUp") || state.keys.has("w") ? 1 : 0),
    };

    const touch = state.touchMove;
    return {
      x: keyboard.x + touch.x,
      y: keyboard.y + touch.y,
    };
  }

  function updateHazards(dt) {
    let burnDps = 0;
    if (circleIntersectsWard(player.x, player.y, 0)) {
      burnDps += WARD.burnDps;
    }

    for (const torch of TORCHES) {
      if (distance(player.x, player.y, torch.x, torch.y) <= player.radius + torch.radius) {
        burnDps += 2;
      }
    }

    if (burnDps <= 0) {
      player.burnFeedback = 0;
      return;
    }

    player.hp = Math.max(0, player.hp - burnDps * dt);
    player.burnFeedback -= dt;
    if (player.burnFeedback <= 0) {
      addFloatingText(player.x, player.y - 34, "burn");
      burst(player.x, player.y, "#d85e44", burnDps > 10 ? 12 : 6);
      player.burnFeedback = 0.78;
    }

    if (player.hp <= 0) {
      state.gameOver = true;
      state.won = false;
      state.messageTimer = 0.8;
      burst(player.x, player.y, "#d85e44", 42);
    }
  }

  function updatePickups() {
    for (const pickup of healthPickups) {
      if (pickup.collected) continue;
      if (distance(pickup.x, pickup.y, player.x, player.y) > pickup.radius + player.radius) continue;

      pickup.collected = true;
      player.maxHp += pickup.maxBoost;
      player.hp = Math.min(player.maxHp, player.hp + pickup.heal);
      addFloatingText(pickup.x, pickup.y - 24, "+HP");
      burst(pickup.x, pickup.y, "#6db36a", 22);
    }

    if (
      !weaponPickup.collected &&
      distance(weaponPickup.x, weaponPickup.y, player.x, player.y) <= weaponPickup.radius + player.radius
    ) {
      weaponPickup.collected = true;
      player.weapon = weaponPickup.weapon;
      addFloatingText(weaponPickup.x, weaponPickup.y - 28, WEAPONS[player.weapon].name);
      burst(weaponPickup.x, weaponPickup.y, "#9ed8c2", 32);
    }
  }

  function attack() {
    if (player.attackCooldown > 0) return;

    const weapon = WEAPONS[player.weapon];
    player.attackCooldown = weapon.cooldown;
    player.slashTimer = weapon.slashTimer;
    state.shake = Math.max(state.shake, 3);

    if (player.weapon === "crossbow") {
      firePlayerProjectile(weapon);
      return;
    }

    const centerX = player.x + Math.cos(player.angle) * weapon.reach;
    const centerY = player.y + Math.sin(player.angle) * weapon.reach;

    for (const enemy of enemies) {
      if (enemy.spawnDelay > 0) continue;
      const dx = enemy.x - centerX;
      const dy = enemy.y - centerY;
      const dist = Math.hypot(dx, dy);
      const angle = angleDelta(player.angle, Math.atan2(dy, dx));
      if (dist < weapon.range && Math.abs(angle) < weapon.spread) {
        hurtEnemy(enemy, weapon.enemyDamage, player.angle);
      }
    }

    if (boss.alive) {
      const dx = boss.x - centerX;
      const dy = boss.y - centerY;
      const dist = Math.hypot(dx, dy);
      const angle = angleDelta(player.angle, Math.atan2(dy, dx));
      if (dist < weapon.range + boss.radius * 0.4 && Math.abs(angle) < weapon.spread) {
        hurtBoss(weapon.bossDamage, player.angle);
      }
    }
  }

  function firePlayerProjectile(weapon) {
    const aimX = Math.cos(player.angle);
    const aimY = Math.sin(player.angle);
    projectiles.push({
      owner: "player",
      kind: "blunt",
      x: player.x + aimX * 34,
      y: player.y + aimY * 34,
      vx: aimX * weapon.projectileSpeed,
      vy: aimY * weapon.projectileSpeed,
      angle: player.angle,
      radius: 7,
      life: 1.7,
      enemyDamage: weapon.enemyDamage,
      bossDamage: weapon.bossDamage,
      burnDps: weapon.burnDps,
      burnSeconds: weapon.burnSeconds,
    });
    burst(player.x + aimX * 34, player.y + aimY * 34, "#cfa36a", 5);
  }

  function hurtEnemy(enemy, amount, angle) {
    if (enemy.invulnerable > 0) return;
    enemy.hp -= amount;
    enemy.invulnerable = 0.12;
    moveCircle(enemy, Math.cos(angle) * 22, Math.sin(angle) * 22, { blockWard: true });
    burst(enemy.x, enemy.y, "#5e8c5a", 10);
    addFloatingText(enemy.x, enemy.y - 22, amount);
    state.shake = Math.max(state.shake, 5);

    if (enemy.hp <= 0) {
      const index = enemies.indexOf(enemy);
      if (index >= 0) enemies.splice(index, 1);
      burst(enemy.x, enemy.y, "#d6b25e", 18);
      if (!state.won) spawnEnemy();
    }
  }

  function damageEnemy(enemy, amount, color = "#d85e44", showText = true) {
    enemy.hp -= amount;
    burst(enemy.x, enemy.y, color, 5);
    if (showText) addFloatingText(enemy.x, enemy.y - 22, Math.ceil(amount));
    if (enemy.hp <= 0) {
      const index = enemies.indexOf(enemy);
      if (index >= 0) enemies.splice(index, 1);
      burst(enemy.x, enemy.y, "#d6b25e", 18);
      if (!state.won) spawnEnemy();
    }
  }

  function hurtBoss(amount, angle) {
    if (boss.invulnerable > 0 || !boss.alive) return;
    boss.hp -= amount;
    boss.invulnerable = 0.1;
    moveCircle(boss, Math.cos(angle) * 11, Math.sin(angle) * 11, { blockWard: true });
    burst(boss.x, boss.y, "#d85e44", 12);
    addFloatingText(boss.x, boss.y - 50, amount);
    state.shake = Math.max(state.shake, 6);

    if (boss.hp <= 0) {
      boss.alive = false;
      state.gameOver = true;
      state.won = true;
      state.messageTimer = 0.8;
      projectiles.length = 0;
      burst(boss.x, boss.y, "#d6b25e", 70);
    }
  }

  function damageBoss(amount, color = "#d85e44", showText = true) {
    if (!boss.alive) return;
    boss.hp -= amount;
    burst(boss.x, boss.y, color, 6);
    if (showText) addFloatingText(boss.x, boss.y - 50, Math.ceil(amount));
    if (boss.hp <= 0) {
      boss.alive = false;
      state.gameOver = true;
      state.won = true;
      state.messageTimer = 0.8;
      projectiles.length = 0;
      burst(boss.x, boss.y, "#d6b25e", 70);
    }
  }

  function igniteTarget(target, burnDps, seconds) {
    target.burnDps = burnDps;
    target.burnTimer = Math.max(target.burnTimer || 0, seconds);
    target.burnTick = 0;
    burst(target.x, target.y, "#d85e44", 12);
  }

  function updateEnemyBurn(enemy, dt) {
    if (!enemy.burnTimer || enemy.burnTimer <= 0) return;
    enemy.burnTimer = Math.max(0, enemy.burnTimer - dt);
    enemy.burnTick -= dt;
    damageEnemy(enemy, (enemy.burnDps || 0) * dt, "#d85e44", false);
    if (enemy.burnTick <= 0 && enemy.hp > 0) {
      addFloatingText(enemy.x, enemy.y - 34, "burn");
      enemy.burnTick = 0.72;
    }
  }

  function updateBossBurn(dt) {
    if (!boss.burnTimer || boss.burnTimer <= 0 || !boss.alive) return;
    boss.burnTimer = Math.max(0, boss.burnTimer - dt);
    boss.burnTick -= dt;
    damageBoss((boss.burnDps || 0) * dt, "#d85e44", false);
    if (boss.burnTick <= 0 && boss.alive) {
      addFloatingText(boss.x, boss.y - 62, "burn");
      boss.burnTick = 0.72;
    }
  }

  function updateEnemies(dt) {
    while (enemies.length < ENEMY_TARGET_COUNT && !state.won) {
      spawnEnemy();
    }

    for (const enemy of enemies) {
      enemy.spawnDelay = Math.max(0, enemy.spawnDelay - dt);
      enemy.attackCooldown = Math.max(0, enemy.attackCooldown - dt);
      enemy.invulnerable = Math.max(0, enemy.invulnerable - dt);
      updateEnemyBurn(enemy, dt);
      if (!enemies.includes(enemy)) continue;
      if (enemy.spawnDelay > 0) continue;

      const dx = player.x - enemy.x;
      const dy = player.y - enemy.y;
      const dist = Math.hypot(dx, dy);
      let vx = 0;
      let vy = 0;

      if (dist < 510) {
        vx = dx / dist;
        vy = dy / dist;
      } else {
        enemy.wander += Math.sin(state.now + enemy.x) * dt * 0.4;
        vx = Math.cos(enemy.wander) * 0.25;
        vy = Math.sin(enemy.wander) * 0.25;
      }

      for (const other of enemies) {
        if (other === enemy || other.spawnDelay > 0) continue;
        const odx = enemy.x - other.x;
        const ody = enemy.y - other.y;
        const overlapDist = Math.hypot(odx, ody) || 1;
        const needed = enemy.radius + other.radius + 8;
        if (overlapDist < needed) {
          vx += (odx / overlapDist) * 0.65;
          vy += (ody / overlapDist) * 0.65;
        }
      }

      const length = Math.hypot(vx, vy);
      if (length > 0) {
        moveCircle(enemy, (vx / length) * enemy.speed * dt, (vy / length) * enemy.speed * dt, { blockWard: true });
      }

      if (!circleIntersectsWard(player.x, player.y, 0) && dist < enemy.radius + player.radius + 8 && enemy.attackCooldown <= 0) {
        damagePlayer(9);
        enemy.attackCooldown = 0.72;
      }
    }
  }

  function updateBoss(dt) {
    if (!boss.alive) return;
    updateBossBurn(dt);
    if (!boss.alive) return;

    boss.attackCooldown = Math.max(0, boss.attackCooldown - dt);
    boss.shotCooldown = Math.max(0, boss.shotCooldown - dt);

    const dx = player.x - boss.x;
    const dy = player.y - boss.y;
    const dist = Math.hypot(dx, dy) || 1;
    const aggression = player.x > WORLD.width * 0.46 ? 1 : 0.35;
    moveCircle(
      boss,
      (dx / dist) * boss.speed * aggression * dt,
      (dy / dist) * boss.speed * aggression * dt,
      { blockWard: true }
    );

    if (!circleIntersectsWard(player.x, player.y, 0) && dist < boss.radius + player.radius + 12 && boss.attackCooldown <= 0) {
      damagePlayer(18);
      boss.attackCooldown = 0.9;
      state.shake = Math.max(state.shake, 8);
    }

    if (dist < 680 && boss.shotCooldown <= 0) {
      boss.shotCooldown = 1.35;
      const angle = Math.atan2(dy, dx);
      projectiles.push({
        owner: "boss",
        kind: "orb",
        x: boss.x + Math.cos(angle) * 42,
        y: boss.y + Math.sin(angle) * 42,
        vx: Math.cos(angle) * 245,
        vy: Math.sin(angle) * 245,
        angle,
        radius: 9,
        life: 3.2,
      });
    }
  }

  function updateProjectiles(dt) {
    for (let i = projectiles.length - 1; i >= 0; i -= 1) {
      const shot = projectiles[i];
      shot.life -= dt;
      const nextX = shot.x + shot.vx * dt;
      const nextY = shot.y + shot.vy * dt;

      if (shot.owner === "boss" && circleIntersectsWard(nextX, nextY, shot.radius)) {
        burst(shot.x, shot.y, "#d85e44", 10);
        projectiles.splice(i, 1);
        continue;
      }

      shot.x = nextX;
      shot.y = nextY;

      if (circleHitsWalls(shot.x, shot.y, shot.radius) || circleHitsObstacles(shot.x, shot.y, shot.radius) || shot.life <= 0) {
        burst(shot.x, shot.y, shot.owner === "player" ? "#cfa36a" : "#b7354c", 8);
        projectiles.splice(i, 1);
        continue;
      }

      if (shot.owner === "player") {
        if (hitHostileWithProjectile(shot)) {
          projectiles.splice(i, 1);
        }
        continue;
      }

      if (distance(shot.x, shot.y, player.x, player.y) < shot.radius + player.radius) {
        damagePlayer(13);
        burst(shot.x, shot.y, "#b7354c", 14);
        projectiles.splice(i, 1);
      }
    }
  }

  function hitHostileWithProjectile(shot) {
    for (const enemy of enemies) {
      if (enemy.spawnDelay > 0) continue;
      if (distance(shot.x, shot.y, enemy.x, enemy.y) > shot.radius + enemy.radius) continue;

      damageEnemy(enemy, shot.enemyDamage, "#cfa36a");
      igniteTarget(enemy, shot.burnDps, shot.burnSeconds);
      burst(shot.x, shot.y, "#d85e44", 14);
      return true;
    }

    if (boss.alive && distance(shot.x, shot.y, boss.x, boss.y) <= shot.radius + boss.radius) {
      damageBoss(shot.bossDamage, "#cfa36a");
      igniteTarget(boss, shot.burnDps, shot.burnSeconds);
      burst(shot.x, shot.y, "#d85e44", 18);
      return true;
    }

    return false;
  }

  function damagePlayer(amount) {
    if (player.invulnerable > 0 || state.gameOver) return;
    player.hp = Math.max(0, player.hp - amount);
    player.invulnerable = 0.42;
    state.shake = Math.max(state.shake, 7);
    addFloatingText(player.x, player.y - 34, amount);
    burst(player.x, player.y, "#668fc4", 12);

    if (player.hp <= 0) {
      state.gameOver = true;
      state.won = false;
      state.messageTimer = 0.8;
      burst(player.x, player.y, "#d85e44", 42);
    }
  }

  function moveCircle(entity, dx, dy, options = {}) {
    entity.x = clamp(entity.x + dx, entity.radius + 24, WORLD.width - entity.radius - 24);
    if (circleHitsObstacles(entity.x, entity.y, entity.radius) || (options.blockWard && circleIntersectsWard(entity.x, entity.y, entity.radius))) {
      entity.x = clamp(entity.x - dx, entity.radius + 24, WORLD.width - entity.radius - 24);
    }

    entity.y = clamp(entity.y + dy, entity.radius + 24, WORLD.height - entity.radius - 24);
    if (circleHitsObstacles(entity.x, entity.y, entity.radius) || (options.blockWard && circleIntersectsWard(entity.x, entity.y, entity.radius))) {
      entity.y = clamp(entity.y - dy, entity.radius + 24, WORLD.height - entity.radius - 24);
    }
  }

  function circleHitsWalls(x, y, radius) {
    return x < radius + 24 || y < radius + 24 || x > WORLD.width - radius - 24 || y > WORLD.height - radius - 24;
  }

  function circleHitsObstacles(x, y, radius) {
    return obstacles.some((rect) => circleRectCollision(x, y, radius, rect));
  }

  function circleIntersectsWard(x, y, radius) {
    return distance(x, y, WARD.x, WARD.y) < WARD.radius + radius;
  }

  function circleRectCollision(cx, cy, radius, rect) {
    const closestX = clamp(cx, rect.x, rect.x + rect.w);
    const closestY = clamp(cy, rect.y, rect.y + rect.h);
    return distance(cx, cy, closestX, closestY) < radius;
  }

  function updateParticles(dt) {
    for (let i = particles.length - 1; i >= 0; i -= 1) {
      const p = particles[i];
      p.life -= dt;
      p.x += p.vx * dt;
      p.y += p.vy * dt;
      p.vx *= 0.96;
      p.vy *= 0.96;
      if (p.life <= 0) particles.splice(i, 1);
    }
  }

  function updateFloatingText(dt) {
    for (let i = floatingText.length - 1; i >= 0; i -= 1) {
      const text = floatingText[i];
      text.life -= dt;
      text.y -= 28 * dt;
      if (text.life <= 0) floatingText.splice(i, 1);
    }
  }

  function updateCamera(dt) {
    const targetX = clamp(player.x - state.width / 2, 0, Math.max(0, WORLD.width - state.width));
    const targetY = clamp(player.y - state.height / 2, 0, Math.max(0, WORLD.height - state.height));
    const follow = 1 - Math.pow(0.0001, dt);
    state.camera.x += (targetX - state.camera.x) * follow;
    state.camera.y += (targetY - state.camera.y) * follow;
  }

  function updateHud() {
    const playerHp = Math.ceil(clamp(player.hp, 0, player.maxHp));
    const bossHp = Math.ceil(clamp(boss.hp, 0, boss.maxHp));
    playerHealthEl.style.width = `${clamp(player.hp / player.maxHp, 0, 1) * 100}%`;
    playerHealthTextEl.textContent = `${playerHp}/${player.maxHp}`;
    bossHealthEl.style.width = `${clamp(boss.hp / boss.maxHp, 0, 1) * 100}%`;
    bossHealthTextEl.textContent = `${bossHp}/${boss.maxHp}`;
    enemyCountEl.textContent = String(enemies.filter((enemy) => enemy.spawnDelay <= 0).length);
    weaponNameEl.textContent = WEAPONS[player.weapon].name;
    syncEndActions();
  }

  function syncEndActions() {
    if (!state.gameOver || state.bye) {
      endActionsEl.hidden = true;
      return;
    }

    endActionsEl.hidden = false;
    againButton.hidden = !state.won;
    byeButton.hidden = !state.won;
    restartButton.hidden = state.won;
  }

  function draw() {
    ctx.clearRect(0, 0, state.width, state.height);
    const shakeX = (Math.random() - 0.5) * state.shake;
    const shakeY = (Math.random() - 0.5) * state.shake;

    ctx.save();
    ctx.translate(Math.round(-state.camera.x + shakeX), Math.round(-state.camera.y + shakeY));
    drawDungeon();
    drawPickups();
    drawProjectiles();
    drawEnemies();
    drawBoss();
    drawPlayer();
    drawParticles();
    drawFloatingText();
    ctx.restore();

    drawVignette();
    if (state.gameOver) {
      drawEndState();
    }
  }

  function drawDungeon() {
    ctx.fillStyle = "#151719";
    ctx.fillRect(0, 0, WORLD.width, WORLD.height);

    const startCol = Math.max(0, Math.floor(state.camera.x / WORLD.tile) - 1);
    const endCol = Math.min(Math.ceil(WORLD.width / WORLD.tile), Math.ceil((state.camera.x + state.width) / WORLD.tile) + 1);
    const startRow = Math.max(0, Math.floor(state.camera.y / WORLD.tile) - 1);
    const endRow = Math.min(Math.ceil(WORLD.height / WORLD.tile), Math.ceil((state.camera.y + state.height) / WORLD.tile) + 1);

    for (let row = startRow; row < endRow; row += 1) {
      for (let col = startCol; col < endCol; col += 1) {
        const x = col * WORLD.tile;
        const y = row * WORLD.tile;
        const tone = (col * 11 + row * 7) % 5;
        ctx.fillStyle = tone === 0 ? "#1f2223" : tone === 1 ? "#202427" : "#1b1e20";
        ctx.fillRect(x, y, WORLD.tile, WORLD.tile);
        ctx.strokeStyle = "rgba(243, 232, 202, 0.045)";
        ctx.strokeRect(x + 0.5, y + 0.5, WORLD.tile, WORLD.tile);
      }
    }

    drawOuterWalls();
    drawObstacles();
    drawTorches();
    drawBossSigil();
  }

  function drawOuterWalls() {
    ctx.fillStyle = "#282b2d";
    ctx.fillRect(0, 0, WORLD.width, 28);
    ctx.fillRect(0, WORLD.height - 28, WORLD.width, 28);
    ctx.fillRect(0, 0, 28, WORLD.height);
    ctx.fillRect(WORLD.width - 28, 0, 28, WORLD.height);
    ctx.strokeStyle = "rgba(214, 178, 94, 0.25)";
    ctx.lineWidth = 2;
    ctx.strokeRect(28, 28, WORLD.width - 56, WORLD.height - 56);
  }

  function drawObstacles() {
    for (const rect of obstacles) {
      const gradient = ctx.createLinearGradient(rect.x, rect.y, rect.x, rect.y + rect.h);
      gradient.addColorStop(0, "#34383a");
      gradient.addColorStop(1, "#202426");
      ctx.fillStyle = gradient;
      ctx.fillRect(rect.x, rect.y, rect.w, rect.h);
      ctx.strokeStyle = "rgba(243, 232, 202, 0.13)";
      ctx.lineWidth = 2;
      ctx.strokeRect(rect.x + 1, rect.y + 1, rect.w - 2, rect.h - 2);
      ctx.fillStyle = "rgba(0, 0, 0, 0.16)";
      ctx.fillRect(rect.x + 8, rect.y + rect.h - 10, rect.w - 16, 5);
    }
  }

  function drawTorches() {
    for (const torch of TORCHES) {
      const flicker = 0.7 + Math.sin(state.now * 10 + torch.x) * 0.18;
      const glow = ctx.createRadialGradient(torch.x, torch.y, 6, torch.x, torch.y, 145 * flicker);
      glow.addColorStop(0, "rgba(216, 94, 68, 0.44)");
      glow.addColorStop(0.25, "rgba(214, 178, 94, 0.21)");
      glow.addColorStop(1, "rgba(214, 178, 94, 0)");
      ctx.fillStyle = glow;
      ctx.beginPath();
      ctx.arc(torch.x, torch.y, 145 * flicker, 0, TAU);
      ctx.fill();
      ctx.fillStyle = "#d6b25e";
      ctx.beginPath();
      ctx.ellipse(torch.x, torch.y, 7, 14, 0, 0, TAU);
      ctx.fill();
      ctx.fillStyle = "#34231a";
      ctx.fillRect(torch.x - 3, torch.y + 10, 6, 18);
    }
  }

  function drawBossSigil() {
    ctx.save();
    ctx.translate(WARD.x, WARD.y);
    const pulse = 0.5 + Math.sin(state.now * 4) * 0.5;
    ctx.fillStyle = `rgba(183, 53, 76, ${0.06 + pulse * 0.04})`;
    ctx.beginPath();
    ctx.arc(0, 0, WARD.radius, 0, TAU);
    ctx.fill();
    ctx.strokeStyle = "rgba(183, 53, 76, 0.56)";
    ctx.lineWidth = 4;
    ctx.beginPath();
    ctx.arc(0, 0, WARD.radius, 0, TAU);
    ctx.moveTo(-90, 0);
    ctx.lineTo(90, 0);
    ctx.moveTo(0, -90);
    ctx.lineTo(0, 90);
    ctx.stroke();
    ctx.strokeStyle = `rgba(216, 94, 68, ${0.42 + pulse * 0.25})`;
    ctx.lineWidth = 2;
    ctx.beginPath();
    ctx.arc(0, 0, WARD.radius - 10, 0, TAU);
    ctx.stroke();
    drawWardSkull();
    ctx.restore();
  }

  function drawWardSkull() {
    ctx.save();
    ctx.translate(0, -8);
    ctx.fillStyle = "#ead7a8";
    ctx.strokeStyle = "#2b1018";
    ctx.lineWidth = 4;
    ctx.beginPath();
    ctx.arc(0, -12, 34, Math.PI, 0);
    ctx.lineTo(30, 18);
    ctx.quadraticCurveTo(0, 34, -30, 18);
    ctx.closePath();
    ctx.fill();
    ctx.stroke();

    ctx.fillStyle = "#0d1014";
    ctx.beginPath();
    ctx.arc(-13, -10, 8, 0, TAU);
    ctx.arc(13, -10, 8, 0, TAU);
    ctx.fill();
    ctx.beginPath();
    ctx.moveTo(0, -2);
    ctx.lineTo(8, 14);
    ctx.lineTo(-8, 14);
    ctx.closePath();
    ctx.fill();

    ctx.strokeStyle = "#0d1014";
    ctx.lineWidth = 3;
    ctx.beginPath();
    ctx.moveTo(-15, 21);
    ctx.lineTo(-10, 29);
    ctx.moveTo(-5, 24);
    ctx.lineTo(-3, 34);
    ctx.moveTo(5, 24);
    ctx.lineTo(3, 34);
    ctx.moveTo(15, 21);
    ctx.lineTo(10, 29);
    ctx.stroke();

    ctx.fillStyle = "#34231a";
    ctx.beginPath();
    ctx.moveTo(-28, 22);
    ctx.quadraticCurveTo(-16, 54, 0, 62);
    ctx.quadraticCurveTo(16, 54, 28, 22);
    ctx.quadraticCurveTo(0, 34, -28, 22);
    ctx.fill();
    ctx.restore();
  }

  function drawPickups() {
    for (const pickup of healthPickups) {
      if (!pickup.collected) drawHealthPickup(pickup);
    }

    if (!weaponPickup.collected) drawWeaponPickup();
  }

  function drawHealthPickup(pickup) {
    const pulse = 0.5 + Math.sin(state.now * 5 + pickup.x) * 0.5;
    const glow = ctx.createRadialGradient(pickup.x, pickup.y, 4, pickup.x, pickup.y, 46);
    glow.addColorStop(0, `rgba(109, 179, 106, ${0.45 + pulse * 0.22})`);
    glow.addColorStop(1, "rgba(109, 179, 106, 0)");
    ctx.fillStyle = glow;
    ctx.beginPath();
    ctx.arc(pickup.x, pickup.y, 46, 0, TAU);
    ctx.fill();

    ctx.fillStyle = "#6db36a";
    ctx.strokeStyle = "#ead7a8";
    ctx.lineWidth = 2;
    ctx.beginPath();
    ctx.arc(pickup.x, pickup.y, pickup.radius, 0, TAU);
    ctx.fill();
    ctx.stroke();

    ctx.strokeStyle = "#f3e8ca";
    ctx.lineWidth = 5;
    ctx.lineCap = "round";
    ctx.beginPath();
    ctx.moveTo(pickup.x - 9, pickup.y);
    ctx.lineTo(pickup.x + 9, pickup.y);
    ctx.moveTo(pickup.x, pickup.y - 9);
    ctx.lineTo(pickup.x, pickup.y + 9);
    ctx.stroke();
  }

  function drawWeaponPickup() {
    const pulse = 0.5 + Math.sin(state.now * 6) * 0.5;
    const glow = ctx.createRadialGradient(weaponPickup.x, weaponPickup.y, 8, weaponPickup.x, weaponPickup.y, 58);
    glow.addColorStop(0, `rgba(207, 163, 106, ${0.48 + pulse * 0.24})`);
    glow.addColorStop(1, "rgba(207, 163, 106, 0)");
    ctx.fillStyle = glow;
    ctx.beginPath();
    ctx.arc(weaponPickup.x, weaponPickup.y, 58, 0, TAU);
    ctx.fill();

    ctx.save();
    ctx.translate(weaponPickup.x, weaponPickup.y + Math.sin(state.now * 5) * 3);
    ctx.rotate(-0.18);
    ctx.strokeStyle = "#cfa36a";
    ctx.lineWidth = 7;
    ctx.lineCap = "round";
    ctx.beginPath();
    ctx.moveTo(-34, 0);
    ctx.lineTo(34, 0);
    ctx.stroke();
    ctx.strokeStyle = "#ead7a8";
    ctx.lineWidth = 4;
    ctx.beginPath();
    ctx.moveTo(-18, -18);
    ctx.quadraticCurveTo(2, -31, 22, -18);
    ctx.moveTo(-18, 18);
    ctx.quadraticCurveTo(2, 31, 22, 18);
    ctx.moveTo(4, -20);
    ctx.lineTo(4, 20);
    ctx.moveTo(34, 0);
    ctx.lineTo(48, 0);
    ctx.stroke();
    ctx.restore();
  }

  function drawEnemies() {
    for (const enemy of enemies) {
      if (enemy.spawnDelay > 0) {
        drawSpawn(enemy);
        continue;
      }

      ctx.save();
      ctx.translate(enemy.x, enemy.y);
      if (enemy.invulnerable > 0) ctx.globalAlpha = 0.55;
      const angle = Math.atan2(player.y - enemy.y, player.x - enemy.x);
      ctx.rotate(angle + Math.PI / 2);
      ctx.drawImage(sprites.enemy, -24, -24, 48, 48);
      ctx.restore();
      if (enemy.burnTimer > 0) drawBurnAura(enemy.x, enemy.y, enemy.radius + 10);

      drawTinyBar(enemy.x, enemy.y - 31, 40, enemy.hp / enemy.maxHp, "#5e8c5a");
    }
  }

  function drawSpawn(enemy) {
    const progress = 1 - enemy.spawnDelay / 1.1;
    ctx.save();
    ctx.translate(enemy.x, enemy.y);
    ctx.strokeStyle = `rgba(94, 140, 90, ${0.25 + progress * 0.45})`;
    ctx.lineWidth = 3;
    ctx.beginPath();
    ctx.arc(0, 0, 22 + progress * 12, 0, TAU);
    ctx.stroke();
    ctx.restore();
  }

  function drawBoss() {
    if (!boss.alive) return;
    ctx.save();
    ctx.translate(boss.x, boss.y);
    if (boss.invulnerable > 0) ctx.globalAlpha = 0.55;
    const angle = Math.atan2(player.y - boss.y, player.x - boss.x);
    ctx.rotate(angle + Math.PI / 2);
    ctx.drawImage(sprites.boss, -61, -61, 122, 122);
    ctx.restore();
    if (boss.burnTimer > 0) drawBurnAura(boss.x, boss.y, boss.radius + 18);
  }

  function drawBurnAura(x, y, radius) {
    const pulse = 0.5 + Math.sin(state.now * 12 + x) * 0.5;
    ctx.strokeStyle = `rgba(216, 94, 68, ${0.35 + pulse * 0.35})`;
    ctx.lineWidth = 3;
    ctx.beginPath();
    ctx.arc(x, y, radius + pulse * 4, 0, TAU);
    ctx.stroke();
  }

  function drawPlayer() {
    ctx.save();
    ctx.translate(player.x, player.y);
    if (player.invulnerable > 0 && Math.floor(state.now * 30) % 2 === 0) {
      ctx.globalAlpha = 0.42;
    }
    ctx.rotate(player.angle + Math.PI / 2);
    drawLegs();
    ctx.drawImage(sprites.player, -29, -29, 58, 58);
    drawHeldWeapon(player.weapon);
    ctx.restore();

    if (player.slashTimer > 0) {
      const weapon = WEAPONS[player.weapon];
      const alpha = player.slashTimer / weapon.slashTimer;
      ctx.save();
      ctx.translate(player.x, player.y);
      ctx.rotate(player.angle);
      if (player.weapon === "crossbow") {
        ctx.fillStyle = withAlpha(weapon.accent, alpha);
        ctx.beginPath();
        ctx.arc(42, 0, 12 * alpha, 0, TAU);
        ctx.fill();
      } else {
        ctx.strokeStyle = withAlpha(weapon.color, alpha);
        ctx.lineWidth = 10;
        ctx.lineCap = "round";
        ctx.beginPath();
        ctx.arc(weapon.reach, 0, weapon.arcRadius, -weapon.spread, weapon.spread);
        ctx.stroke();
        ctx.strokeStyle = withAlpha(weapon.accent, alpha * 0.75);
        ctx.lineWidth = 4;
        ctx.beginPath();
        ctx.arc(weapon.reach, 0, weapon.outerArcRadius, -weapon.spread * 0.82, weapon.spread * 0.82);
        ctx.stroke();
      }
      ctx.restore();
    }
  }

  function drawLegs() {
    const phase = player.isWalking ? player.walkTimer : 0;
    const leftSwing = Math.sin(phase) * 12;
    const rightSwing = Math.sin(phase + Math.PI) * 12;

    ctx.strokeStyle = "#161f2a";
    ctx.lineWidth = 9;
    ctx.lineCap = "round";
    ctx.beginPath();
    ctx.moveTo(-8, 10);
    ctx.lineTo(-10 + leftSwing * 0.3, 28 + leftSwing * 0.18);
    ctx.moveTo(8, 10);
    ctx.lineTo(10 + rightSwing * 0.3, 28 + rightSwing * 0.18);
    ctx.stroke();

    ctx.strokeStyle = "#668fc4";
    ctx.lineWidth = 5;
    ctx.beginPath();
    ctx.moveTo(-8, 10);
    ctx.lineTo(-10 + leftSwing * 0.3, 28 + leftSwing * 0.18);
    ctx.moveTo(8, 10);
    ctx.lineTo(10 + rightSwing * 0.3, 28 + rightSwing * 0.18);
    ctx.stroke();
  }

  function drawHeldWeapon(weaponKey) {
    const flop = player.isWalking ? Math.sin(player.walkTimer * 1.45) * 0.34 + Math.sin(player.walkTimer * 2.7) * 0.08 : 0;
    const bob = player.isWalking ? Math.sin(player.walkTimer * 1.1) * 2.8 : 0;

    if (weaponKey === "crossbow") {
      ctx.save();
      ctx.translate(2, bob * 0.45);
      ctx.rotate(-0.18 + flop * 0.18);
      ctx.strokeStyle = "#cfa36a";
      ctx.lineWidth = 5;
      ctx.lineCap = "round";
      ctx.beginPath();
      ctx.moveTo(5, 1);
      ctx.lineTo(36, 1);
      ctx.stroke();
      ctx.strokeStyle = "#ead7a8";
      ctx.lineWidth = 4;
      ctx.lineCap = "round";
      ctx.beginPath();
      ctx.moveTo(12, -12);
      ctx.quadraticCurveTo(23, -22, 34, -12);
      ctx.moveTo(12, 14);
      ctx.quadraticCurveTo(23, 24, 34, 14);
      ctx.moveTo(23, -13);
      ctx.lineTo(23, 15);
      ctx.stroke();
      ctx.restore();
      return;
    }

    ctx.save();
    ctx.translate(0, bob);
    ctx.rotate(-0.54 + flop);
    ctx.strokeStyle = "#d77aa3";
    ctx.lineWidth = 8;
    ctx.lineCap = "round";
    ctx.beginPath();
    ctx.moveTo(12, 3);
    ctx.lineTo(29, -18);
    ctx.stroke();
    ctx.strokeStyle = "#f0b4ca";
    ctx.lineWidth = 4;
    ctx.beginPath();
    ctx.moveTo(8, 6);
    ctx.lineTo(17, 12);
    ctx.stroke();
    ctx.restore();
  }

  function drawProjectiles() {
    for (const shot of projectiles) {
      if (shot.owner === "player") {
        drawBluntProjectile(shot);
        continue;
      }

      const glow = ctx.createRadialGradient(shot.x, shot.y, 0, shot.x, shot.y, 36);
      glow.addColorStop(0, "rgba(216, 94, 68, 0.9)");
      glow.addColorStop(1, "rgba(183, 53, 76, 0)");
      ctx.fillStyle = glow;
      ctx.beginPath();
      ctx.arc(shot.x, shot.y, 36, 0, TAU);
      ctx.fill();
      ctx.fillStyle = "#b7354c";
      ctx.beginPath();
      ctx.arc(shot.x, shot.y, shot.radius, 0, TAU);
      ctx.fill();
    }
  }

  function drawBluntProjectile(shot) {
    const glow = ctx.createRadialGradient(shot.x, shot.y, 0, shot.x, shot.y, 26);
    glow.addColorStop(0, "rgba(216, 94, 68, 0.42)");
    glow.addColorStop(1, "rgba(216, 94, 68, 0)");
    ctx.fillStyle = glow;
    ctx.beginPath();
    ctx.arc(shot.x, shot.y, 26, 0, TAU);
    ctx.fill();

    ctx.save();
    ctx.translate(shot.x, shot.y);
    ctx.rotate(shot.angle);
    ctx.fillStyle = "#8d6c47";
    ctx.strokeStyle = "#ead7a8";
    ctx.lineWidth = 2;
    ctx.beginPath();
    ctx.moveTo(-9, -4);
    ctx.lineTo(9, -4);
    ctx.quadraticCurveTo(13, -4, 13, 0);
    ctx.quadraticCurveTo(13, 4, 9, 4);
    ctx.lineTo(-9, 4);
    ctx.quadraticCurveTo(-13, 4, -13, 0);
    ctx.quadraticCurveTo(-13, -4, -9, -4);
    ctx.closePath();
    ctx.fill();
    ctx.stroke();
    ctx.fillStyle = "#d85e44";
    ctx.beginPath();
    ctx.arc(13, 0, 4, 0, TAU);
    ctx.fill();
    ctx.restore();
  }

  function drawParticles() {
    for (const p of particles) {
      ctx.globalAlpha = clamp(p.life / p.maxLife, 0, 1);
      ctx.fillStyle = p.color;
      ctx.beginPath();
      ctx.arc(p.x, p.y, p.size, 0, TAU);
      ctx.fill();
      ctx.globalAlpha = 1;
    }
  }

  function drawFloatingText() {
    ctx.save();
    ctx.font = "800 14px Inter, system-ui, sans-serif";
    ctx.textAlign = "center";
    ctx.textBaseline = "middle";
    for (const text of floatingText) {
      ctx.globalAlpha = clamp(text.life / 0.7, 0, 1);
      ctx.fillStyle = "#f3e8ca";
      ctx.strokeStyle = "rgba(13, 16, 20, 0.9)";
      ctx.lineWidth = 4;
      ctx.strokeText(text.value, text.x, text.y);
      ctx.fillText(text.value, text.x, text.y);
    }
    ctx.restore();
  }

  function drawTinyBar(x, y, width, ratio, color) {
    ctx.fillStyle = "rgba(13, 16, 20, 0.78)";
    ctx.fillRect(x - width / 2, y, width, 5);
    ctx.fillStyle = color;
    ctx.fillRect(x - width / 2, y, width * clamp(ratio, 0, 1), 5);
  }

  function drawVignette() {
    const gradient = ctx.createRadialGradient(
      state.width / 2,
      state.height / 2,
      Math.min(state.width, state.height) * 0.2,
      state.width / 2,
      state.height / 2,
      Math.max(state.width, state.height) * 0.72
    );
    gradient.addColorStop(0, "rgba(0, 0, 0, 0)");
    gradient.addColorStop(1, "rgba(0, 0, 0, 0.5)");
    ctx.fillStyle = gradient;
    ctx.fillRect(0, 0, state.width, state.height);
  }

  function drawEndState() {
    const alpha = state.messageTimer > 0 ? 1 - state.messageTimer / 0.8 : 1;
    state.messageTimer = Math.max(0, state.messageTimer - 1 / 60);

    ctx.save();
    ctx.globalAlpha = alpha;
    ctx.fillStyle = "rgba(13, 16, 20, 0.62)";
    ctx.fillRect(0, 0, state.width, state.height);
    ctx.textAlign = "center";
    ctx.textBaseline = "middle";
    ctx.fillStyle = "#f3e8ca";
    ctx.font = "800 44px Inter, system-ui, sans-serif";
    ctx.fillText(state.bye ? "TOO BAD" : state.won ? "Victory" : "Defeated", state.width / 2, state.bye ? state.height / 2 : state.height / 2 - 22);
    ctx.restore();
  }

  function burst(x, y, color, count) {
    for (let i = 0; i < count; i += 1) {
      const angle = Math.random() * TAU;
      const speed = 60 + Math.random() * 150;
      const life = 0.28 + Math.random() * 0.36;
      particles.push({
        x,
        y,
        vx: Math.cos(angle) * speed,
        vy: Math.sin(angle) * speed,
        size: 2 + Math.random() * 4,
        color,
        life,
        maxLife: life,
      });
    }
  }

  function addFloatingText(x, y, value) {
    floatingText.push({
      x,
      y,
      value: String(value),
      life: 0.7,
    });
  }

  function screenToWorld(x, y) {
    return {
      x: x + state.camera.x,
      y: y + state.camera.y,
    };
  }

  function angleDelta(a, b) {
    return Math.atan2(Math.sin(b - a), Math.cos(b - a));
  }

  function distance(x1, y1, x2, y2) {
    return Math.hypot(x2 - x1, y2 - y1);
  }

  function clamp(value, min, max) {
    return Math.max(min, Math.min(max, value));
  }

  function withAlpha(hex, alpha) {
    const clean = hex.replace("#", "");
    const value = Number.parseInt(clean, 16);
    const r = (value >> 16) & 255;
    const g = (value >> 8) & 255;
    const b = value & 255;
    return `rgba(${r}, ${g}, ${b}, ${alpha})`;
  }

  function setupInput() {
    window.addEventListener("keydown", (event) => {
      if (["ArrowUp", "ArrowDown", "ArrowLeft", "ArrowRight", " "].includes(event.key)) {
        event.preventDefault();
      }
      state.keys.add(event.key.length === 1 ? event.key.toLowerCase() : event.key);
    });

    window.addEventListener("keyup", (event) => {
      state.keys.delete(event.key.length === 1 ? event.key.toLowerCase() : event.key);
    });

    canvas.addEventListener("pointermove", (event) => {
      const rect = canvas.getBoundingClientRect();
      state.pointer.x = event.clientX - rect.left;
      state.pointer.y = event.clientY - rect.top;
      state.pointer.active = true;
    });

    canvas.addEventListener("pointerdown", (event) => {
      canvas.setPointerCapture(event.pointerId);
      const rect = canvas.getBoundingClientRect();
      state.pointer.x = event.clientX - rect.left;
      state.pointer.y = event.clientY - rect.top;
      state.pointer.down = true;
      state.pointer.active = true;
    });

    canvas.addEventListener("pointerup", () => {
      state.pointer.down = false;
    });

    canvas.addEventListener("pointerleave", () => {
      state.pointer.active = false;
      state.pointer.down = false;
    });

    touchStick.addEventListener("pointerdown", (event) => {
      state.touchMove.id = event.pointerId;
      touchStick.setPointerCapture(event.pointerId);
      updateTouchStick(event);
    });

    touchStick.addEventListener("pointermove", (event) => {
      if (event.pointerId === state.touchMove.id) updateTouchStick(event);
    });

    touchStick.addEventListener("pointerup", clearTouchStick);
    touchStick.addEventListener("pointercancel", clearTouchStick);

    attackButton.addEventListener("pointerdown", (event) => {
      event.preventDefault();
      state.touchAttack = true;
    });

    attackButton.addEventListener("pointerup", () => {
      state.touchAttack = false;
    });

    attackButton.addEventListener("pointercancel", () => {
      state.touchAttack = false;
    });

    againButton.addEventListener("click", resetGame);
    restartButton.addEventListener("click", resetGame);
    byeButton.addEventListener("click", () => {
      state.bye = true;
      state.tooBadTimer = 1.25;
      syncEndActions();
    });
  }

  function updateTouchStick(event) {
    const rect = touchStick.getBoundingClientRect();
    const cx = rect.left + rect.width / 2;
    const cy = rect.top + rect.height / 2;
    const dx = event.clientX - cx;
    const dy = event.clientY - cy;
    const length = Math.hypot(dx, dy);
    const max = rect.width * 0.34;
    const amount = Math.min(length, max);
    const nx = length > 0 ? dx / length : 0;
    const ny = length > 0 ? dy / length : 0;
    state.touchMove.x = nx * (amount / max);
    state.touchMove.y = ny * (amount / max);
    touchKnob.style.transform = `translate(calc(-50% + ${nx * amount}px), calc(-50% + ${ny * amount}px))`;
  }

  function clearTouchStick(event) {
    if (event.pointerId !== state.touchMove.id) return;
    state.touchMove.id = null;
    state.touchMove.x = 0;
    state.touchMove.y = 0;
    touchKnob.style.transform = "translate(-50%, -50%)";
  }

  function loop(timestamp) {
    const seconds = timestamp / 1000;
    const dt = state.lastTimestamp ? seconds - state.lastTimestamp : 0;
    state.lastTimestamp = seconds;
    update(dt);
    draw();
    requestAnimationFrame(loop);
  }

  window.addEventListener("resize", resize);
  setupInput();
  resize();
  resetGame();
  updateHud();
  touchControls.hidden = false;
  requestAnimationFrame(loop);
})();
