import {
  FlutterPlugin,
  FlutterPluginBinding,
  MethodChannel,
  EventChannel,
  StandardMethodCodec,
  StreamHandler,
  EventSink,
  Any
} from "@ohos/flutter_ohos";
import { LogUtil } from "./utils/LogUtil";
import { MethodCallHandler } from "./MethodCallHandler";

/**
 * AmapSearchFluttifyPlugin 插件主入口，实现FlutterPlugin接口
 * 提供高德搜索服务相关的功能
 */
export default class AmapSearchFluttifyPlugin implements FlutterPlugin, StreamHandler {
  private channel?: MethodChannel;
  private eventChannel?: EventChannel;
  private methodCallHandler?: MethodCallHandler;
  private eventSink?: EventSink;

  /**
   * 获取唯一类名
   */
  getUniqueClassName(): string {
    return "AmapSearchFluttifyPlugin";
  }

  /**
   * 当Flutter端开始监听事件流时调用
   */
  onListen(args: Any, events: EventSink): void {
    this.eventSink = events;
    LogUtil.setEventSink(events);
  }

  /**
   * 当Flutter端取消监听事件流时调用
   */
  onCancel(args: Any): void {
    this.eventSink = undefined;
    LogUtil.setEventSink(undefined);
  }

  /**
   * 插件绑定到引擎时回调
   */
  onAttachedToEngine(binding: FlutterPluginBinding): void {
    LogUtil.d("AmapSearchFluttifyPlugin", "onAttachedToEngine");
    
    // 创建MethodChannel，使用与Android一致的名称
    this.channel = new MethodChannel(
      binding.getBinaryMessenger(),
      "me.yohom/amap_search_fluttify",
      StandardMethodCodec.INSTANCE
    );

    // 创建EventChannel，用于发送日志到Flutter
    this.eventChannel = new EventChannel(
      binding.getBinaryMessenger(),
      "me.yohom/amap_search_fluttify/log"
    );
    this.eventChannel.setStreamHandler(this);

    // 创建方法调用处理器
    this.methodCallHandler = new MethodCallHandler(binding.getBinaryMessenger());
    this.channel.setMethodCallHandler(this.methodCallHandler);
  }

  /**
   * 插件从引擎解绑时回调
   */
  onDetachedFromEngine(binding: FlutterPluginBinding): void {
    LogUtil.d("AmapSearchFluttifyPlugin", "onDetachedFromEngine");
    this.channel?.setMethodCallHandler(null);
    this.methodCallHandler = undefined;
  }
}

