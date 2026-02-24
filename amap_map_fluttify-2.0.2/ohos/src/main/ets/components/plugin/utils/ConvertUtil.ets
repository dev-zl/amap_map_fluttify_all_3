import {
  AMapOptions,
  CameraPosition,
  CameraUpdate,
  CameraUpdateFactory,
  LatLng,
  LatLngBounds,
  MapsInitializer,
  MapType,
  Point,
  Poi,
  CustomMapStyleOptions,
  MyLocationStyle
} from '@amap/amap_lbs_map3d';
import { AMapLocationManagerImpl } from '@amap/amap_lbs_location';
import { AMapPrivacyAgreeStatus, AMapPrivacyInfoStatus, AMapPrivacyShowStatus } from '@amap/amap_lbs_common';
import { Any, FlutterInjector } from '@ohos/flutter_ohos';
import { display } from '@kit.ArkUI';
import { image } from '@kit.ImageKit';
import { geoLocationManager } from '@kit.LocationKit';
import { LogUtil } from './LogUtil';
import { AMapOptionsSink } from '../core/AMapOptionsSink';
import AmapMapFluttifyPlugin from '../AmapMapFluttifyPlugin';
import { BitmapDescriptor, BitmapDescriptorFactory } from '@amap/amap_lbs_map3d';
import { ArrayList } from '@kit.ArkTS';
import { Context } from '@kit.AbilityKit';
import { Const } from './Const';

/**
 * ConvertUtil 数据转换工具类
 * 负责Flutter和HarmonyOS之间的数据格式转换
 */
export class ConvertUtil {
  static CLASS_NAME: string = 'ConvertUtil';
  static density: number = 1;
  static apiKey: string = "";

  /**
   * 设置隐私声明
   * 必须在初始化地图之前调用,否则会抛出 AMapPrivacyShowUnknow 错误
   */
  static setPrivacyStatement(context: Context, object: Any): void {
    try {
      LogUtil.d("ConvertUtil", `setPrivacyStatement 开始`);
      if (object === null || object === undefined) {
        LogUtil.w("ConvertUtil", `隐私声明参数为空,使用默认值`);
        // 即使参数为空,也要设置默认值,避免 SDK 抛出异常
        object = new Map();
        (object as Map<String, Object>).set('hasContains', true);
        (object as Map<String, Object>).set('hasShow', true);
        (object as Map<String, Object>).set('hasAgree', true);
      }
      const map: Map<String, Object> = object as Map<String, Object>;
      let hasContains: boolean = true; // 默认值设为 true
      let hasShow: boolean = true; // 默认值设为 true
      let hasAgree: boolean = true; // 默认值设为 true

      if (map.has('hasContains')) {
        hasContains = ConvertUtil.toBoolean(map.get("hasContains")!);
      }
      if (map.has('hasShow')) {
        hasShow = ConvertUtil.toBoolean(map.get('hasShow')!);
      }
      if (map.has('hasAgree')) {
        hasAgree = ConvertUtil.toBoolean(map.get('hasAgree')!);
      }

      LogUtil.d("ConvertUtil", `隐私声明参数: hasContains=${hasContains}, hasShow=${hasShow}, hasAgree=${hasAgree}`);

      // 保存隐私政策状态到全局常量
      Const.setPrivacyHasContains(hasContains);
      Const.setPrivacyHasShow(hasShow);
      Const.setPrivacyHasAgree(hasAgree);

      LogUtil.d("ConvertUtil", `隐私政策状态已保存到全局常量`);

      // 调用高德 SDK 的隐私政策 API
      try {
        LogUtil.i("ConvertUtil", `开始调用高德SDK隐私政策API`);

        // 1. 设置隐私权政策展示状态
        const privacyShowStatus: AMapPrivacyShowStatus = hasShow ? AMapPrivacyShowStatus.DidShow : AMapPrivacyShowStatus.NotShow;
        const privacyInfoStatus: AMapPrivacyInfoStatus = hasContains ? AMapPrivacyInfoStatus.DidContain : AMapPrivacyInfoStatus.NotContain;

        LogUtil.i("ConvertUtil", `调用 AMapLocationManagerImpl.updatePrivacyShow(${privacyShowStatus}, ${privacyInfoStatus}, context)`);
        AMapLocationManagerImpl.updatePrivacyShow(privacyShowStatus, privacyInfoStatus, context);
        LogUtil.i("ConvertUtil", `AMapLocationManagerImpl.updatePrivacyShow 调用成功`);

        // 2. 设置隐私权政策同意状态
        const privacyAgreeStatus: AMapPrivacyAgreeStatus = hasAgree ? AMapPrivacyAgreeStatus.DidAgree : AMapPrivacyAgreeStatus.NotAgree;

        LogUtil.i("ConvertUtil", `调用 AMapLocationManagerImpl.updatePrivacyAgree(${privacyAgreeStatus}, context)`);
        AMapLocationManagerImpl.updatePrivacyAgree(privacyAgreeStatus, context);
        LogUtil.i("ConvertUtil", `AMapLocationManagerImpl.updatePrivacyAgree 调用成功`);

        LogUtil.i("ConvertUtil", `高德SDK隐私政策API调用完成`);
      } catch (sdkError) {
        LogUtil.e("ConvertUtil", `调用高德SDK隐私政策API失败`, sdkError instanceof Error ? sdkError : new Error(String(sdkError)));
        // 即使SDK调用失败,也继续执行,因为状态已保存到全局常量
      }

      LogUtil.i("ConvertUtil", `隐私声明设置完成`);
    } catch (error) {
      LogUtil.e("ConvertUtil", "setPrivacyStatement", error instanceof Error ? error : new Error(String(error)));
      // 即使设置失败,也不应该阻止应用启动
      LogUtil.w("ConvertUtil", `隐私声明设置出错,但不影响继续执行`);
    }
  }

