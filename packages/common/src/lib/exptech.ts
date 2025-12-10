
interface ILogger {
    info(...args: any[]): void;
    error(...args: any[]): void;
}

interface IConfig {
    getConfig(): any;
    writeConfig(config: any): void;
}

const consoleLogger: ILogger = {
    info: console.log,
    error: console.error,
};

const mockConfig: IConfig = {
    getConfig: () => ({
        user: {
            email: 'test@example.com',
            pass: 'password',
        },
        login: {},
    }),
    writeConfig: (config: any) => {
        console.log('Writing config:', config);
    },
};

export class ExpTech {
    static #instance: ExpTech | null = null;
    private logger: ILogger = consoleLogger;
    private readonly config: IConfig = mockConfig;
    private getconfig: any;
    public key: string | null = null;
    private login_token: string | null = null;
    private refresh_login_token: string | null = null;
    private expires_at: string | null = null;


    constructor(logger: ILogger = consoleLogger, config: IConfig = mockConfig) {
        if (ExpTech.#instance) {
            return ExpTech.#instance;
        }
        this.logger = logger;
        this.config = config;
        this.getconfig = this.config.getConfig();
        this.key = null;
        ExpTech.#instance = this;
    }

    static getInstance(logger?: ILogger, config?: IConfig) {
        if (!ExpTech.#instance) {
            ExpTech.#instance = new ExpTech(logger, config);
        }
        return ExpTech.#instance;
    }

    setCredentials(email: string, pass: string) {
        if (!this.getconfig.user) {
            this.getconfig.user = {};
        }
        this.getconfig.user.email = email;
        this.getconfig.user.pass = pass;
    }

    async #login(): Promise<string | null> {
        const controller = new AbortController();
        const timeout = setTimeout(() => controller.abort(), 60000);

        try {
            const response = await fetch('https://api.exptech.dev/api/v1/auth/login', {
                body: JSON.stringify({
                    email: this.getconfig.user.email,
                    password: this.getconfig.user.pass
                }),
                headers: {
                    'Content-Type': 'application/json',
                },
                method: 'POST',
                signal: controller.signal,
            });

            if (response && response.ok) {
                const ans = await response.json();
                this.login_token = ans.token;
                this.refresh_login_token = ans.refresh_token;
                this.expires_at = ans.expires_at;
                this.getconfig.login.token = this.login_token;
                this.getconfig.login.refresh_token = this.refresh_login_token;
                this.getconfig.login.expires_at = this.expires_at;
                this.config.writeConfig(this.getconfig);
                return await this.#serviceToken();
            } else {
                this.logger.info("Login http status code: ", response.status);
                const errorData = await response.json().catch(() => null);
                const errorMessage = errorData?.message || `登入失敗，狀態碼: ${response.status}`;
                throw new Error(errorMessage);
            }
        } catch (error: any) {
            if (error.name === "AbortError") {
                this.logger.error("請求超時");
                throw new Error("請求超時");
            } else {
                this.logger.error(error.message);
                throw error;
            }
        } finally {
            clearTimeout(timeout);
        }
    }

    async #serviceToken(): Promise<string | null> {
        const controller = new AbortController();
        const timeout = setTimeout(() => controller.abort(), 60000);

        try {
            const response = await fetch(`https://api.exptech.dev/api/v1/auth/service-tokens`, {
                body: JSON.stringify({
                    note: 'trem-lite',
                    permissions: [10_101, 10_102, 102, 20_101, 202]
                }),
                headers: {
                    'Authorization': `Bearer ${this.login_token}`,
                    'Content-Type': 'application/json',
                },
                method: 'POST',
                signal: controller.signal,
            });

            if (response && response.ok) {
                const ans = await response.json();
                this.key = ans.token;
                this.getconfig.user.token = this.key;
                this.config.writeConfig(this.getconfig);
                return this.key;
            } else {
                this.logger.error("ServiceToken http status code: ", response.status);
            }
        } catch (error: any) {
            if (error.name === "AbortError") {
                this.logger.error("請求超時");
            } else {
                this.logger.error(error.message);
            }
        } finally {
            clearTimeout(timeout);
        }
        return null;
    }

    async runlogin(): Promise<string | null> {
        this.key = await this.#login();
        return this.key;
    }

    getKey(): string | null {
        return this.key;
    }

    async handleLogin() {
        const email = prompt("Enter your ExpTech email:");
        const password = prompt("Enter your ExpTech password:");
        if (email && password) {
            this.setCredentials(email, password);
            const key = await this.runlogin();
            if (key) {
                localStorage.setItem('loginData', JSON.stringify({
                    isLoggedIn: true,
                    apiKey: key,
                    userEmail: email
                }));
                return { key, email };
            }
        }
        return null;
    }

    handleLogout() {
        localStorage.removeItem('loginData');
        this.key = null;
        this.login_token = null;
        this.refresh_login_token = null;
        this.expires_at = null;
        console.log('Logged out');
    }

    getLoginData() {
        const savedLoginData = localStorage.getItem('loginData');
        if (savedLoginData) {
            return JSON.parse(savedLoginData);
        }
        return null;
    }
}
