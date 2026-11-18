#!/usr/bin/env python3
"""umall 与 ebest 同款商品匹配脚本。规则全部来自 matching_rules.json。

用法: python3 match_products.py --umall-dir <umall json目录> --ebest <ebest json文件或目录> [--rules matching_rules.json] [--out 输出.csv] [--extended]
"""
import argparse, csv, glob, json, os, re, sys, time

BASE = os.path.dirname(os.path.abspath(__file__))
CJK = re.compile(r'[一-鿿]+')
NUM = r'(\d+(?:\.\d+)?)'
RANGE = r'\s*[-–—~～]\s*'


def has_term(text, term):
    if term.isascii():
        return re.search(r'(?<![a-z])' + re.escape(term) + r'(?![a-z])', text) is not None
    return term in text


ALIASES = {}
MIN_SHARED = 3


def norm(text):
    text = text or ''
    for a, b in ALIASES.items():
        text = text.replace(a, b)
    return re.sub(r'\s+', ' ', (text or '').lower().replace('-', ' ').replace('_', ' '))


class Rules:
    def __init__(self, path):
        with open(path, encoding='utf-8') as f:
            self.c = json.load(f)
        u = self.c['units']
        self.wmap, self.vmap = u['weight_g'], u['volume_ml']
        alt = '|'.join(sorted({*self.wmap, *self.vmap}, key=len, reverse=True))
        self.unit_re = alt
        self.count_re = '|'.join(u['count'])
        syn = []
        for key, words in self.c['keyword_synonyms'].items():
            for w in words:
                syn.append((w.lower(), key))
        self.syn = sorted(syn, key=lambda x: -len(x[0]))
        global MIN_SHARED
        MIN_SHARED = self.c.get('min_shared_tokens', 3)
        ALIASES.clear()
        ALIASES.update(self.c.get('text_aliases', {}))
        self.stop = sorted((w.lower() for w in self.c['stopwords']), key=len, reverse=True)

    # ---------- 类别 ----------
    def group_by_title(self, text):
        t = norm(text)
        best, best_score = None, 0
        weak = set(self.c['category_weak_words'])
        pe = self.c['produce_exclusion_markers']
        processed = any(m in t for m in pe['markers'])
        for g, words in self.c['category_title_keywords'].items():
            if processed and g in pe['groups']:
                continue
            s, tt = 0, t
            for w in sorted((w.lower() for w in words), key=len, reverse=True):
                if has_term(tt, w):
                    s += len(w) * (self.c['category_weak_weight'] if w in weak else 1)
                    tt = tt.replace(w, ' ' * len(w))   # 命中后遮蔽，避免短词重复计分
            if s > best_score:       # 同分取列表中靠前的类别
                best, best_score = g, s
        return best

    def group_by_slug(self, slug, cid):
        for g, d in self.c['category_groups'].items():
            if any(slug.startswith(s) for s in d.get('umall_slugs', [])) or str(cid) in d.get('umall_slug_ids', []):
                return g
        return None

    def group_by_ebest(self, name):
        for g, d in self.c['category_groups'].items():
            if name in d.get('ebest_categories', []):
                return g
        return None

    # ---------- 关键词 ----------
    def keys(self, text):
        t = norm(text)
        found = set()
        for w, key in self.syn:  # 长词优先，匹配后遮蔽，避免 洋葱 同时命中 葱
            if has_term(t, w):
                found.add(key)
                t = t.replace(w, ' ' * len(w)) if not w.isascii() else re.sub(r'(?<![a-z])' + re.escape(w) + r'(?![a-z])', ' ', t)
        return found

    def tokens(self, text):
        t = norm(text)
        t = re.sub(NUM + r'\s*(' + self.unit_re + r')(?![a-z])', ' ', t)
        for w in self.stop:
            t = t.replace(w, ' ')
        toks = set(re.findall(r'[a-z]{3,}', t))
        for run in CJK.findall(t):
            if len(run) == 1:
                continue
            toks.update(run[i:i + 2] for i in range(len(run) - 1))
        return toks

    def attrs(self, text):
        t = norm(text)
        return {g: {w for w in ws if w in t} for g, ws in self.c['attribute_groups'].items()}

    def same_group(self, a, b):
        if a == b:
            return True
        return any(a in g and b in g for g in self.c['compatible_groups'])

    # ---------- 产地 / 品种 / 品牌 ----------
    def _hits(self, text, table):
        t = norm(text)
        out = set()
        for k, words in table.items():
            if any(has_term(t, w.lower()) for w in words):
                out.add(k)
        return out

    def countries(self, text):
        return self._hits(text, self.c['countries'])

    def varieties(self, text):
        return self._hits(text, self.c['varieties'])

    def first_token(self, title):
        t = re.sub(r'【[^】]*】|\[[^\]]*\]|\([^)]*\)|（[^）]*）|[#】【\[\]*]', ' ', title).lower().replace('’', "'")
        words = [w for ws in list(self.c['countries'].values()) + list(self.c['varieties'].values()) for w in ws]
        for w in sorted(words, key=len, reverse=True):
            t = re.sub(r'(?<![a-z])' + re.escape(w.lower()) + r'(?![a-z])', ' ', t) if w.isascii() else t.replace(w, ' ')
        parts = t.split()
        return parts[0] if parts else ''

    def brand(self, title, cjk_brands):
        tok = self.first_token(title)
        m = re.match(r"[a-z][a-z&'.\-]*", tok)
        if m:
            b = m.group(0).strip('.-')
            generic = self.c['brand_rules']['generic_latin']
            if len(b) >= 2 and b not in generic and not any(b == w for w, _ in self.syn):
                return self.bnorm(norm(b))
            return None
        m = CJK.match(tok)
        if m and m.group(0) in cjk_brands:
            return m.group(0)
        for b in cjk_brands:
            if tok.startswith(b):
                return b
        return None

    @staticmethod
    def bnorm(s):
        return re.sub(r"[\s'’.\-]", '', s.lower())

    # ---------- 规格 ----------
    def spec(self, text):
        """返回 (维度, 基础数量, 件数)。维度: weight(g) / volume(ml) / count / None"""
        t = norm(text)
        size = dim = None
        # 形如 900g-1kg / 0.9-1kg / 约1kg
        m = re.search(NUM + r'\s*(' + self.unit_re + r')?' + RANGE + NUM + r'\s*(' + self.unit_re + r')(?![a-z])', t)
        if m:
            u2 = m.group(4)
            u1 = m.group(2) or u2
            lo = float(m.group(1)) * self.factor(u1)[1]
            hi = float(m.group(3)) * self.factor(u2)[1]
            dim, size = self.factor(u2)[0], (lo + hi) / 2
            end = m.end()
        else:
            m = re.search(NUM + r'\s*(' + self.unit_re + r')(?![a-z])', t)
            if m:
                dim, f = self.factor(m.group(2))
                size, end = float(m.group(1)) * f, m.end()
        if size:
            mult = re.match(r'\s*[*x×]\s*(\d+)', t[end:])
            if mult:
                size *= int(mult.group(1))
            return dim, size, None
        m = re.search(NUM + r'\s*(' + self.count_re + r')', t)
        if m:
            return 'count', float(m.group(1)), None
        return None, None, None

    def factor(self, unit):
        if unit in self.wmap:
            return 'weight', self.wmap[unit]
        return 'volume', self.vmap[unit]


