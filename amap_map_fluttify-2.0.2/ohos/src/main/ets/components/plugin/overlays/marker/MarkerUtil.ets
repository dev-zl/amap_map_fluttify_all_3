import { Any } from "@ohos/flutter_ohos";
import { ConvertUtil } from "../../utils/ConvertUtil";
import { MarkerOptionsSink } from "./MarkerOptionsSink";

/**
 * MarkerUtil Marker工具类
 */
export class MarkerUtil {
  static async interpretMarkerOptions(obj: Any, sink: MarkerOptionsSink): Promise<string | undefined> {
    if (obj == undefined) {
      return undefined;
    }

    const data: Map<string | number, Any> = obj as Map<string | number, Any>;

    const alpha: Any = data.get('alpha');
    if (alpha != undefined) {
      sink.setAlpha(ConvertUtil.toNumber(alpha));
    }

    const anchor: Any = data.get('anchor');
    if (anchor != undefined) {
      const anchorData: Any[] = ConvertUtil.toList(anchor);
      sink.setAnchor(ConvertUtil.toNumber(anchorData[0]), ConvertUtil.toNumber(anchorData[1]));
    }

    const draggable: Any = data.get('draggable');
    if (draggable != undefined) {
      sink.setDraggable(ConvertUtil.toBoolean(draggable));
    }

    const flat: Any = data.get('flat');
    if (flat != undefined) {
      sink.setFlat(ConvertUtil.toBoolean(flat));
    }

    const icon: Any = data.get('icon');
    if (icon != undefined) {
      const a = await ConvertUtil.toBitmapDescriptor(icon);
      if (a != undefined) {
        sink.setIcon(a);
      }
    }

    const infoWindow: Any = data.get('infoWindow');
    if (infoWindow != undefined) {
      MarkerUtil.interpretInfoWindowOptions(sink, infoWindow as Map<string, string>);
    }

    const position: Any = data.get('position');
    if (position != undefined) {
      sink.setPosition(ConvertUtil.toLatLng(position));
    }

    const rotation: Any = data.get('rotation');
    if (rotation != undefined) {
      sink.setRotation(Math.abs(360 - ConvertUtil.toNumber(rotation)));
    }

    const visible: Any = data.get('visible');
    if (visible != undefined) {
      sink.setVisible(ConvertUtil.toBoolean(visible));
    }

    const zIndex: Any = data.get('zIndex');
    if (zIndex != undefined) {
      sink.setZIndex(ConvertUtil.toNumber(zIndex));
    }

    const infoWindowEnable: Any = data.get("infoWindowEnable");
    if (infoWindowEnable != undefined) {
      sink.setInfoWindowEnable(ConvertUtil.toBoolean(infoWindowEnable));
    }

    const clickable: Any = data.get("clickable");
    if (clickable != undefined) {
      sink.setClickable(ConvertUtil.toBoolean(clickable));
    }

    const markerId: string = data.get("id");
    if (markerId != undefined) {
      return markerId;
    }

    return undefined;
  }

  static interpretInfoWindowOptions(sink: MarkerOptionsSink, infoWindow: Map<string, string>): void {
    let title: string = infoWindow.get('title') ?? '';
    let snippet: string = infoWindow.get('snippet') ?? '';
    if (title != undefined && title.length > 0) {
      sink.setTitle(title);
    }
    if (snippet != undefined && snippet.length > 0) {
      sink.setSnippet(snippet);
    }
  }
}

