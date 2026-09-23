import { DatabaseSync } from 'node:sqlite';
import bcrypt from 'bcryptjs';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const dataDir = path.join(__dirname, '..', 'data');
fs.mkdirSync(dataDir, { recursive: true });

export const db = new DatabaseSync(path.join(dataDir, 'titanfit.db'));
db.exec('PRAGMA journal_mode = WAL; PRAGMA foreign_keys = ON;');

export const nowIso = () => new Date().toISOString();

export function all(sql, params = []) {
  return db.prepare(sql).all(...params);
}

export function get(sql, params = []) {
  return db.prepare(sql).get(...params);
}

export function run(sql, params = []) {
  return db.prepare(sql).run(...params);
}

export function initSchema() {
  db.exec(`
    CREATE TABLE IF NOT EXISTS users (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      email TEXT UNIQUE NOT NULL,
      password_hash TEXT NOT NULL,
      role TEXT NOT NULL DEFAULT 'cliente',
      phone TEXT,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    );

    CREATE TABLE IF NOT EXISTS classes (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      description TEXT,
      trainer TEXT NOT NULL,
      starts_at TEXT NOT NULL,
      duration_min INTEGER NOT NULL,
      capacity INTEGER NOT NULL,
      room TEXT,
      difficulty TEXT NOT NULL DEFAULT 'intermedio',
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    );

    CREATE TABLE IF NOT EXISTS bookings (
      id TEXT PRIMARY KEY,
      user_id TEXT NOT NULL,
      class_id TEXT NOT NULL,
      status TEXT NOT NULL DEFAULT 'pendiente',
      notes TEXT,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      FOREIGN KEY (user_id) REFERENCES users(id),
      FOREIGN KEY (class_id) REFERENCES classes(id)
    );

    CREATE TABLE IF NOT EXISTS membership_plans (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      description TEXT,
      duration_days INTEGER NOT NULL,
      price INTEGER NOT NULL,
      benefits TEXT,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    );

    CREATE TABLE IF NOT EXISTS memberships (
      id TEXT PRIMARY KEY,
      user_id TEXT NOT NULL,
      plan_id TEXT NOT NULL,
      start_date TEXT NOT NULL,
      end_date TEXT NOT NULL,
      status TEXT NOT NULL DEFAULT 'activa',
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      FOREIGN KEY (user_id) REFERENCES users(id),
      FOREIGN KEY (plan_id) REFERENCES membership_plans(id)
    );

    CREATE TABLE IF NOT EXISTS routines (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      goal TEXT,
      level TEXT,
      duration_weeks INTEGER,
      exercises TEXT,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    );

    CREATE TABLE IF NOT EXISTS inventory (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      category TEXT,
      quantity INTEGER NOT NULL DEFAULT 0,
      status TEXT NOT NULL DEFAULT 'operativo',
      location TEXT,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    );
  `);
}

function addDays(date, days) {
  const d = new Date(date);
  d.setDate(d.getDate() + days);
  return d;
}

function atTime(date, hhmm) {
  const [h, m] = hhmm.split(':').map(Number);
  const d = new Date(date);
  d.setHours(h, m, 0, 0);
  return d.toISOString();
}