def unit_price(price, dim, size):
    if dim == 'weight':
        return price / size * 1000, 'AUD/kg'
    if dim == 'volume':
        return price / size * 1000, 'AUD/L'
    if dim == 'count':
        return price / size, 'AUD/pc'
    return price, 'AUD/pc'


def promo_note(r, texts, tag_notes=()):
    """收集多买优惠 / 满减满赠等价格规则无法折算的促销说明（如 “5.99，三件8折”），只记录不参与比价。"""
    pn = r.c['promo_notes']
    notes = list(tag_notes)
    for t in texts:
        for pat in pn['patterns']:
            for m in re.finditer(pat, t or '', re.I):
                notes.append(m.group(0).strip())
    out = []
    for n in notes:
        if n and n not in out:
            out.append(n)
    return '；'.join(out)


def umall_promo(r, it):
    pn = r.c['promo_notes']
    now, tags = time.time(), []
    for pa in it.get('promotion_activity') or []:
        label = pn['umall_tag_types'].get(pa.get('tag_type'))
        if not label or not (int(pa.get('start_time') or 0) <= now <= int(pa.get('end_time') or 4e9)):
            continue
        tags.append(label if label == pa.get('promotion_tag') or not pa.get('promotion_tag') else f"{label}({pa['promotion_tag']})")
    return promo_note(r, [it['item_name'], ' '.join(it.get('tagList') or [])], tags)


