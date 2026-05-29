import type {
  CoupleDocument,
  PhotoDocument,
  RandomEventDocument,
  UserDocument,
} from "./models.js";

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

export function serializeUser(
  user: UserDocument,
  couple?: CoupleDocument | null,
  partner?: UserDocument | null,
) {
  return {
    id: user._id.toString(),
    displayName: user.displayName,
    partnerName: user.partnerName,
    email: user.email ?? null,
    avatarUrl: user.avatarUrl ?? null,
    partnerAvatarUrl: partner?.avatarUrl ?? user.partnerAvatarUrl ?? null,
    fallbackPartnerAvatarUrl: user.partnerAvatarUrl ?? null,
    emailVerifiedAt: user.emailVerifiedAt?.toISOString() ?? null,
    trustedDeviceCount: user.trustedDevices?.length ?? 0,
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

export function serializeRandomEvent(event: RandomEventDocument) {
  return {
    id: event._id.toString(),
    coupleId: event.coupleId.toString(),
    userId: event.userId.toString(),
    category: event.category,
    prompt: localizeRandomText(event.prompt),
    detail: localizeOptionalRandomText(event.detail),
    createdAt: event.createdAt.toISOString(),
  };
}

function localizeOptionalRandomText(value?: string | null) {
  if (!value || !value.trim()) {
    return null;
  }
  return localizeRandomText(value);
}

function localizeRandomText(value: string) {
  const trimmed = value.trim();
  return legacyRandomText[trimmed] ?? trimmed;
}

const legacyRandomText: Record<string, string> = {
  "Cau hoi doi minh": "Câu hỏi đôi mình",
  "Mot cau hoi nho de hai nguoi noi chuyen that hon.":
    "Một câu hỏi nhỏ để hai người nói chuyện thật hơn.",
  "Thu thach snap": "Thử thách snap",
  "Mot hanh dong nho de gui cho nhau ngay bay gio.":
    "Một hành động nhỏ để gửi cho nhau ngay bây giờ.",
  "Hom nay lam gi": "Hôm nay làm gì",
  "Mot y tuong hen ho hoac cung nhau lam gi do.":
    "Một ý tưởng hẹn hò hoặc cùng nhau làm gì đó.",
  "An gi bay gio": "Ăn gì bây giờ",
  "Khi ca hai cung khong biet chon mon nao.":
    "Khi cả hai cùng không biết chọn món nào.",
  "Tin hieu vu tru": "Tín hiệu vũ trụ",
  "Mot thong diep nhe nhang cho ngay hom nay.":
    "Một thông điệp nhẹ nhàng cho ngày hôm nay.",
  "Hom nay co dieu gi nho xiu lam em/anh vui khong?":
    "Hôm nay có điều gì nhỏ xíu làm em/anh vui không?",
  "Neu duoc tua lai mot khoanh khac cua hai dua, ban chon luc nao?":
    "Nếu được tua lại một khoảnh khắc của hai đứa, bạn chọn lúc nào?",
  "Dieu gi o nguoi ay lam ban thay yen tam nhat?":
    "Điều gì ở người ấy làm bạn thấy yên tâm nhất?",
  "Neu toi nay goi video 15 phut, ban muon ke chuyen gi dau tien?":
    "Nếu tối nay gọi video 15 phút, bạn muốn kể chuyện gì đầu tiên?",
  "Mot loi khen that long ma ban muon gui cho nguoi ay la gi?":
    "Một lời khen thật lòng mà bạn muốn gửi cho người ấy là gì?",
  "Chup mot thu dang o ngay ben trai ban.":
    "Chụp một thứ đang ở ngay bên trái bạn.",
  'Caption goi y: "em/anh thay cai nay dau tien ne".':
    'Caption gợi ý: "em/anh thấy cái này đầu tiên nè".',
  "Gui mot snap voi bieu cam dang yeu nhat trong 3 giay.":
    "Gửi một snap với biểu cảm đáng yêu nhất trong 3 giây.",
  "Khong can dep, can that.": "Không cần đẹp, cần thật.",
  "Chup bau troi hoac anh sang gan ban nhat luc nay.":
    "Chụp bầu trời hoặc ánh sáng gần bạn nhất lúc này.",
  "Chup mot goc ban lam viec/hoc tap hien tai.":
    "Chụp một góc bàn làm việc/học tập hiện tại.",
  "Gui mot tam anh co trai tim an dau do trong khung hinh.":
    "Gửi một tấm ảnh có trái tim ẩn đâu đó trong khung hình.",
  "Dat lich xem phim cung nhau toi nay.":
    "Đặt lịch xem phim cùng nhau tối nay.",
  "Di an mot mon ca hai lau roi chua an.":
    "Đi ăn một món cả hai lâu rồi chưa ăn.",
  "Cung nhau di dao 20 phut va khong cam dien thoai.":
    "Cùng nhau đi dạo 20 phút và không cầm điện thoại.",
  "Viet cho nhau 3 dieu biet on trong ngay.":
    "Viết cho nhau 3 điều biết ơn trong ngày.",
  "Chon mot bai nhac lam nhac nen cho ngay hom nay.":
    "Chọn một bài nhạc làm nhạc nền cho ngày hôm nay.",
  "Pho hoac bun bo": "Phở hoặc bún bò",
  "Mon am nong, hop luc can nap lai nang luong.":
    "Món ấm nóng, hợp lúc cần nạp lại năng lượng.",
  "Tra sua size nho": "Trà sữa size nhỏ",
  "Du vui, khong qua toi loi.": "Đủ vui, không quá tội lỗi.",
  "Com tam": "Cơm tấm",
  "Lua chon chac bung va de vui.": "Lựa chọn chắc bụng và dễ vui.",
  "Mi cay": "Mì cay",
  "Neu hom nay can mot chut kich thich.":
    "Nếu hôm nay cần một chút kích thích.",
  "Banh mi": "Bánh mì",
  "Nhanh, gon, khong can nghi nhieu.": "Nhanh, gọn, không cần nghĩ nhiều.",
  "Hom nay hay noi mot cau nhe nhang voi nguoi ay truoc khi ngu.":
    "Hôm nay hãy nói một câu nhẹ nhàng với người ấy trước khi ngủ.",
  "Mot tin nhan nho doi khi giu ca ngay lai.":
    "Một tin nhắn nhỏ đôi khi giữ cả ngày lại.",
  "Vu tru bao rang hai dua nen chup them mot tam anh binh thuong.":
    "Vũ trụ bảo rằng hai đứa nên chụp thêm một tấm ảnh bình thường.",
  "Nhung tam binh thuong thuong la ky niem lau nhat.":
    "Những tấm bình thường thường là kỷ niệm lâu nhất.",
  "Dung doi dung luc moi gui yeu thuong.":
    "Đừng đợi đúng lúc mới gửi yêu thương.",
  "Gui ngay khi nghi toi.": "Gửi ngay khi nghĩ tới.",
  "Neu hom nay met, chi can noi that la minh met.":
    "Nếu hôm nay mệt, chỉ cần nói thật là mình mệt.",
  "Rieng tu va an toan la ly do app nay ton tai.":
    "Riêng tư và an toàn là lý do app này tồn tại.",
};
