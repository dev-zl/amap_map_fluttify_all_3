import {
  CameraPosition,
  CustomMapStyleOptions,
  MyLocationStyle,
  LatLngBounds,
  AMapOptions
} from "@amap/amap_lbs_map3d";
import { MapPlatformView } from "./MapPlatformView";
import { AMapOptionsSink } from "./core/AMapOptionsSink";
import { common, Context } from "@kit.AbilityKit";
import { Any, BinaryMessenger } from "@ohos/flutter_ohos";
import { ConvertUtil } from "./utils/ConvertUtil";
import { Const } from "./utils/Const";
import { LogUtil } from "./utils/LogUtil";

/**
 * AMapOptionsBuilder 地图参数构建器，实现AMapOptionsSink接口
 * 用于配置地图初始化参数和相关属性
 */
export class AMapOptionsBuilder implements AMapOptionsSink {
  // 地图配置选项
  options: AMapOptions = new AMapOptions();
  // 自定义地图样式
  customMapStyleOptions?: CustomMapStyleOptions;
  // 定位样式
  myLocationStyle?: MyLocationStyle;
  // 最小缩放级别
  minZoomLevel: number = 3;
  // 最大缩放级别
  maxZoomLevel: number = 20;
  // 地图显示范围
  latLngBounds?: LatLngBounds;
  // 是否显示路况
  trafficEnabled: boolean = true;
  // 是否支持点击POI
  touchPoiEnabled: boolean = true;
  // 是否显示建筑物
  buildingsEnabled: boolean = true;
  // 是否显示标签
  labelsEnabled: boolean = true;
  // 定位蓝点锚点X
  anchorX: number = 2.0;
  // 定位蓝点锚点Y
  anchorY: number = 2.0;
  // 初始marker数据
  initialMarkers?: Any;
  // 初始polyline数据
  initialPolylines?: Any;
  // 初始polygon数据
  initialPolygons?: Any;
  // 地图平台视图对象
  private aMapPlatformView?: MapPlatformView;
  // 上下文对象
  private context?: Context;
  // 视图ID
  private viewId?: number;

  /**
   * 构建地图平台视图
   * @param id 视图ID
   * @param context 上下文
   * @param binaryMessenger 消息通道
   * @returns MapPlatformView
   */
  build(id: number, context: Context, binaryMessenger: BinaryMessenger): MapPlatformView {
    LogUtil.d('AMapOptionsBuilder', `build 开始，viewId: ${id}`);
    this.viewId = id;
    // 默认关闭缩放控件
    this.options.zoomControlsEnabled(false);
    try {
      LogUtil.d('AMapOptionsBuilder', `创建 MapPlatformView，options: ${JSON.stringify(this.options)}`);
    } catch (e) {
      LogUtil.d('AMapOptionsBuilder', `创建 MapPlatformView，options(无法序列化): ${String(this.options)}`);
    }
    let platformView = new MapPlatformView(context as common.UIAbilityContext, id, this.options, binaryMessenger, this);
    this.aMapPlatformView = platformView;
    this.context = context;
    // 监听地图初始化完成事件
    this.context.eventHub.on(`onMapFinished_${id}`, () => {
      LogUtil.d('AMapOptionsBuilder', `收到地图初始化完成事件，viewId: ${id}`);
      this.afterInit();
    });
    LogUtil.d('AMapOptionsBuilder', `build 完成，viewId: ${id}`);
    return this.aMapPlatformView!;
  }

  /**
   * 解绑事件监听
   */
  public offEventhub(): void {
    if (this.viewId !== undefined) {
      this.context?.eventHub.off(`onMapFinished_${this.viewId}`);
    }
  }