def ebest_promo(r, it):
    pool = it.get('preferential_pool_info') or {}
    return promo_note(r, [it.get('title'), it.get('short_title'), pool.get('title') if isinstance(pool, dict) else ''])


def umall_price(r, it):
    """促销价/折扣价存在时取较低者（含限时促销，且仅在活动有效期内）。"""
    pr = r.c['price_rules']
    div = r.c['inputs']['umall_price_divisor']
    cands = [float(it[pr['umall_price_field']])]
    for f in pr['umall_promo_price_fields']:
        if it.get(f) not in (None, ''):
            cands.append(float(it[f]))
    now = time.time()
    for pa in it.get('promotion_activity') or []:
        if pa.get('tag_type') not in pr['umall_promo_tag_types'] or pa.get('activity_price') in (None, ''):
            continue
        if pr['umall_check_promo_window'] and not (int(pa.get('start_time') or 0) <= now <= int(pa.get('end_time') or 4e9)):
            continue
        cands.append(float(pa['activity_price']))
    cands = [c for c in cands if c > 0]
    return min(cands) / div if cands else 0.0


def ebest_price(r, it):
    pr = r.c['price_rules']
    cands = [it.get(pr['ebest_price_field'])] + [it.get(f) for f in pr['ebest_promo_price_fields']]
    cands = [float(c) for c in cands if c not in (None, '') and float(c) > 0]
    return min(cands) if cands else 0.0


def load_umall(r, umall_dir):
    cfg = r.c['inputs']
    items = {}
    for f in sorted(glob.glob(os.path.join(umall_dir, '*.json'))):
        if f.endswith('index.json'):
            continue
        d = json.load(open(f, encoding='utf-8'))
        slug = d.get('category', '')
        for it in d['items']:
            sid = it['item_id']
            if sid in items:
                continue
            text = f"{it['item_name']} {it.get('seo_en') or ''}"
            grp = r.group_by_title(it['item_name']) or r.group_by_slug(slug, d.get('category_id'))
            if umall_price(r, it) <= 0:
                continue
            items[sid] = dict(sku=sid, title=it['item_name'], text=text, keytext=it['item_name'], group=grp,
                              price=umall_price(r, it), promo=umall_promo(r, it))
    return list(items.values())


def load_ebest(r, ebest):
    cfg = r.c['inputs']
    if os.path.isdir(ebest):
        ebest = sorted(glob.glob(os.path.join(ebest, '*.json')))[-1]
    out = []
    for it in json.load(open(ebest, encoding='utf-8')):
        if cfg['ebest_only_on_sale'] and not it.get('on_sale'):
            continue
        grp = r.group_by_ebest(it.get('category_name')) or r.c['ebest_parent_groups'].get(str(it.get('parent_category_id')))
        tgrp = r.group_by_title(f"{it['title']} {it.get('short_title') or ''}")
        if tgrp in r.c['ebest_title_override_groups'] or (grp and it.get('category_name') == '冷冻蔬果' and tgrp):
            grp = tgrp
        if ebest_price(r, it) <= 0:
            continue
        grp = grp or tgrp
        text = f"{it['title']} {it.get('short_title') or ''}"
        out.append(dict(sku=it['id'], title=it['title'], text=text, keytext=text, group=grp, price=ebest_price(r, it),
                        promo=ebest_promo(r, it)))
    return out


