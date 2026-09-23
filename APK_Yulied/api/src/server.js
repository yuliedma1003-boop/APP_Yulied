import express from 'express';
import cors from 'cors';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import os from 'node:os';
import {
  initSchema,
  seedIfEmpty,
  all,
  get,
  run,
  nowIso,
  publicUser,
  mapClass,
  mapBooking,
  mapPlan,
  mapMembership,
  mapRoutine,
  mapInventory,
  snapshotSince,
} from './db.js';

const PORT = Number(process.env.PORT || 3000);
const JWT_SECRET = process.env.JWT_SECRET || 'titanfit-sena-3311983-yulied-lopez';

initSchema();
seedIfEmpty();

const app = express();
app.use(cors());
app.use(express.json({ limit: '2mb' }));

function signToken(user) {
  return jwt.sign({ sub: user.id, role: user.role, email: user.email }, JWT_SECRET, { expiresIn: '7d' });
}

function auth(required = true) {
  return (req, res, next) => {
    const header = req.headers.authorization || '';
    const token = header.startsWith('Bearer ') ? header.slice(7) : null;
    if (!token) {
      if (!required) return next();
      return res.status(401).json({ ok: false, error: 'Token requerido' });
    }
    try {
      const payload = jwt.verify(token, JWT_SECRET);
      const user = get('SELECT * FROM users WHERE id = ?', [payload.sub]);
      if (!user) return res.status(401).json({ ok: false, error: 'Usuario no encontrado' });
      req.user = user;
      next();
    } catch {
      return res.status(401).json({ ok: false, error: 'Token inválido o vencido' });
    }
  };
}

function requireAdmin(req, res, next) {
  if (req.user?.role !== 'administrador') {
    return res.status(403).json({ ok: false, error: 'Solo el administrador puede realizar esta acción' });
  }
  next();
}

function ok(res, data, status = 200) {
  return res.status(status).json({ ok: true, data });
}

function fail(res, error, status = 400) {
  return res.status(status).json({ ok: false, error });
}

app.get('/api/health', (_req, res) => {
  ok(res, {
    service: 'TitanFit API',
    student: 'Yulied Marcela Lopez',
    ficha: '3311983',
    programa: 'ADSO - SENA',
    time: nowIso(),
  });
});

app.post('/api/auth/register', (req, res) => {
  const { id, name, email, password, phone } = req.body || {};
  if (!name || !email || !password) return fail(res, 'Nombre, correo y contraseña son obligatorios');
  if (String(password).length < 6) return fail(res, 'La contraseña debe tener al menos 6 caracteres');
  const exists = get('SELECT id FROM users WHERE email = ?', [String(email).trim().toLowerCase()]);
  if (exists) return fail(res, 'Ya existe una cuenta con ese correo', 409);
  const ts = nowIso();
  const userId = id || `user-${Date.now()}`;
  run(
    `INSERT INTO users (id, name, email, password_hash, role, phone, created_at, updated_at)
     VALUES (?, ?, ?, ?, 'cliente', ?, ?, ?)`,
    [userId, name.trim(), String(email).trim().toLowerCase(), bcrypt.hashSync(password, 10), phone || '', ts, ts],
  );
  const user = get('SELECT * FROM users WHERE id = ?', [userId]);
  return ok(res, { user: publicUser(user), token: signToken(user) }, 201);
});

app.post('/api/auth/login', (req, res) => {
  const { email, password } = req.body || {};
  if (!email || !password) return fail(res, 'Correo y contraseña son obligatorios');
  const user = get('SELECT * FROM users WHERE email = ?', [String(email).trim().toLowerCase()]);
  if (!user || !bcrypt.compareSync(password, user.password_hash)) {
    return fail(res, 'Credenciales incorrectas', 401);
  }
  return ok(res, { user: publicUser(user), token: signToken(user) });
});

app.get('/api/auth/me', auth(), (req, res) => ok(res, publicUser(req.user)));

app.get('/api/classes', auth(), (_req, res) => {
  const rows = all('SELECT * FROM classes ORDER BY starts_at ASC').map(mapClass);
  ok(res, rows);
});