  /**
   * 设置屏幕密度
   */
  static initDensity(): void {
    ConvertUtil.density = display.getDefaultDisplaySync().densityPixels;
  }

  /**
   * 检查并设置API Key
   */
  static checkApiKey(object: Any): void {
    LogUtil.d("ConvertUtil", `checkApiKey 被调用,object: ${JSON.stringify(object)}`);

    if (object === null || object === undefined) {
      LogUtil.d("ConvertUtil", "checkApiKey: object 为空,直接返回");
      return;
    }

    try {
      const keyObject: Any = (object as Map<string, Any>).get("ohosKey");
      LogUtil.d("ConvertUtil", `checkApiKey: 从 object 中获取到的 ohosKey: ${keyObject}`);

      if (keyObject !== null && keyObject !== undefined) {
        const aKey: string = ConvertUtil.toString(keyObject);
        LogUtil.d("ConvertUtil", `checkApiKey: 转换后的 API Key: ${aKey}`);

        if (aKey && aKey.trim() !== '' && aKey !== ConvertUtil.apiKey) {
          LogUtil.d("ConvertUtil", `checkApiKey: 设置新的 API Key: ${aKey}`);
          ConvertUtil.apiKey = aKey;

          // 同时设置地图SDK和定位SDK的API Key
          try {
            MapsInitializer.setApiKey(aKey);
            LogUtil.d("ConvertUtil", "checkApiKey: MapsInitializer.setApiKey 调用成功");
          } catch (e) {
            LogUtil.e("ConvertUtil", "MapsInitializer.setApiKey 失败", e instanceof Error ? e : new Error(String(e)));
          }

          // 同时设置定位SDK的API Key
          try {
            AMapLocationManagerImpl.setApiKey(aKey);
            LogUtil.d("ConvertUtil", "checkApiKey: AMapLocationManagerImpl.setApiKey 调用成功");
          } catch (e) {
            LogUtil.e("ConvertUtil", "AMapLocationManagerImpl.setApiKey 失败", e instanceof Error ? e : new Error(String(e)));
          }
        } else {
          LogUtil.d("ConvertUtil", `checkApiKey: API Key 未改变或为空,跳过设置。当前 apiKey: ${ConvertUtil.apiKey}`);
        }
      } else {
        LogUtil.d("ConvertUtil", "checkApiKey: keyObject 为空");
      }
    } catch (error) {
      LogUtil.e("ConvertUtil", "checkApiKey", error instanceof Error ? error : new Error(String(error)));
    }
  }

