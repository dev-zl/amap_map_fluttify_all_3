import {
  Any,
  FlutterPlugin,
  FlutterPluginBinding,
  MethodChannel,
  EventChannel,
  StandardMethodCodec,
  StandardMessageCodec,
  StreamHandler,
  EventSink
} from "@ohos/flutter_ohos";
import { LogUtil } from "./utils/LogUtil";
import { MethodCallHandler } from "./MethodCallHandler";
import { MapViewFactory } from "./MapViewFactory";
import { TextureMapViewFactory } from "./TextureMapViewFactory";
import { WearMapViewFactory } from "./WearMapViewFactory";
import { DownloadProgressViewFactory } from "./DownloadProgressViewFactory";

/**
 * AmapMapFluttifyPlugin 插件主入口，实现FlutterPlugin接口。
 * 主要功能：
 * 1. 插件注册与反注册，管理MethodChannel/BinaryMessenger。
 * 2. 注册PlatformViewFactory到Flutter引擎，实现原生地图视图与Flutter的桥接。
 * 3. 负责插件生命周期管理。
 */
export default class AmapMapFluttifyPlugin implements FlutterPlugin, StreamHandler {
  // MethodChannel对象
  private channel?: MethodChannel;
  // EventChannel对象，用于发送日志
  private eventChannel?: EventChannel;
  // 插件绑定对象静态引用
  public static binding: FlutterPluginBinding;
  // 方法调用处理器
  private methodCallHandler?: MethodCallHandler;
  // 事件接收器
  private eventSink?: EventSink;

  /**
   * 获取唯一类名
   * @returns 类名字符串
   */
  getUniqueClassName(): string {
    return "AmapMapFluttifyPlugin";
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
   * 插件绑定到引擎时回调，注册原生视图工厂和MethodChannel
   * @param binding 插件绑定对象
   */
  onAttachedToEngine(binding: FlutterPluginBinding): void {
    console.log("========================================");
    console.log("[AmapMapFluttify] 插件开始初始化");
    console.log("========================================");
    
    LogUtil.i("AmapMapFluttifyPlugin", "onAttachedToEngine 开始执行");
    AmapMapFluttifyPlugin.binding = binding;

    // 创建MethodChannel，使用与Android一致的名称
    LogUtil.i("AmapMapFluttifyPlugin", "创建 MethodChannel: me.yohom/amap_map_fluttify");
    this.channel = new MethodChannel(
      binding.getBinaryMessenger(),
      "me.yohom/amap_map_fluttify",
      StandardMethodCodec.INSTANCE
    );

    // 创建EventChannel，用于发送日志到Flutter
    this.eventChannel = new EventChannel(
      binding.getBinaryMessenger(),
      "me.yohom/amap_map_fluttify/log"
    );
    this.eventChannel.setStreamHandler(this);

    // 创建方法调用处理器
    LogUtil.i("AmapMapFluttifyPlugin", "创建 MethodCallHandler");
    this.methodCallHandler = new MethodCallHandler(binding.getBinaryMessenger());
    this.channel.setMethodCallHandler(this.methodCallHandler);
    LogUtil.i("AmapMapFluttifyPlugin", "MethodCallHandler 设置完成");

    // 注册PlatformViewFactory
    const platformViewRegistry = binding.getPlatformViewRegistry();
    LogUtil.i("AmapMapFluttifyPlugin", "开始注册 PlatformViewFactory");

    // 注册MapView
    platformViewRegistry.registerViewFactory(
      "me.yohom/com.amap.api.maps.MapView",
      new MapViewFactory(binding.getBinaryMessenger(), StandardMessageCodec.INSTANCE)
    );
    LogUtil.i("AmapMapFluttifyPlugin", "MapView 注册完成");

    // 注册TextureMapView
    platformViewRegistry.registerViewFactory(
      "me.yohom/com.amap.api.maps.TextureMapView",
      new TextureMapViewFactory(binding.getBinaryMessenger(), StandardMessageCodec.INSTANCE)
    );
    LogUtil.i("AmapMapFluttifyPlugin", "TextureMapView 注册完成");

    // 注册WearMapView
    platformViewRegistry.registerViewFactory(
      "me.yohom/com.amap.api.maps.WearMapView",
      new WearMapViewFactory(binding.getBinaryMessenger(), StandardMessageCodec.INSTANCE)
    );
    LogUtil.i("AmapMapFluttifyPlugin", "WearMapView 注册完成");

    // 注册DownloadProgressView
    platformViewRegistry.registerViewFactory(
      "me.yohom/com.amap.api.maps.offlinemap.DownloadProgressView",
      new DownloadProgressViewFactory(binding.getBinaryMessenger(), StandardMessageCodec.INSTANCE)
    );
    LogUtil.i("AmapMapFluttifyPlugin", "DownloadProgressView 注册完成");

    console.log("========================================");
    console.log("[AmapMapFluttify] 插件初始化完成");
    console.log("========================================");
  }

  /**
   * 插件从引擎解绑时回调，清理MethodChannel
   * @param binding 插件绑定对象
   */
  onDetachedFromEngine(binding: FlutterPluginBinding): void {
    LogUtil.i("AmapMapFluttifyPlugin", "onDetachedFromEngine");
    this.channel?.setMethodCallHandler(null);
    this.eventChannel?.setStreamHandler(null);
    this.methodCallHandler = undefined;
    this.eventSink = undefined;
    LogUtil.setEventSink(undefined);
  }
}