app.post('/api/classes', auth(), requireAdmin, (req, res) => {
  const { id, name, description, trainer, startsAt, durationMin, capacity, room, difficulty } = req.body || {};
  if (!name || !trainer || !startsAt) return fail(res, 'Nombre, entrenador y fecha son obligatorios');
  const ts = nowIso();
  const classId = id || `class-${Date.now()}`;
  run(
    `INSERT INTO classes (id, name, description, trainer, starts_at, duration_min, capacity, room, difficulty, created_at, updated_at)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
    [classId, name, description || '', trainer, startsAt, durationMin || 45, capacity || 12, room || '', difficulty || 'intermedio', ts, ts],
  );
  ok(res, mapClass(get('SELECT * FROM classes WHERE id = ?', [classId])), 201);
});

app.put('/api/classes/:id', auth(), requireAdmin, (req, res) => {
  const current = get('SELECT * FROM classes WHERE id = ?', [req.params.id]);
  if (!current) return fail(res, 'Clase no encontrada', 404);
  const ts = nowIso();
  const next = {
    name: req.body.name ?? current.name,
    description: req.body.description ?? current.description,
    trainer: req.body.trainer ?? current.trainer,
    starts_at: req.body.startsAt ?? current.starts_at,
    duration_min: req.body.durationMin ?? current.duration_min,
    capacity: req.body.capacity ?? current.capacity,
    room: req.body.room ?? current.room,
    difficulty: req.body.difficulty ?? current.difficulty,
  };
  run(
    `UPDATE classes SET name=?, description=?, trainer=?, starts_at=?, duration_min=?, capacity=?, room=?, difficulty=?, updated_at=? WHERE id=?`,
    [next.name, next.description, next.trainer, next.starts_at, next.duration_min, next.capacity, next.room, next.difficulty, ts, req.params.id],
  );
  ok(res, mapClass(get('SELECT * FROM classes WHERE id = ?', [req.params.id])));
});

app.delete('/api/classes/:id', auth(), requireAdmin, (req, res) => {
  run('DELETE FROM bookings WHERE class_id = ?', [req.params.id]);
  run('DELETE FROM classes WHERE id = ?', [req.params.id]);
  ok(res, { id: req.params.id, deleted: true });
});

app.get('/api/bookings', auth(), (req, res) => {
  const rows = req.user.role === 'administrador'
    ? all('SELECT * FROM bookings ORDER BY created_at DESC')
    : all('SELECT * FROM bookings WHERE user_id = ? ORDER BY created_at DESC', [req.user.id]);
  ok(res, rows.map(mapBooking));
});

app.post('/api/bookings', auth(), (req, res) => {
  const { id, classId, notes, userId } = req.body || {};
  if (!classId) return fail(res, 'La clase es obligatoria');
  const gymClass = get('SELECT * FROM classes WHERE id = ?', [classId]);
  if (!gymClass) return fail(res, 'La clase no existe', 404);
  const ownerId = req.user.role === 'administrador' && userId ? userId : req.user.id;
  const taken = get(
    `SELECT COUNT(*) AS n FROM bookings WHERE class_id = ? AND status != 'cancelada'`,
    [classId],
  )?.n ?? 0;
  if (taken >= gymClass.capacity) return fail(res, 'La clase ya no tiene cupos');
  const duplicated = get(
    `SELECT id FROM bookings WHERE user_id = ? AND class_id = ? AND status != 'cancelada'`,
    [ownerId, classId],
  );
  if (duplicated) return fail(res, 'Ya tienes una reserva activa para esta clase');
  const ts = nowIso();
  const bookingId = id || `book-${Date.now()}`;
  run(
    `INSERT INTO bookings (id, user_id, class_id, status, notes, created_at, updated_at)
     VALUES (?, ?, ?, 'pendiente', ?, ?, ?)`,
    [bookingId, ownerId, classId, notes || '', ts, ts],
  );
  ok(res, mapBooking(get('SELECT * FROM bookings WHERE id = ?', [bookingId])), 201);
});

app.patch('/api/bookings/:id', auth(), (req, res) => {
  const booking = get('SELECT * FROM bookings WHERE id = ?', [req.params.id]);
  if (!booking) return fail(res, 'Reserva no encontrada', 404);
  const status = req.body.status;
  if (!['confirmada', 'cancelada', 'pendiente'].includes(status)) {
    return fail(res, 'Estado no válido');
  }
  const isOwner = booking.user_id === req.user.id;
  const isAdmin = req.user.role === 'administrador';
  if (status === 'cancelada' && !isOwner && !isAdmin) {
    return fail(res, 'No puedes cancelar la reserva de otra persona', 403);
  }
  if (status === 'confirmada' && !isAdmin) {
    return fail(res, 'Solo el administrador confirma reservas', 403);
  }
  if (status === 'pendiente' && !isAdmin) {
    return fail(res, 'Solo el administrador puede devolver una reserva a pendiente', 403);
  }
  const ts = nowIso();
  run('UPDATE bookings SET status = ?, updated_at = ? WHERE id = ?', [status, ts, booking.id]);
  ok(res, mapBooking(get('SELECT * FROM bookings WHERE id = ?', [booking.id])));
});

app.get('/api/memberships/plans', auth(), (_req, res) => {
  ok(res, all('SELECT * FROM membership_plans ORDER BY price ASC').map(mapPlan));
});

app.get('/api/memberships', auth(), (req, res) => {
  const rows = req.user.role === 'administrador'
    ? all('SELECT * FROM memberships ORDER BY created_at DESC')
    : all('SELECT * FROM memberships WHERE user_id = ? ORDER BY created_at DESC', [req.user.id]);
  ok(res, rows.map(mapMembership));
});

app.post('/api/memberships/subscribe', auth(), (req, res) => {
  const { id, planId } = req.body || {};
  const plan = get('SELECT * FROM membership_plans WHERE id = ?', [planId]);
  if (!plan) return fail(res, 'El plan no existe', 404);
  const ts = nowIso();
  const start = new Date();
  const end = new Date(start.getTime() + plan.duration_days * 86400000);
  run(
    `UPDATE memberships SET status = 'vencida', updated_at = ? WHERE user_id = ? AND status = 'activa'`,
    [ts, req.user.id],
  );
  const memId = id || `mem-${Date.now()}`;
  run(
    `INSERT INTO memberships (id, user_id, plan_id, start_date, end_date, status, created_at, updated_at)
     VALUES (?, ?, ?, ?, ?, 'activa', ?, ?)`,
    [memId, req.user.id, plan.id, start.toISOString().slice(0, 10), end.toISOString().slice(0, 10), ts, ts],
  );
  ok(res, mapMembership(get('SELECT * FROM memberships WHERE id = ?', [memId])), 201);
});

app.get('/api/routines', auth(), (_req, res) => {
  ok(res, all('SELECT * FROM routines ORDER BY name').map(mapRoutine));
});

app.get('/api/inventory', auth(), requireAdmin, (_req, res) => {
  ok(res, all('SELECT * FROM inventory ORDER BY name').map(mapInventory));
});

app.post('/api/inventory', auth(), requireAdmin, (req, res) => {
  const { id, name, category, quantity, status, location } = req.body || {};
  if (!name) return fail(res, 'El nombre del equipo es obligatorio');
  const ts = nowIso();
  const itemId = id || `inv-${Date.now()}`;
  run(
    `INSERT INTO inventory (id, name, category, quantity, status, location, created_at, updated_at)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
    [itemId, name, category || 'general', Number(quantity || 0), status || 'operativo', location || '', ts, ts],
  );
  ok(res, mapInventory(get('SELECT * FROM inventory WHERE id = ?', [itemId])), 201);
});

