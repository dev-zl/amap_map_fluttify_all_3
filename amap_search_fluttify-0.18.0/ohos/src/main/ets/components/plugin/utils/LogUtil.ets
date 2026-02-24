import { EventSink } from "@ohos/flutter_ohos";

/**
 * LogUtil 日志工具类
 */
export class LogUtil {
  static isDebugMode: boolean = false;
  private static eventSink?: EventSink;
  private static pluginName: string = "amap_search_fluttify";

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

  static d(tag: string, message: string): void {
    if (LogUtil.isDebugMode) {
      console.debug(`[${tag}] ${message}`);
      LogUtil.sendToFlutter("DEBUG", tag, message);
    }
  }

  static i(tag: string, message: string): void {
    console.info(`[${tag}] ${message}`);
    LogUtil.sendToFlutter("INFO", tag, message);
  }

  static w(tag: string, message: string): void {
    console.warn(`[${tag}] ${message}`);
    LogUtil.sendToFlutter("WARN", tag, message);
  }

  static e(tag: string, message: string): void {
    console.error(`[${tag}] ${message}`);
    LogUtil.sendToFlutter("ERROR", tag, message);
  }
}

