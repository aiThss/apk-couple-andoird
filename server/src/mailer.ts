import nodemailer from 'nodemailer';
import { config } from './config.js';
import { HttpError } from './errors.js';

function createTransporter() {
  if (!config.smtp.host) {
    return null;
  }

  return nodemailer.createTransport({
    host: config.smtp.host,
    port: config.smtp.port,
    secure: config.smtp.secure,
    requireTLS: !config.smtp.secure,
    auth:
      config.smtp.user && config.smtp.pass
        ? {
            user: config.smtp.user,
            pass: config.smtp.pass,
          }
        : undefined,
  });
}

let transporter: nodemailer.Transporter | null | undefined;

function getTransporter() {
  transporter ??= createTransporter();
  return transporter;
}

export async function sendVerificationEmail(email: string, code: string) {
  const mailer = getTransporter();
  if (!mailer) {
    throw new HttpError(
      503,
      'Email delivery is not configured on the server',
      'EMAIL_DELIVERY_NOT_CONFIGURED',
    );
  }

  await mailer.sendMail({
    from: config.smtp.mailFrom,
    to: email,
    subject: 'Mã xác thực Couple Snap',
    text: [
      `Mã xác thực Couple Snap của bạn là ${code}.`,
      '',
      'Mã này hết hạn sau 10 phút. Nếu bạn không yêu cầu mã này, hãy bỏ qua email.',
    ].join('\n'),
    html: `
      <div style="font-family:Arial,sans-serif;line-height:1.5;color:#171717">
        <h2>Xác thực Couple Snap</h2>
        <p>Mã của bạn là:</p>
        <p style="font-size:28px;font-weight:800;letter-spacing:6px">${code}</p>
        <p>Mã này hết hạn sau 10 phút.</p>
      </div>
    `,
  });
}
