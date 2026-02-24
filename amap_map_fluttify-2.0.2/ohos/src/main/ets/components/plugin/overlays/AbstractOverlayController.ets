import { Any, MethodChannel } from '@ohos/flutter_ohos';

/**
 * AbstractOverlayController 抽象覆盖物控制器基类
 * 用于管理覆盖物（Marker、Polyline、Polygon等）的通用逻辑
 */
export abstract class AbstractOverlayController<T> {
  protected controllerMapByDartId: Map<string, T>;
  protected idMapByOverlyId: Map<string, string>;
  protected methodChannel: MethodChannel;

  constructor(methodChannel: MethodChannel) {
    this.methodChannel = methodChannel;
    this.controllerMapByDartId = new Map();
    this.idMapByOverlyId = new Map<string, string>();
  }
}

