import { Any, BinaryMessenger, MessageCodec, PlatformView, PlatformViewFactory } from "@ohos/flutter_ohos";
import { common } from "@kit.AbilityKit";
import { LogUtil } from "./utils/LogUtil";
import { AMapOptionsBuilder } from "./AMapOptionsBuilder";
import { CommonUtils } from "./utils/CommonUtils";
import { ConvertUtil } from "./utils/ConvertUtil";
import { Const } from "./utils/Const";
import { CameraPosition } from "@amap/amap_lbs_map3d";
import { display } from "@kit.ArkUI";

/**
 * MapViewFactory 地图平台视图工厂类，实现PlatformViewFactory接口。
 * 负责创建MapPlatformView实例，解析Flutter传递的参数，初始化地图参数。
 */
export class MapViewFactory extends PlatformViewFactory {
  private messenger: BinaryMessenger;

  /**
   * 构造函数
   * @param messenger Flutter消息通道
   * @param createArgsCodes 参数编解码器
   */
  constructor(messenger: BinaryMessenger, createArgsCodes: MessageCodec<Object>) {
    super(createArgsCodes);
    this.messenger = messenger;
  }

  /**
   * 创建地图平台视图
   * @param context 上下文
   * @param viewId 视图ID
   * @param args Flutter传递的参数
   * @returns PlatformView
   */
  public create(context: common.Context, viewId: number, args: Any): PlatformView {
    // 使用强制日志确保能看到调用信息
    LogUtil.d("MapViewFactory", `create开始，viewId: ${viewId}`);
    try {
      LogUtil.d("MapViewFactory", `接收到的参数: ${JSON.stringify(args)}`);
    } catch (e) {
      LogUtil.d("MapViewFactory", `接收到的参数(无法序列化): ${String(args)}`);
    }

    // 构建地图参数Builder
    LogUtil.i("MapViewFactory", `创建AMapOptionsBuilder`);
    const builder: AMapOptionsBuilder = new AMapOptionsBuilder();
    let params: Map<String, Object> = args as Map<String, Object>;
    LogUtil.i("MapViewFactory", `参数解析完成，开始处理各项配置`);

    // 设置屏幕密度
    ConvertUtil.density = display.getDefaultDisplaySync().densityPixels;
    LogUtil.i("MapViewFactory", `屏幕密度设置: ${ConvertUtil.density}`);

    // 检查并设置 API Key（必须在其他初始化之前）
    if (params.has("apiKey")) {
      LogUtil.i("MapViewFactory", `检查并设置 API Key`);
      try {
        const apiKey: Object = CommonUtils.argumentParse("apiKey", args);
        LogUtil.i("MapViewFactory", `解析到的 apiKey: ${JSON.stringify(apiKey)}`);
        ConvertUtil.checkApiKey(apiKey);
        LogUtil.i("MapViewFactory", `API Key 设置完成`);
      } catch (error) {
        LogUtil.e("MapViewFactory", "设置API Key时出错", error instanceof Error ? error : new Error(String(error)));
      }
    } else {
      LogUtil.w("MapViewFactory", `警告：未提供 API Key，地图可能无法正常显示`);
    }

    // 设置隐私声明（必须在创建地图之前设置，否则会抛出异常）
    // 优先使用参数中的隐私声明，如果没有则使用全局保存的状态
    if (params.has('privacyStatement')) {
      LogUtil.i("MapViewFactory", `设置隐私声明（从参数中获取）`);
      ConvertUtil.setPrivacyStatement(context, CommonUtils.argumentParse('privacyStatement', args));
    } else {
      // 使用全局保存的隐私权政策状态
      const privacyStatement = new Map<string, Object>();
      privacyStatement.set('hasContains', Const.getPrivacyHasContains());
      privacyStatement.set('hasShow', Const.getPrivacyHasShow());
      privacyStatement.set('hasAgree', Const.getPrivacyHasAgree());
      LogUtil.i("MapViewFactory", `未提供隐私声明参数，使用全局保存的状态: hasContains=${Const.getPrivacyHasContains()}, hasShow=${Const.getPrivacyHasShow()}, hasAgree=${Const.getPrivacyHasAgree()}`);
      ConvertUtil.setPrivacyStatement(context, privacyStatement);
    }

    // 解析地图options参数
    let options: Any = CommonUtils.argumentParse('options', args);
    if (options != undefined) {
      LogUtil.i("MapViewFactory", `解析地图options参数`);
      // 初始化信息保存在Builder里面
      ConvertUtil.interpretAMapOptions(options, builder);
      LogUtil.i("MapViewFactory", `地图options参数解析完成`);
    } else {
      LogUtil.i("MapViewFactory", `未提供地图options参数`);
    }

    // 设置初始相机位置
    if (params.has('initialCameraPosition')) {
      LogUtil.i("MapViewFactory", `设置初始相机位置`);
      let cameraPosition: CameraPosition =
        ConvertUtil.toCameraPosition(CommonUtils.argumentParse('initialCameraPosition', args));
      builder.setCamera(cameraPosition);
      LogUtil.i("MapViewFactory", `初始相机位置设置完成`);
    } else {
      LogUtil.i("MapViewFactory", `未提供初始相机位置`);
    }

    // 设置初始marker
    if (params.has("markersToAdd")) {
      LogUtil.i("MapViewFactory", `设置初始markers`);
      builder.setInitialMarkers(CommonUtils.argumentParse('markersToAdd', args) as object[]);
    }

    // 设置初始polyline
    if (params.has("polylinesToAdd")) {
      LogUtil.i("MapViewFactory", `设置初始polylines`);
      builder.setInitialPolylines(CommonUtils.argumentParse('polylinesToAdd', args) as object[]);
    }

    // 设置初始polygon
    if (params.has("polygonsToAdd")) {
      LogUtil.i("MapViewFactory", `设置初始polygons`);
      builder.setInitialPolygons(CommonUtils.argumentParse('polygonsToAdd', args) as object[]);
    }

    // 设置调试模式
    if (params.has("debugMode")) {
      LogUtil.isDebugMode = ConvertUtil.toBoolean(CommonUtils.argumentParse('debugMode', args));
      LogUtil.i("MapViewFactory", `调试模式设置: ${LogUtil.isDebugMode}`);
    }

    // 构建并返回地图平台视图
    LogUtil.i("MapViewFactory", `开始构建MapPlatformView`);
    const platformView = builder.build(viewId, context, this.messenger);
    LogUtil.i("MapViewFactory", `MapPlatformView构建完成，viewId: ${viewId}`);
    return platformView;
  }
}

