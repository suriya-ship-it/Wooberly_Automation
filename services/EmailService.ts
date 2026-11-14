import nodemailer from 'nodemailer';
import * as fs from 'fs';
import * as path from 'path';

export class EmailService {
    private static envLoaded = false;

    private static loadEnv() {
        if (this.envLoaded) return;
        const envPath = path.resolve(__dirname, '../.env');
        if (fs.existsSync(envPath)) {
            const lines = fs.readFileSync(envPath, 'utf-8').split('\n');
            for (const line of lines) {
                const trimmed = line.trim();
                if (!trimmed || trimmed.startsWith('#')) continue;
                const index = trimmed.indexOf('=');
                if (index !== -1) {
                    const key = trimmed.slice(0, index).trim();
                    const val = trimmed.slice(index + 1).trim();
                    if (!process.env[key]) {
                        process.env[key] = val;
                    }
                }
            }
        }
        this.envLoaded = true;
    }

    /**
     * Resolves recipients list from REPORT_EMAILS env variable.
     */
    public static getRecipients(): string[] {
        // Prefer TO_EMAIL env variable (comma‑separated list). Fallback to REPORT_EMAILS for backward compatibility.
        const raw = process.env.TO_EMAIL || process.env.REPORT_EMAILS || '';
        if (!raw) return [];
        return raw
            .split(',')
            .map(e => e.trim())
            .filter(e => e.includes('@'));
    }

    /**
     * Finds the latest passed test video in 'Test reference' directory.
     */
    public static getLatestVideoPath(specificFilename?: string): string | null {
        const testRefDir = path.resolve(__dirname, '../Test reference');
        if (!fs.existsSync(testRefDir)) return null;

        if (specificFilename) {
            const target = path.join(testRefDir, specificFilename);
            if (fs.existsSync(target)) return target;
        }

        const candidateLatest = path.join(testRefDir, 'latest_execution.mp4');
        if (fs.existsSync(candidateLatest)) return candidateLatest;

        const files = fs.readdirSync(testRefDir).filter(f => f.endsWith('.mp4'));
        if (files.length === 0) return null;

        files.sort((a, b) => {
            const timeA = fs.statSync(path.join(testRefDir, a)).mtimeMs;
            const timeB = fs.statSync(path.join(testRefDir, b)).mtimeMs;
            return timeB - timeA;
        });

        return path.join(testRefDir, files[0]);
    }

    /**
     * Sends test pass notification with execution video attachment.
     */
    public static async sendTestPassedReport(videoFilename?: string): Promise<boolean> {
        // Ensure environment variables are loaded
        this.loadEnv();
        const recipients = this.getRecipients();
        if (recipients.length === 0) {
            console.log('[EmailService] ⚠️ No valid recipients configured in REPORT_EMAILS. Skipping email dispatch.');
            return false;
        }

        console.log('\n========================================================================');
        console.log('📧 [EmailService] Preparing Test Pass Report Email...');
        console.log(`Recipients: ${recipients.join(', ')}`);
        console.log('========================================================================');

        const videoPath = this.getLatestVideoPath(videoFilename);
        const attachments: any[] = [];

        if (videoPath && fs.existsSync(videoPath)) {
            const stats = fs.statSync(videoPath);
            const sizeMb = (stats.size / (1024 * 1024)).toFixed(2);
            if (stats.size > 20 * 1024 * 1024) {
                console.log(`[EmailService] ℹ️ Video size (${sizeMb} MB) exceeds SMTP attachment limit (20 MB). Video saved locally at: ${videoPath}`);
            } else {
                console.log(`[EmailService] Attaching execution video: ${path.basename(videoPath)} (${sizeMb} MB)`);
                attachments.push({
                    filename: path.basename(videoPath),
                    path: videoPath,
                    contentType: 'video/mp4',
                });
            }
        } else {
            console.warn('[EmailService] ⚠️ No video recording file found to attach.');
        }

        const smtpHost = process.env.SMTP_HOST || 'smtp.gmail.com';
        const smtpPort = parseInt(process.env.SMTP_PORT || '587', 10);
        const smtpSecure = process.env.SMTP_SECURE === 'true' || smtpPort === 465;
        const smtpUser = process.env.SMTP_USER || '';
        const smtpPass = process.env.SMTP_PASS || '';
        const emailFrom = process.env.EMAIL_FROM || smtpUser || 'no-reply@radicalstart.com';

        let transporter: nodemailer.Transporter;

        if (smtpUser && smtpPass) {
            transporter = nodemailer.createTransport({
                host: smtpHost,
                port: smtpPort,
                secure: smtpSecure,
                auth: {
                    user: smtpUser,
                    pass: smtpPass,
                },
            });
        } else {
            console.log('[EmailService] SMTP credentials not set; using local sendmail transport fallback...');
            transporter = nodemailer.createTransport({
                sendmail: true,
                newline: 'unix',
                path: '/usr/sbin/sendmail',
            });
        }

        const appTitle = process.env.APP_NAME || "RentALL Space";
        const mailOptions = {
            from: `"${appTitle} Automation" <${emailFrom}>`,
            to: recipients.join(', '),
            subject: `✅ ${appTitle} Mobile Automation Test Passed Successfully - Video Reference`,
            text: `Hello Team,\n\nSmoke testing for ${appTitle} has been completed.\n\nAutomation status: PASSED.\n\n`,
            html: `
                <div style="font-family: Arial, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; border: 1px solid #e0e0e0; border-radius: 8px; padding: 20px;">
                    <h2 style="color: #2e7d32; border-bottom: 2px solid #2e7d32; padding-bottom: 8px;">✅ ${appTitle} Mobile Automation Test Report</h2>
                    <p>Hello Team,</p>
                    <p>Smoke testing for ${appTitle} has been completed.</p>
                    <p>Automation status: <strong>PASSED</strong>.</p>
                    
                    <hr style="border: 0; border-top: 1px solid #eee; margin: 20px 0;"/>
                    <p style="font-size: 12px; color: #777;">Best regards,<br/><strong>${appTitle} Automation Suite</strong></p>
                </div>`,
            //attachments,
        };

        try {
            const info = await transporter.sendMail(mailOptions);
            console.log(`[EmailService] ✅ Email report dispatched successfully! Message ID: ${info.messageId}`);
            return true;
        } catch (err: any) {
            console.warn(`[EmailService] ⚠️ Could not dispatch email report: ${err?.message ?? err}`);
            console.warn(`[EmailService] Tip: Configure SMTP_USER and SMTP_PASS in .env to send via authenticated SMTP.`);
            return false;
        }
    }
}
