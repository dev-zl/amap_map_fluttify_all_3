import {
  AMap,
  MapView,
  MapViewComponent,
  MapViewCreateCallback,
  MapViewManager
} from '@amap/amap_lbs_map3d';
import { Params } from '@ohos/flutter_ohos/src/main/ets/plugin/platform/PlatformView';
import { MapPlatformView } from './MapPlatformView';
import { Const } from './utils/Const';
import common from '@ohos.app.ability.common';
import { LogUtil } from './utils/LogUtil';

/**
 * AMapComponent 地图组件，负责地图的生命周期管理与回调处理
 */
@Component
export struct AMapComponent {
  @Prop mParams: Params;
  // 地图平台视图对象
  customView: MapPlatformView = this.mParams.platformView as MapPlatformView;
  // 地图视图名称
  private mapViewName: string = "";
  // 保存上下文，避免在异步回调中获取失败
  private context?: common.UIAbilityContext;

  /**
   * 组件即将显示时回调，注册地图创建回调
   */
  aboutToAppear(): void {
    try {
      const viewId = this.customView.getViewId();
      LogUtil.d('AMapComponent', `aboutToAppear开始，viewId: ${viewId}`);
      this.mapViewName = `harmony_map_${viewId}`;
      LogUtil.d('AMapComponent', `mapViewName设置完成: ${this.mapViewName}`);
      LogUtil.d('AMapComponent', `build方法将使用mapViewName: ${this.mapViewName} 创建地图组件`);
      // 保存上下文
      LogUtil.d('AMapComponent', `开始获取context`);
      this.context = getContext(this) as common.UIAbilityContext;
      if (!this.context) {
        LogUtil.e('AMapComponent', 'aboutToAppear', new Error('Failed to get context in aboutToAppear'));
      } else {
        LogUtil.d('AMapComponent', 'Context获取成功');
      }
      LogUtil.d('AMapComponent', `开始注册MapViewCreatedCallback`);
      MapViewManager.getInstance().registerMapViewCreatedCallback(this.mapViewCreateCallback);
      LogUtil.d('AMapComponent', 'MapViewCreatedCallback注册完成');
      LogUtil.d('AMapComponent', `aboutToAppear完成，viewId: ${viewId}`);
    } catch (error) {
      LogUtil.e('AMapComponent', 'aboutToAppear', error instanceof Error ? error : new Error(String(error)));
    }
  }

  /**
   * 组件即将消失时回调，注销地图回调并释放资源
   */
  aboutToDisappear(): void {
    try {
      const viewId = this.customView.getViewId();
      LogUtil.d('AMapComponent', `aboutToDisappear开始，viewId: ${viewId}`);
      let aMap: AMap | undefined = Const.getAMap(viewId);
      if (aMap) {
        LogUtil.d('AMapComponent', `关闭定位功能`);
        aMap.setMyLocationEnabled(false);
      } else {
        LogUtil.w('AMapComponent', `AMap对象不存在，viewId: ${viewId}`);
      }
      if (this.mapViewCreateCallback) {
        LogUtil.d('AMapComponent', `注销MapViewCreatedCallback`);
        MapViewManager.getInstance().unregisterMapViewCreatedCallback(this.mapViewCreateCallback);
      }
      let mapview = Const.getMapView(viewId);
      if (mapview) {
        LogUtil.d('AMapComponent', `销毁MapView`);
        mapview.onDestroy();
      } else {
        LogUtil.w('AMapComponent', `MapView对象不存在，viewId: ${viewId}`);
      }
      // 清理静态缓存
      LogUtil.d('AMapComponent', `清理静态缓存`);
      Const.setMapView(undefined, viewId);
      Const.setAMap(undefined, viewId);
      Const.setMapLoaded(false, viewId);
      LogUtil.d('AMapComponent', `aboutToDisappear完成，viewId: ${viewId}`);
    } catch (error) {
      LogUtil.e('AMapComponent', 'aboutToDisappear', error instanceof Error ? error : new Error(String(error)));
    }
  }

  /**
   * 地图视图创建回调
   * @param mapview 地图视图对象
   * @param mapViewName 地图视图名称
   */
  public mapViewCreateCallback: MapViewCreateCallback = (mapview?: MapView, mapViewName?: string) => {
    try {
      LogUtil.d('AMapComponent', `mapViewCreateCallback被调用，mapview: ${mapview ? '存在' : 'null'}, mapViewName: ${mapViewName}`);
      if (!mapview) {
        LogUtil.w('AMapComponent', `mapViewCreateCallback: mapview为空，直接返回`);
        return;
      }
      if (mapViewName !== this.mapViewName) {
        LogUtil.w('AMapComponent', `mapViewName不匹配，期望: ${this.mapViewName}, 实际: ${mapViewName}`);
        return;
      }
      const viewId = this.customView.getViewId();
      LogUtil.d('AMapComponent', `mapViewCreateCallback开始处理，viewId: ${viewId}, mapViewName: ${mapViewName}`);
      
      // 设置静态缓存
      LogUtil.d('AMapComponent', `设置MapView到静态缓存`);
      Const.setMapView(mapview, viewId);
      LogUtil.d('AMapComponent', `调用mapview.onCreate()`);
      mapview.onCreate();
      LogUtil.d('AMapComponent', `mapview.onCreate()完成，开始异步获取地图对象`);
      
      // 异步获取地图对象
      mapview.getMapAsync((map) => {
        try {
          LogUtil.d('AMapComponent', `getMapAsync回调执行，开始设置AMap`);
          Const.setAMap(map, viewId);
          Const.setMapLoaded(true, viewId);
          LogUtil.d('AMapComponent', `AMap设置完成，viewId: ${viewId}, mapViewName: ${mapViewName}`);
          let mapReadyResult = Const.getMapReadyResult(viewId);
          if (mapReadyResult != undefined) {
            LogUtil.d('AMapComponent', `调用mapReadyResult.success()`);
            mapReadyResult.success(null);
            Const.setMapReadyResult(undefined, viewId);
          } else {
            LogUtil.d('AMapComponent', `mapReadyResult不存在，跳过`);
          }
          // 触发地图初始化完成事件
          if (this.context) {
            try {
              const eventName = `onMapFinished_${viewId}`;
              LogUtil.d('AMapComponent', `准备发送事件: ${eventName}`);
              this.context.eventHub.emit(eventName);
              LogUtil.d('AMapComponent', `事件发送成功: ${eventName}`);
            } catch (e) {
              LogUtil.e('AMapComponent', 'mapViewCreateCallback', e instanceof Error ? e : new Error(String(e)));
            }
          } else {
            LogUtil.e('AMapComponent', 'mapViewCreateCallback', new Error('Context is null, cannot emit onMapFinished event'));
          }
          LogUtil.d('AMapComponent', `getMapAsync回调执行完成`);
        } catch (error) {
          LogUtil.e('AMapComponent', 'getMapAsync回调', error instanceof Error ? error : new Error(String(error)));
        }
      });
      LogUtil.d('AMapComponent', `mapViewCreateCallback处理完成`);
    } catch (error) {
      LogUtil.e('AMapComponent', 'mapViewCreateCallback', error instanceof Error ? error : new Error(String(error)));
    }
  };

  /**
   * 构建地图组件视图
   */
  build() {
    Stack() {
      MapViewComponent({ mapViewName: this.mapViewName })
        .zIndex(0)
    }
    .width('100%')
    .height('100%');
  }
}

/**
 * 地图组件Builder方法
 * @param params 参数
 */
@Builder
export function AMapBuilder(params: Params) {
  AMapComponent({ mParams: params });
}

