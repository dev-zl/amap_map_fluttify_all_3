import { LatLng } from '@amap/amap_lbs_map3d';

/**
 * Constants 常量工具类
 */
export class Constants {
  /**
   * ARGB 数值转十六进制
   */
  public static argbToHex(argbNumber: number): number {
    // 提取各分量
    const alpha = (argbNumber >>> 24) & 0xFF;
    const red = (argbNumber >>> 16) & 0xFF;
    const green = (argbNumber >>> 8) & 0xFF;
    const blue = argbNumber & 0xFF;

    // 拼接为十六进制字符串
    const hexString = `#${alpha.toString(16).padStart(2, '0')}${red.toString(16).padStart(2, '0')}${green.toString(16).padStart(2, '0')}${blue.toString(16).padStart(2, '0')}`;
    // 将十六进制字符串转换为数值类型
    return parseInt(hexString.replace('#', ''), 16);
  }
}

