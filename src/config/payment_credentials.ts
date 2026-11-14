import * as fs from 'fs';
import * as path from 'path';

function loadEnv() {
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
}

loadEnv();

export interface CardExpiry {
    month: string;
    year: string;
    formatted: string; // e.g. "12/45"
}

/**
 * Validates and computes a non-expired card expiry date.
 * If the configured year/month is in the past, it automatically adds a future month and year.
 */
export function getValidCardExpiry(rawExpiry?: string): CardExpiry {
    const expiryStr = (rawExpiry || process.env.TEST_CARD_EXPIRY || '12/45').trim();
    const now = new Date();
    const currentYear = now.getFullYear(); // e.g. 2026
    const currentMonth = now.getMonth() + 1; // 1-12

    let [mStr, yStr] = expiryStr.includes('/') ? expiryStr.split('/') : [expiryStr.slice(0, 2), expiryStr.slice(2)];
    let month = parseInt(mStr || '12', 10);
    let year = parseInt(yStr || '45', 10);

    // Convert 2-digit year to 4-digit year
    if (year < 100) {
        year += 2000;
    }

    // If month is invalid or already expired, auto-calculate a future valid date
    if (month < 1 || month > 12) {
        month = 12;
    }

    if (year < currentYear || (year === currentYear && month <= currentMonth)) {
        // Automatically roll forward 3 years into the future
        year = currentYear + 3;
        month = 12;
    }

    const formattedMonth = month.toString().padStart(2, '0');
    const formattedYear2Digit = (year % 100).toString().padStart(2, '0');

    return {
        month: formattedMonth,
        year: formattedYear2Digit,
        formatted: `${formattedMonth}/${formattedYear2Digit}`,
    };
}

export const PaymentConfig = {
    get paymentType(): 'Card' | 'Cash' {
        const type = (process.env.PAYMENT_TYPE || 'Card').trim().toLowerCase();
        return type.includes('cash') ? 'Cash' : 'Card';
    },

    get isCard(): boolean {
        return this.paymentType === 'Card';
    },

    get cardNumber(): string {
        return (process.env.TEST_CARD_NUMBER || '4242424242424242').replace(/\s+/g, '');
    },

    get cardNumberSpaced(): string {
        return this.cardNumber.replace(/(\d{4})/g, '$1 ').trim();
    },

    get cardExpiry(): CardExpiry {
        return getValidCardExpiry(process.env.TEST_CARD_EXPIRY);
    },

    get cardCvc(): string {
        return (process.env.TEST_CARD_CVC || '123').trim();
    },

    get cardZip(): string {
        return (process.env.TEST_CARD_ZIP || '90001').trim();
    },
};
