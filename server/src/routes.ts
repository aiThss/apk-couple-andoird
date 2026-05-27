import crypto from 'node:crypto';
import fs from 'node:fs';
import path from 'node:path';
import bcrypt from 'bcryptjs';
import express from 'express';
import multer from 'multer';
import { z } from 'zod';
import { config } from './config.js';
import { requireAdmin, requireUser } from './auth.js';
import { HttpError } from './errors.js';
import { sendVerificationEmail } from './mailer.js';
import {
  Couple,
  Photo,
  RandomEvent,
  User,
  VerificationCode,
  type CoupleDocument,
  type UserDocument,
  type VerificationPurpose,
} from './models.js';
import {
  serializeCouple,
  serializePhoto,
  serializeRandomEvent,
  serializeUser,
} from './serializers.js';
import { signToken } from './tokens.js';

const router = express.Router();

const codeTtlMs = 10 * 60 * 1000;
const codeCooldownMs = 60 * 1000;
const maxCodeAttempts = 5;

fs.mkdirSync(config.uploadDir, { recursive: true });

const upload = multer({
  storage: multer.diskStorage({
    destination: (_req, _file, cb) => cb(null, config.uploadDir),
    filename: (_req, file, cb) => {
      const ext = path.extname(file.originalname || '').toLowerCase() || '.jpg';
      cb(null, `${Date.now()}-${Math.random().toString(16).slice(2)}${ext}`);
    },
  }),
  limits: { fileSize: 10 * 1024 * 1024 },
  fileFilter: (_req, file, cb) => {
    if (!file.mimetype.startsWith('image/')) {
      cb(new HttpError(400, 'Only image uploads are allowed'));
      return;
    }
    cb(null, true);
  },
});

const optionalString = z.string().trim().optional().or(z.literal(''));
const optionalCode = z.string().trim().regex(/^\d{6}$/).optional().or(z.literal(''));

const authSchema = z.object({
  displayName: z.string().trim().min(1).max(80),
  partnerName: z.string().trim().min(1).max(80),
  coupleCode: z.string().trim().min(3).max(32),
  loveStartDate: z.coerce.date(),
  email: z.string().trim().email().optional().or(z.literal('')),
  password: z.string().min(6).max(128).optional().or(z.literal('')),
  deviceId: optionalString,
  emailCode: optionalCode,
});

const loginSchema = z.object({
  email: z.string().trim().email(),
  password: z.string().min(6).max(128),
  deviceId: optionalString,
  emailCode: optionalCode,
});

const requestCodeSchema = z.object({
  email: z.string().trim().email(),
  deviceId: z.string().trim().min(8).max(160),
  purpose: z.enum(['signup', 'device']).optional(),
});

const profileSchema = z.object({
  displayName: z.string().trim().min(1).max(80).optional(),
  partnerName: z.string().trim().min(1).max(80).optional(),
  loveStartDate: z.coerce.date().optional(),
});

const randomDrawSchema = z.object({
  category: z
    .enum(['question', 'challenge', 'date', 'food', 'cosmic'])
    .default('question'),
});

const adminLoginSchema = z.object({
  email: z.string().trim().email(),
  password: z.string().min(1),
});

const randomCategories = [
  {
    key: 'question',
    label: 'Cau hoi doi minh',
    description: 'Mot cau hoi nho de hai nguoi noi chuyen that hon.',
  },
  {
    key: 'challenge',
    label: 'Thu thach snap',
    description: 'Goi y chup mot khoanh khac de gui cho nguoi ay.',
  },
  {
    key: 'date',
    label: 'Hom nay lam gi',
    description: 'Mot y tuong hen ho hoac cung nhau lam gi do.',
  },
  {
    key: 'food',
    label: 'An gi bay gio',
    description: 'De vu tru chon mon cho hai nguoi.',
  },
  {
    key: 'cosmic',
    label: 'Tin hieu vu tru',
    description: 'Mot thong diep nhe nhang cho ngay hom nay.',
  },
] as const;

const randomPrompts: Record<
  string,
  Array<{
    prompt: string;
    detail?: string;
  }>
