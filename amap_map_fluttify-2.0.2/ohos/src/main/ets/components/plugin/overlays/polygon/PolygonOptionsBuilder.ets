import { LatLng, PolygonOptions } from "@amap/amap_lbs_map3d";
import { PolygonOptionsSink } from "./PolygonOptionsSink";
import { ArrayList } from "@kit.ArkTS";

/**
 * PolygonOptionsBuilder Polygon选项构建器
 */
export class PolygonOptionsBuilder implements PolygonOptionsSink {
  private options: PolygonOptions;

  constructor() {
    this.options = new PolygonOptions();
    this.options.setUsePolylineStroke(true);
  }

  build(): PolygonOptions {
    return this.options;
  }

  setPoints(points: LatLng[]): void {
    let array = new ArrayList<LatLng>();
    points.forEach((lat) => {
      array.add(lat);
    });
    this.options.setPoints(array);
  }

  setStrokeColor(color: number): void {
    this.options.setStrokeColor(color);
  }

  setFillColor(color: number): void {
    this.options.setFillColor(color);
  }

  setStrokeWidth(width: number): void {
    this.options.setStrokeWidth(width);
  }

  setZIndex(zIndex: number): void {
    this.options.setZIndex(zIndex);
  }

  setVisible(visible: boolean): void {
    this.options.setVisible(visible);
  }
}

