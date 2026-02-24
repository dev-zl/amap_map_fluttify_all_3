import { Any, BinaryMessenger, MessageCodec, PlatformView, PlatformViewFactory } from "@ohos/flutter_ohos";
import { common } from "@kit.AbilityKit";
import { LogUtil } from "./utils/LogUtil";
import { MapViewFactory } from "./MapViewFactory";

/**
 * WearMapViewFactory 可穿戴设备地图平台视图工厂类
 */
export class WearMapViewFactory extends PlatformViewFactory {
  private messenger: BinaryMessenger;
  private mapViewFactory: MapViewFactory;

  constructor(messenger: BinaryMessenger, createArgsCodes: MessageCodec<Object>) {
    super(createArgsCodes);
    this.messenger = messenger;
    this.mapViewFactory = new MapViewFactory(messenger, createArgsCodes);
  }

  public create(context: common.Context, viewId: number, args: Any): PlatformView {
    LogUtil.d("WearMapViewFactory", `Creating WearMapView with viewId: ${viewId}`);
    // WearMapView 在 HarmonyOS 中可以使用相同的实现
    return this.mapViewFactory.create(context, viewId, args);
  }
}

