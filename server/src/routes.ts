import fs from 'node:fs';
import path from 'node:path';
import bcrypt from 'bcryptjs';
import express from 'express';
import multer from 'multer';
import { z } from 'zod';
import { config } from './config.js';
import { requireAdmin, requireUser } from './auth.js';
import { HttpError } from './errors.js';
import { Couple, Photo, User, type CoupleDocument, type UserDocument } from './models.js';
import { serializeCouple, serializePhoto, serializeUser } from './serializers.js';
import { signToken } from './tokens.js';

const router = express.Router();

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

const authSchema = z.object({
  displayName: z.string().trim().min(1).max(80),
  partnerName: z.string().trim().min(1).max(80),
  coupleCode: z.string().trim().min(3).max(32),
  loveStartDate: z.coerce.date(),
  email: z.string().trim().email().optional().or(z.literal('')),
  password: z.string().min(6).max(128).optional().or(z.literal('')),
});

const loginSchema = z.object({
  email: z.string().trim().email(),
  password: z.string().min(6).max(128),
});

const profileSchema = z.object({
  displayName: z.string().trim().min(1).max(80).optional(),
  partnerName: z.string().trim().min(1).max(80).optional(),
  loveStartDate: z.coerce.date().optional(),
});

const adminLoginSchema = z.object({
  email: z.string().trim().email(),
  password: z.string().min(1),
});

function normalizeCoupleCode(value: string): string {
  return value.trim().toUpperCase().replace(/\s+/g, '-');
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

function requestBaseUrl(req: express.Request): string {
  return (
    config.publicBaseUrl ??
    `${req.protocol}://${req.get('host')}`
  ).replace(/\/$/, '');
}

router.get('/health', (_req, res) => {
  res.json({ ok: true, service: 'couple-snap-api' });
});

router.post('/auth/start', async (req, res, next) => {
  try {
    const input = authSchema.parse(req.body);
    const email = input.email ? input.email.toLowerCase() : undefined;
    const password = input.password || undefined;

    let user: UserDocument | null = email ? await User.findOne({ email }) : null;
    if (user) {
      if (!user.passwordHash || !password || !(await bcrypt.compare(password, user.passwordHash))) {
        throw new HttpError(401, 'Invalid email or password');
      }
    } else {
      user = await User.create({
        displayName: input.displayName,
        partnerName: input.partnerName,
        email,
        passwordHash: password ? await bcrypt.hash(password, 12) : undefined,
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
      user: serializeUser(user, couple),
    });
  } catch (error) {
    next(error);
  }
});

router.post('/auth/login', async (req, res, next) => {
  try {
    const input = loginSchema.parse(req.body);
    const user = await User.findOne({ email: input.email.toLowerCase() });
    if (!user || !user.passwordHash || !(await bcrypt.compare(input.password, user.passwordHash))) {
      throw new HttpError(401, 'Invalid email or password');
    }

    const couple = await loadUserCouple(user);
    res.json({
      token: signToken({ sub: user._id.toString(), role: 'user' }),
      user: serializeUser(user, couple),
    });
  } catch (error) {
    next(error);
  }
});

router.get('/me', requireUser, async (req, res, next) => {
  try {
    const couple = await loadUserCouple(req.user!);
    res.json({ user: serializeUser(req.user!, couple) });
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
    res.json({ user: serializeUser(user, couple) });
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
    const publicPath = `/uploads/${req.file.filename}`;
    const photo = await Photo.create({
      coupleId: user.coupleId,
      ownerId: user._id,
      ownerName: user.displayName,
      imageUrl: `${requestBaseUrl(req)}${publicPath}`,
      storagePath: publicPath,
      caption,
    });

    res.status(201).json({ photo: serializePhoto(photo) });
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
    const [users, couples, photos, blockedUsers] = await Promise.all([
      User.countDocuments(),
      Couple.countDocuments(),
      Photo.countDocuments({ deletedAt: { $exists: false } }),
      User.countDocuments({ status: 'blocked' }),
    ]);

    res.json({ users, couples, photos, blockedUsers });
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

export { router };