def learn_cjk_brands(r, *datasets):
    br = r.c['brand_rules']
    cnt = {}
    for rows in datasets:
        for x in rows:
            m = CJK.match(r.first_token(x['title']))
            if m and len(m.group(0)) >= 2:
                cnt[m.group(0)] = cnt.get(m.group(0), 0) + 1
    auto = {w for w, n in cnt.items() if n >= br['min_cjk_brand_freq'] and not r.keys(w) and not any(s in w for s in r.stop)}
    return set(br['cjk_brands']) | auto


def brand_vocab(r, rows, cjk_brands):
    """品牌词：已知品牌 + 标题前几个词里反复出现的纯中文词。"""
    br = r.c['brand_rules']
    cnt = {}
    for rows_ in rows:
        for x in rows_:
            t = re.sub(r'【[^】]*】|\[[^\]]*\]', ' ', x['title'])
            for tok in t.split()[:br['brand_token_positions']]:
                m = CJK.fullmatch(tok)
                if m and 2 <= len(tok) <= 6:
                    cnt[tok] = cnt.get(tok, 0) + 1
    vocab = set(cjk_brands)
    vocab |= {w for w, n in cnt.items() if n >= br['min_cjk_brand_freq'] and not r.keys(w) and not any(s in w for s in r.stop)}
    return vocab


def strip_brand(text, brand, vocab):
    for w in sorted(vocab, key=len, reverse=True):
        text = text.replace(w, ' ')
    return text


def core_chars(r, x, vocab):
    """主标题的核心汉字集合：去掉括号备注、规格数字、停用词和品牌后剩下的字，用于对字序不同的标题做相似度比较。"""
    t = re.sub(r'【[^】]*】|\[[^\]]*\]|\([^)]*\)|（[^）]*）', ' ', x['title'])
    t = norm(t)
    t = re.sub(NUM + r'\s*(' + r.unit_re + r')(?![a-z])', ' ', t)
    for w in r.stop:
        t = t.replace(w, ' ')
    t = strip_brand(t, x['brand'], vocab)
    if x['brand']:
        t = t.replace(x['flat'][:0] + (x['brand'] or ''), ' ')
    return set(''.join(CJK.findall(t)))


COUNT_RE = re.compile(r'(\d+)\s*(?:pcs|pc|粒|只|个|枚|片|颗|入|条)(?![a-z])')


def pack_count(text):
    m = COUNT_RE.search(norm(text))
    return int(m.group(1)) if m else None


def prepare(r, rows, cjk_brands=(), vocab=()):
    for x in rows:
        x['country'] = r.countries(x['keytext'])
        x['variety'] = r.varieties(x['keytext'])
        x['brand'] = r.brand(x['title'], cjk_brands) if r.c['brand_rules']['enabled'] else None
        x['flat'] = Rules.bnorm(norm(x['text']))
        ft = r.first_token(x['title'])
        mm = CJK.fullmatch(ft) if ft else None
        x['wbrand'] = ft if mm and 2 <= len(ft) <= 5 and not r.keys(ft) and not any(ft == s or (len(s) >= 2 and ft.startswith(s)) for s in r.stop) else None
        x['keys'] = r.keys(x['keytext'])
        core = strip_brand(x['text'], x['brand'], vocab)
        first = r.first_token(x['title'])
        if x['brand'] and first.isascii():
            core = core.lower().replace(first, ' ')
        x['toks'] = r.tokens(core)
        x['toks_alt'] = r.tokens(strip_brand(x['title'], x['brand'], vocab))   # 仅主标题（不含短标题/英文链接词）
        x['chars'] = core_chars(r, x, vocab)
        x['count'] = pack_count(x['text'])
        x['attrs'] = r.attrs(x['keytext'])
        for g in r.c.get('title_only_attribute_groups', []):      # 这些属性只看主标题，避免短标题里的营销词干扰
            x['attrs'][g] = r.attrs(x['title'])[g]
        x['dim'], x['size'], _ = r.spec(x['text'])
    return rows


