import {
  CameraPosition,
  CameraUpdate,
  CustomMapStyleOptions,
  LatLngBounds,
  MyLocationStyle,
  AMap,
  CameraUpdateFactory,
  LatLng,
  Poi,
  OnCameraChangeListener
} from "@amap/amap_lbs_map3d";
import { Any, MethodCall, MethodChannel, MethodResult, EventSink } from "@ohos/flutter_ohos";
import { MyMethodCallHandler } from "../MyMethodCallHandler";
import { CommonUtils } from "../utils/CommonUtils";
import { Const } from "../utils/Const";
import { ConvertUtil } from "../utils/ConvertUtil";
import { AMapOptionsSink } from "./AMapOptionsSink";
import { common } from "@kit.AbilityKit";
import { geoLocationManager } from "@kit.LocationKit";
import { LogUtil } from "../utils/LogUtil";

/**
 * MapController 地图控制器
 * 处理地图相关MethodChannel消息，实现Flutter与原生地图的通信
 */
export class MapController implements MyMethodCallHandler, AMapOptionsSink {
  methodChannel?: MethodChannel;
  context?: common.UIAbilityContext;
  public viewId: number;
  myLocationShowing: boolean = false;
  private eventSink?: EventSink;
  private moveStarted: boolean = false;

  constructor(methodChannel: MethodChannel, context: common.UIAbilityContext, viewId: number) {
    LogUtil.d("MapController", `构造函数开始，viewId: ${viewId}`);
    this.methodChannel = methodChannel;
    this.context = context;
    this.viewId = viewId;
    // 监听地图初始化完成事件
    const eventName = `onMapFinished_${this.viewId}`;
    LogUtil.d("MapController", `注册事件监听: ${eventName}`);
    this.context.eventHub.on(eventName, () => {
      LogUtil.d("MapController", `收到地图初始化完成事件，开始执行afterInit`);
      this.afterInit();
    });
    LogUtil.d("MapController", `构造函数完成，viewId: ${viewId}`);
  }

  /**
   * 解绑地图初始化完成事件
   */
  public offEventhub(): void {
    this.context?.eventHub.off(`onMapFinished_${this.viewId}`);
  }

  /**
   * 设置事件接收器
   */
  public setEventSink(sink: EventSink | undefined): void {
    this.eventSink = sink;
  }