  /**
   * 转换为本地地图类型
   */
  static toLocalMapType(dartMapIndex: number): number {
    const localTypeArray: number[] = [
      MapType.MAP_TYPE_NORMAL,
      MapType.MAP_TYPE_SATELLITE,
      MapType.MAP_TYPE_NIGHT,
      MapType.MAP_TYPE_NAVI,
      MapType.MAP_TYPE_BUS
    ];

    if (dartMapIndex < 0 || dartMapIndex >= localTypeArray.length) {
      return localTypeArray[0];
    }

    return localTypeArray[dartMapIndex];
  }

  /**
   * 转换为CameraUpdate
   */
  static toCameraUpdate(o: Any): CameraUpdate {
    let data: Any[] = ConvertUtil.toList(o);
    switch (ConvertUtil.toString(data[0])) {
      case 'newCameraPosition':
        return CameraUpdateFactory.newCameraPosition(ConvertUtil.toCameraPosition(data[1]));
      case 'newLatLng':
        return CameraUpdateFactory.newLatLng(ConvertUtil.toLatLng(data[1]));
      case "newLatLngBounds":
        return CameraUpdateFactory.newLatLngBounds(
          ConvertUtil.toLatLngBounds(data[1])!,
          ConvertUtil.toPixels(data[2])
        );
      case "newLatLngZoom":
        return CameraUpdateFactory.newLatLngZoom(
          ConvertUtil.toLatLng(data[1]),
          ConvertUtil.toFloat(data[2])
        );
      case "scrollBy":
        return CameraUpdateFactory.scrollBy(
          ConvertUtil.toFloatPixels(data[1]),
          ConvertUtil.toFloatPixels(data[2])
        );
      case "zoomBy":
        if (data.length === 2) {
          return CameraUpdateFactory.zoomBy(ConvertUtil.toFloat(data[1]));
        } else {
          return CameraUpdateFactory.zoomBy(
            ConvertUtil.toFloat(data[1]),
            ConvertUtil.toPoint(data[2])
          );
        }
      case "zoomIn":
        return CameraUpdateFactory.zoomIn();
      case "zoomOut":
        return CameraUpdateFactory.zoomOut();
      case "zoomTo":
        return CameraUpdateFactory.zoomTo(ConvertUtil.toFloat(data[1]));
      default:
        throw new Error("Cannot interpret " + o + " as CameraUpdate");
    }
  }

  /**
   * 转换为列表
   */
  static toList(o: Any): Any[] {
    if (Array.isArray(o)) {
      return o as Any[];
    }
    return [];
  }

  /**
   * 转换为字符串
   */
  static toString(o: Any): string {
    if (typeof o === 'string') {
      return o as string;
    }
    return String(o);
  }

  /**
   * 转换为整数
   */
  static toInt(o: Any): number {
    if (o === undefined || o === null) {
      return 0;
    }
    if (typeof o === 'number') {
      return Math.floor(o);
    }
    return 0;
  }

  /**
   * 转换为浮点数
   */
  static toFloat(o: Any): number {
    if (o === undefined || o === null) {
      return 0;
    }
    if (typeof o === 'number') {
      return o;
    }
    return 0;
  }

  /**
   * 转换为数字
   */
  static toNumber(o: Any): number {
    if (typeof o === 'number') {
      return o;
    }
    return 0;
  }