> = {
  question: [
    { prompt: 'Hom nay co dieu gi nho xiu lam em/anh vui khong?' },
    { prompt: 'Neu duoc tua lai mot khoanh khac cua hai dua, ban chon luc nao?' },
    { prompt: 'Dieu gi o nguoi ay lam ban thay yen tam nhat?' },
    { prompt: 'Neu toi nay goi video 15 phut, ban muon ke chuyen gi dau tien?' },
    { prompt: 'Mot loi khen that long ma ban muon gui cho nguoi ay la gi?' },
  ],
  challenge: [
    {
      prompt: 'Chup mot thu dang o ngay ben trai ban.',
      detail: 'Caption goi y: "em/anh thay cai nay dau tien ne".',
    },
    {
      prompt: 'Gui mot snap voi bieu cam dang yeu nhat trong 3 giay.',
      detail: 'Khong can dep, can that.',
    },
    { prompt: 'Chup bau troi hoac anh sang gan ban nhat luc nay.' },
    { prompt: 'Chup mot goc ban lam viec/hoc tap hien tai.' },
    { prompt: 'Gui mot tam anh co trai tim an dau do trong khung hinh.' },
  ],
  date: [
    { prompt: 'Dat lich xem phim cung nhau toi nay.' },
    { prompt: 'Di an mot mon ca hai lau roi chua an.' },
    { prompt: 'Cung nhau di dao 20 phut va khong cam dien thoai.' },
    { prompt: 'Viet cho nhau 3 dieu biet on trong ngay.' },
    { prompt: 'Chon mot bai nhac lam nhac nen cho ngay hom nay.' },
  ],
  food: [
    { prompt: 'Pho hoac bun bo', detail: 'Mon am nong, hop luc can nap lai nang luong.' },
    { prompt: 'Tra sua size nho', detail: 'Du vui, khong qua toi loi.' },
    { prompt: 'Com tam', detail: 'Lua chon chac bung va de vui.' },
    { prompt: 'Mi cay', detail: 'Neu hom nay can mot chut kich thich.' },
    { prompt: 'Banh mi', detail: 'Nhanh, gon, khong can nghi nhieu.' },
  ],
  cosmic: [
    {
      prompt: 'Hom nay hay noi mot cau nhe nhang voi nguoi ay truoc khi ngu.',
      detail: 'Mot tin nhan nho doi khi giu ca ngay lai.',
    },
    {
      prompt: 'Vu tru bao rang hai dua nen chup them mot tam anh binh thuong.',
      detail: 'Nhung tam binh thuong thuong la ky niem lau nhat.',
    },
    {
      prompt: 'Dung doi dung luc moi gui yeu thuong.',
      detail: 'Gui ngay khi nghi toi.',
    },
    {
      prompt: 'Neu hom nay met, chi can noi that la minh met.',
      detail: 'Rieng tu va an toan la ly do app nay ton tai.',
    },
  ],
};

function normalizeCoupleCode(value: string): string {
  return value.trim().toUpperCase().replace(/\s+/g, '-');
}

function normalizeEmail(value: string): string {
  return value.trim().toLowerCase();
}

function normalizeOptional(value?: string): string | undefined {
  const trimmed = value?.trim();
  return trimmed ? trimmed : undefined;
}

function requireDeviceId(value?: string): string {
  const deviceId = normalizeOptional(value);
  if (!deviceId) {
    throw new HttpError(400, 'Device id is required', 'DEVICE_ID_REQUIRED');
  }
  return deviceId;
}

function codeHash(
  email: string,
  purpose: VerificationPurpose,
  deviceId: string,
  code: string,
): string {
  return crypto
    .createHash('sha256')
    .update(`${email}:${purpose}:${deviceId}:${code}:${config.jwtSecret}`)
    .digest('hex');
}

function generateCode(): string {
  return crypto.randomInt(100000, 1000000).toString();
}

function hasTrustedDevice(user: UserDocument, deviceId: string): boolean {
  return user.trustedDevices?.some((device) => device.deviceId === deviceId) ?? false;
}

function trustDevice(user: UserDocument, deviceId: string) {
  const now = new Date();
  const existing = user.trustedDevices?.find((device) => device.deviceId === deviceId);
  if (existing) {
    existing.lastSeenAt = now;
    return;
  }

  user.trustedDevices.push({
    deviceId,
    createdAt: now,
    lastSeenAt: now,
  });
}

