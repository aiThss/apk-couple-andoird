import { Schema, model, type HydratedDocument, type Types } from 'mongoose';

export type UserStatus = 'active' | 'blocked';

export interface UserRecord {
  displayName: string;
  partnerName: string;
  email?: string;
  passwordHash?: string;
  role: 'user';
  status: UserStatus;
  coupleId?: Types.ObjectId;
  createdAt: Date;
  updatedAt: Date;
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

const userSchema = new Schema<UserRecord>(
  {
    displayName: { type: String, required: true, trim: true },
    partnerName: { type: String, required: true, trim: true },
    email: { type: String, trim: true, lowercase: true, sparse: true, unique: true },
    passwordHash: { type: String },
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

export type UserDocument = HydratedDocument<UserRecord>;
export type CoupleDocument = HydratedDocument<CoupleRecord>;
export type PhotoDocument = HydratedDocument<PhotoRecord>;

export const User = model<UserRecord>('User', userSchema);
export const Couple = model<CoupleRecord>('Couple', coupleSchema);
export const Photo = model<PhotoRecord>('Photo', photoSchema);