def sim(u, e):
    """标题核心词相似度：主标题与完整文本（含短标题、英文词）交叉比较，取最高。"""
    best = 0.0
    for a in (u['toks'], u['toks_alt']):
        for b in (e['toks'], e['toks_alt']):
            s = jac(a, b)
            if len(a & b) < min(MIN_SHARED, len(a), len(b)):
                s = min(s, 0.3)
            best = max(best, s)
    return best


def jac(a, b):
    return len(a & b) / len(a | b) if a and b else 0.0


CM_RE = re.compile(r'(\d+(?:\.\d+)?)\s*cm')
FLAVOR_RE = re.compile(r'([一-鿿]{1,6})(?:味|口味|风味|香型)')


def flavors(text):
    t = re.sub(r'【[^】]*】|\[[^\]]*\]', ' ', text)
    return {m.strip() for m in FLAVOR_RE.findall(t)}


def flavor_ok(r, u, e):
    """两边标题都写了 X味 时，口味必须一致（一方是另一方的结尾词算一致，如 水白桃 与 白桃）；
    一方带口味词（flavor_words）而另一方没有同一个词，也视为不同款。"""
    fu, fe = flavors(u['keytext']), flavors(e['keytext'])
    if fu and fe:
        for a in fu:
            if not any(a.endswith(b) or b.endswith(a) for b in fe):
                return False
    fw = r.c['flavor_words']
    for a, b in ((u['flat'], e['flat']), (e['flat'], u['flat'])):
        for w in fw:
            if w in a and w not in b:
                return False
    return True


