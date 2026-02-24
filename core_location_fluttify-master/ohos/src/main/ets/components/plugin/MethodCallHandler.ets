import {
  MethodCall,
  MethodResult,
  MethodCallHandler as IMethodCallHandler
} from "@ohos/flutter_ohos";
import { LogUtil } from "./utils/LogUtil";

/**
 * MethodCallHandler 处理来自Flutter的方法调用
 */
export class MethodCallHandler implements IMethodCallHandler {
  /**
   * 处理方法调用
   */
  onMethodCall(call: MethodCall, result: MethodResult): void {
    const methodName = call.method;
    LogUtil.d("MethodCallHandler", `onMethodCall: ${methodName}`);

    // 根据方法名分发到对应的处理器
    switch (methodName) {
      case "getPlatformVersion":
        result.success(`HarmonyOS ${globalThis.ohosVersion || "Unknown"}`);
        break;
      
      default:
        // 对于 Fluttify 生成的方法，格式通常是 "类名::方法名"
        if (methodName.includes("::")) {
          // 暂时返回 notImplemented，后续可以根据需要实现具体方法
          LogUtil.w("MethodCallHandler", `Method not implemented: ${methodName}`);
          result.notImplemented();
        } else {
          result.notImplemented();
        }
        break;
    }
  }
}

