import {
  FlutterPlugin,
  FlutterPluginBinding,
  MethodChannel,
  MethodCall,
  MethodResult,
  StandardMethodCodec
} from "@ohos/flutter_ohos";
import { LogUtil } from "./utils/LogUtil";
import { MethodCallHandler } from "./MethodCallHandler";

/**
 * CoreLocationFluttifyPlugin 插件主入口，实现FlutterPlugin接口
 * 提供位置服务相关的功能
 */
export default class CoreLocationFluttifyPlugin implements FlutterPlugin {
  private channel?: MethodChannel;
  private methodCallHandler?: MethodCallHandler;

  /**
   * 获取唯一类名
   */
  getUniqueClassName(): string {
    return "CoreLocationFluttifyPlugin";
  }

  /**
   * 插件绑定到引擎时回调
   */
  onAttachedToEngine(binding: FlutterPluginBinding): void {
    LogUtil.d("CoreLocationFluttifyPlugin", "onAttachedToEngine");
    
    // 创建MethodChannel，使用与Dart层一致的名称
    this.channel = new MethodChannel(
      binding.getBinaryMessenger(),
      "com.fluttify/core_location_method",
      StandardMethodCodec.INSTANCE
    );

    // 创建方法调用处理器
    this.methodCallHandler = new MethodCallHandler();
    this.channel.setMethodCallHandler(this.methodCallHandler);
  }

  /**
   * 插件从引擎解绑时回调
   */
  onDetachedFromEngine(binding: FlutterPluginBinding): void {
    LogUtil.d("CoreLocationFluttifyPlugin", "onDetachedFromEngine");
    this.channel?.setMethodCallHandler(null);
    this.methodCallHandler = undefined;
  }
}