function trustedDevice(deviceId: string) {
  const now = new Date();
  return {
    deviceId,
    createdAt: now,
    lastSeenAt: now,
  };
}

async function requestVerificationCode(
  email: string,
  purpose: VerificationPurpose,
  deviceId: string,
) {
  const now = new Date();
  const recent = await VerificationCode.findOne({
    email,
    purpose,
    deviceId,
    consumedAt: { $exists: false },
    expiresAt: { $gt: now },
  }).sort({ createdAt: -1 });

  if (recent && now.getTime() - recent.createdAt.getTime() < codeCooldownMs) {
    throw new HttpError(
      429,
      'Please wait before requesting another code',
      'EMAIL_CODE_COOLDOWN',
    );
  }

  const code = generateCode();
  await VerificationCode.create({
    email,
    purpose,
    deviceId,
    codeHash: codeHash(email, purpose, deviceId, code),
    attempts: 0,
    expiresAt: new Date(now.getTime() + codeTtlMs),
  });

  await sendVerificationEmail(email, code);
}

async function verifyEmailCode(
  email: string,
  purpose: VerificationPurpose,
  deviceId: string,
  code?: string,
) {
  const normalizedCode = normalizeOptional(code);
  if (!normalizedCode) {
    throw new HttpError(
      428,
      'Email verification code required',
      'EMAIL_CODE_REQUIRED',
    );
  }

  const verification = await VerificationCode.findOne({
    email,
    purpose,
    deviceId,
    consumedAt: { $exists: false },
    expiresAt: { $gt: new Date() },
  }).sort({ createdAt: -1 });

  if (!verification) {
    throw new HttpError(401, 'Invalid or expired email code', 'INVALID_EMAIL_CODE');
  }

  if (verification.attempts >= maxCodeAttempts) {
    throw new HttpError(429, 'Too many code attempts', 'EMAIL_CODE_LOCKED');
  }

  if (verification.codeHash !== codeHash(email, purpose, deviceId, normalizedCode)) {
    verification.attempts += 1;
    await verification.save();
    throw new HttpError(401, 'Invalid or expired email code', 'INVALID_EMAIL_CODE');
  }

  verification.consumedAt = new Date();
  await verification.save();
}

async function ensureTrustedEmailDevice(
  user: UserDocument,
  deviceId: string,
  emailCode?: string,
) {
  if (hasTrustedDevice(user, deviceId)) {
    trustDevice(user, deviceId);
    return;
  }

  await verifyEmailCode(user.email!, 'device', deviceId, emailCode);
  user.emailVerifiedAt ??= new Date();
  trustDevice(user, deviceId);
}

async function findOrCreateCouple(
  code: string,
  loveStartDate: Date,
  user: UserDocument,
): Promise<CoupleDocument> {
  let couple = await Couple.findOne({ code });
  if (!couple) {
    couple = await Couple.create({
      code,
      loveStartDate,
      memberIds: [user._id],
    });
    return couple;
  }

  const alreadyMember = couple.memberIds.some((id) => id.equals(user._id));
  if (!alreadyMember && couple.memberIds.length >= 2) {
    throw new HttpError(409, 'Couple code already has two members');
  }

  if (!alreadyMember) {
    couple.memberIds.push(user._id);
  }

  if (alreadyMember) {
    couple.loveStartDate = loveStartDate;
  }

  await couple.save();
  return couple;
}

async function loadUserCouple(user: UserDocument) {
  if (!user.coupleId) {
    return null;
  }
  return Couple.findById(user.coupleId);
}

async function loadPartner(user: UserDocument, couple?: CoupleDocument | null) {
  if (!couple) {
    return null;
  }

  const partnerId = couple.memberIds.find((id) => !id.equals(user._id));
  return partnerId ? User.findById(partnerId) : null;
}

async function serializeCurrentUser(user: UserDocument, couple?: CoupleDocument | null) {
  const resolvedCouple = couple ?? (await loadUserCouple(user));
  const partner = await loadPartner(user, resolvedCouple);
  return serializeUser(user, resolvedCouple, partner);
}