  /**
   * 地图初始化完成后的回调
   */
  private afterInit(): void {
    LogUtil.d('AMapOptionsBuilder', `afterInit开始，viewId: ${this.viewId}, platformViewId: ${this.aMapPlatformView?.getViewId()}`);
    
    // 设置初始相机位置
    const camera = this.options.getCamera();
    if (camera != undefined) {
      LogUtil.d('AMapOptionsBuilder', `设置初始相机位置`);
      this.aMapPlatformView?.getMapController()?.setCamera(camera);
    } else {
      LogUtil.d('AMapOptionsBuilder', `未设置初始相机位置`);
    }
    
    // 设置自定义地图样式
    if (this.customMapStyleOptions != undefined) {
      LogUtil.d('AMapOptionsBuilder', `设置自定义地图样式`);
      this.aMapPlatformView?.getMapController()?.setCustomMapStyleOptions(this.customMapStyleOptions);
    }
    
    // 设置定位样式
    if (this.myLocationStyle != undefined) {
      LogUtil.d('AMapOptionsBuilder', `设置定位样式`);
      this.aMapPlatformView?.getMapController()?.setMyLocationStyle(this.myLocationStyle);
    }
    
    // 设置定位锚点
    if (this.anchorX >= 0 && this.anchorX <= 1.0 && this.anchorY <= 1.0 && this.anchorY >= 0) {
      LogUtil.d('AMapOptionsBuilder', `设置定位锚点: (${this.anchorX}, ${this.anchorY})`);
      this.aMapPlatformView?.getMapController()?.setScreenAnchor(this.anchorX, this.anchorY);
    }
    
    // 设置缩放级别范围
    LogUtil.d('AMapOptionsBuilder', `设置缩放级别范围: min=${this.minZoomLevel}, max=${this.maxZoomLevel}`);
    this.aMapPlatformView?.getMapController()?.setMinZoomLevel(this.minZoomLevel);
    this.aMapPlatformView?.getMapController()?.setMaxZoomLevel(this.maxZoomLevel);
    
    // 设置地图显示范围
    if (undefined != this.latLngBounds) {
      LogUtil.d('AMapOptionsBuilder', `设置地图显示范围`);
      this.aMapPlatformView?.getMapController()?.setLatLngBounds(this.latLngBounds);
    }
    
    // 设置路况、POI、建筑物、标签等显示
    LogUtil.d('AMapOptionsBuilder', `设置地图显示选项: traffic=${this.trafficEnabled}, touchPoi=${this.touchPoiEnabled}, buildings=${this.buildingsEnabled}, labels=${this.labelsEnabled}`);
    this.aMapPlatformView?.getMapController()?.setTrafficEnabled(this.trafficEnabled);
    this.aMapPlatformView?.getMapController()?.setTouchPoiEnabled(this.touchPoiEnabled);
    this.aMapPlatformView?.getMapController()?.setBuildingsEnabled(this.buildingsEnabled);
    this.aMapPlatformView?.getMapController()?.setLabelsEnabled(this.labelsEnabled);
    
    // 添加初始marker
    if (undefined != this.initialMarkers) {
      let markerList: Any[] = ConvertUtil.toList(this.initialMarkers);
      LogUtil.d('AMapOptionsBuilder', `markerList : ${markerList.length}`);
      this.aMapPlatformView?.getMarkersController()?.addByList(markerList);
    }
    
    // 添加初始polyline
    if (undefined != this.initialPolylines) {
      let polylineList: Any[] = ConvertUtil.toList(this.initialPolylines);
      LogUtil.d('AMapOptionsBuilder', `polylineList : ${polylineList.length}`);
      if (polylineList.length > 0) {
        this.aMapPlatformView?.getPolylinesController()?.addByList(polylineList);
      }
    }
    
    // 添加初始polygon
    if (undefined != this.initialPolygons) {
      let polygonList: Object[] = ConvertUtil.toList(this.initialPolygons);
      LogUtil.d('AMapOptionsBuilder', `initialPolygons length:${polygonList.length}`);
      if (polygonList.length > 0) {
        this.aMapPlatformView?.getPolygonsController()?.addByList(polygonList);
      }
    }
    LogUtil.d('AMapOptionsBuilder', `afterInit完成，viewId: ${this.viewId}`);
  }

  // AMapOptionsSink 接口实现
  setCamera(camera: CameraPosition): void {
    this.options.camera(camera);
  }

  setMapType(mapType: number): void {
    this.options.mapType(mapType);
  }

  setCustomMapStyleOptions(options: CustomMapStyleOptions): void {
    this.customMapStyleOptions = options;
  }

  setMyLocationStyle(style: MyLocationStyle): void {
    this.myLocationStyle = style;
  }

  setScreenAnchor(x: number, y: number): void {
    this.anchorX = x;
    this.anchorY = y;
  }

  setMinZoomLevel(minZoomLevel: number): void {
    this.minZoomLevel = minZoomLevel;
  }

  setMaxZoomLevel(maxZoomLevel: number): void {
    this.maxZoomLevel = maxZoomLevel;
  }

  setLatLngBounds(bounds: LatLngBounds): void {
    this.latLngBounds = bounds;
  }

  setTrafficEnabled(enabled: boolean): void {
    this.trafficEnabled = enabled;
  }

  setTouchPoiEnabled(enabled: boolean): void {
    this.touchPoiEnabled = enabled;
  }

  setBuildingsEnabled(enabled: boolean): void {
    this.buildingsEnabled = enabled;
  }

  setLabelsEnabled(enabled: boolean): void {
    this.labelsEnabled = enabled;
  }

  setCompassEnabled(enabled: boolean): void {
    this.options.compassEnabled(enabled);
  }

  setScaleEnabled(enabled: boolean): void {
    this.options.scaleControlsEnabled(enabled);
  }

  setZoomGesturesEnabled(enabled: boolean): void {
    this.options.zoomGesturesEnabled(enabled);
  }

  setScrollGesturesEnabled(enabled: boolean): void {
    this.options.scrollGesturesEnabled(enabled);
  }

  setRotateGesturesEnabled(enabled: boolean): void {
    this.options.rotateGesturesEnabled(enabled);
  }

  setTiltGesturesEnabled(enabled: boolean): void {
    this.options.tiltGesturesEnabled(enabled);
  }

  setInitialMarkers(markers: object[]): void {
    this.initialMarkers = markers;
  }

  setInitialPolylines(polylines: object[]): void {
    this.initialPolylines = polylines;
  }

  setInitialPolygons(polygons: object[]): void {
    this.initialPolygons = polygons;
  }
}

