import {
  Any,
  BinaryMessenger,
  MethodCall,
  MethodCallHandler as IMethodCallHandler,
  MethodResult,
} from "@ohos/flutter_ohos";
import { LogUtil } from "./utils/LogUtil";
import { HashMap } from "@kit.ArkTS";
import { MapsInitializer } from '@amap/amap_lbs_map3d';
import { Const } from "./utils/Const";
import AmapMapFluttifyPlugin from "./AmapMapFluttifyPlugin";

/**
 * 方法调用处理器接口
 */
export interface Handler {
  call(args: Any, result: MethodResult): void;
}

/**
 * 测试插件是否加载的 Handler
 */
class CheckPluginHandler implements Handler {
  call(args: Any, result: MethodResult): void {
    try {
      LogUtil.i("MethodCallHandler", "收到 checkPlugin 调用 - 插件已正确加载");
      console.log("=== HARMONYOS PLUGIN IS LOADED ===");
      result.success("HarmonyOS 插件已正确加载");
    } catch (error) {
      LogUtil.e("MethodCallHandler", "checkPlugin", error as Error);
      result.error(
        "CHECK_FAILED",
        error instanceof Error ? error.message : String(error),
        null
      );
    }
  }
}

/**
 * 初始化高德地图的 Handler
 */
class InitAmapHandler implements Handler {
  call(args: Any, result: MethodResult): void {
    try {
      LogUtil.d("MethodCallHandler", "收到 initAMap 调用");

      // 解析参数
      const params = args as Map<string, Object>;
      const apiKey = params?.get("apiKey");
      const apiKeyStr = apiKey ? String(apiKey) : '';

      LogUtil.d("MethodCallHandler", `API Key: ${apiKeyStr}`);

      if (apiKeyStr && apiKeyStr.trim() !== '') {
        // 调用高德地图 SDK 初始化
        MapsInitializer.setApiKey(apiKeyStr);
        LogUtil.d("MethodCallHandler", "高德地图 SDK 初始化成功");
        result.success("初始化成功");
      } else {
        LogUtil.e("MethodCallHandler", "initAMap", new Error("API Key 为空"));
        result.error("INVALID_API_KEY", "API Key 不能为空", null);
      }
    } catch (error) {
      LogUtil.e("MethodCallHandler", "initAMap", error as Error);
      result.error(
        "INIT_FAILED",
        error instanceof Error ? error.message : String(error),
        null
      );
    }
  }
}

/**
 * 更新隐私权政策展示状态的 Handler
 */
class UpdatePrivacyShowHandler implements Handler {
  call(args: Any, result: MethodResult): void {
    try {
      LogUtil.d("MethodCallHandler", "收到 updatePrivacyShow 调用");
      
      // 解析参数
      const params = args as Map<string, Object>;
      const value = params?.get("value");
      const hasShow = value === true || value === "true" || value === 1;
      
      LogUtil.d("MethodCallHandler", `updatePrivacyShow 参数解析: value=${value}, hasShow=${hasShow}`);
      
      // 保存到全局状态，供创建地图时使用
      Const.setPrivacyHasShow(hasShow);
      // 默认设置 hasContains 为 true（如果已展示，通常也包含隐私政策）
      if (hasShow) {
        Const.setPrivacyHasContains(true);
      }
      
      LogUtil.d("MethodCallHandler", `隐私权政策展示状态已保存: hasShow=${hasShow}, hasContains=${Const.getPrivacyHasContains()}`);
      
      // 状态已保存，实际的 SDK 调用会在创建地图时通过 creationParams 传递
      // 这样确保在创建地图之前隐私权政策状态已正确设置
      LogUtil.d("MethodCallHandler", `隐私权政策展示状态设置完成`);
      result.success("隐私权政策展示状态设置成功");
    } catch (error) {
      LogUtil.e("MethodCallHandler", "updatePrivacyShow", error as Error);
      result.error(
        "UPDATE_FAILED",
        error instanceof Error ? error.message : String(error),
        null
      );
    }
  }
}

/**
 * 更新隐私权政策同意状态的 Handler
 */
class UpdatePrivacyAgreeHandler implements Handler {
  call(args: Any, result: MethodResult): void {
    try {
      LogUtil.d("MethodCallHandler", "收到 updatePrivacyAgree 调用");
      
      // 解析参数
      const params = args as Map<string, Object>;
      const value = params?.get("value");
      const hasAgree = value === true || value === "true" || value === 1;
      
      LogUtil.d("MethodCallHandler", `updatePrivacyAgree 参数解析: value=${value}, hasAgree=${hasAgree}`);
      
      // 保存到全局状态，供创建地图时使用
      Const.setPrivacyHasAgree(hasAgree);
      
      LogUtil.d("MethodCallHandler", `隐私权政策同意状态已保存: hasAgree=${hasAgree}`);
      
      // 状态已保存，实际的 SDK 调用会在创建地图时通过 creationParams 传递
      // 这样确保在创建地图之前隐私权政策状态已正确设置
      LogUtil.d("MethodCallHandler", `隐私权政策同意状态设置完成`);
      result.success("隐私权政策同意状态设置成功");
    } catch (error) {
      LogUtil.e("MethodCallHandler", "updatePrivacyAgree", error as Error);
      result.error(
        "UPDATE_FAILED",
        error instanceof Error ? error.message : String(error),
        null
      );
    }
  }
}

/**
 * MethodCallHandler 负责处理来自Flutter的MethodChannel调用
 * 通过Handler映射表分发到对应的处理方法
 */
export class MethodCallHandler implements IMethodCallHandler {
  private handlerMap: HashMap<string, Handler> = new HashMap();
  private messenger: BinaryMessenger;

  constructor(messenger: BinaryMessenger) {
    this.messenger = messenger;
    this.initHandlers();
  }

  /**
   * 初始化所有Handler
   * 这里需要注册所有SubHandler中的方法
   */
  private initHandlers(): void {
    LogUtil.d("MethodCallHandler", "开始注册 MethodChannel 处理器...");

    // 注册插件测试方法
    this.handlerMap.set("checkPlugin", new CheckPluginHandler());

    // 注册鸿蒙高德地图初始化方法
    this.handlerMap.set("initAMap", new InitAmapHandler());

    // 注册隐私权政策相关方法
    this.handlerMap.set("updatePrivacyShow", new UpdatePrivacyShowHandler());
    this.handlerMap.set("updatePrivacyAgree", new UpdatePrivacyAgreeHandler());

    LogUtil.d("MethodCallHandler", "MethodChannel 处理器注册完成");
  }

  /**
   * 处理MethodChannel调用
   * @param call 方法调用对象
   * @param result 返回结果对象
   */
  onMethodCall(call: MethodCall, result: MethodResult): void {
    const methodName = call.method;
    const args: Object = call.args;

    LogUtil.d("MethodCallHandler", `onMethodCall: ${methodName}`);

    const handler = this.handlerMap.get(methodName);
    if (handler) {
      try {
        handler.call(args, result);
      } catch (error) {
        LogUtil.e("MethodCallHandler", methodName, error as Error);
        result.error(
          error instanceof Error ? error.message : String(error),
          null,
          null
        );
      }
    } else {
      LogUtil.w("MethodCallHandler", `Method not implemented: ${methodName}`);
      result.notImplemented();
    }
  }

  /**
   * 注册一个Handler
   * @param methodName 方法名
   * @param handler 处理器
   */
  public registerHandler(methodName: string, handler: Handler): void {
    this.handlerMap.set(methodName, handler);
  }
}

