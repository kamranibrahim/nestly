/**
 * Seeds App Store showcase data for a Nestly account using the Firebase
 * client Auth + Firestore REST APIs (no Admin / service account required).
 *
 * Usage:
 *   NESTLY_PASSWORD='your-password' node tool/seed_appstore_client.mjs
 *   NESTLY_PASSWORD='...' node tool/seed_appstore_client.mjs other@email.com
 */
const EMAIL = (process.argv[2] || 'devtime3@gmail.com').trim().toLowerCase();
const PASSWORD = process.env.NESTLY_PASSWORD || process.argv[3] || '';
const API_KEY = 'AIzaSyBjOi7n11m9Hc82fOyD4zFUx2BtrnHmEhg'; // web key from firebase_options.dart
const PROJECT_ID = 'nestly-family-os';

const COLORS = {
  dad: 4290069222, // 0xFFB2B2E6
  mom: 4294290136, // 0xFFF5C6D8
  ayaan: 4292134835, // 0xFFD4E7B3
  noor: 4294955176, // 0xFFFFD8A8
};

function dayAt(base, hour, minute = 0, dayOffset = 0) {
  const d = new Date(base);
  d.setDate(d.getDate() + dayOffset);
  d.setHours(hour, minute, 0, 0);
  return d;
}

function startOfToday() {
  const n = new Date();
  return new Date(n.getFullYear(), n.getMonth(), n.getDate());
}

function tsValue(date) {
  return { timestampValue: date.toISOString() };
}
function str(v) {
  return { stringValue: v == null ? '' : String(v) };
}
function num(v) {
  return { doubleValue: Number(v) };
}
function int(v) {
  return { integerValue: String(Math.trunc(v)) };
}
function bool(v) {
  return { booleanValue: Boolean(v) };
}
function nil() {
  return { nullValue: null };
}

function docPath(...parts) {
  return `projects/${PROJECT_ID}/databases/(default)/documents/${parts.join('/')}`;
}

async function signIn(email, password) {
  const res = await fetch(
    `https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${API_KEY}`,
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email, password, returnSecureToken: true }),
    },
  );
  const json = await res.json();
  if (!res.ok) {
    throw new Error(`Sign-in failed: ${JSON.stringify(json)}`);
  }
  return json; // { idToken, localId, ... }
}

async function api(idToken, method, path, body) {
  const url = `https://firestore.googleapis.com/v1/${path}`;
  const res = await fetch(url, {
    method,
    headers: {
      Authorization: `Bearer ${idToken}`,
      'Content-Type': 'application/json',
    },
    body: body ? JSON.stringify(body) : undefined,
  });
  const text = await res.text();
  if (!res.ok) {
    throw new Error(`${method} ${path} → ${res.status}: ${text}`);
  }
  return text ? JSON.parse(text) : null;
}

async function getDoc(idToken, ...parts) {
  try {
    return await api(idToken, 'GET', docPath(...parts));
  } catch (err) {
    if (String(err.message).includes('404')) return null;
    throw err;
  }
}

async function upsertDoc(idToken, fields, ...parts) {
  return api(idToken, 'PATCH', docPath(...parts), { fields });
}

async function listDocs(idToken, ...parts) {
  const json = await api(idToken, 'GET', docPath(...parts));
  return json?.documents || [];
}

async function clearCollection(idToken, ...parts) {
  const docs = await listDocs(idToken, ...parts);
  for (const doc of docs) {
    await api(idToken, 'DELETE', doc.name);
  }
}

async function writeMany(idToken, collectionParts, docs) {
  for (const [id, fields] of Object.entries(docs)) {
    await upsertDoc(idToken, fields, ...collectionParts, id);
  }
}

function randomId() {
  return Math.random().toString(36).slice(2, 10).toUpperCase();
}

