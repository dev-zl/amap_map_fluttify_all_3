/**
 * LogUtil 日志工具类
 */
export class LogUtil {
  static isDebugMode: boolean = false;

  static d(tag: string, message: string): void {
    if (this.isDebugMode) {
      console.debug(`[${tag}] ${message}`);
    }
  }

  static i(tag: string, message: string): void {
    console.info(`[${tag}] ${message}`);
  }

  static w(tag: string, message: string): void {
    console.warn(`[${tag}] ${message}`);
  }

  static e(tag: string, message: string): void {
    console.error(`[${tag}] ${message}`);
  }
}