function requestBaseUrl(req: express.Request): string {
  return (
    config.publicBaseUrl ??
    `${req.protocol}://${req.get('host')}`
  ).replace(/\/$/, '');
}

function filePublicUrl(req: express.Request, file: Express.Multer.File) {
  const publicPath = `/uploads/${file.filename}`;
  return {
    publicPath,
    imageUrl: `${requestBaseUrl(req)}${publicPath}`,
  };
}

function pickRandom(category: string) {
  const prompts = randomPrompts[category] ?? randomPrompts.question;
  return prompts[Math.floor(Math.random() * prompts.length)];
}

router.get('/health', (_req, res) => {
  res.json({ ok: true, service: 'couple-snap-api' });
});

router.post('/auth/request-code', async (req, res, next) => {
  try {
    const input = requestCodeSchema.parse(req.body);
    const email = normalizeEmail(input.email);
    const user = await User.findOne({ email });
    const purpose = input.purpose ?? (user ? 'device' : 'signup');

    await requestVerificationCode(email, purpose, input.deviceId);
    res.json({ ok: true, purpose, expiresInSeconds: codeTtlMs / 1000 });
  } catch (error) {
    next(error);
  }
});

router.post('/auth/start', async (req, res, next) => {
  try {
    const input = authSchema.parse(req.body);
    const email = input.email ? normalizeEmail(input.email) : undefined;
    const password = input.password || undefined;

    let user: UserDocument | null = email ? await User.findOne({ email }) : null;
    if (user) {
      if (!user.passwordHash || !password || !(await bcrypt.compare(password, user.passwordHash))) {
        throw new HttpError(401, 'Invalid email or password');
      }

      const deviceId = requireDeviceId(input.deviceId);
      await ensureTrustedEmailDevice(user, deviceId, input.emailCode);
    } else {
      const deviceId = email ? requireDeviceId(input.deviceId) : undefined;

      if (email) {
        await verifyEmailCode(email, 'signup', deviceId!, input.emailCode);
      }

      user = await User.create({
        displayName: input.displayName,
        partnerName: input.partnerName,
        email,
        passwordHash: password ? await bcrypt.hash(password, 12) : undefined,
        emailVerifiedAt: email ? new Date() : undefined,
        trustedDevices: deviceId ? [trustedDevice(deviceId)] : [],
        role: 'user',
        status: 'active',
      });
    }

    user.displayName = input.displayName;
    user.partnerName = input.partnerName;

    const couple = await findOrCreateCouple(
      normalizeCoupleCode(input.coupleCode),
      input.loveStartDate,
      user,
    );
    user.coupleId = couple._id;
    await user.save();

    res.json({
      token: signToken({ sub: user._id.toString(), role: 'user' }),
      user: await serializeCurrentUser(user, couple),
    });
  } catch (error) {
    next(error);
  }
});

router.post('/auth/login', async (req, res, next) => {
  try {
    const input = loginSchema.parse(req.body);
    const email = normalizeEmail(input.email);
    const user = await User.findOne({ email });
    if (!user || !user.passwordHash || !(await bcrypt.compare(input.password, user.passwordHash))) {
      throw new HttpError(401, 'Invalid email or password');
    }

    const deviceId = requireDeviceId(input.deviceId);
    await ensureTrustedEmailDevice(user, deviceId, input.emailCode);
    await user.save();

    const couple = await loadUserCouple(user);
    res.json({
      token: signToken({ sub: user._id.toString(), role: 'user' }),
      user: await serializeCurrentUser(user, couple),
    });
  } catch (error) {
    next(error);
  }
});

router.get('/me', requireUser, async (req, res, next) => {
  try {
    const couple = await loadUserCouple(req.user!);
    res.json({ user: await serializeCurrentUser(req.user!, couple) });
  } catch (error) {
    next(error);
  }
});