  /**
   * 地图初始化完成后的回调，绑定地图事件监听
   */
  private afterInit(): void {
    LogUtil.d("MapController", `afterInit开始，viewId: ${this.viewId}`);
    const amap = Const.getAMap(this.viewId);
    if (amap) {
      LogUtil.d("MapController", `获取到AMap对象，开始绑定事件监听`);
      // 监听定位变化
      LogUtil.d("MapController", `设置定位变化监听器`);
      amap.setOnMyLocationChangeListener((location: geoLocationManager.Location) => {
        if (this.methodChannel && this.myLocationShowing) {
          let params: Map<string, Any> = new Map();
          params.set('location', ConvertUtil.location2Map(location));
          this.methodChannel.invokeMethod('location#changed', params);
        }
      });

      // 监听相机移动
      LogUtil.d("MapController", `设置相机移动监听器`);
      amap.setOnCameraChangeListener(new OnCameraChangeListener(
        (position: CameraPosition) => {
          // 通过 EventChannel 发送地图移动事件
          if (this.eventSink) {
            try {
              const positionMap = ConvertUtil.cameraPositionToMap(position);
              const eventData: Map<string, Any> = new Map();
              eventData.set('type', 'onMapMoving');
              eventData.set('position', positionMap);
              
              if (!this.moveStarted) {
                // 第一次移动，发送 onMapMoveStart 事件
                const startEventData: Map<string, Any> = new Map();
                startEventData.set('type', 'onMapMoveStart');
                startEventData.set('position', positionMap);
                this.eventSink.success(startEventData);
                this.moveStarted = true;
              }
              
              // 发送移动中事件
              this.eventSink.success(eventData);
            } catch (error) {
              LogUtil.e("MapController", "onCameraChange", error instanceof Error ? error : new Error(String(error)));
            }
          }
          
          // 保持原有的 MethodChannel 调用（用于兼容）
          if (this.methodChannel) {
            let params: Map<string, Any> = new Map();
            params.set('position', ConvertUtil.cameraPositionToMap(position));
            this.methodChannel.invokeMethod('camera#onMove', params);
          }
        },
        (position: CameraPosition) => {
          // 通过 EventChannel 发送地图移动结束事件
          if (this.eventSink) {
            try {
              const positionMap = ConvertUtil.cameraPositionToMap(position);
              const eventData: Map<string, Any> = new Map();
              eventData.set('type', 'onMapMoveEnd');
              eventData.set('position', positionMap);
              this.eventSink.success(eventData);
              this.moveStarted = false;
            } catch (error) {
              LogUtil.e("MapController", "onCameraChangeFinish", error instanceof Error ? error : new Error(String(error)));
            }
          }
          
          // 保持原有的 MethodChannel 调用（用于兼容）
          if (this.methodChannel) {
            let params: Map<string, Any> = new Map();
            params.set('position', ConvertUtil.cameraPositionToMap(position));
            this.methodChannel.invokeMethod('camera#onMoveEnd', params);
          }
        }));

      // 监听地图单击
      LogUtil.d("MapController", `设置地图单击监听器`);
      amap.setOnMapClickListener((point: LatLng) => {
        if (this.methodChannel) {
          let params: Map<string, Any> = new Map();
          params.set('latLng', [point.latitude, point.longitude]);
          this.methodChannel.invokeMethod('map#onTap', params);
        }
      });

      // 监听地图长按
      LogUtil.d("MapController", `设置地图长按监听器`);
      amap.setOnMapLongClickListener((point: LatLng) => {
        if (this.methodChannel) {
          let params: Map<string, Any> = new Map();
          params.set('latLng', [point.latitude, point.longitude]);
          this.methodChannel.invokeMethod('map#onLongPress', params);
        }
      });

      // 监听POI点击
      LogUtil.d("MapController", `设置POI点击监听器`);
      amap.addOnPOIClickListener((poi: Poi) => {
        if (this.methodChannel) {
          let params: Map<string, Any> = new Map();
          params.set('poi', ConvertUtil.poiToMap(poi));
          this.methodChannel.invokeMethod('map#onPoiTouched', params);
        }
      });
      LogUtil.d("MapController", `所有事件监听器设置完成`);
    } else {
      LogUtil.w("MapController", `AMap对象不存在，无法绑定事件监听，viewId: ${this.viewId}`);
    }
    LogUtil.d("MapController", `afterInit完成，viewId: ${this.viewId}`);
  }

  /**
   * 获取本控制器注册的方法ID列表
   */
  getRegisterMethodIdArray(): string[] {
    return Const.METHOD_ID_LIST_FOR_MAP;
  }

  /**
   * MethodChannel消息分发处理
   */
  doMethodCall(call: MethodCall, result: MethodResult): void {
    const method: string = call.method;
    LogUtil.d("MapController", `doMethodCall开始，method: ${method}, viewId: ${this.viewId}`);
    const aMap = Const.getAMap(this.viewId);
    LogUtil.d("MapController", `获取AMap对象: ${aMap ? '存在' : '不存在'}`);

    switch (method) {
      case Const.METHOD_MAP_WAIT_FOR_MAP:
        LogUtil.d("MapController", `处理METHOD_MAP_WAIT_FOR_MAP`);
        let mapLoaded = Const.getMapLoaded(this.viewId);
        LogUtil.d("MapController", `地图加载状态: ${mapLoaded}`);
        if (mapLoaded) {
          LogUtil.d("MapController", `地图已加载，直接返回success`);
          result.success(null);
          return;
        }
        LogUtil.d("MapController", `地图未加载，保存result等待地图加载完成`);
        Const.setMapReadyResult(result, this.viewId);
        break;

      case Const.METHOD_MAP_UPDATE:
        ConvertUtil.interpretAMapOptions(CommonUtils.argumentParse('options', call.args), this);
        result.success(null);
        break;

      case Const.METHOD_MAP_MOVE_CAMERA:
        let cameraUpdate: CameraUpdate =
          ConvertUtil.toCameraUpdate(CommonUtils.argumentParse("cameraUpdate", call.args));
        this.moveCamera(cameraUpdate);
        result.success(null);
        break;

      case Const.METHOD_MAP_TAKE_SNAPSHOT:
        if (aMap != undefined) {
          // TODO: 实现截图功能
          result.success(null);
        }
        break;

      case Const.METHOD_MAP_CLEAR_DISK:
        if (aMap != undefined) {
          // TODO: 实现清除缓存功能
          result.success(null);
        }
        break;

      default:
        LogUtil.w("MapController", `Method not found: ${method}`);
        break;
    }
  }

