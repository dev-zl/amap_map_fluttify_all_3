import {
  MethodCall,
  MethodResult,
  MethodCallHandler as IMethodCallHandler,
  BinaryMessenger
} from "@ohos/flutter_ohos";
import { LogUtil } from "./utils/LogUtil";
import { HashMap } from "@kit.ArkTS";
import { SubHandlerCustom } from "./sub_handler/custom/SubHandlerCustom";

/**
 * MethodCallHandler 处理来自Flutter的方法调用
 * 使用Fluttify生成的方法分发机制
 */
export class MethodCallHandler implements IMethodCallHandler {
  private handlerMapList: HashMap<string, (args: any, result: MethodResult) => void> = new HashMap();

  constructor(messenger: BinaryMessenger) {
    this.initHandlers(messenger);
  }

  /**
   * 初始化处理器映射表
   */
  private initHandlers(messenger: BinaryMessenger): void {
    // 注册自定义处理器
    const customHandlers = SubHandlerCustom.getInstance().getSubHandler(messenger);
    // 遍历并注册所有处理器
    const keys = customHandlers.keys();
    for (let i = 0; i < keys.length; i++) {
      const methodName = keys[i];
      const handler = customHandlers.get(methodName);
      if (handler) {
        this.handlerMapList.set(methodName, handler);
      }
    }
  }

  /**
   * 处理方法调用
   */
  onMethodCall(call: MethodCall, result: MethodResult): void {
    const methodName = call.method;
    LogUtil.d("MethodCallHandler", `onMethodCall: ${methodName}`);

    // 查找对应的处理器
    const handler = this.handlerMapList.get(methodName);
    if (handler) {
      try {
        handler(call.args, result);
      } catch (error) {
        LogUtil.e("MethodCallHandler", `Error handling method ${methodName}: ${error}`);
        result.error(error.toString(), null, null);
      }
    } else {
      LogUtil.w("MethodCallHandler", `Method not implemented: ${methodName}`);
      result.notImplemented();
    }
  }
}

