import { AMap, MapView } from "@amap/amap_lbs_map3d";
import { MethodResult, Any } from "@ohos/flutter_ohos";

/**
 * Const 常量工具类
 * 用于管理地图对象、视图ID映射等
 */
export class Const {
  // 地图相关方法常量
  static readonly METHOD_MAP_WAIT_FOR_MAP: string = "map#waitForMap";
  static readonly METHOD_MAP_UPDATE: string = "map#update";
  static readonly METHOD_MAP_MOVE_CAMERA: string = "camera#move";
  static readonly METHOD_MAP_TAKE_SNAPSHOT: string = "map#takeSnapshot";
  static readonly METHOD_MAP_CLEAR_DISK: string = "map#clearDisk";

  // Marker 相关方法
  static readonly METHOD_MARKER_UPDATE: string = "markers#update";
  static readonly METHOD_ID_LIST_FOR_MARKER: string[] = [Const.METHOD_MARKER_UPDATE];

  // Polyline 相关方法
  static readonly METHOD_POLYLINE_UPDATE: string = "polylines#update";
  static readonly METHOD_ID_LIST_FOR_POLYLINE: string[] = [Const.METHOD_POLYLINE_UPDATE];

  // Polygon 相关方法
  static readonly METHOD_POLYGON_UPDATE: string = "polygons#update";
  static readonly METHOD_ID_LIST_FOR_POLYGON: string[] = [Const.METHOD_POLYGON_UPDATE];

  // 地图相关方法列表
  static readonly METHOD_ID_LIST_FOR_MAP: string[] = [
    Const.METHOD_MAP_WAIT_FOR_MAP,
    Const.METHOD_MAP_UPDATE,
    Const.METHOD_MAP_MOVE_CAMERA,
    Const.METHOD_MAP_TAKE_SNAPSHOT,
    Const.METHOD_MAP_CLEAR_DISK
  ];

  // 存储键名
  static readonly MAP_VIEW = 'mapview';
  static readonly A_MAP = 'aMap';
  static readonly MAP_LOADED = 'mapLoaded';
  static readonly MAP_READY_RESULT = 'mapReadyResult';
  static readonly LATITUDE = 'latitude';
  static readonly LONGITUDE = 'longitude';

  // 对象存储映射
  private static mapLoadedMap: Map<number, boolean> = new Map<number, boolean>();
  private static mapReadyResultMap: Map<number, MethodResult> = new Map<number, MethodResult>();
  private static aMapMap: Map<number, AMap> = new Map<number, AMap>();
  private static mapViewMap: Map<number, MapView> = new Map<number, MapView>();
  
  // HEAP 用于存储对象引用（类似 Android 的 HEAP）
  private static heap: Map<string, Any> = new Map<string, Any>();

  // 全局存储（用于 viewId 未指定时）
  private static globalMapView?: MapView;
  private static globalAMap?: AMap;
  private static globalMapLoaded: boolean = false;
  private static globalMapReadyResult?: MethodResult;
  private static globalLatitude: number = 39.909187;
  private static globalLongitude: number = 116.397451;
  
  // 隐私权政策状态（全局保存，用于创建地图时使用）
  private static privacyHasShow: boolean = true;
  private static privacyHasAgree: boolean = true;
  private static privacyHasContains: boolean = true;

  /**
   * 获取 MapView
   */
  static getMapView(viewId?: number): MapView | undefined {
    if (viewId === undefined) {
      return Const.globalMapView;
    }
    return Const.mapViewMap.get(viewId);
  }

  /**
   * 设置 MapView
   */
  static setMapView(value: MapView | undefined, viewId?: number): void {
    if (viewId === undefined) {
      Const.globalMapView = value;
    } else {
      if (value) {
        Const.mapViewMap.set(viewId, value);
      } else {
        Const.mapViewMap.delete(viewId);
      }
    }
  }

  /**
   * 获取 AMap
   */
  static getAMap(viewId?: number): AMap | undefined {
    if (viewId === undefined) {
      return Const.globalAMap;
    }
    return Const.aMapMap.get(viewId);
  }

  /**
   * 设置 AMap
   */
  static setAMap(value: AMap | undefined, viewId?: number): void {
    if (viewId === undefined) {
      Const.globalAMap = value;
    } else {
      if (value) {
        Const.aMapMap.set(viewId, value);
      } else {
        Const.aMapMap.delete(viewId);
      }
    }
  }

  /**
   * 获取地图加载状态
   */
  static getMapLoaded(viewId?: number): boolean {
    if (viewId === undefined) {
      return Const.globalMapLoaded;
    }
    return Const.mapLoadedMap.get(viewId) ?? false;
  }

  /**
   * 设置地图加载状态
   */
  static setMapLoaded(value: boolean, viewId?: number): void {
    if (viewId === undefined) {
      Const.globalMapLoaded = value;
    } else {
      Const.mapLoadedMap.set(viewId, value);
    }
  }

  /**
   * 获取地图就绪结果
   */
  static getMapReadyResult(viewId?: number): MethodResult | undefined {
    if (viewId === undefined) {
      return Const.globalMapReadyResult;
    }
    return Const.mapReadyResultMap.get(viewId);
  }

  /**
   * 设置地图就绪结果
   */
  static setMapReadyResult(value: MethodResult | undefined, viewId?: number): void {
    if (viewId === undefined) {
      Const.globalMapReadyResult = value;
    } else {
      if (value) {
        Const.mapReadyResultMap.set(viewId, value);
      } else {
        Const.mapReadyResultMap.delete(viewId);
      }
    }
  }

  /**
   * 获取纬度
   */
  static getLatitude(): number {
    return Const.globalLatitude;
  }

  /**
   * 设置纬度
   */
  static setLatitude(value: number): void {
    Const.globalLatitude = value;
  }

  /**
   * 获取经度
   */
  static getLongitude(): number {
    return Const.globalLongitude;
  }

  /**
   * 设置经度
   */
  static setLongitude(value: number): void {
    Const.globalLongitude = value;
  }

  /**
   * 存储对象到 HEAP
   */
  static put(key: string, value: Object): void {
    Const.heap.set(key, value);
  }

  /**
   * 从 HEAP 获取对象
   */
  static get(key: string): Object | undefined {
    return Const.heap.get(key);
  }

  /**
   * 从 HEAP 移除对象
   */
  static remove(key: string): void {
    Const.heap.delete(key);
  }

  /**
   * 获取隐私权政策展示状态
   */
  static getPrivacyHasShow(): boolean {
    return Const.privacyHasShow;
  }

  /**
   * 设置隐私权政策展示状态
   */
  static setPrivacyHasShow(value: boolean): void {
    Const.privacyHasShow = value;
  }

  /**
   * 获取隐私权政策同意状态
   */
  static getPrivacyHasAgree(): boolean {
    return Const.privacyHasAgree;
  }

  /**
   * 设置隐私权政策同意状态
   */
  static setPrivacyHasAgree(value: boolean): void {
    Const.privacyHasAgree = value;
  }

  /**
   * 获取隐私权政策包含状态
   */
  static getPrivacyHasContains(): boolean {
    return Const.privacyHasContains;
  }

  /**
   * 设置隐私权政策包含状态
   */
  static setPrivacyHasContains(value: boolean): void {
    Const.privacyHasContains = value;
  }
}