  /**
   * 转换为布尔值
   */
  static toBoolean(o: Any): boolean {
    if (typeof o === 'boolean') {
      return o;
    }
    return false;
  }

  /**
   * 转换为像素值
   */
  static toPixels(o: Any): number {
    if (typeof o === 'number') {
      return o;
    }
    return 0;
  }

  /**
   * 转换为LatLng
   */
  static toLatLng(o: Any): LatLng {
    const data: Any[] = Array.isArray(o) ? o : [];
    if (data.length < 2 || typeof data[0] !== 'number' || typeof data[1] !== 'number') {
      throw new Error('Invalid input format for LatLng conversion');
    }
    return new LatLng(data[0], data[1]);
  }

  /**
   * 转换为LatLngBounds
   */
  static toLatLngBounds(o: Any): LatLngBounds | undefined {
    if (o == null) {
      return undefined;
    }
    let data: Any[] = ConvertUtil.toList(o);
    if (data.length < 2) {
      throw new Error('Input list must contain at least two elements for LatLngBounds conversion');
    }
    return new LatLngBounds(ConvertUtil.toLatLng(data[0]), ConvertUtil.toLatLng(data[1]));
  }

  /**
   * 转换为CameraPosition
   */
  static toCameraPosition(o: Any): CameraPosition {
    let data: Map<Any, Any> = o as Map<Any, Any>;
    let builder = CameraPosition.builder();
    builder.bearing(ConvertUtil.toFloat(data.get("bearing")));
    builder.target(ConvertUtil.toLatLng(data.get("target")));
    builder.tilt(ConvertUtil.toFloat(data.get("tilt")));
    builder.zoom(ConvertUtil.toFloat(data.get("zoom")));
    return builder.build();
  }

  /**
   * 转换为Point
   */
  static toPoint(o: Any): Point {
    let data: Any[] = ConvertUtil.toList(o);
    return new Point(ConvertUtil.toPixels(data[0]), ConvertUtil.toPixels(data[1]));
  }

  /**
   * 转换为点列表
   */
  static toPoints(o: Any): ArrayList<LatLng> {
    let data: Any[] = ConvertUtil.toList(o);
    let array: ArrayList<LatLng> = new ArrayList();
    data.forEach((value: Any) => {
      const list: Any[] = ConvertUtil.toList(value);
      array.add(new LatLng(ConvertUtil.toFloat(list[0]), ConvertUtil.toFloat(list[1])));
    });
    return array;
  }

  /**
   * 转换为Int32Array
   */
  static toInt32List(o: Object): Int32Array {
    const array: Object[] = ConvertUtil.toList(o);
    return Int32Array.of(...array.map(v => ConvertUtil.toInt(v)));
  }

  /**
   * 转换为BitmapDescriptor列表
   */
  static async toBitmapDescriptorList(obj: Object): Promise<ArrayList<BitmapDescriptor> | undefined> {
    const rawList: Object[] = ConvertUtil.toList(obj);
    const bitmapList: ArrayList<BitmapDescriptor> = new ArrayList();
    for (let i = 0; i < rawList.length; i++) {
      const value = rawList[i];
      const bit = await ConvertUtil.toBitmapDescriptor(value);
      if (bit) {
        bitmapList.add(bit);
      }
    }
    return bitmapList;
  }

  /**
   * 转换为浮点像素值
   */
  static toFloatPixels(o: Any): number {
    return ConvertUtil.toFloat(o) * ConvertUtil.density;
  }

  /**
   * 将定位信息转换为Map
   */
  static location2Map(location: geoLocationManager.Location): Any | null {
    if (!location) {
      return null;
    }
    if (location.altitude > 90 || location.altitude < -90 || 
        location.longitude > 180 || location.longitude < -180) {
      return null;
    }
    let obj: Map<string, Any> = new Map();
    obj.set('latLng', [location.latitude, location.longitude]);
    obj.set('accuracy', location.accuracy);
    obj.set('altitude', location.altitude);
    obj.set('bearing', location.direction);
    obj.set('speed', location.speed);
    obj.set('time', location.timeStamp);
    return obj;
  }