export function seedIfEmpty() {
  const count = get('SELECT COUNT(*) AS n FROM users');
  if (count?.n > 0) return;

  const ts = nowIso();
  const adminHash = bcrypt.hashSync('Admin123*', 10);
  const yuliedHash = bcrypt.hashSync('Yulied123*', 10);

  run(
    `INSERT INTO users (id, name, email, password_hash, role, phone, created_at, updated_at)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
    ['admin-titanfit-001', 'Administrador TitanFit', 'admin@titanfit.co', adminHash, 'administrador', '3000000000', ts, ts],
  );
  run(
    `INSERT INTO users (id, name, email, password_hash, role, phone, created_at, updated_at)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
    ['user-yulied-001', 'Yulied Marcela Lopez', 'yulied@titanfit.co', yuliedHash, 'cliente', '3105550188', ts, ts],
  );

  const catalog = [
    {
      name: 'Spinning Power',
      trainer: 'Camila Restrepo',
      time: '06:00',
      duration: 45,
      capacity: 18,
      room: 'Sala Cardio',
      difficulty: 'intermedio',
      days: [1, 3, 5],
      description: 'Intervalos de alta intensidad sobre bicicleta. Quema calórica y resistencia.',
    },
    {
      name: 'Yoga Restaurativo',
      trainer: 'Laura Mendez',
      time: '07:30',
      duration: 60,
      capacity: 16,
      room: 'Sala Yoga',
      difficulty: 'principiante',
      days: [2, 4, 6],
      description: 'Movilidad, respiración y control. Ideal para recuperación muscular.',
    },
    {
      name: 'HIIT Titan',
      trainer: 'Andres Molina',
      time: '18:00',
      duration: 40,
      capacity: 20,
      room: 'Zona Funcional',
      difficulty: 'avanzado',
      days: [1, 2, 4],
      description: 'Circuito explosivo de fuerza y cardio. Bloques de 40 segundos.',
    },
    {
      name: 'Entrenamiento Funcional',
      trainer: 'Diego Herrera',
      time: '19:00',
      duration: 50,
      capacity: 14,
      room: 'Zona Funcional',
      difficulty: 'intermedio',
      days: [1, 3, 5],
      description: 'Patrones de movimiento, core y estabilidad con peso corporal y kettlebells.',
    },
    {
      name: 'Boxeo Fitness',
      trainer: 'Valentina Cruz',
      time: '17:00',
      duration: 55,
      capacity: 12,
      room: 'Ring',
      difficulty: 'intermedio',
      days: [2, 4, 6],
      description: 'Técnica de golpes, saco y trabajo de piernas. Sin contacto de combate.',
    },
    {
      name: 'Fuerza y Potencia',
      trainer: 'Andres Molina',
      time: '08:00',
      duration: 60,
      capacity: 10,
      room: 'Sala de Pesas',
      difficulty: 'avanzado',
      days: [1, 3, 5],
      description: 'Sentadilla, peso muerto y press. Progresión de cargas.',
    },
    {
      name: 'GAP',
      trainer: 'Camila Restrepo',
      time: '09:30',
      duration: 45,
      capacity: 20,
      room: 'Sala Grupal',
      difficulty: 'principiante',
      days: [2, 4, 6],
      description: 'Glúteos, abdomen y piernas con bandas y peso corporal.',
    },
  ];

  const today = new Date();
  today.setHours(0, 0, 0, 0);
  let classIndex = 1;
  const createdClasses = [];

  for (let i = 0; i < 16; i++) {
    const day = addDays(today, i);
    const weekday = day.getDay();
    for (const item of catalog) {
      if (!item.days.includes(weekday)) continue;
      const id = `class-${String(classIndex).padStart(3, '0')}`;
      const starts = atTime(day, item.time);
      run(
        `INSERT INTO classes (id, name, description, trainer, starts_at, duration_min, capacity, room, difficulty, created_at, updated_at)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
        [id, item.name, item.description, item.trainer, starts, item.duration, item.capacity, item.room, item.difficulty, ts, ts],
      );
      createdClasses.push(id);
      classIndex += 1;
    }
  }

  const plans = [
    ['plan-basico', 'Plan Básico', 'Acceso a zona de pesas y 4 clases grupales al mes.', 30, 89900, ['Zona de pesas', '4 clases grupales', 'Casillero']],
    ['plan-plus', 'Plan Plus', 'Entrenamiento ilimitado de clases y 1 valoración mensual.', 90, 239900, ['Clases ilimitadas', 'Valoración mensual', 'Rutina personalizada', 'Sauna']],
    ['plan-elite', 'Plan Elite', 'Todo Plus + nutrición y 4 sesiones 1 a 1 con entrenador.', 365, 799900, ['Todo del Plan Plus', '4 sesiones 1 a 1', 'Plan nutricional', 'Invitado 2 veces al mes']],
    ['plan-diario', 'Pase Diario', 'Acceso de un día a todas las zonas del gimnasio.', 1, 18000, ['Acceso completo 1 día']],
  ];
  for (const [id, name, description, days, price, benefits] of plans) {
    run(
      `INSERT INTO membership_plans (id, name, description, duration_days, price, benefits, created_at, updated_at)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
      [id, name, description, days, price, JSON.stringify(benefits), ts, ts],
    );
  }

  const start = ts.slice(0, 10);
  const end = addDays(new Date(), 30).toISOString().slice(0, 10);
  run(
    `INSERT INTO memberships (id, user_id, plan_id, start_date, end_date, status, created_at, updated_at)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
    ['mem-yulied-001', 'user-yulied-001', 'plan-plus', start, end, 'activa', ts, ts],
  );

  const routines = [
    [
      'rutina-fullbody',
      'Full Body Principiante',
      'Adaptación muscular',
      'principiante',
      4,
      [
        { name: 'Sentadilla goblet', sets: 3, reps: '12', rest: '60s' },
        { name: 'Press de banca con mancuernas', sets: 3, reps: '10', rest: '75s' },
        { name: 'Remo con mancuerna', sets: 3, reps: '12', rest: '60s' },
        { name: 'Plancha', sets: 3, reps: '30s', rest: '45s' },
      ],
    ],
    [
      'rutina-hipertrofia',
      'Hipertrofia Upper/Lower',
      'Ganancia de masa muscular',
      'intermedio',
      8,
      [
        { name: 'Press banca barra', sets: 4, reps: '8-10', rest: '90s' },
        { name: 'Dominadas asistidas', sets: 4, reps: '8', rest: '90s' },
        { name: 'Prensa de piernas', sets: 4, reps: '12', rest: '75s' },
        { name: 'Elevaciones laterales', sets: 3, reps: '15', rest: '45s' },
      ],
    ],
    [
      'rutina-grasa',
      'Pérdida de grasa metabólica',
      'Definición y resistencia',
      'intermedio',
      6,
      [
        { name: 'Kettlebell swing', sets: 4, reps: '20', rest: '45s' },
        { name: 'Burpees', sets: 4, reps: '10', rest: '45s' },
        { name: 'Farmer walk', sets: 4, reps: '40m', rest: '60s' },
        { name: 'Bici asalto', sets: 4, reps: '30s', rest: '30s' },
      ],
    ],
    [
      'rutina-fuerza',
      'Fuerza 5x5',
      'Incremento de marcas',
      'avanzado',
      8,
      [
        { name: 'Sentadilla trasera', sets: 5, reps: '5', rest: '150s' },
        { name: 'Press banca', sets: 5, reps: '5', rest: '150s' },
        { name: 'Peso muerto', sets: 5, reps: '5', rest: '180s' },
        { name: 'Press militar', sets: 5, reps: '5', rest: '120s' },
      ],
    ],
  ];
  for (const [id, name, goal, level, weeks, exercises] of routines) {
    run(
      `INSERT INTO routines (id, name, goal, level, duration_weeks, exercises, created_at, updated_at)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
      [id, name, goal, level, weeks, JSON.stringify(exercises), ts, ts],
    );
  }

  const inventory = [
    ['inv-01', 'Mancuernas hexagonales (par 10kg)', 'pesas', 12, 'operativo', 'Sala de pesas'],
    ['inv-02', 'Barra olímpica 20kg', 'pesas', 8, 'operativo', 'Sala de pesas'],
    ['inv-03', 'Caminadora comercial', 'cardio', 6, 'operativo', 'Sala Cardio'],
    ['inv-04', 'Bicicleta spinning', 'cardio', 18, 'operativo', 'Sala Cardio'],
    ['inv-05', 'Kettlebell 16kg', 'funcional', 10, 'operativo', 'Zona Funcional'],
    ['inv-06', 'Colchoneta yoga', 'yoga', 20, 'operativo', 'Sala Yoga'],
    ['inv-07', 'Saco de boxeo', 'combate', 4, 'mantenimiento', 'Ring'],
    ['inv-08', 'Máquina smith', 'pesas', 2, 'operativo', 'Sala de pesas'],
    ['inv-09', 'Cuerda de batalla', 'funcional', 3, 'operativo', 'Zona Funcional'],
    ['inv-10', 'Remo Concept2', 'cardio', 3, 'fuera_de_servicio', 'Sala Cardio'],
  ];
  for (const [id, name, category, quantity, status, location] of inventory) {
    run(
      `INSERT INTO inventory (id, name, category, quantity, status, location, created_at, updated_at)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
      [id, name, category, quantity, status, location, ts, ts],
    );
  }

  if (createdClasses.length >= 3) {
    run(
      `INSERT INTO bookings (id, user_id, class_id, status, notes, created_at, updated_at)
       VALUES (?, ?, ?, ?, ?, ?, ?)`,
      ['book-001', 'user-yulied-001', createdClasses[0], 'confirmada', 'Reserva de demostración', ts, ts],
    );
    run(
      `INSERT INTO bookings (id, user_id, class_id, status, notes, created_at, updated_at)
       VALUES (?, ?, ?, ?, ?, ?, ?)`,
      ['book-002', 'user-yulied-001', createdClasses[2], 'pendiente', 'Esperando confirmación del admin', ts, ts],
    );
  }
}

export function publicUser(row) {
  if (!row) return null;
  return {
    id: row.id,
    name: row.name,
    email: row.email,
    role: row.role,
    phone: row.phone,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
  };
}

export function mapClass(row) {
  if (!row) return null;
  const taken = get(
    `SELECT COUNT(*) AS n FROM bookings WHERE class_id = ? AND status != 'cancelada'`,
    [row.id],
  )?.n ?? 0;
  return {
    id: row.id,
    name: row.name,
    description: row.description,
    trainer: row.trainer,
    startsAt: row.starts_at,
    durationMin: row.duration_min,
    capacity: row.capacity,
    available: Math.max(0, row.capacity - taken),
    room: row.room,
    difficulty: row.difficulty,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
  };
}

export function mapBooking(row) {
  if (!row) return null;
  const gymClass = get('SELECT * FROM classes WHERE id = ?', [row.class_id]);
  const user = get('SELECT * FROM users WHERE id = ?', [row.user_id]);
  return {
    id: row.id,
    userId: row.user_id,
    classId: row.class_id,
    status: row.status,
    notes: row.notes,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
    userName: user?.name ?? '',
    userEmail: user?.email ?? '',
    className: gymClass?.name ?? '',
    trainer: gymClass?.trainer ?? '',
    startsAt: gymClass?.starts_at ?? '',
    room: gymClass?.room ?? '',
  };
}

export function mapPlan(row) {
  if (!row) return null;
  let benefits = [];
  try {
    benefits = JSON.parse(row.benefits || '[]');
  } catch {
    benefits = [];
  }
  return {
    id: row.id,
    name: row.name,
    description: row.description,
    durationDays: row.duration_days,
    price: row.price,
    benefits,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
  };
}

export function mapMembership(row) {
  if (!row) return null;
  const plan = get('SELECT * FROM membership_plans WHERE id = ?', [row.plan_id]);
  return {
    id: row.id,
    userId: row.user_id,
    planId: row.plan_id,
    startDate: row.start_date,
    endDate: row.end_date,
    status: row.status,
    planName: plan?.name ?? '',
    createdAt: row.created_at,
    updatedAt: row.updated_at,
  };
}

export function mapRoutine(row) {
  if (!row) return null;
  let exercises = [];
  try {
    exercises = JSON.parse(row.exercises || '[]');
  } catch {
    exercises = [];
  }
  return {
    id: row.id,
    name: row.name,
    goal: row.goal,
    level: row.level,
    durationWeeks: row.duration_weeks,
    exercises,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
  };
}

export function mapInventory(row) {
  if (!row) return null;
  return {
    id: row.id,
    name: row.name,
    category: row.category,
    quantity: row.quantity,
    status: row.status,
    location: row.location,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
  };
}

export function snapshotSince(since) {
  const clause = since ? 'WHERE updated_at > ?' : '';
  const params = since ? [since] : [];
  return {
    users: all(`SELECT id, name, email, role, phone, created_at, updated_at FROM users ${clause}`, params).map(publicUser),
    classes: all(`SELECT * FROM classes ${clause}`, params).map(mapClass),
    bookings: all(`SELECT * FROM bookings ${clause}`, params).map(mapBooking),
    plans: all(`SELECT * FROM membership_plans ${clause}`, params).map(mapPlan),
    memberships: all(`SELECT * FROM memberships ${clause}`, params).map(mapMembership),
    routines: all(`SELECT * FROM routines ${clause}`, params).map(mapRoutine),
    inventory: all(`SELECT * FROM inventory ${clause}`, params).map(mapInventory),
  };
}
