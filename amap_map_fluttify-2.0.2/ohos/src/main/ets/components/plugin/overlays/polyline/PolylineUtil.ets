import { Any } from "@ohos/flutter_ohos";
import { Constants } from "../../utils/Constants";
import { ConvertUtil } from "../../utils/ConvertUtil";
import { LogUtil } from "../../utils/LogUtil";
import { PolylineOptionsSink } from "./PolylineOptionsSink";
import { LineCapType, LineJoinType } from "@amap/amap_lbs_map3d";

/**
 * PolylineUtil Polyline工具类
 */
export class PolylineUtil {
  private static CLASS_NAME = 'PolylineUtil';
  private static DASH_LINE_TYPE = [-1, 0, 1];

  static async interpretOptions(obj: Any, sink: PolylineOptionsSink): Promise<string | undefined> {
    if (obj == undefined) {
      return undefined;
    }

    const data: Map<string | number, Any> = obj as Map<string | number, Any>;

    const points: Any = data.get('points');
    if (points != undefined) {
      sink.setPoints(ConvertUtil.toPoints(points));
    }

    const width: Any = data.get('width');
    if (width != undefined) {
      sink.setWidth(ConvertUtil.toFloatPixels(width));
    }

    const visible: Any = data.get('visible');
    if (visible != undefined) {
      sink.setVisible(ConvertUtil.toBoolean(visible));
    }

    const geodesic: Any = data.get('geodesic');
    if (geodesic != undefined) {
      sink.setGeodesic(ConvertUtil.toBoolean(geodesic));
    }

    const gradient: Any = data.get('gradient');
    if (gradient != undefined) {
      sink.setGradient(ConvertUtil.toBoolean(gradient));
    }

    const alpha: Any = data.get('alpha');
    if (alpha != undefined) {
      sink.setAlpha(ConvertUtil.toFloat(alpha));
    }

    const dashLineType: Any = data.get('dashLineType');
    if (dashLineType != undefined) {
      let rawType = ConvertUtil.toNumber(dashLineType);
      if (rawType > PolylineUtil.DASH_LINE_TYPE.length) {
        rawType = 0;
      }
      if (PolylineUtil.DASH_LINE_TYPE[rawType] === -1) {
        sink.setDashLine(false);
      } else {
        sink.setDashLine(true);
        sink.setDashLineType(PolylineUtil.DASH_LINE_TYPE[rawType]);
      }
    }

    const capType: Any = data.get('capType');
    if (capType != undefined) {
      sink.setLineCapType(ConvertUtil.toInt(capType) as LineCapType);
    }

    const joinType: Any = data.get('joinType');
    if (joinType != undefined) {
      sink.setLineJoinType(ConvertUtil.toInt(joinType) as LineJoinType);
    }

    const customTexture: Any = data.get('customTexture');
    if (customTexture != undefined) {
      const bit = await ConvertUtil.toBitmapDescriptor(customTexture);
      if (bit) {
        sink.setCustomTexture(bit);
      }
    }

    const customTextureList: Any = data.get('customTextureList');
    if (customTextureList != undefined) {
      const bit = await ConvertUtil.toBitmapDescriptorList(customTextureList);
      if (bit) {
        sink.setCustomTextureList(bit);
      }
    }

    const color: Any = data.get('color');
    if (color != undefined) {
      sink.setColor(ConvertUtil.toNumber(color));
    }

    const colorList: Any = data.get('colorList');
    if (colorList != undefined) {
      sink.setColorList(ConvertUtil.toInt32List(colorList));
    }

    const id: string = data.get('id') as string;
    if (id != undefined) {
      return id;
    }
    return undefined;
  }
}