  /**
   * 将CameraPosition转换为Map
   */
  static cameraPositionToMap(position: CameraPosition | undefined): Object | undefined {
    if (position == undefined) {
      return undefined;
    }
    let data = new Map<string, Object>();
    data.set('bearing', position.bearing);
    data.set('target', [position.target.latitude, position.target.longitude]);
    data.set('tilt', position.tilt);
    data.set('zoom', position.zoom);
    return data;
  }

  /**
   * 将Poi转换为Map
   */
  static poiToMap(poi: Poi): Object | null {
    if (!poi) {
      return null;
    }
    let obj: Map<string, Object> = new Map();
    const coordinate = poi.getCoordinate();
    if (coordinate) {
      obj.set('id', poi.getPoiId() ?? '');
      obj.set('name', poi.getName() ?? '');
      obj.set('latLng', [coordinate.latitude, coordinate.longitude]);
    }
    return obj;
  }

  /**
   * 解析AMapOptions并应用到sink
   */
  static async interpretAMapOptions(obj: Object, sink: AMapOptionsSink): Promise<void> {
    try {
      let data: Map<string, Object> = obj as Map<string, Object>;

      // 地图类型
      let mapType: Object | undefined = data.get('mapType');
      if (mapType !== undefined) {
        sink.setMapType(ConvertUtil.toLocalMapType(ConvertUtil.toFloat(mapType)));
      }

      // 建筑物显示
      const buildingsEnabled: Any = data.get('buildingsEnabled');
      if (buildingsEnabled !== undefined) {
        sink.setBuildingsEnabled(ConvertUtil.toBoolean(buildingsEnabled));
      }

      // 自定义地图样式
      const customStyleOptions: Any = data.get('customStyleOptions');
      if (customStyleOptions !== undefined) {
        sink.setCustomMapStyleOptions(ConvertUtil.toCustomMapStyleOptions(customStyleOptions));
      }

      // 定位样式
      const myLocationStyleData: Any = data.get('myLocationStyle');
      if (myLocationStyleData !== undefined) {
        sink.setMyLocationStyle(await ConvertUtil.toMyLocationStyle(myLocationStyleData, ConvertUtil.density));
      }

      // 屏幕锚点
      const screenAnchor: Any = data.get('screenAnchor');
      if (screenAnchor !== undefined) {
        const anchorData: Any[] = ConvertUtil.toList(screenAnchor);
        if (anchorData.length >= 2) {
          const x = ConvertUtil.toFloat(anchorData[0]);
          const y = ConvertUtil.toFloat(anchorData[1]);
          sink.setScreenAnchor(x, y);
        }
      }

      // 指南针
      const compassEnabled: Any = data.get('compassEnabled');
      if (compassEnabled !== undefined) {
        sink.setCompassEnabled(ConvertUtil.toBoolean(compassEnabled));
      }

      // 标签显示
      const labelsEnabled: Any = data.get('labelsEnabled');
      if (labelsEnabled !== undefined) {
        sink.setLabelsEnabled(ConvertUtil.toBoolean(labelsEnabled));
      }

      // 地理区域限制
      const limitBounds: Any = data.get('limitBounds');
      if (limitBounds !== undefined) {
        const targetData: Any[] = ConvertUtil.toList(limitBounds);
        const result = ConvertUtil.toLatLngBounds(targetData);
        if (result != undefined) {
          sink.setLatLngBounds(result);
        }
      }

      // 缩放范围
      const minMaxZoomPreference: Any = data.get('minMaxZoomPreference');
      if (minMaxZoomPreference !== undefined) {
        const targetData: Any[] = ConvertUtil.toList(minMaxZoomPreference);
        if (targetData.length >= 2) {
          sink.setMinZoomLevel(ConvertUtil.toFloatWrapperWithDefault(targetData[0], 3));
          sink.setMaxZoomLevel(ConvertUtil.toFloatWrapperWithDefault(targetData[1], 20));
        }
      }

      // 比例尺
      const scaleEnabled: Any = data.get('scaleEnabled');
      if (scaleEnabled !== undefined) {
        sink.setScaleEnabled(ConvertUtil.toBoolean(scaleEnabled));
      }

      // POI点击
      const touchPoiEnabled: Any = data.get('touchPoiEnabled');
      if (touchPoiEnabled !== undefined) {
        sink.setTouchPoiEnabled(ConvertUtil.toBoolean(touchPoiEnabled));
      }

      // 路况
      const trafficEnabled: Any = data.get('trafficEnabled');
      if (trafficEnabled !== undefined) {
        sink.setTrafficEnabled(ConvertUtil.toBoolean(trafficEnabled));
      }

      // 手势控制
      const rotateGesturesEnabled: Any = data.get('rotateGesturesEnabled');
      if (rotateGesturesEnabled !== undefined) {
        sink.setRotateGesturesEnabled(ConvertUtil.toBoolean(rotateGesturesEnabled));
      }

      const scrollGesturesEnabled: Any = data.get('scrollGesturesEnabled');
      if (scrollGesturesEnabled !== undefined) {
        sink.setScrollGesturesEnabled(ConvertUtil.toBoolean(scrollGesturesEnabled));
      }

      const tiltGesturesEnabled: Any = data.get('tiltGesturesEnabled');
      if (tiltGesturesEnabled !== undefined) {
        sink.setTiltGesturesEnabled(ConvertUtil.toBoolean(tiltGesturesEnabled));
      }

      const zoomGesturesEnabled: Any = data.get('zoomGesturesEnabled');
      if (zoomGesturesEnabled !== undefined) {
        sink.setZoomGesturesEnabled(ConvertUtil.toBoolean(zoomGesturesEnabled));
      }
    } catch (error) {
      LogUtil.e("ConvertUtil", "interpretAMapOptions", error as Error);
    }
  }

