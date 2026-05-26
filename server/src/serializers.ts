import type { CoupleDocument, PhotoDocument, UserDocument } from './models.js';

export function serializeCouple(couple: CoupleDocument | null | undefined) {
  if (!couple) {
    return null;
  }

  return {
    id: couple._id.toString(),
    code: couple.code,
    loveStartDate: couple.loveStartDate.toISOString(),
    memberIds: couple.memberIds.map((id) => id.toString()),
    createdAt: couple.createdAt.toISOString(),
  };
}

export function serializeUser(user: UserDocument, couple?: CoupleDocument | null) {
  return {
    id: user._id.toString(),
    displayName: user.displayName,
    partnerName: user.partnerName,
    email: user.email ?? null,
    role: user.role,
    status: user.status,
    couple: serializeCouple(couple ?? null),
    createdAt: user.createdAt.toISOString(),
  };
}

export function serializePhoto(photo: PhotoDocument) {
  return {
    id: photo._id.toString(),
    coupleId: photo.coupleId.toString(),
    ownerId: photo.ownerId.toString(),
    ownerName: photo.ownerName,
    imageUrl: photo.imageUrl,
    storagePath: photo.storagePath,
    caption: photo.caption,
    deletedAt: photo.deletedAt?.toISOString() ?? null,
    createdAt: photo.createdAt.toISOString(),
  };
}
