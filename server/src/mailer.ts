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
    subject: 'Your Couple Snap verification code',
    text: [
      `Your Couple Snap code is ${code}.`,
      '',
      'This code expires in 10 minutes. If you did not request it, you can ignore this email.',
    ].join('\n'),
    html: `
      <div style="font-family:Arial,sans-serif;line-height:1.5;color:#171717">
        <h2>Couple Snap verification</h2>
        <p>Your code is:</p>
        <p style="font-size:28px;font-weight:800;letter-spacing:6px">${code}</p>
        <p>This code expires in 10 minutes.</p>
      </div>
    `,
  });
}