  /**
   * 转换为CustomMapStyleOptions
   */
  static toCustomMapStyleOptions(obj: Any): CustomMapStyleOptions {
    const map: Map<Any, Any> = obj as Map<Any, Any>;
    const customMapStyleOptions: CustomMapStyleOptions = new CustomMapStyleOptions();
    const enableData: Any = map.get('enabled');
    if (enableData !== undefined) {
      customMapStyleOptions.setEnable(ConvertUtil.toBoolean(enableData));
    }
    const styleData: Any = map.get('styleData');
    if (styleData !== undefined) {
      customMapStyleOptions.setStyleId(ConvertUtil.toString(styleData));
    }
    return customMapStyleOptions;
  }

  /**
   * 转换为MyLocationStyle
   */
  static async toMyLocationStyle(obj: Any, density: number): Promise<MyLocationStyle> {
    const map: Map<Any, Any> = obj as Map<Any, Any>;
    const myLocationStyle: MyLocationStyle = new MyLocationStyle();
    const enableData: Any = map.get('enabled');
    if (enableData != undefined) {
      myLocationStyle.showMyLocation(ConvertUtil.toBoolean(enableData));
    }
    myLocationStyle.myLocationType(MyLocationStyle.LOCATION_TYPE_FOLLOW_NO_CENTER);

    // TODO: 实现更多样式设置
    return myLocationStyle;
  }

  /**
   * 带默认值的浮点数转换
   */
  static toFloatWrapperWithDefault(obj: Any, defaultValue: number): number {
    return (obj == undefined) ? defaultValue : ConvertUtil.toFloat(obj);
  }