app.put('/api/inventory/:id', auth(), requireAdmin, (req, res) => {
  const current = get('SELECT * FROM inventory WHERE id = ?', [req.params.id]);
  if (!current) return fail(res, 'Equipo no encontrado', 404);
  const ts = nowIso();
  run(
    `UPDATE inventory SET name=?, category=?, quantity=?, status=?, location=?, updated_at=? WHERE id=?`,
    [
      req.body.name ?? current.name,
      req.body.category ?? current.category,
      req.body.quantity ?? current.quantity,
      req.body.status ?? current.status,
      req.body.location ?? current.location,
      ts,
      req.params.id,
    ],
  );
  ok(res, mapInventory(get('SELECT * FROM inventory WHERE id = ?', [req.params.id])));
});

app.delete('/api/inventory/:id', auth(), requireAdmin, (req, res) => {
  run('DELETE FROM inventory WHERE id = ?', [req.params.id]);
  ok(res, { id: req.params.id, deleted: true });
});

function upsertUser(record) {
  const ts = nowIso();
  const existing = get('SELECT * FROM users WHERE id = ? OR email = ?', [record.id, String(record.email || '').toLowerCase()]);
  if (existing) return publicUser(existing);
  if (!record.email || !record.password) return null;
  const id = record.id || `user-${Date.now()}`;
  run(
    `INSERT INTO users (id, name, email, password_hash, role, phone, created_at, updated_at)
     VALUES (?, ?, ?, ?, 'cliente', ?, ?, ?)`,
    [id, record.name || 'Usuario', String(record.email).toLowerCase(), bcrypt.hashSync(record.password, 10), record.phone || '', ts, ts],
  );
  return publicUser(get('SELECT * FROM users WHERE id = ?', [id]));
}

