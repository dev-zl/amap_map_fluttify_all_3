import { AMap, Marker, MarkerOptions } from "@amap/amap_lbs_map3d";
import { Any, MethodCall, MethodChannel, MethodResult } from "@ohos/flutter_ohos";
import { CommonUtils } from "../../utils/CommonUtils";
import { ConvertUtil } from "../../utils/ConvertUtil";
import { MarkerController } from "./MarkerController";
import { MarkerOptionsBuilder } from "./MarkerOptionsBuilder";
import { MarkerUtil } from "./MarkerUtil";
import { AbstractOverlayController } from "../AbstractOverlayController";
import { MyMethodCallHandler } from "../../MyMethodCallHandler";
import { Const } from "../../utils/Const";

/**
 * MarkersController Marker控制器
 */
export class MarkersController
  extends AbstractOverlayController<MarkerController> implements MyMethodCallHandler {

  private viewId: number;

  constructor(methodChannel: MethodChannel, viewId: number) {
    super(methodChannel);
    this.viewId = viewId;
  }

  doMethodCall(call: MethodCall, result: MethodResult): void {
    const method: string = call.method;
    switch (method) {
      case Const.METHOD_MARKER_UPDATE:
        this.invokeMarkerOptions(call, result);
        break;
    }
  }

  getRegisterMethodIdArray(): string[] {
    return Const.METHOD_ID_LIST_FOR_MARKER;
  }

  public invokeMarkerOptions(methodCall: MethodCall, result: MethodResult): void {
    let args: Any = methodCall.args;

    let markersToAdd: Any = CommonUtils.argumentParse('markersToAdd', args);
    if (markersToAdd) {
      this.addByList(markersToAdd as object[]);
    }

    let markersToChange: Any = CommonUtils.argumentParse('markersToChange', args);
    if (markersToChange) {
      this.updateByList(markersToChange as object[]);
    }

    let markerIdsToRemove: Any = CommonUtils.argumentParse('markersToRemove', args);
    if (markerIdsToRemove) {
      this.removeByIdList(markerIdsToRemove as object[]);
    }

    result.success(null);
  }

  public addByList(markersToAdd: object[]): void {
    if (markersToAdd) {
      markersToAdd.forEach((value) => {
        this.add(value);
      });
    }
  }

  private async add(markerObj: object): Promise<void> {
    let builder: MarkerOptionsBuilder = new MarkerOptionsBuilder();
    let dartMarkerId: string | undefined = await MarkerUtil.interpretMarkerOptions(markerObj, builder);
    if (dartMarkerId != undefined) {
      let markerOptions: MarkerOptions = builder.build();
      let aMap = Const.getAMap(this.viewId);
      const marker = aMap?.addMarker(markerOptions);
      let clickable: Any = CommonUtils.argumentParse('clickable', markerObj);
      if (clickable != undefined) {
        marker?.setClickable(ConvertUtil.toBoolean(clickable));
      }
      let markerController = new MarkerController(marker);
      this.controllerMapByDartId.set(dartMarkerId, markerController);
    }
  }

  private updateByList(markersToChange: object[]): void {
    if (markersToChange != undefined) {
      for (let index = 0; index < markersToChange.length; index++) {
        const element = markersToChange[index];
        this.update(element);
      }
    }
  }

  private async update(markerToChange: object): Promise<void> {
    let dartMarkerId: string = CommonUtils.argumentParse('id', markerToChange);
    if (dartMarkerId && this.controllerMapByDartId.has(dartMarkerId)) {
      let markerController = this.controllerMapByDartId.get(dartMarkerId);
      if (markerController) {
        await MarkerUtil.interpretMarkerOptions(markerToChange, markerController);
      }
    }
  }

  private removeByIdList(markerIdsToRemove: object[]): void {
    if (markerIdsToRemove == undefined) {
      return;
    }

    for (let index = 0; index < markerIdsToRemove.length; index++) {
      const rawMarkerId = markerIdsToRemove[index];
      if (rawMarkerId == undefined) {
        continue;
      }
      const dartMarkerId: string = String(rawMarkerId);
      if (this.controllerMapByDartId.has(dartMarkerId)) {
        const markerController = this.controllerMapByDartId.get(dartMarkerId);
        markerController?.remove();
        this.controllerMapByDartId.delete(dartMarkerId);
      }
    }
  }
}