  /**
   * 转换为BitmapDescriptor
   */
  static async toBitmapDescriptor(obj: Any): Promise<BitmapDescriptor | undefined> {
    const data: Any[] = ConvertUtil.toList(obj);
    let flutterLoader = FlutterInjector.getInstance().getFlutterLoader();
    let rmg = AmapMapFluttifyPlugin.binding.getApplicationContext().resourceManager;
    
    switch (ConvertUtil.toString(data[0])) {
      case 'defaultMarker':
        if (data.length == 1) {
          return BitmapDescriptorFactory.defaultMarker();
        } else {
          return BitmapDescriptorFactory.defaultMarker(ConvertUtil.toNumber(data[1]));
        }

      case 'fromAsset':
        if (data.length == 2) {
          const s1 = ConvertUtil.toString(data[1]);
          const assetName: string = flutterLoader.getLookupKeyForAsset(s1);
          let rawfile = await rmg.getRawFileContent(assetName);
          let buffer = rawfile.buffer.slice(0);
          return await BitmapDescriptorFactory.fromPixelMap(image.createImageSource(buffer).createPixelMapSync());
        } else {
          const s1 = ConvertUtil.toString(data[1]);
          const s2 = ConvertUtil.toString(data[2]);
          const assetName: string = flutterLoader.getLookupKeyForAsset(s1, s2);
          let rawfile = await rmg.getRawFileContent(assetName);
          let buffer = rawfile.buffer.slice(0);
          return await BitmapDescriptorFactory.fromPixelMap(image.createImageSource(buffer).createPixelMapSync());
        }

      case 'fromAssetImage':
        if (data.length == 3) {
          const s1 = ConvertUtil.toString(data[1]);
          const assetName: string = flutterLoader.getLookupKeyForAsset(s1);
          let rawfile = await rmg.getRawFileContent(assetName);
          let buffer = rawfile.buffer.slice(0);
          let result: BitmapDescriptor | undefined;
          result = await BitmapDescriptorFactory.fromPixelMap(image.createImageSource(buffer).createPixelMapSync());
          return result;
        } else {
          throw new Error("'fromAssetImage' Expected exactly 3 arguments, got: " + data.length);
        }

      case 'fromBytes':
        return ConvertUtil.getBitmapFromBytes(data);

      default:
        throw new Error("Cannot interpret " + obj + " as BitmapDescriptor");
    }
  }

  /**
   * 从字节数组获取BitmapDescriptor
   */
  static getBitmapFromBytes(data: Any[]): BitmapDescriptor | undefined {
    if (data.length == 2) {
      try {
        return BitmapDescriptorFactory.fromPixelMapSync(ConvertUtil.toBitmap(data[1]));
      } catch (e) {
        throw new Error('Unable to interpret bytes as a valid image.' + e);
      }
    } else {
      throw new Error('fromBytes should have exactly one argument, the bytes. Got: ' + data.length);
    }
  }

  /**
   * 转换为PixelMap
   */
  static toBitmap(obj: Any): image.PixelMap {
    try {
      let byteArray: number[] | Uint8Array;
      if (obj instanceof Uint8Array) {
        byteArray = obj;
      } else if (Array.isArray(obj)) {
        byteArray = obj as number[];
      } else {
        throw new Error("无法将数据转换为字节数组");
      }

      if (!byteArray || byteArray.length === 0) {
        throw new Error("字节数组为空或长度为0");
      }

      const uint8Array = (byteArray instanceof Uint8Array) ?
        byteArray : new Uint8Array(byteArray);

      const imageSource = image.createImageSource(uint8Array.buffer);
      if (!imageSource) {
        throw new Error("无法创建图像源");
      }

      const options: image.DecodingOptions = {
        desiredSize: { width: 0, height: 0 },
        desiredPixelFormat: image.PixelMapFormat.RGBA_8888
      } as image.DecodingOptions;

      const pixelMap = imageSource.createPixelMapSync(options);
      if (!pixelMap) {
        throw new Error("无法解码字节数组为有效图像");
      }

      return pixelMap;
    } catch (error) {
      throw new Error(`无法将字节解码为有效图像: ${error}`);
    }
  }
}

