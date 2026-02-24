import {
  Any,
  BinaryMessenger,
  MethodCall,
  MethodCallHandler as IMethodCallHandler,
  MethodChannel,
  EventChannel,
  MethodResult,
  StandardMethodCodec,
  StreamHandler,
  EventSink,
} from "@ohos/flutter_ohos";
import PlatformView, { Params } from "@ohos/flutter_ohos/src/main/ets/plugin/platform/PlatformView";
import { common } from "@kit.AbilityKit";
import { LogUtil } from "./utils/LogUtil";
import {
  AMapOptions
} from "@amap/amap_lbs_map3d";
import { Const } from "./utils/Const";
import { MapController } from "./core/MapController";
import { MarkersController } from "./overlays/marker/MarkersController";
import { PolylinesController } from "./overlays/polyline/PolylinesController";
import { PolygonsController } from "./overlays/polygon/PolygonsController";
import { HashMap } from "@kit.ArkTS";
import { MyMethodCallHandler } from "./MyMethodCallHandler";
import { AMapOptionsBuilder } from "./AMapOptionsBuilder";
import { AMapBuilder } from "./AMapComponent";

/**
 * MapPlatformView 封装地图平台视图，负责与Flutter MethodChannel通信
 */
@Observed
export class MapPlatformView extends PlatformView implements IMethodCallHandler, StreamHandler {
  public methodChannel: MethodChannel;
  private eventChannel?: EventChannel;
  private viewId: number;
  private context: common.UIAbilityContext;
  private builder?: AMapOptionsBuilder;
  private myMethodCallHandlerMap?: HashMap<string, MyMethodCallHandler>;
  private mapController?: MapController;
  private markersController?: MarkersController;
  private polylinesController?: PolylinesController;
  private polygonsController?: PolygonsController;
  private eventSink?: EventSink;

  /**
   * 构造函数
   * @param context 上下文
   * @param viewId 视图ID
   * @param options 地图选项
   * @param messenger Flutter消息通道
   * @param builder 地图参数构建器
   */
  constructor(context: common.UIAbilityContext, viewId: number, options: AMapOptions, messenger: BinaryMessenger, builder: AMapOptionsBuilder) {
    super();
    LogUtil.d("MapPlatformView", `构造函数开始，viewId: ${viewId}`);
    this.viewId = viewId;
    this.builder = builder;
    this.context = context;
    
    // 创建MethodChannel，使用与Android一致的命名规则
    const channelName = `me.yohom/amap_map_fluttify_${viewId}`;
    LogUtil.d("MapPlatformView", `创建MethodChannel: ${channelName}`);
    this.methodChannel = new MethodChannel(
      messenger,
      channelName,
      StandardMethodCodec.INSTANCE
    );
    this.methodChannel.setMethodCallHandler(this);
    
    // 创建EventChannel，用于地图移动事件
    const eventChannelName = `${channelName}/map_move_events`;
    LogUtil.d("MapPlatformView", `创建EventChannel: ${eventChannelName}`);
    this.eventChannel = new EventChannel(messenger, eventChannelName);
    this.eventChannel.setStreamHandler(this);
    
    LogUtil.d("MapPlatformView", `MethodChannel和EventChannel设置完成，开始初始化Handler映射表`);
    this.initMyMethodCallHandlerMap();
    LogUtil.d("MapPlatformView", `构造函数完成，viewId: ${viewId}`);
  }

  /**
   * 当Flutter端开始监听事件流时调用
   */
  onListen(args: Any, events: EventSink): void {
    LogUtil.d("MapPlatformView", `EventChannel onListen, viewId: ${this.viewId}`);
    this.eventSink = events;
    // 将 EventSink 传递给 MapController
    this.mapController?.setEventSink(events);
  }

  /**
   * 当Flutter端取消监听事件流时调用
   */
  onCancel(args: Any): void {
    LogUtil.d("MapPlatformView", `EventChannel onCancel, viewId: ${this.viewId}`);
    this.eventSink = undefined;
    this.mapController?.setEventSink(undefined);
  }

  /**
   * 获取视图ID
   */
  public getViewId(): number {
    return this.viewId;
  }