router.patch('/me', requireUser, async (req, res, next) => {
  try {
    const input = profileSchema.parse(req.body);
    const user = req.user!;

    if (input.displayName) user.displayName = input.displayName;
    if (input.partnerName) user.partnerName = input.partnerName;

    const couple = await loadUserCouple(user);
    if (couple && input.loveStartDate) {
      couple.loveStartDate = input.loveStartDate;
      await couple.save();
    }

    await user.save();
    res.json({ user: await serializeCurrentUser(user, couple) });
  } catch (error) {
    next(error);
  }
});

router.post('/me/avatar', requireUser, upload.single('avatar'), async (req, res, next) => {
  try {
    if (!req.file) {
      throw new HttpError(400, 'Avatar file is required');
    }

    const user = req.user!;
    const { publicPath, imageUrl } = filePublicUrl(req, req.file);
    user.avatarUrl = imageUrl;
    user.avatarStoragePath = publicPath;
    await user.save();

    res.json({ user: await serializeCurrentUser(user) });
  } catch (error) {
    next(error);
  }
});

router.post('/me/partner-avatar', requireUser, upload.single('avatar'), async (req, res, next) => {
  try {
    if (!req.file) {
      throw new HttpError(400, 'Avatar file is required');
    }

    const user = req.user!;
    const { publicPath, imageUrl } = filePublicUrl(req, req.file);
    user.partnerAvatarUrl = imageUrl;
    user.partnerAvatarStoragePath = publicPath;
    await user.save();

    res.json({ user: await serializeCurrentUser(user) });
  } catch (error) {
    next(error);
  }
});

router.get('/photos/latest-partner', requireUser, async (req, res, next) => {
  try {
    const user = req.user!;
    if (!user.coupleId) {
      throw new HttpError(409, 'User is not in a couple');
    }

    const photo = await Photo.findOne({
      coupleId: user.coupleId,
      ownerId: { $ne: user._id },
      deletedAt: { $exists: false },
    }).sort({ createdAt: -1 });

    res.json({ photo: photo ? serializePhoto(photo) : null });
  } catch (error) {
    next(error);
  }
});

router.get('/photos', requireUser, async (req, res, next) => {
  try {
    const user = req.user!;
    if (!user.coupleId) {
      throw new HttpError(409, 'User is not in a couple');
    }

    const photos = await Photo.find({
      coupleId: user.coupleId,
      deletedAt: { $exists: false },
    })
      .sort({ createdAt: -1 })
      .limit(100);

    res.json({ photos: photos.map(serializePhoto) });
  } catch (error) {
    next(error);
  }
});

router.post('/photos', requireUser, upload.single('photo'), async (req, res, next) => {
  try {
    const user = req.user!;
    if (!user.coupleId) {
      throw new HttpError(409, 'User is not in a couple');
    }
    if (!req.file) {
      throw new HttpError(400, 'Photo file is required');
    }

    const caption = String(req.body.caption ?? '').trim() || 'A new snap';
    const { publicPath, imageUrl } = filePublicUrl(req, req.file);
    const photo = await Photo.create({
      coupleId: user.coupleId,
      ownerId: user._id,
      ownerName: user.displayName,
      imageUrl,
      storagePath: publicPath,
      caption,
    });

    res.status(201).json({ photo: serializePhoto(photo) });
  } catch (error) {
    next(error);
  }
});

router.get('/random/categories', requireUser, (_req, res) => {
  res.json({ categories: randomCategories });
});

router.get('/random/history', requireUser, async (req, res, next) => {
  try {
    const user = req.user!;
    if (!user.coupleId) {
      throw new HttpError(409, 'User is not in a couple');
    }

    const events = await RandomEvent.find({ coupleId: user.coupleId })
      .sort({ createdAt: -1 })
      .limit(30);

    res.json({ events: events.map(serializeRandomEvent) });
  } catch (error) {
    next(error);
  }
});

router.post('/random/draw', requireUser, async (req, res, next) => {
  try {
    const user = req.user!;
    if (!user.coupleId) {
      throw new HttpError(409, 'User is not in a couple');
    }

    const input = randomDrawSchema.parse(req.body);
    const result = pickRandom(input.category);
    const event = await RandomEvent.create({
      coupleId: user.coupleId,
      userId: user._id,
      category: input.category,
      prompt: result.prompt,
      detail: result.detail,
    });

    res.status(201).json({ event: serializeRandomEvent(event) });
  } catch (error) {
    next(error);
  }
});

