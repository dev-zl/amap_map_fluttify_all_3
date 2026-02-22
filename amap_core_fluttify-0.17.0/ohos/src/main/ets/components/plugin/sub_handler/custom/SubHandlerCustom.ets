import {
  BinaryMessenger,
  MethodResult
} from "@ohos/flutter_ohos";
import { HashMap } from "@kit.ArkTS";
import { LogUtil } from "../../utils/LogUtil";

/**
 * SubHandlerCustom 自定义方法处理器
 * 对应Android的SubHandlerCustom
 */
export class SubHandlerCustom {
  private static instance: SubHandlerCustom = new SubHandlerCustom();

  private constructor() {}

  public static getInstance(): SubHandlerCustom {
    return this.instance;
  }

  /**
   * 获取子处理器映射表
   */
  public getSubHandler(messenger: BinaryMessenger): HashMap<string, (args: any, result: MethodResult) => void> {
    const handlerMap = new HashMap<string, (args: any, result: MethodResult) => void>();
    
    // 这里可以添加自定义的方法处理器
    // 例如：
    // handlerMap.set("AMapServices::sharedServices", (args, result) => {
    //   // 实现逻辑
    //   result.success(null);
    // });

    LogUtil.d("SubHandlerCustom", `Registered ${handlerMap.size()} custom handlers`);
    return handlerMap;
  }
}

