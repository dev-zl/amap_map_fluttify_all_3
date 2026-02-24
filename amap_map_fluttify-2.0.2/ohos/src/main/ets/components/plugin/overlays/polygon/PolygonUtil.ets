import { LatLng } from "@amap/amap_lbs_map3d";
import { Any } from "@ohos/flutter_ohos";
import { ConvertUtil } from "../../utils/ConvertUtil";
import { PolygonOptionsSink } from "./PolygonOptionsSink";

/**
 * PolygonUtil Polygon工具类
 */
export class PolygonUtil {
  static interpretOptions(obj: Any, sink: PolygonOptionsSink): string | undefined {
    const map: Map<string, Any> = obj as Map<string, Any>;

    // 设置点集合
    const points: Any = map.get('points');
    if (points !== undefined) {
      let pts = ConvertUtil.toPoints(points);
      let array: LatLng[] = [];
      pts.forEach((lat) => {
        array.push(lat);
      });
      sink.setPoints(array);
    }

    // 设置边框颜色
    const strokeColor: Any = map.get('strokeColor');
    if (strokeColor !== undefined) {
      sink.setStrokeColor(ConvertUtil.toNumber(strokeColor));
    }

    // 设置填充颜色
    const fillColor: Any = map.get('fillColor');
    if (fillColor !== undefined) {
      sink.setFillColor(ConvertUtil.toNumber(fillColor));
    }

    // 设置边框宽度
    const strokeWidth: Any = map.get('strokeWidth');
    if (strokeWidth !== undefined) {
      sink.setStrokeWidth(ConvertUtil.toFloatPixels(strokeWidth));
    }

    // 设置Z轴指数
    const zIndex: Any = map.get('zIndex');
    if (zIndex !== undefined) {
      sink.setZIndex(ConvertUtil.toFloat(zIndex));
    }

    // 设置可见性
    const visible: Any = map.get('visible');
    if (visible !== undefined) {
      sink.setVisible(ConvertUtil.toBoolean(visible));
    }

    let polygonId: string | undefined = map.get('id') as string;
    if (polygonId) {
      return polygonId;
    }

    return undefined;
  }
}