function applyChange(user, change) {
  const entity = change.entity;
  const operation = change.operation;
  const record = change.record || {};
  const ts = nowIso();

  if (entity === 'users' && operation === 'create') {
    return { entity, result: upsertUser(record) };
  }

  if (entity === 'bookings' && operation === 'create') {
    const classId = record.classId || record.class_id;
    const gymClass = get('SELECT * FROM classes WHERE id = ?', [classId]);
    if (!gymClass) return { entity, error: 'Clase no existe' };
    const ownerId = user.role === 'administrador' && record.userId ? record.userId : user.id;
    const exists = get('SELECT * FROM bookings WHERE id = ?', [record.id]);
    if (exists) return { entity, result: mapBooking(exists) };
    const duplicated = get(
      `SELECT id FROM bookings WHERE user_id = ? AND class_id = ? AND status != 'cancelada'`,
      [ownerId, classId],
    );
    if (duplicated) return { entity, result: mapBooking(get('SELECT * FROM bookings WHERE id = ?', [duplicated.id])) };
    run(
      `INSERT INTO bookings (id, user_id, class_id, status, notes, created_at, updated_at)
       VALUES (?, ?, ?, ?, ?, ?, ?)`,
      [record.id, ownerId, classId, record.status || 'pendiente', record.notes || '', ts, ts],
    );
    return { entity, result: mapBooking(get('SELECT * FROM bookings WHERE id = ?', [record.id])) };
  }

  if (entity === 'bookings' && operation === 'update') {
    const booking = get('SELECT * FROM bookings WHERE id = ?', [record.id]);
    if (!booking) return { entity, error: 'Reserva no existe' };
    const status = record.status || booking.status;
    const isOwner = booking.user_id === user.id;
    const isAdmin = user.role === 'administrador';
    if (status === 'confirmada' && !isAdmin) return { entity, error: 'Solo admin confirma' };
    if (status === 'pendiente' && !isAdmin) return { entity, error: 'Solo admin cambia a pendiente' };
    if (status === 'cancelada' && !isOwner && !isAdmin) return { entity, error: 'No autorizado' };
    run('UPDATE bookings SET status = ?, notes = ?, updated_at = ? WHERE id = ?', [
      status,
      record.notes ?? booking.notes,
      ts,
      booking.id,
    ]);
    return { entity, result: mapBooking(get('SELECT * FROM bookings WHERE id = ?', [booking.id])) };
  }

  if (entity === 'memberships' && operation === 'create') {
    const plan = get('SELECT * FROM membership_plans WHERE id = ?', [record.planId]);
    if (!plan) return { entity, error: 'Plan no existe' };
    const exists = get('SELECT * FROM memberships WHERE id = ?', [record.id]);
    if (exists) return { entity, result: mapMembership(exists) };
    run(`UPDATE memberships SET status = 'vencida', updated_at = ? WHERE user_id = ? AND status = 'activa'`, [ts, user.id]);
    const start = new Date();
    const end = new Date(start.getTime() + plan.duration_days * 86400000);
    run(
      `INSERT INTO memberships (id, user_id, plan_id, start_date, end_date, status, created_at, updated_at)
       VALUES (?, ?, ?, ?, ?, 'activa', ?, ?)`,
      [record.id, user.id, plan.id, start.toISOString().slice(0, 10), end.toISOString().slice(0, 10), ts, ts],
    );
    return { entity, result: mapMembership(get('SELECT * FROM memberships WHERE id = ?', [record.id])) };
  }

  if (entity === 'classes' && user.role === 'administrador') {
    if (operation === 'create') {
      const exists = get('SELECT * FROM classes WHERE id = ?', [record.id]);
      if (exists) return { entity, result: mapClass(exists) };
      run(
        `INSERT INTO classes (id, name, description, trainer, starts_at, duration_min, capacity, room, difficulty, created_at, updated_at)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
        [record.id, record.name, record.description || '', record.trainer, record.startsAt, record.durationMin || 45, record.capacity || 12, record.room || '', record.difficulty || 'intermedio', ts, ts],
      );
      return { entity, result: mapClass(get('SELECT * FROM classes WHERE id = ?', [record.id])) };
    }
    if (operation === 'update') {
      run(
        `UPDATE classes SET name=?, description=?, trainer=?, starts_at=?, duration_min=?, capacity=?, room=?, difficulty=?, updated_at=? WHERE id=?`,
        [record.name, record.description, record.trainer, record.startsAt, record.durationMin, record.capacity, record.room, record.difficulty, ts, record.id],
      );
      return { entity, result: mapClass(get('SELECT * FROM classes WHERE id = ?', [record.id])) };
    }
    if (operation === 'delete') {
      run('DELETE FROM bookings WHERE class_id = ?', [record.id]);
      run('DELETE FROM classes WHERE id = ?', [record.id]);
      return { entity, result: { id: record.id, deleted: true } };
    }
  }

  if (entity === 'inventory' && user.role === 'administrador') {
    if (operation === 'create') {
      const exists = get('SELECT * FROM inventory WHERE id = ?', [record.id]);
      if (exists) return { entity, result: mapInventory(exists) };
      run(
        `INSERT INTO inventory (id, name, category, quantity, status, location, created_at, updated_at)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
        [record.id, record.name, record.category || 'general', record.quantity || 0, record.status || 'operativo', record.location || '', ts, ts],
      );
      return { entity, result: mapInventory(get('SELECT * FROM inventory WHERE id = ?', [record.id])) };
    }
    if (operation === 'update') {
      run(
        `UPDATE inventory SET name=?, category=?, quantity=?, status=?, location=?, updated_at=? WHERE id=?`,
        [record.name, record.category, record.quantity, record.status, record.location, ts, record.id],
      );
      return { entity, result: mapInventory(get('SELECT * FROM inventory WHERE id = ?', [record.id])) };
    }
    if (operation === 'delete') {
      run('DELETE FROM inventory WHERE id = ?', [record.id]);
      return { entity, result: { id: record.id, deleted: true } };
    }
  }

  return { entity, error: 'Cambio no aplicado' };
}

app.post('/api/sync', auth(), (req, res) => {
  const changes = Array.isArray(req.body?.changes) ? req.body.changes : [];
  const since = req.body?.since || null;
  const applied = [];
  for (const change of changes) {
    try {
      applied.push(applyChange(req.user, change));
    } catch (error) {
      applied.push({ entity: change.entity, error: error.message });
    }
  }
  ok(res, {
    applied,
    snapshot: snapshotSince(since),
    serverTime: nowIso(),
  });
});

app.use((_req, res) => fail(res, 'Ruta no encontrada', 404));

app.listen(PORT, '0.0.0.0', () => {
  const nets = os.networkInterfaces();
  const ips = [];
  for (const list of Object.values(nets)) {
    for (const net of list || []) {
      if (net.family === 'IPv4' && !net.internal) ips.push(net.address);
    }
  }
  console.log(`TitanFit API lista en http://localhost:${PORT}`);
  for (const ip of ips) console.log(`LAN: http://${ip}:${PORT}`);
  console.log('Estudiante: Yulied Marcela Lopez | ADSO SENA 3311983');
});