router.post('/admin/login', (req, res, next) => {
  try {
    const input = adminLoginSchema.parse(req.body);
    if (
      input.email.toLowerCase() !== config.adminEmail ||
      input.password !== config.adminPassword
    ) {
      throw new HttpError(401, 'Invalid admin credentials');
    }

    res.json({
      token: signToken({ sub: config.adminEmail, role: 'admin' }),
      admin: { email: config.adminEmail },
    });
  } catch (error) {
    next(error);
  }
});

router.get('/admin/summary', requireAdmin, async (_req, res, next) => {
  try {
    const [users, couples, photos, blockedUsers, randomEvents] = await Promise.all([
      User.countDocuments(),
      Couple.countDocuments(),
      Photo.countDocuments({ deletedAt: { $exists: false } }),
      User.countDocuments({ status: 'blocked' }),
      RandomEvent.countDocuments(),
    ]);

    res.json({ users, couples, photos, blockedUsers, randomEvents });
  } catch (error) {
    next(error);
  }
});

router.get('/admin/users', requireAdmin, async (_req, res, next) => {
  try {
    const users = await User.find().sort({ createdAt: -1 }).limit(200);
    const coupleIds = users.map((user) => user.coupleId).filter(Boolean);
    const couples = await Couple.find({ _id: { $in: coupleIds } });
    const coupleById = new Map(couples.map((couple) => [couple._id.toString(), couple]));

    res.json({
      users: users.map((user) =>
        serializeUser(user, user.coupleId ? coupleById.get(user.coupleId.toString()) : null),
      ),
    });
  } catch (error) {
    next(error);
  }
});

router.patch('/admin/users/:id', requireAdmin, async (req, res, next) => {
  try {
    const input = z
      .object({
        status: z.enum(['active', 'blocked']).optional(),
        displayName: z.string().trim().min(1).max(80).optional(),
        partnerName: z.string().trim().min(1).max(80).optional(),
      })
      .parse(req.body);

    const user = await User.findById(req.params.id);
    if (!user) throw new HttpError(404, 'User not found');
    if (input.status) user.status = input.status;
    if (input.displayName) user.displayName = input.displayName;
    if (input.partnerName) user.partnerName = input.partnerName;
    await user.save();

    res.json({ user: serializeUser(user, await loadUserCouple(user)) });
  } catch (error) {
    next(error);
  }
});

router.get('/admin/couples', requireAdmin, async (_req, res, next) => {
  try {
    const couples = await Couple.find().sort({ createdAt: -1 }).limit(200);
    res.json({ couples: couples.map(serializeCouple) });
  } catch (error) {
    next(error);
  }
});

router.patch('/admin/couples/:id', requireAdmin, async (req, res, next) => {
  try {
    const input = z.object({ loveStartDate: z.coerce.date() }).parse(req.body);
    const couple = await Couple.findById(req.params.id);
    if (!couple) throw new HttpError(404, 'Couple not found');
    couple.loveStartDate = input.loveStartDate;
    await couple.save();
    res.json({ couple: serializeCouple(couple) });
  } catch (error) {
    next(error);
  }
});

router.get('/admin/photos', requireAdmin, async (_req, res, next) => {
  try {
    const photos = await Photo.find({ deletedAt: { $exists: false } })
      .sort({ createdAt: -1 })
      .limit(200);
    res.json({ photos: photos.map(serializePhoto) });
  } catch (error) {
    next(error);
  }
});

router.delete('/admin/photos/:id', requireAdmin, async (req, res, next) => {
  try {
    const photo = await Photo.findById(req.params.id);
    if (!photo) throw new HttpError(404, 'Photo not found');
    photo.deletedAt = new Date();
    await photo.save();
    res.json({ photo: serializePhoto(photo) });
  } catch (error) {
    next(error);
  }
});

router.get('/admin/random-events', requireAdmin, async (_req, res, next) => {
  try {
    const events = await RandomEvent.find().sort({ createdAt: -1 }).limit(200);
    res.json({ events: events.map(serializeRandomEvent) });
  } catch (error) {
    next(error);
  }
});

export { router };
