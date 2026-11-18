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


def norm(text):
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
        self.stop = sorted((w.lower() for w in self.c['stopwords']), key=len, reverse=True)

    # ---------- 类别 ----------
    def group_by_title(self, text):
        t = norm(text)
        best, best_score = None, 0
        for g, words in self.c['category_title_keywords'].items():
            s, tt = 0, t
            for w in sorted((w.lower() for w in words), key=len, reverse=True):
                if has_term(tt, w):
                    s += len(w)
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
        t = re.sub(r'【[^】]*】|\[[^\]]*\]|\([^)]*\)|（[^）]*）', ' ', title).lower().replace('’', "'")
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
                return self.bnorm(b)
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
                              price=umall_price(r, it))
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
        out.append(dict(sku=it['id'], title=it['title'], text=text, keytext=text, group=grp, price=ebest_price(r, it)))
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


def prepare(r, rows, cjk_brands=(), vocab=()):
    for x in rows:
        x['country'] = r.countries(x['keytext'])
        x['variety'] = r.varieties(x['keytext'])
        x['brand'] = r.brand(x['title'], cjk_brands) if r.c['brand_rules']['enabled'] else None
        x['flat'] = Rules.bnorm(x['text'])
        x['keys'] = r.keys(x['keytext'])
        core = strip_brand(x['text'], x['brand'], vocab)
        first = r.first_token(x['title'])
        if x['brand'] and first.isascii():
            core = core.lower().replace(first, ' ')
        x['toks'] = r.tokens(core)
        x['attrs'] = r.attrs(x['keytext'])
        x['dim'], x['size'], _ = r.spec(x['text'])
    return rows


def jac(a, b):
    return len(a & b) / len(a | b) if a and b else 0.0


def score(r, u, e):
    tol = r.c['price_tolerance']
    classified = bool(u['group'] and e['group'])
    if classified and not r.same_group(u['group'], e['group']):
        return None
    # 产地、品种、品牌：不同则不匹配
    if u['country'] and e['country'] and not (u['country'] & e['country']):
        return None
    if u['variety'] and e['variety']:
        if not (u['variety'] & e['variety']):
            return None
    elif r.c.get('variety_strict') and (u['variety'] or e['variety']):
        return None
    if (u['brand'] and u['brand'] not in e['flat']) or (e['brand'] and e['brand'] not in u['flat']):
        return None
    for g in u['attrs']:
        if u['attrs'][g] and e['attrs'][g] and not (u['attrs'][g] & e['attrs'][g]):
            return None
    # 关键词：两边都识别出关键词则必须有交集
    if u['keys'] and e['keys']:
        if not (u['keys'] & e['keys']):
            return None
        title = 0.7 * jac(u['keys'], e['keys']) + 0.3 * jac(u['toks'], e['toks'])
    else:
        title = jac(u['toks'], e['toks'])
        if title < (r.c['min_title_score'] if classified else r.c['min_title_score_unclassified']):
            return None
    # 规格：维度必须一致（重量/容量/件数），不同规格折算单价后比较
    if u['dim'] != e['dim'] and not (u['dim'] is None and e['dim'] is None):
        return None
    if u['dim']:
        spec_sim = min(u['size'], e['size']) / max(u['size'], e['size'])
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
    cols = list(r.c['output']['columns']) + (['umall price (AUD)', 'ebest price (AUD)', 'price diff pct'] if a.extended else [])
    out = a.out or os.path.join(BASE, r.c['output']['file'])
    n_match = n_unmatched = 0
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
                continue
            cands.sort(key=lambda x: -x[0])
            for s, e in cands[:r.c['max_matches_per_umall']]:
                up, uu = unit_price(u['price'], u['dim'], u['size']) if u['dim'] else (u['price'], 'AUD/pc')
                ep, eu = unit_price(e['price'], e['dim'], e['size']) if e['dim'] else (e['price'], 'AUD/pc')
                row = [u['group'] or e['group'] or '其他', u['title'], u['sku'], e['title'], e['sku'], round(up, 2), uu, round(ep, 2), eu]
                if a.extended:
                    row += [u['price'], e['price'], round((ep / up - 1) * 100, 1)]
                w.writerow(row)
                n_match += 1
    print(f'umall 商品 {len(um)}，ebest 候选 {len(eb)}，匹配 {n_match}，未匹配 {n_unmatched}\n输出: {out}')


if __name__ == '__main__':
    sys.exit(main())