async function main() {
  if (!PASSWORD) {
    console.error(
      'Missing password. Run:\n  NESTLY_PASSWORD="..." node tool/seed_appstore_client.mjs',
    );
    process.exit(1);
  }

  const auth = await signIn(EMAIL, PASSWORD);
  const idToken = auth.idToken;
  const uid = auth.localId;
  console.log(`Signed in as ${EMAIL} (${uid})`);

  const now = new Date();
  const today = startOfToday();

  const userDoc = await getDoc(idToken, 'users', uid);
  let nestId = userDoc?.fields?.nestId?.stringValue;
  let inviteCode = 'SHOWCS';

  if (!nestId) {
    nestId = `nest_${randomId()}`;
    await upsertDoc(
      idToken,
      {
        name: str('The Ibrahims'),
        inviteCode: str(inviteCode),
        createdBy: str(uid),
        createdAt: tsValue(now),
        showcaseSeededAt: tsValue(now),
      },
      'nests',
      nestId,
    );
    await upsertDoc(
      idToken,
      { nestId: str(nestId), createdAt: tsValue(now) },
      'inviteCodes',
      inviteCode,
    );
    await upsertDoc(
      idToken,
      {
        email: str(EMAIL),
        displayName: str('Kamran Ibrahim'),
        nestId: str(nestId),
      },
      'users',
      uid,
    );
    console.log(`Created nest ${nestId}`);
  } else {
    const nestDoc = await getDoc(idToken, 'nests', nestId);
    inviteCode = nestDoc?.fields?.inviteCode?.stringValue || inviteCode;
    await upsertDoc(
      idToken,
      {
        name: str('The Ibrahims'),
        inviteCode: str(inviteCode),
        createdBy: nestDoc?.fields?.createdBy || str(uid),
        createdAt: nestDoc?.fields?.createdAt || tsValue(now),
        showcaseSeededAt: tsValue(now),
      },
      'nests',
      nestId,
    );
    console.log(`Using nest ${nestId} (${inviteCode})`);
  }

  for (const name of [
    'tasks',
    'shoppingLists',
    'shoppingItems',
    'events',
    'expenses',
    'bills',
    'emergency',
    'vault',
    'timeline',
    'meals',
    'care',
    'careProfiles',
    'school',
  ]) {
    await clearCollection(idToken, 'nests', nestId, name);
  }

  const dad = uid;

  await writeMany(idToken, ['nests', nestId, 'members'], {
    [dad]: {
      name: str('Kamran Ibrahim'),
      role: str('Dad'),
      initials: str('K'),
      colorValue: int(COLORS.dad),
      userId: str(uid),
      updatedAt: tsValue(now),
    },
    mom: {
      name: str('Sara Ibrahim'),
      role: str('Mom'),
      initials: str('S'),
      colorValue: int(COLORS.mom),
      updatedAt: tsValue(now),
    },
    ayaan: {
      name: str('Ayaan Ibrahim'),
      role: str('Son'),
      initials: str('A'),
      colorValue: int(COLORS.ayaan),
      updatedAt: tsValue(now),
    },
    noor: {
      name: str('Noor Ibrahim'),
      role: str('Daughter'),
      initials: str('N'),
      colorValue: int(COLORS.noor),
      updatedAt: tsValue(now),
    },
  });

  await writeMany(idToken, ['nests', nestId, 'tasks'], {
    'task-1': {
      title: str('School drop-off'),
      assigneeId: str(dad),
      dueLabel: str('Today'),
      done: bool(false),
      recurring: bool(true),
      createdAt: tsValue(now),
      updatedAt: tsValue(now),
    },
    'task-2': {
      title: str('Pack soccer kit'),
      assigneeId: str('ayaan'),
      dueLabel: str('Today'),
      done: bool(false),
      recurring: bool(false),
      createdAt: tsValue(now),
      updatedAt: tsValue(now),
    },
    'task-3': {
      title: str('Water the plants'),
      assigneeId: str('noor'),
      dueLabel: str('Today'),
      done: bool(true),
      recurring: bool(true),
      createdAt: tsValue(now),
      updatedAt: tsValue(now),
    },
    'task-4': {
      title: str('Prep family dinner'),
      assigneeId: str('mom'),
      dueLabel: str('Today'),
      done: bool(false),
      recurring: bool(true),
      createdAt: tsValue(now),
      updatedAt: tsValue(now),
    },
    'task-5': {
      title: str('Pay internet bill'),
      assigneeId: str(dad),
      dueLabel: str('Fri'),
      done: bool(false),
      recurring: bool(false),
      createdAt: tsValue(now),
      updatedAt: tsValue(now),
    },
    'task-6': {
      title: str('Sign permission slip'),
      assigneeId: str('mom'),
      dueLabel: str('Tomorrow'),
      done: bool(false),
      recurring: bool(false),
      createdAt: tsValue(now),
      updatedAt: tsValue(now),
    },
    'task-7': {
      title: str('Empty dishwasher'),
      assigneeId: str('ayaan'),
      dueLabel: str('Today'),
      done: bool(false),
      recurring: bool(true),
      createdAt: tsValue(now),
      updatedAt: tsValue(now),
    },
  });

  await writeMany(idToken, ['nests', nestId, 'shoppingLists'], {
    'list-groceries': {
      name: str('Family Groceries'),
      createdAt: tsValue(now),
      updatedAt: tsValue(now),
    },
  });

  await writeMany(idToken, ['nests', nestId, 'shoppingItems'], {
    'item-1': {
      listId: str('list-groceries'),
      name: str('Organic milk'),
      category: str('Dairy'),
      qty: str('2 L'),
      done: bool(false),
      sortOrder: int(0),
      createdAt: tsValue(now),
      updatedAt: tsValue(now),
    },
    'item-2': {
      listId: str('list-groceries'),
      name: str('Free-range eggs'),
      category: str('Dairy'),
      qty: str('12'),
      done: bool(false),
      sortOrder: int(1),
      createdAt: tsValue(now),
      updatedAt: tsValue(now),
    },
    'item-3': {
      listId: str('list-groceries'),
      name: str('Bananas'),
      category: str('Produce'),
      qty: str('1 kg'),
      done: bool(true),
      sortOrder: int(2),
      createdAt: tsValue(now),
      updatedAt: tsValue(now),
    },
    'item-4': {
      listId: str('list-groceries'),
      name: str('Chicken breast'),
      category: str('Meat'),
      qty: str('1 kg'),
      done: bool(false),
      sortOrder: int(3),
      createdAt: tsValue(now),
      updatedAt: tsValue(now),
    },
    'item-5': {
      listId: str('list-groceries'),
      name: str('Sourdough bread'),
      category: str('Bakery'),
      qty: str('2'),
      done: bool(false),
      sortOrder: int(4),
      createdAt: tsValue(now),
      updatedAt: tsValue(now),
    },
    'item-6': {
      listId: str('list-groceries'),
      name: str('Baby spinach'),
      category: str('Produce'),
      qty: str('200 g'),
      done: bool(false),
      sortOrder: int(5),
      createdAt: tsValue(now),
      updatedAt: tsValue(now),
    },
    'item-7': {
      listId: str('list-groceries'),
      name: str('Dish soap'),
      category: str('Home'),
      qty: str('1'),
      done: bool(false),
      sortOrder: int(6),
      createdAt: tsValue(now),
      updatedAt: tsValue(now),
    },
    'item-8': {
      listId: str('list-groceries'),
      name: str('Greek yogurt'),
      category: str('Dairy'),
      qty: str('4'),
      done: bool(true),
      sortOrder: int(7),
      createdAt: tsValue(now),
      updatedAt: tsValue(now),
    },
  });

  await writeMany(idToken, ['nests', nestId, 'events'], {
    'event-1': {
      title: str('School drop-off'),
      memberId: str(dad),
      category: str('School'),
      location: str('Greenfield Academy'),
      startsAt: tsValue(dayAt(today, 7, 45)),
      endsAt: tsValue(dayAt(today, 8, 15)),
      allDay: bool(false),
      createdAt: tsValue(now),
      updatedAt: tsValue(now),
    },
    'event-2': {
      title: str('Dentist — Noor'),
      memberId: str('mom'),
      category: str('Health'),
      location: str('SmileCare Clinic'),
      startsAt: tsValue(dayAt(today, 11, 30)),
      endsAt: tsValue(dayAt(today, 12, 15)),
      allDay: bool(false),
      createdAt: tsValue(now),
      updatedAt: tsValue(now),
    },
    'event-3': {
      title: str('Soccer practice'),
      memberId: str('ayaan'),
      category: str('Sports'),
      location: str('City Field B'),
      startsAt: tsValue(dayAt(today, 16, 30)),
      endsAt: tsValue(dayAt(today, 18, 0)),
      allDay: bool(false),
      createdAt: tsValue(now),
      updatedAt: tsValue(now),
    },
    'event-4': {
      title: str('Family dinner'),
      memberId: str('mom'),
      category: str('Family'),
      location: str('Home'),
      startsAt: tsValue(dayAt(today, 19, 0)),
      endsAt: tsValue(dayAt(today, 20, 0)),
      allDay: bool(false),
      createdAt: tsValue(now),
      updatedAt: tsValue(now),
    },
    'event-5': {
      title: str('Parent-teacher meeting'),
      memberId: str(dad),
      category: str('School'),
      location: str('Greenfield Academy'),
      startsAt: tsValue(dayAt(today, 15, 0, 1)),
      endsAt: tsValue(dayAt(today, 15, 45, 1)),
      allDay: bool(false),
      createdAt: tsValue(now),
      updatedAt: tsValue(now),
    },
    'event-6': {
      title: str("Ayaan's birthday"),
      memberId: str('ayaan'),
      category: str('Birthday'),
      location: nil(),
      startsAt: tsValue(dayAt(today, 0, 0, 4)),
      endsAt: nil(),
      allDay: bool(true),
      createdAt: tsValue(now),
      updatedAt: tsValue(now),
    },
    'event-7': {
      title: str('Car service'),
      memberId: str(dad),
      category: str('Home'),
      location: str('AutoCare Center'),
      startsAt: tsValue(dayAt(today, 10, 0, 5)),
      endsAt: tsValue(dayAt(today, 12, 0, 5)),
      allDay: bool(false),
      createdAt: tsValue(now),
      updatedAt: tsValue(now),
    },
  });

  await writeMany(idToken, ['nests', nestId, 'expenses'], {
    'exp-1': {
      title: str('Weekly groceries'),
      category: str('Groceries'),
      amount: num(86.4),
      paidBy: str('Kamran'),
      spentAt: tsValue(today),
      createdAt: tsValue(now),
      updatedAt: tsValue(now),
    },
    'exp-2': {
      title: str('Fuel'),
      category: str('Transport'),
      amount: num(42),
      paidBy: str('Sara'),
      spentAt: tsValue(dayAt(today, 12, 0, -1)),
      createdAt: tsValue(now),
      updatedAt: tsValue(now),
    },
    'exp-3': {
      title: str('School supplies'),
      category: str('Kids'),
      amount: num(28.5),
      paidBy: str('Sara'),
      spentAt: tsValue(dayAt(today, 12, 0, -3)),
      createdAt: tsValue(now),
      updatedAt: tsValue(now),
    },
    'exp-4': {
      title: str('Plumbing fix'),
      category: str('Home'),
      amount: num(120),
      paidBy: str('Kamran'),
      spentAt: tsValue(dayAt(today, 12, 0, -5)),
      createdAt: tsValue(now),
      updatedAt: tsValue(now),
    },
    'exp-5': {
      title: str('Soccer club fees'),
      category: str('Kids'),
      amount: num(65),
      paidBy: str('Kamran'),
      spentAt: tsValue(dayAt(today, 12, 0, -7)),
      createdAt: tsValue(now),
      updatedAt: tsValue(now),
    },
  });

  await writeMany(idToken, ['nests', nestId, 'bills'], {
    'bill-1': {
      title: str('Electricity'),
      amount: num(64.2),
      dueAt: tsValue(dayAt(today, 9, 0, 3)),
      paid: bool(false),
      createdAt: tsValue(now),
      updatedAt: tsValue(now),
    },
    'bill-2': {
      title: str('Internet'),
      amount: num(49.99),
      dueAt: tsValue(dayAt(today, 9, 0, 5)),
      paid: bool(false),
      createdAt: tsValue(now),
      updatedAt: tsValue(now),
    },
    'bill-3': {
      title: str('Water'),
      amount: num(22.5),
      dueAt: tsValue(dayAt(today, 9, 0, -2)),
      paid: bool(true),
      createdAt: tsValue(now),
      updatedAt: tsValue(now),
    },
    'bill-4': {
      title: str('Rent'),
      amount: num(1450),
      dueAt: tsValue(dayAt(today, 9, 0, 8)),
      paid: bool(false),
      createdAt: tsValue(now),
      updatedAt: tsValue(now),
    },
  });

  await writeMany(idToken, ['nests', nestId, 'emergency'], {
    'em-1': {
      label: str('Emergency contact'),
      value: str('Omar Ibrahim · +1 555 0142'),
      iconName: str('phone'),
      sortOrder: int(0),
      updatedAt: tsValue(now),
    },
    'em-2': {
      label: str('Family doctor'),
      value: str('Dr. Patel · City Care'),
      iconName: str('doctor'),
      sortOrder: int(1),
      updatedAt: tsValue(now),
    },
    'em-3': {
      label: str('Nearest hospital'),
      value: str('Riverside General · 8 min'),
      iconName: str('hospital'),
      sortOrder: int(2),
      updatedAt: tsValue(now),
    },
    'em-4': {
      label: str('Allergies'),
      value: str('Ayaan — peanuts · Noor — none'),
      iconName: str('warning'),
      sortOrder: int(3),
      updatedAt: tsValue(now),
    },
    'em-5': {
      label: str('Blood groups'),
      value: str('K O+ · S A+ · A B+ · N O+'),
      iconName: str('blood'),
      sortOrder: int(4),
      updatedAt: tsValue(now),
    },
    'em-6': {
      label: str('Insurance'),
      value: str('HealthPlus Family · #HP-88241'),
      iconName: str('shield'),
      sortOrder: int(5),
      updatedAt: tsValue(now),
    },
  });

  await writeMany(idToken, ['nests', nestId, 'vault'], {
    'vault-1': {
      title: str('Passports'),
      category: str('IDs'),
      fileName: str('passports.pdf'),
      storagePath: nil(),
      mimeType: str('application/pdf'),
      sizeBytes: int(245000),
      notes: str('Family passports — renew Noor 2027'),
      expiresAt: tsValue(dayAt(today, 0, 0, 400)),
      createdAt: tsValue(dayAt(today, 12, 0, -14)),
      updatedAt: tsValue(dayAt(today, 12, 0, -14)),
    },
    'vault-2': {
      title: str('Car insurance'),
      category: str('Car'),
      fileName: str('car-insurance.pdf'),
      storagePath: nil(),
      mimeType: str('application/pdf'),
      sizeBytes: int(180000),
      notes: str('Policy #CI-44102'),
      expiresAt: tsValue(dayAt(today, 0, 0, 90)),
      createdAt: tsValue(dayAt(today, 12, 0, -1)),
      updatedAt: tsValue(dayAt(today, 12, 0, -1)),
    },
    'vault-3': {
      title: str('Birth certificates'),
      category: str('IDs'),
      fileName: str('birth-certificates.pdf'),
      storagePath: nil(),
      mimeType: str('application/pdf'),
      sizeBytes: int(320000),
      notes: str(''),
      expiresAt: nil(),
      createdAt: tsValue(dayAt(today, 12, 0, -60)),
      updatedAt: tsValue(dayAt(today, 12, 0, -60)),
    },
    'vault-4': {
      title: str('Home warranty'),
      category: str('Home'),
      fileName: str('home-warranty.pdf'),
      storagePath: nil(),
      mimeType: str('application/pdf'),
      sizeBytes: int(150000),
      notes: str('Covers HVAC + appliances'),
      expiresAt: tsValue(dayAt(today, 0, 0, 200)),
      createdAt: tsValue(dayAt(today, 12, 0, -120)),
      updatedAt: tsValue(dayAt(today, 12, 0, -120)),
    },
    'vault-5': {
      title: str('School records'),
      category: str('Family'),
      fileName: str('school-records.pdf'),
      storagePath: nil(),
      mimeType: str('application/pdf'),
      sizeBytes: int(410000),
      notes: str('Ayaan + Noor 2025–26'),
      expiresAt: nil(),
      createdAt: tsValue(dayAt(today, 12, 0, -7)),
      updatedAt: tsValue(dayAt(today, 12, 0, -7)),
    },
  });

  await writeMany(idToken, ['nests', nestId, 'timeline'], {
    'tl-1': {
      message: str('Kamran completed grocery shopping'),
      memberId: str(dad),
      memberName: str('Kamran'),
      createdAt: tsValue(new Date(now.getTime() - 20 * 60 * 1000)),
    },
    'tl-2': {
      message: str('Sara uploaded car insurance'),
      memberId: str('mom'),
      memberName: str('Sara'),
      createdAt: tsValue(new Date(now.getTime() - 60 * 60 * 1000)),
    },
    'tl-3': {
      message: str('Noor watered the plants'),
      memberId: str('noor'),
      memberName: str('Noor'),
      createdAt: tsValue(new Date(now.getTime() - 2 * 60 * 60 * 1000)),
    },
    'tl-4': {
      message: str('Ayaan added soccer practice'),
      memberId: str('ayaan'),
      memberName: str('Ayaan'),
      createdAt: tsValue(dayAt(today, 18, 0, -1)),
    },
    'tl-5': {
      message: str('Water bill marked as paid'),
      memberId: str(dad),
      memberName: str('Kamran'),
      createdAt: tsValue(dayAt(today, 10, 0, -1)),
    },
  });

  await writeMany(idToken, ['nests', nestId, 'meals'], {
    'meal-1': {
      weekday: int(1),
      mealType: str('Dinner'),
      title: str('Lemon herb chicken'),
      ingredients: str('chicken breast, lemon, garlic, spinach, rice'),
      createdAt: tsValue(now),
      updatedAt: tsValue(now),
    },
    'meal-2': {
      weekday: int(2),
      mealType: str('Dinner'),
      title: str('Pasta primavera'),
      ingredients: str('pasta, zucchini, cherry tomatoes, parmesan'),
      createdAt: tsValue(now),
      updatedAt: tsValue(now),
    },
    'meal-3': {
      weekday: int(3),
      mealType: str('Dinner'),
      title: str('Fish tacos'),
      ingredients: str('white fish, tortillas, cabbage, lime, yogurt'),
      createdAt: tsValue(now),
      updatedAt: tsValue(now),
    },
    'meal-4': {
      weekday: int(4),
      mealType: str('Dinner'),
      title: str('Beef stir-fry'),
      ingredients: str('beef, broccoli, soy sauce, ginger, rice'),
      createdAt: tsValue(now),
      updatedAt: tsValue(now),
    },
    'meal-5': {
      weekday: int(5),
      mealType: str('Dinner'),
      title: str('Homemade pizza night'),
      ingredients: str('pizza dough, mozzarella, tomato sauce, basil'),
      createdAt: tsValue(now),
      updatedAt: tsValue(now),
    },
    'meal-6': {
      weekday: int(6),
      mealType: str('Dinner'),
      title: str('Grill & salad'),
      ingredients: str('burgers, buns, mixed greens, avocado'),
      createdAt: tsValue(now),
      updatedAt: tsValue(now),
    },
    'meal-7': {
      weekday: int(7),
      mealType: str('Dinner'),
      title: str('Roast chicken Sunday'),
      ingredients: str('whole chicken, potatoes, carrots, rosemary'),
      createdAt: tsValue(now),
      updatedAt: tsValue(now),
    },
  });

  await writeMany(idToken, ['nests', nestId, 'care'], {
    'care-1': {
      title: str('Walk Milo'),
      category: str('Pet'),
      cadenceDays: int(1),
      lastDoneAt: tsValue(dayAt(today, 7, 0)),
      nextDueAt: tsValue(dayAt(today, 18, 0)),
      notes: str('Evening walk around the park'),
      memberId: str('ayaan'),
      createdAt: tsValue(now),
      updatedAt: tsValue(now),
    },
    'care-2': {
      title: str('Change HVAC filter'),
      category: str('Home'),
      cadenceDays: int(90),
      lastDoneAt: tsValue(dayAt(today, 12, 0, -60)),
      nextDueAt: tsValue(dayAt(today, 12, 0, 30)),
      notes: str('Filters in utility closet'),
      memberId: str(dad),
      createdAt: tsValue(now),
      updatedAt: tsValue(now),
    },
    'care-3': {
      title: str('Car oil check'),
      category: str('Car'),
      cadenceDays: int(30),
      lastDoneAt: tsValue(dayAt(today, 12, 0, -20)),
      nextDueAt: tsValue(dayAt(today, 12, 0, 10)),
      notes: str('Honda CR-V'),
      memberId: str(dad),
      createdAt: tsValue(now),
      updatedAt: tsValue(now),
    },
    'care-4': {
      title: str('Water houseplants'),
      category: str('Home'),
      cadenceDays: int(3),
      lastDoneAt: tsValue(dayAt(today, 9, 0, -1)),
      nextDueAt: tsValue(dayAt(today, 9, 0, 2)),
      notes: str(''),
      memberId: str('noor'),
      createdAt: tsValue(now),
      updatedAt: tsValue(now),
    },
  });

  await writeMany(idToken, ['nests', nestId, 'careProfiles'], {
    ayaan: {
      memberId: str('ayaan'),
      medications: str(''),
      allergies: str('Peanuts — EpiPen in backpack'),
      mobilityNotes: str(''),
      primaryDoctor: str('Dr. Patel · City Care'),
      notes: str('Soccer season — keep inhaler for asthma flare-ups'),
      createdAt: tsValue(now),
      updatedAt: tsValue(now),
    },
    noor: {
      memberId: str('noor'),
      medications: str(''),
      allergies: str('None'),
      mobilityNotes: str(''),
      primaryDoctor: str('Dr. Patel · City Care'),
      notes: str('Upcoming dentist checkup today'),
      createdAt: tsValue(now),
      updatedAt: tsValue(now),
    },
  });

  await writeMany(idToken, ['nests', nestId, 'school'], {
    'school-1': {
      title: str('Morning drop-off'),
      kind: str('Pickup'),
      cadenceDays: int(1),
      lastDoneAt: tsValue(dayAt(today, 7, 45, -1)),
      nextAt: tsValue(dayAt(today, 7, 45)),
      location: str('Greenfield Academy'),
      memberId: str(dad),
      notes: str('Main gate'),
      createdAt: tsValue(now),
      updatedAt: tsValue(now),
    },
    'school-2': {
      title: str('Soccer practice'),
      kind: str('Sports'),
      cadenceDays: int(7),
      lastDoneAt: tsValue(dayAt(today, 16, 30, -7)),
      nextAt: tsValue(dayAt(today, 16, 30)),
      location: str('City Field B'),
      memberId: str('ayaan'),
      notes: str('Bring water bottle + shin guards'),
      createdAt: tsValue(now),
      updatedAt: tsValue(now),
    },
    'school-3': {
      title: str('Piano lesson'),
      kind: str('Club'),
      cadenceDays: int(7),
      lastDoneAt: tsValue(dayAt(today, 16, 0, -3)),
      nextAt: tsValue(dayAt(today, 16, 0, 4)),
      location: str('Harmony Music'),
      memberId: str('noor'),
      notes: str('Book bag with sheet music'),
      createdAt: tsValue(now),
      updatedAt: tsValue(now),
    },
    'school-4': {
      title: str('Afternoon pickup'),
      kind: str('Pickup'),
      cadenceDays: int(1),
      lastDoneAt: tsValue(dayAt(today, 15, 15, -1)),
      nextAt: tsValue(dayAt(today, 15, 15)),
      location: str('Greenfield Academy'),
      memberId: str('mom'),
      notes: str('Car line B'),
      createdAt: tsValue(now),
      updatedAt: tsValue(now),
    },
  });

  await upsertDoc(
    idToken,
    {
      email: str(EMAIL),
      displayName: str('Kamran Ibrahim'),
      nestId: str(nestId),
      showcaseSeededAt: tsValue(now),
    },
    'users',
    uid,
  );

  console.log('Showcase seed complete.');
  console.log(
    JSON.stringify(
      {
        email: EMAIL,
        uid,
        nestId,
        inviteCode,
        nestName: 'The Ibrahims',
      },
      null,
      2,
    ),
  );
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
