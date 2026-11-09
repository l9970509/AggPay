/**
 * 支付渠道模型
 *
 * 每个渠道聚合了「付款码 / 扫一扫 / 收款码」三种能力的深链。
 * 深链由目标应用定义，可能随版本调整，因此统一收敛在这里，便于维护。
 */

export enum PayMode {
  /** 出示付款码（被扫） */
  CODE = 'code',
  /** 主动扫商户码 */
  SCAN = 'scan',
  /** 出示收款码（收钱） */
  COLLECT = 'collect'
}

export interface PayChannel {
  id: string;
  /** 展示名 */
  name: string;
  /** 卡片副标题 */
  slogan: string;
  /** 鸿蒙包名，深链失败时用显式 Want 兜底 */
  bundleName: string;
  /** 卡片渐变起始色 */
  brandStart: string;
  /** 卡片渐变结束色 */
  brandEnd: string;
  /** 品牌主色（用于图标、描边） */
  brand: string;
  /** 图标资源 */
  icon: Resource;
}

export const CHANNEL_WECHAT: PayChannel = {
  id: 'wechat',
  name: '微信',
  slogan: 'WeChat Pay',
  bundleName: 'com.tencent.wechat',
  brandStart: '#12D06C',
  brandEnd: '#039B4D',
  brand: '#07C160',
  icon: $r('app.media.ic_wechat')
};

export const CHANNEL_ALIPAY: PayChannel = {
  id: 'alipay',
  name: '支付宝',
  slogan: 'Alipay',
  bundleName: 'com.alipay.mobile.client',
  brandStart: '#3D8BFF',
  brandEnd: '#0A56CC',
  brand: '#1677FF',
  icon: $r('app.media.ic_alipay')
};

export const ALL_CHANNELS: PayChannel[] = [CHANNEL_WECHAT, CHANNEL_ALIPAY];

export function channelById(id: string): PayChannel {
  const hit: PayChannel | undefined = ALL_CHANNELS.find((c: PayChannel) => c.id === id);
  return hit === undefined ? CHANNEL_WECHAT : hit;
}

/**
 * 微信快捷方式使用的参数键。
 *
 * 微信在 module.json5 里把「我的二维码 / 扫一扫 / 收付款」注册为系统快捷方式，
 * 每个快捷方式只带一个参数 shortCutKey，取值即下面三个常量。桌面点快捷方式时，
 * BMS 把这组参数注入 Want 后启动 EntryAbility，微信读到参数就直接进对应页面。
 * 由于参数是普通 Want 参数而非签名校验，第三方显式拉起时同样生效（真机已验证）。
 */
export const WECHAT_SHORTCUT_PAY: string = 'shortCutPay';
export const WECHAT_SHORTCUT_SCAN: string = 'shortCutScan';

/**
 * 返回该「渠道 + 模式」直达目标页面所需的 Want 参数；无直达能力时返回空对象。
 *
 * 微信：快捷方式只带一个 shortCutKey。注意微信没有给「收款码」单独注册快捷方式，
 *       shortCutPay 落在「收付款」页，该页默认显示付款码，收款码需再点一次「二维码收款」。
 *
 * 支付宝：长按菜单（3D Touch）的快捷方式是「appId + source」参数注入 EntryAbility，
 *       比 alipays:// scheme 少一次链接解析、也不依赖 scheme 是否被注册；
 *       实测只传 appId 会落到首页，必须带 source=Harmony3DTouch 才直达目标页。
 */
export function launchParamsOf(channelId: string, mode: PayMode): Record<string, string> {
  const params: Record<string, string> = {};
  if (channelId === 'wechat') {
    switch (mode) {
      case PayMode.CODE:
      case PayMode.COLLECT:
        params['shortCutKey'] = WECHAT_SHORTCUT_PAY;
        return params;
      case PayMode.SCAN:
        params['shortCutKey'] = WECHAT_SHORTCUT_SCAN;
        return params;
      default:
        return params;
    }
  }
  if (channelId === 'alipay') {
    let appId: string = '';
    switch (mode) {
      case PayMode.CODE:
        appId = '20000056';
        break;
      case PayMode.SCAN:
        appId = '10000007';
        break;
      case PayMode.COLLECT:
        appId = '20000123';
        break;
      default:
        return params;
    }
    params['appId'] = appId;
    params['source'] = 'Harmony3DTouch';
    return params;
  }
  return params;
}

/**
 * 组装目标深链（兜底用）。
 *
 * 说明：两条渠道都能靠 Want 参数直达（见 launchParamsOf），此处 scheme 仅在参数路径失败时兜底。
 */
export function buildUri(channelId: string, mode: PayMode): string {
  if (channelId === 'alipay') {
    switch (mode) {
      case PayMode.SCAN:
        return 'alipays://platformapi/startapp?appId=10000007-20000067';
      case PayMode.COLLECT:
        return 'alipays://platformapi/startapp?appId=20000123';
      default:
        return 'alipays://platformapi/startapp?appId=20000056';
    }
  }
  switch (mode) {
    case PayMode.SCAN:
      return 'weixin://scanqrcode';
    case PayMode.COLLECT:
      return 'weixin://';
    default:
      return 'weixin://';
  }
}

/** 该渠道的付款码是否为「直达」能力（微信靠 shortCutKey 参数直达，支付宝靠 startapp 路由） */
export function isCodeDeepLink(channelId: string): boolean {
  return channelId === 'alipay' || channelId === 'wechat';
}
