import { Schema, model, type HydratedDocument, type Types } from 'mongoose';

export type UserStatus = 'active' | 'blocked';

export interface UserRecord {
  displayName: string;
  partnerName: string;
  email?: string;
  passwordHash?: string;
  avatarUrl?: string;
  avatarStoragePath?: string;
  partnerAvatarUrl?: string;
  partnerAvatarStoragePath?: string;
  emailVerifiedAt?: Date;
  trustedDevices: TrustedDeviceRecord[];
  role: 'user';
  status: UserStatus;
  coupleId?: Types.ObjectId;
  createdAt: Date;
  updatedAt: Date;
}

export interface TrustedDeviceRecord {
  deviceId: string;
  label?: string;
  createdAt: Date;
  lastSeenAt: Date;
}

export interface CoupleRecord {
  code: string;
  loveStartDate: Date;
  memberIds: Types.ObjectId[];
  createdAt: Date;
  updatedAt: Date;
}

export interface PhotoRecord {
  coupleId: Types.ObjectId;
  ownerId: Types.ObjectId;
  ownerName: string;
  imageUrl: string;
  storagePath: string;
  caption: string;
  deletedAt?: Date;
  createdAt: Date;
  updatedAt: Date;
}

export type VerificationPurpose = 'signup' | 'device';

export interface VerificationCodeRecord {
  email: string;
  purpose: VerificationPurpose;
  deviceId: string;
  codeHash: string;
  attempts: number;
  consumedAt?: Date;
  expiresAt: Date;
  createdAt: Date;
  updatedAt: Date;
}

export interface RandomEventRecord {
  coupleId: Types.ObjectId;
  userId: Types.ObjectId;
  category: string;
  prompt: string;
  detail?: string;
  createdAt: Date;
  updatedAt: Date;
}

const trustedDeviceSchema = new Schema<TrustedDeviceRecord>(
  {
    deviceId: { type: String, required: true, trim: true },
    label: { type: String, trim: true },
    createdAt: { type: Date, required: true },
    lastSeenAt: { type: Date, required: true },
  },
  { _id: false },
);

const userSchema = new Schema<UserRecord>(
  {
    displayName: { type: String, required: true, trim: true },
    partnerName: { type: String, required: true, trim: true },
    email: { type: String, trim: true, lowercase: true, sparse: true, unique: true },
    passwordHash: { type: String },
    avatarUrl: { type: String },
    avatarStoragePath: { type: String },
    partnerAvatarUrl: { type: String },
    partnerAvatarStoragePath: { type: String },
    emailVerifiedAt: { type: Date },
    trustedDevices: { type: [trustedDeviceSchema], default: [] },
    role: { type: String, enum: ['user'], default: 'user', required: true },
    status: { type: String, enum: ['active', 'blocked'], default: 'active', required: true },
    coupleId: { type: Schema.Types.ObjectId, ref: 'Couple' },
  },
  { timestamps: true },
);

const coupleSchema = new Schema<CoupleRecord>(
  {
    code: { type: String, required: true, uppercase: true, trim: true, unique: true, index: true },
    loveStartDate: { type: Date, required: true },
    memberIds: [{ type: Schema.Types.ObjectId, ref: 'User', required: true }],
  },
  { timestamps: true },
);

const photoSchema = new Schema<PhotoRecord>(
  {
    coupleId: { type: Schema.Types.ObjectId, ref: 'Couple', required: true, index: true },
    ownerId: { type: Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    ownerName: { type: String, required: true, trim: true },
    imageUrl: { type: String, required: true },
    storagePath: { type: String, required: true },
    caption: { type: String, required: true, trim: true, maxlength: 140 },
    deletedAt: { type: Date },
  },
  { timestamps: true },
);

photoSchema.index({ coupleId: 1, createdAt: -1 });

const verificationCodeSchema = new Schema<VerificationCodeRecord>(
  {
    email: { type: String, required: true, trim: true, lowercase: true, index: true },
    purpose: { type: String, enum: ['signup', 'device'], required: true },
    deviceId: { type: String, required: true, trim: true },
    codeHash: { type: String, required: true },
    attempts: { type: Number, default: 0, required: true },
    consumedAt: { type: Date },
    expiresAt: { type: Date, required: true, expires: 0 },
  },
  { timestamps: true },
);

verificationCodeSchema.index({ email: 1, purpose: 1, deviceId: 1, createdAt: -1 });

const randomEventSchema = new Schema<RandomEventRecord>(
  {
    coupleId: { type: Schema.Types.ObjectId, ref: 'Couple', required: true, index: true },
    userId: { type: Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    category: { type: String, required: true, trim: true },
    prompt: { type: String, required: true, trim: true, maxlength: 240 },
    detail: { type: String, trim: true, maxlength: 500 },
  },
  { timestamps: true },
);

randomEventSchema.index({ coupleId: 1, createdAt: -1 });

export type UserDocument = HydratedDocument<UserRecord>;
export type CoupleDocument = HydratedDocument<CoupleRecord>;
export type PhotoDocument = HydratedDocument<PhotoRecord>;
export type VerificationCodeDocument = HydratedDocument<VerificationCodeRecord>;
export type RandomEventDocument = HydratedDocument<RandomEventRecord>;

export const User = model<UserRecord>('User', userSchema);
export const Couple = model<CoupleRecord>('Couple', coupleSchema);
export const Photo = model<PhotoRecord>('Photo', photoSchema);
export const VerificationCode = model<VerificationCodeRecord>(
  'VerificationCode',
  verificationCodeSchema,
);
export const RandomEvent = model<RandomEventRecord>('RandomEvent', randomEventSchema);
