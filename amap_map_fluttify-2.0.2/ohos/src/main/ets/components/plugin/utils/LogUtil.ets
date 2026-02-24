import hilog from '@ohos.hilog';
import { EventSink } from "@ohos/flutter_ohos";

/**
 * LogUtil - 日志工具类
 */
export class LogUtil {
  private static readonly TAG = 'AmapMapFluttify';
  private static readonly DOMAIN = 0xFF00;
  public static isDebugMode: boolean = true;
  private static eventSink?: EventSink;
  private static pluginName: string = "amap_map_fluttify";

  /**
   * 设置事件接收器
   * @param sink EventSink 实例
   */
  static setEventSink(sink: EventSink | undefined): void {
    LogUtil.eventSink = sink;
  }

  /**
   * 发送日志到 Flutter
   * @param level 日志级别
   * @param tag 标签
   * @param message 消息
   */
  private static sendToFlutter(level: string, tag: string, message: string): void {
    if (LogUtil.eventSink) {
      try {
        const logMessage = `[${tag}] ${message}`;
        LogUtil.eventSink.success({
          level: level,
          tag: tag,
          message: message,
          fullMessage: logMessage
        });
      } catch (error) {
        // 忽略错误，避免影响正常功能
      }
    }
  }

  /**
   * 信息日志
   * @param className 类名
   * @param msg 日志信息
   */
  public static i(className: string, msg: string): void {
    if (LogUtil.isDebugMode) {
      hilog.info(LogUtil.DOMAIN, LogUtil.TAG, `[INFO] ${className}: ${msg}`);
      LogUtil.sendToFlutter("INFO", className, msg);
    }
  }

  /**
   * 警告日志
   * @param className 类名
   * @param msg 日志信息
   */
  public static w(className: string, msg: string): void {
    if (LogUtil.isDebugMode) {
      hilog.warn(LogUtil.DOMAIN, LogUtil.TAG, `[WARN] ${className}: ${msg}`);
      LogUtil.sendToFlutter("WARN", className, msg);
    }
  }

  /**
   * 错误日志
   * @param className 类名
   * @param method 方法名
   * @param error 错误信息
   */
  public static e(className: string, method: string, error?: Error): void {
    if (LogUtil.isDebugMode) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      const stack = error instanceof Error && error.stack ? `\nStack: ${error.stack}` : '';
      const fullMessage = `${className}.${method}: ${errorMsg}${stack}`;
      hilog.error(LogUtil.DOMAIN, LogUtil.TAG, `[ERROR] ${fullMessage}`);
      LogUtil.sendToFlutter("ERROR", className, fullMessage);
    }
  }
  
  /**
   * 调试日志
   * @param className 类名
   * @param msg 日志信息
   */
  public static d(className: string, msg: string): void {
    if (LogUtil.isDebugMode) {
      hilog.debug(LogUtil.DOMAIN, LogUtil.TAG, `[DEBUG] ${className}: ${msg}`);
      LogUtil.sendToFlutter("DEBUG", className, msg);
    }
  }
}

