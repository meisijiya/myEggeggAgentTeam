#!/usr/bin/env python3
"""
v5.3.4-8 修复 6 agent frontmatter:
- 4 agent (roomdoor/laoJiangHu/qiqi/ccy): 撤销 v5.3.4-5 /tmp/** 改动（回 v5.2 形式）
- librarian: external_directory 修顺序 + 保留 /tmp/**
- update: external_directory 修顺序（不加 /tmp/**）
"""

import re
import sys
import yaml

# opencode 1.17.7 permission 评估器（reviewer 提供的源码）
def evaluate_opencode(permission, pattern, rulesets, home='/home/ubuntu'):
    """模拟 opencode 1.17.7 的 findLast 行为
    opencode 解析 ~ 为 home dir
    """
    all_rules = [r for rs in rulesets for r in rs]
    # 解析 pattern 中的 ~
    resolved_pattern = pattern
    if pattern.startswith('~'):
        resolved_pattern = home + pattern[1:]
    matched = [r for r in all_rules
               if wildcard_match(r['permission'], permission)
               and wildcard_match(r['pattern'].replace('~', home), resolved_pattern)]
    if not matched:
        return {'action': 'ask', 'permission': permission, 'pattern': '*'}
    return matched[-1]  # last matching

def wildcard_match(pattern, target):
    """简化 glob 匹配（** 匹配任意层，* 匹配单层）"""
    if pattern == target:
        return True
    if pattern == '*':
        return True
    if '**' in pattern:
        # 把 glob 转换为 regex
        # ** → 任意字符（含 /）
        # * → 任意字符（不含 /）
        regex = re.escape(pattern)
        regex = regex.replace(r'\*\*', '.*')  # ** 优先
        regex = regex.replace(r'\*', '[^/]*')  # 然后 *
        return bool(re.match(f'^{regex}$', target))
    # 单 * 匹配单层
    if '*' in pattern:
        regex = re.escape(pattern).replace(r'\*', '[^/]*')
        return bool(re.match(f'^{regex}$', target))
    return False


# 修 4 agent (回 v5.2 形式 + 修 external_directory 顺序)
def fix_4agent(path, name):
    """撤销 v5.3.4-5 /tmp 改动:
    - read/glob/grep: dict 形式 → 单行 allow
    - edit/write: dict 形式 (3条) → dict 形式 (2条，去掉 /tmp/**)
    - external_directory: dict → string "ask"
    """
    with open(path) as f:
        content = f.read()

    # 1. read/glob/grep: dict → allow
    for field in ['read', 'glob', 'grep']:
        old = re.compile(
            rf'  {field}:\n    "\*": allow\n    "/tmp/\*\*": allow\n'
        )
        new = f'  {field}: allow\n'
        content = old.sub(new, content)

    # 2. edit/write: dict (3条) → dict (2条)
    for field in ['edit', 'write']:
        old = re.compile(
            rf'  {field}:\n    "\*": allow\n    "/tmp/\*\*": allow\n    "\*\*/\.env\*": deny\n'
        )
        new = f'  {field}:\n    "*": allow\n    "**/.env*": deny\n'
        content = old.sub(new, content)

    # 3. external_directory: dict → "ask"
    old = re.compile(
        r'  external_directory:\n    "/tmp/\*\*": allow\n    "\*": ask\n'
    )
    new = '  external_directory: ask\n'
    content = old.sub(new, content)

    with open(path, 'w') as f:
        f.write(content)
    print(f"  ✅ {name}.md: 撤销 v5.3.4-5 /tmp 改动（回 v5.2）")


# 修 librarian: 保留 /tmp + 修 external_directory 顺序
def fix_librarian(path, name):
    """librarian: 保留 /tmp/** 但修 external_directory 顺序
    - read/glob/grep/edit/write: 不变（v5.3.4-5 形式，含 /tmp/**）
    - external_directory: 调换顺序（* 在前，/tmp/** 在后）
    """
    with open(path) as f:
        content = f.read()

    # 修 external_directory 顺序
    old = re.compile(
        r'  external_directory:\n    "/tmp/\*\*": allow\n    "\*": ask\n'
    )
    new = '  external_directory:\n    "*": ask\n    "/tmp/**": allow\n'
    content = old.sub(new, content)

    with open(path, 'w') as f:
        f.write(content)
    print(f"  ✅ {name}.md: 修 external_directory 顺序（保留 /tmp/**）")


