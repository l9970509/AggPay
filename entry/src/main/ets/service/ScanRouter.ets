/**
 * 扫码结果识别：把一串原始文本判定成「该怎么处理」。
 * 聚合支付的价值在于扫完就能直接进对应的付款/收款流程，而不是丢一堆文本给用户。
 */

export enum ScanKind {
  WECHAT_PAY = 'wechat_pay',
  ALIPAY_PAY = 'alipay_pay',
  WECHAT_SCHEME = 'wechat_scheme',
  ALIPAY_SCHEME = 'alipay_scheme',
  WEB = 'web',
  PLAIN = 'plain'
}

export interface ScanVerdict {
  kind: ScanKind;
  /** 结果抬头 */
  title: string;
  /** 建议动作文案 */
  actionLabel: string;
  /** 可直接打开的链接；PLAIN 时为空 */
  uri: string;
  /** 结果原文（脱敏后用于展示） */
  display: string;
  /** 附注说明 */
  hint: string;
}

function head(raw: string): string {
  if (raw.length <= 96) {
    return raw;
  }
  return raw.substring(0, 96) + '…';
}

export function classify(raw: string): ScanVerdict {
  const text: string = raw.trim();
  const lower: string = text.toLowerCase();

  if (lower.startsWith('wxp://')) {
    return {
      kind: ScanKind.WECHAT_PAY,
      title: '微信收款码',
      actionLabel: '用微信打开',
      uri: 'weixin://',
      display: head(text),
      hint: '这是微信个人收款码，跳转微信后扫码即可付款'
    };
  }
  if (lower.startsWith('https://qr.alipay.com') || lower.startsWith('http://qr.alipay.com')) {
    return {
      kind: ScanKind.ALIPAY_PAY,
      title: '支付宝收款码',
      actionLabel: '用支付宝打开',
      uri: text.replace('http://', 'https://'),
      display: head(text),
      hint: '这是支付宝收款链接，可直接拉起支付宝付款'
    };
  }
  if (lower.startsWith('alipays://') || lower.startsWith('alipay://')) {
    return {
      kind: ScanKind.ALIPAY_SCHEME,
      title: '支付宝跳转链接',
      actionLabel: '用支付宝打开',
      uri: text,
      display: head(text),
      hint: '将直接调起支付宝处理该请求'
    };
  }
  if (lower.startsWith('weixin://')) {
    return {
      kind: ScanKind.WECHAT_SCHEME,
      title: '微信跳转链接',
      actionLabel: '用微信打开',
      uri: text,
      display: head(text),
      hint: '将直接调起微信处理该请求'
    };
  }
  if (lower.startsWith('http://') || lower.startsWith('https://')) {
    return {
      kind: ScanKind.WEB,
      title: '网页链接',
      actionLabel: '用浏览器打开',
      uri: text,
      display: head(text),
      hint: '链接来源未知，打开前请确认站点可信'
    };
  }
  return {
    kind: ScanKind.PLAIN,
    title: '文本内容',
    actionLabel: '复制文本',
    uri: '',
    display: head(text),
    hint: '未识别的码内容，可复制后手动处理'
  };
}