def score(r, u, e):
    tol = r.c['price_tolerance']
    classified = bool(u['group'] and e['group'])
    sm = sim(u, e)
    sb = r.c['same_brand_spec']
    if u['brand'] and e['brand'] and (u['brand'] in e['flat'] or e['brand'] in u['flat']) and u['dim'] and u['dim'] == e['dim'] \
            and min(u['size'], e['size']) / max(u['size'], e['size']) >= sb['min_spec_ratio'] and u['chars'] and e['chars']:
        dice = 2 * len(u['chars'] & e['chars']) / (len(u['chars']) + len(e['chars']))
        noise = set(''.join(sb['noise_chars']))
        ru, re_ = sorted([len(u['chars'] - e['chars'] - noise), len(e['chars'] - u['chars'] - noise)])
        if dice >= sb['min_char_dice'] and ru <= sb['max_residual_min'] and re_ <= sb['max_residual_max']:
            sm = max(sm, sb['sim_floor'] + 0.2 * dice)
    if classified and not r.same_group(u['group'], e['group']) and sm < r.c['group_relax_score']:
        return None
    # 产地、品种、品牌：不同则不匹配
    if u['country'] and e['country'] and not (u['country'] & e['country']):
        return None
    if u['variety'] and e['variety']:
        if not (u['variety'] & e['variety']):
            return None
    elif r.c.get('variety_strict') and (u['variety'] or e['variety']):
        return None
    for a, b in ((u, e), (e, u)):
        if a['brand'] and a['brand'] not in b['flat']:
            # 对方也识别出了别的品牌 -> 品牌不同；对方没有品牌 -> 仅在标题几乎一致时放行
            if b['brand'] or sm < r.c['brand_one_side_missing_min_score']:
                return None
            if b['wbrand'] and b['wbrand'] not in a['flat'] and u['group'] not in r.c['relaxed_token_groups']:
                return None
    for g in u['attrs']:
        a, b = u['attrs'][g], e['attrs'][g]
        if g in r.c.get('non_produce_attribute_groups', []) and u['group'] in r.c['relaxed_token_groups']:
            continue
        if g in r.c['attribute_exact_groups']:
            if a != b and (a or b) and not ((not a) and not b):
                if a and b or (a or b):
                    return None
        elif a and b and not (a & b):
            return None
    if u['count'] and e['count'] and u['group'] not in r.c['relaxed_token_groups'] \
            and min(u['count'], e['count']) / max(u['count'], e['count']) < 1 - r.c['max_spec_diff']:
        return None      # 包装内件数不同（30pcs 与 48pcs）
    cu, ce = CM_RE.findall(u['keytext'].lower()), CM_RE.findall(e['keytext'].lower())
    if cu and ce and abs(float(cu[0]) - float(ce[0])) > 0.01:
        return None      # 长度规格（卫生巾 22.5cm 与 20.5cm）不同
    if not flavor_ok(r, u, e):
        return None
    wb = r.c['weak_brand']
    if wb['enabled'] and u['wbrand'] and e['wbrand'] and u['group'] not in r.c['relaxed_token_groups'] \
            and u['wbrand'] not in e['flat'] and e['wbrand'] not in u['flat']:
        return None
    # 关键词：两边都识别出关键词则必须有交集
    if u['keys'] and e['keys']:
        mod = set(r.c['modifier_keys'])
        ku, ke = u['keys'] - mod, e['keys'] - mod
        if (ku and ke and not (ku & ke)) or not (u['keys'] & e['keys']):
            return None
        if (u['group'] not in r.c['relaxed_token_groups'] or e['group'] not in r.c['relaxed_token_groups']) \
                and sm < r.c['keyed_min_token_score']:
            return None
        title = 0.7 * jac(u['keys'], e['keys']) + 0.3 * sm
    else:
        title = sm
        if title < (r.c['min_title_score'] if classified else r.c['min_title_score_unclassified']):
            return None
    # 规格：维度必须一致（重量/容量/件数），不同规格折算单价后比较
    pack = False
    if u['dim'] != e['dim'] and not (u['dim'] is None and e['dim'] is None):
        fb = r.c['pack_price_fallback']
        if not (fb['enabled'] and sm >= fb['min_score']):
            return None
        pack = True
    if pack:
        spec_sim = 0.5
        up, ep = u['price'], e['price']
    elif u['dim']:
        spec_sim = min(u['size'], e['size']) / max(u['size'], e['size'])
        same_brand = bool(u['brand'] and e['brand'] and (u['brand'] in e['flat'] or e['brand'] in u['flat']))
        max_diff = r.c['produce_max_spec_diff'] if same_brand and u['group'] in r.c['relaxed_token_groups'] else r.c['max_spec_diff']
        if spec_sim < 1 - max_diff:      # 规格差异过大视为不同商品（含整箱与单瓶）
            return None
        sp = r.c['small_pack']
        if u['dim'] != 'count' and min(u['size'], e['size']) < sp['max_size'] and spec_sim < 1 - sp['max_diff'] \
                and u['group'] not in r.c['relaxed_token_groups'] and '约' not in u['text'] + e['text']:
            return None
        up, _ = unit_price(u['price'], u['dim'], u['size'])
        ep, _ = unit_price(e['price'], e['dim'], e['size'])
    else:
        spec_sim = 1.0
        up, ep = u['price'], e['price']
    if up <= 0 or not (1 - tol) <= ep / up <= (1 + tol):
        return None
    price_fit = 1 - abs(ep / up - 1) / tol
    return title + 0.2 * spec_sim + 0.1 * price_fit


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--umall-dir', required=True, help='umall 商品 json 所在目录')
    ap.add_argument('--ebest', required=True, help='ebest 商品 json 文件，或包含该文件的目录')
    ap.add_argument('--extended', action='store_true', help='额外输出类别、价格差异等列（供系统入库）')
    ap.add_argument('--unmatched-out', help='未匹配商品清单 csv（umall 与 ebest 两侧）')
    ap.add_argument('--rules', default=os.path.join(BASE, 'matching_rules.json'))
    ap.add_argument('--out')
    a = ap.parse_args()
    r = Rules(a.rules)
    um, eb = load_umall(r, a.umall_dir), load_ebest(r, a.ebest)
    cjk_brands = learn_cjk_brands(r, um, eb)
    vocab = brand_vocab(r, (um, eb), cjk_brands)
    um, eb = prepare(r, um, cjk_brands, vocab), prepare(r, eb, cjk_brands, vocab)
    # 倒排索引：按共同的词（或关键词）选候选，避免全量两两比较
    index, max_df = {}, r.c['max_token_df']
    for i, e in enumerate(eb):
        for t in e['toks'] | e['keys']:
            index.setdefault(t, []).append(i)
    index = {t: v for t, v in index.items() if len(v) <= max_df}
    cols = list(r.c['output']['columns']) + (['umall price (AUD)', 'ebest price (AUD)', 'price diff pct', 'umall promo note', 'ebest promo note'] if a.extended else [])
    out = a.out or os.path.join(BASE, r.c['output']['file'])
    n_match = n_unmatched = 0
    matched_e, unmatched_u = set(), []
    with open(out, 'w', newline='', encoding='utf-8-sig') as f:
        w = csv.writer(f)
        w.writerow(cols)
        for u in um:
            cands = []
            cand_ids = set()
            for t in u['toks'] | u['keys']:
                cand_ids.update(index.get(t, ()))
            for i in cand_ids:
                e = eb[i]
                s = score(r, u, e)
                if s is not None:
                    cands.append((s, e))
            if not cands:
                n_unmatched += 1
                unmatched_u.append(u)
                continue
            cands.sort(key=lambda x: -x[0])
            for s, e in cands[:r.c['max_matches_per_umall']]:
                if u['dim'] != e['dim']:     # 无法折算单价：按整包价格比较
                    up, uu, ep, eu = u['price'], r.c['pack_price_fallback']['unit'], e['price'], r.c['pack_price_fallback']['unit']
                else:
                    up, uu = unit_price(u['price'], u['dim'], u['size']) if u['dim'] else (u['price'], 'AUD/pc')
                    ep, eu = unit_price(e['price'], e['dim'], e['size']) if e['dim'] else (e['price'], 'AUD/pc')
                cat = u['group'] or e['group'] or '其他'
                if r.c['category_conflict_use_ebest'] and e['group'] and u['group'] != e['group']:
                    cat = e['group']      # umall 标题关键词归类与 ebest 类别不一致时，以 ebest 的 category_name 为准
                row = [cat, u['title'], u['sku'], e['title'], e['sku'], round(up, 2), uu, round(ep, 2), eu]
                if a.extended:
                    row += [u['price'], e['price'], round((ep / up - 1) * 100, 1), u['promo'], e['promo']]
                w.writerow(row)
                matched_e.add(e['sku'])
                n_match += 1
    if a.unmatched_out:
        def up_of(x):
            return unit_price(x['price'], x['dim'], x['size']) if x['dim'] else (x['price'], 'AUD/pc')
        with open(a.unmatched_out, 'w', newline='', encoding='utf-8-sig') as f:
            w = csv.writer(f)
            w.writerow(['side', 'common category', 'product title', 'sku', 'unit price', 'unit', 'promo note'])
            for side, items in (('umall', unmatched_u), ('ebest', [e for e in eb if e['sku'] not in matched_e])):
                for x in items:
                    pr, un = up_of(x)
                    w.writerow([side, x['group'] or '其他', x['title'], x['sku'], round(pr, 2), un, x['promo']])
    print(f'umall 商品 {len(um)}，ebest 候选 {len(eb)}，匹配 {n_match}，未匹配 {n_unmatched}\n输出: {out}')


if __name__ == '__main__':
    sys.exit(main())