# 修 update: 修 external_directory 顺序（不加 /tmp/**）
def fix_update(path, name):
    """update: 修 external_directory 顺序（不加 /tmp/**）
    - read/glob/grep/edit/write: 撤销 v5.3.4-5 /tmp 改动
    - external_directory: 调换顺序（* 在前，~/.roomdoor-memory/** 在后）
    """
    with open(path) as f:
        content = f.read()

    # 1. read/glob/grep/edit/write: 撤销 /tmp
    for field in ['read', 'glob', 'grep']:
        old = re.compile(
            rf'  {field}:\n(?:\s+"[^"]+": [^\n]+\n)+',
        )
        # 简化：找到 /tmp/** 行并删除
        content = re.sub(
            rf'(  {field}:\n)((?:\s+"[^"]+": [^\n]+\n)+)',
            lambda m: m.group(1) + re.sub(r'    "/tmp/\*\*": allow\n', '', m.group(2)),
            content
        )

    # 2. edit/write: 撤销 /tmp
    for field in ['edit', 'write']:
        content = re.sub(
            rf'(  {field}:\n)((?:\s+"[^"]+": [^\n]+\n)+)',
            lambda m: m.group(1) + re.sub(r'    "/tmp/\*\*": allow\n', '', m.group(2)),
            content
        )

    # 3. external_directory: 修顺序
    old = re.compile(
        r'  external_directory:\n    "~/\.roomdoor-memory/\*\*": allow\n    "/tmp/\*\*": allow\n    "\*": ask\n'
    )
    new = '  external_directory:\n    "*": ask\n    "~/.roomdoor-memory/**": allow\n'
    content = old.sub(new, content)

    with open(path, 'w') as f:
        f.write(content)
    print(f"  ✅ {name}.md: 修 external_directory 顺序（不加 /tmp）")


# YAML 验证
def verify_yaml(path, name):
    with open(path) as f:
        content = f.read()
    match = re.match(r'---\n(.*?)\n---', content, re.DOTALL)
    fm = match.group(1)
    try:
        d = yaml.safe_load(fm)
        return True, d
    except yaml.YAMLError as e:
        return False, str(e)


if __name__ == '__main__':
    base = '/home/ljh2923/opencode-project/myEggeggAgentTeam/agents'

    # 1. 4 agent: 撤销 v5.3.4-5 /tmp
    print("=== 1. 撤销 4 agent v5.3.4-5 /tmp 改动 ===")
    for name in ['roomdoor', 'laoJiangHu', 'qiqi', 'ccy']:
        fix_4agent(f"{base}/{name}.md", name)

    # 2. librarian: 修顺序
    print("\n=== 2. librarian: 修 external_directory 顺序 ===")
    fix_librarian(f"{base}/librarian.md", 'librarian')

    # 3. update: 修顺序
    print("\n=== 3. update: 修 external_directory 顺序 ===")
    fix_update(f"{base}/update.md", 'update')

    # 4. YAML 验证
    print("\n=== 4. YAML 验证 ===")
    for name in ['roomdoor', 'laoJiangHu', 'qiqi', 'ccy', 'librarian', 'update']:
        ok, d = verify_yaml(f"{base}/{name}.md", name)
        if ok:
            perm = d.get('permission', {})
            ext = perm.get('external_directory')
            has_tmp = '/tmp/**' in str(perm)
            print(f"  {name}: ✅ YAML 合法 | external_directory = {ext} | has_tmp_in_perm = {has_tmp}")
        else:
            print(f"  {name}: ❌ YAML 错: {d}")

    # 5. 模拟 opencode 1.17.7 permission 评估器
    print("\n=== 5. 模拟 opencode 1.17.7 行为 ===")
    test_paths = [
        ('roomdoor', 'external_directory', '/tmp/foo', 'should ASK'),
        ('librarian', 'external_directory', '/tmp/foo', 'should ALLOW'),
        ('update', 'external_directory', '/home/ubuntu/.roomdoor-memory/active/foo.md', 'should ALLOW'),
        ('update', 'external_directory', '/tmp/foo', 'should ASK (update 不需 /tmp)'),
        ('update', 'external_directory', '/home/ubuntu/.ssh/id_rsa', 'should ASK'),
        ('librarian', 'external_directory', '/home/ubuntu/.ssh/id_rsa', 'should ASK'),
    ]

    for agent, perm_type, path, expected in test_paths:
        # 解析该 agent 的 external_directory
        with open(f"{base}/{agent}.md") as f:
            content = f.read()
        match = re.match(r'---\n(.*?)\n---', content, re.DOTALL)
        d = yaml.safe_load(match.group(1))
        ext = d['permission'].get('external_directory', 'ask')

        if isinstance(ext, str):
            rules = [{'permission': 'external_directory', 'pattern': '*', 'action': ext}]
        else:
            # dict 形式: {pattern: action}
            rules = [{'permission': 'external_directory', 'pattern': p, 'action': a}
                     for p, a in ext.items()]

        result = evaluate_opencode(perm_type, path, [rules])
        status = '✅' if result['action'] == expected.split()[1].lower() else '❌'
        print(f"  {status} {agent} access {path} → {result['action']} (expected {expected})")