  // AMapOptionsSink 接口实现
  setCamera(camera: CameraPosition): void {
    let aMap = Const.getAMap(this.viewId);
    aMap?.moveCamera(CameraUpdateFactory.newCameraPosition(camera));
  }

  setMapType(mapType: number): void {
    const aMap = Const.getAMap(this.viewId);
    aMap?.setMapType(mapType);
  }

  setCustomMapStyleOptions(options: CustomMapStyleOptions): void {
    const aMap = Const.getAMap(this.viewId);
    aMap?.setCustomMapStyle(options);
  }

  setMyLocationStyle(style: MyLocationStyle): void {
    const aMap = Const.getAMap(this.viewId);
    this.myLocationShowing = style.isMyLocationShowing();
    aMap?.setMyLocationEnabled(this.myLocationShowing);
    aMap?.setMyLocationStyle(style);
  }

  setScreenAnchor(x: number, y: number): void {
    // TODO: 实现屏幕锚点设置
  }

  setMinZoomLevel(minZoomLevel: number): void {
    const aMap = Const.getAMap(this.viewId);
    aMap?.setMinZoomLevel(minZoomLevel);
  }

  setMaxZoomLevel(maxZoomLevel: number): void {
    const aMap = Const.getAMap(this.viewId);
    aMap?.setMaxZoomLevel(maxZoomLevel);
  }

  setLatLngBounds(bounds: LatLngBounds): void {
    const aMap = Const.getAMap(this.viewId);
    aMap?.setMapStatusLimits(bounds);
  }

  setTrafficEnabled(enabled: boolean): void {
    const aMap = Const.getAMap(this.viewId);
    aMap?.setTrafficEnabled(enabled);
  }

  setTouchPoiEnabled(enabled: boolean): void {
    const aMap = Const.getAMap(this.viewId);
    aMap?.setTouchPoiEnable(enabled);
  }

  setBuildingsEnabled(enabled: boolean): void {
    const aMap = Const.getAMap(this.viewId);
    aMap?.showBuildings(enabled);
  }

  setLabelsEnabled(enabled: boolean): void {
    const aMap = Const.getAMap(this.viewId);
    aMap?.showMapText(enabled);
  }

  setCompassEnabled(enabled: boolean): void {
    const aMap = Const.getAMap(this.viewId);
    aMap?.getUiSettings()?.setCompassEnabled(enabled);
  }

  setScaleEnabled(enabled: boolean): void {
    const aMap = Const.getAMap(this.viewId);
    aMap?.getUiSettings()?.setScaleControlsEnabled(enabled);
  }

  setZoomGesturesEnabled(enabled: boolean): void {
    const aMap = Const.getAMap(this.viewId);
    aMap?.getUiSettings()?.setZoomGesturesEnabled(enabled);
  }

  setScrollGesturesEnabled(enabled: boolean): void {
    const aMap = Const.getAMap(this.viewId);
    aMap?.getUiSettings()?.setScrollGesturesEnabled(enabled);
  }

  setRotateGesturesEnabled(enabled: boolean): void {
    const aMap = Const.getAMap(this.viewId);
    aMap?.getUiSettings()?.setRotateGesturesEnabled(enabled);
  }

  setTiltGesturesEnabled(enabled: boolean): void {
    const aMap = Const.getAMap(this.viewId);
    aMap?.getUiSettings()?.setTiltGesturesEnabled(enabled);
  }

  setInitialMarkers(markers: object[]): void {
    // 由 MarkersController 处理
  }

  setInitialPolylines(polylines: object[]): void {
    // 由 PolylinesController 处理
  }

  setInitialPolygons(polygons: object[]): void {
    // 由 PolygonsController 处理
  }

  /**
   * 移动相机到指定位置
   */
  async moveCamera(cameraUpdate: CameraUpdate): Promise<void> {
    let aMap = Const.getAMap(this.viewId);
    aMap?.moveCamera(cameraUpdate);
  }
}