  /**
   * 初始化MethodCallHandler映射表，将不同类型的消息分发到对应的Controller
   */
  private initMyMethodCallHandlerMap(): void {
    LogUtil.d("MapPlatformView", `initMyMethodCallHandlerMap: 开始创建Controllers，viewId: ${this.viewId}`);
    this.markersController = new MarkersController(this.methodChannel, this.viewId);
    LogUtil.d("MapPlatformView", `MarkersController创建完成`);
    this.polylinesController = new PolylinesController(this.methodChannel, this.viewId);
    LogUtil.d("MapPlatformView", `PolylinesController创建完成`);
    this.polygonsController = new PolygonsController(this.methodChannel, this.viewId);
    LogUtil.d("MapPlatformView", `PolygonsController创建完成`);
    this.mapController = new MapController(this.methodChannel, this.context, this.viewId);
    LogUtil.d("MapPlatformView", `MapController创建完成`);
    this.myMethodCallHandlerMap = new HashMap();

    // 注册地图相关方法
    let methodIdArray: string[] = this.mapController?.getRegisterMethodIdArray() ?? [];
    LogUtil.d("MapPlatformView", `注册地图相关方法，数量: ${methodIdArray.length}`);
    if (methodIdArray.length > 0) {
      for (let index = 0; index < methodIdArray.length; index++) {
        const methodId = methodIdArray[index];
        this.myMethodCallHandlerMap?.set(methodId, this.mapController);
      }
    }

    // 注册Marker相关方法
    methodIdArray = this.markersController?.getRegisterMethodIdArray() ?? [];
    if (methodIdArray.length > 0) {
      for (let index = 0; index < methodIdArray.length; index++) {
        const methodId = methodIdArray[index];
        this.myMethodCallHandlerMap?.set(methodId, this.markersController);
      }
    }

    // 注册Polyline相关方法
    methodIdArray = this.polylinesController?.getRegisterMethodIdArray();
    if (methodIdArray && methodIdArray.length > 0) {
      for (let index = 0; index < methodIdArray.length; index++) {
        const methodId = methodIdArray[index];
        this.myMethodCallHandlerMap?.set(methodId, this.polylinesController);
      }
    }

    // 注册Polygon相关方法
    methodIdArray = this.polygonsController?.getRegisterMethodIdArray();
    if (methodIdArray && methodIdArray.length > 0) {
      for (let index = 0; index < methodIdArray.length; index++) {
        const methodId = methodIdArray[index];
        this.myMethodCallHandlerMap?.set(methodId, this.polygonsController);
      }
    }
  }


  /**
   * 处理MethodChannel调用
   * @param call 方法调用对象
   * @param result 返回结果对象
   */
  onMethodCall(call: MethodCall, result: MethodResult): void {
    const methodName = call.method;
    LogUtil.d("MapPlatformView", `onMethodCall: ${methodName}, viewId: ${this.viewId}`);
    try {
      LogUtil.d("MapPlatformView", `onMethodCall参数: ${JSON.stringify(call.args)}`);
    } catch (e) {
      LogUtil.d("MapPlatformView", `onMethodCall参数(无法序列化): ${String(call.args)}`);
    }
    
      // 处理 setMapMoveListener 方法
      if (methodName === 'setMapMoveListener') {
        LogUtil.d("MapPlatformView", `处理setMapMoveListener方法`);
        result.success(null);
        return;
      }
      
      if (this.myMethodCallHandlerMap?.hasKey(methodName)) {
        const handler = this.myMethodCallHandlerMap?.get(methodName);
        if (handler) {
          LogUtil.d("MapPlatformView", `找到Handler，开始处理: ${methodName}`);
          handler.doMethodCall(call, result);
          LogUtil.d("MapPlatformView", `Handler处理完成: ${methodName}`);
        } else {
          LogUtil.w("MapPlatformView", `Handler为空，方法未实现: ${methodName}`);
          result.notImplemented();
        }
      } else {
        LogUtil.w("MapPlatformView", `未找到Handler，方法未实现: ${methodName}`);
        result.notImplemented();
      }
  }

  /**
   * 获取地图组件视图
   * @returns WrappedBuilder
   */
  getView(): WrappedBuilder<[Params]> {
    LogUtil.d("MapPlatformView", `getView被调用，viewId: ${this.viewId}`);
    return new WrappedBuilder(AMapBuilder);
  }

  /**
   * 获取地图控制器
   */
  public getMapController(): MapController | undefined {
    return this.mapController;
  }

  /**
   * 获取Marker控制器
   */
  public getMarkersController(): MarkersController | undefined {
    return this.markersController;
  }

  /**
   * 获取Polyline控制器
   */
  public getPolylinesController(): PolylinesController | undefined {
    return this.polylinesController;
  }

  /**
   * 获取Polygon控制器
   */
  public getPolygonsController(): PolygonsController | undefined {
    return this.polygonsController;
  }

  /**
   * 释放资源
   */
  dispose(): void {
    LogUtil.d("MapPlatformView", `dispose viewId: ${this.viewId}`);
    this.builder?.offEventhub();
    this.mapController?.offEventhub();
  }
}

