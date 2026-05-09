# [[ref:a8f3c2e1-5d7b-4f9a-b6c4-1e8d3b0a7f2e][Specification]]

import os
import re
import sys

_UUID = r'[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}'

RE_HEADING   = re.compile(r'\*+ +(.+)')
RE_ID_PROP   = re.compile(r':ID:[ \t]+(' + _UUID + r')')
RE_ID_INLINE = re.compile(r'\[\[id:(' + _UUID + r')')
RE_REF       = re.compile(r'\[\[ref:(' + _UUID + r')')


def dot_quote(s):
    s = s.replace('\\', '\\\\').replace('"', '\\"').replace('\n', '\\n')
    return f'"{s}"'


def scan_file(path):
    """Scan one .org file using section#graph from the spec.

    Returns (labels, edges) where:
      labels: list of (uuid, heading, filepath)
      edges:  list of (from_uuid, to_uuid)

    Each stack frame is [level, heading, uuid_or_None, own_refs].
    When a frame is closed, refs bubble up to the nearest ancestor UUID
    if the frame itself has none (implicit parent→child edges are also added).
    """
    labels = []
    edges  = []
    stack  = []  # [level, heading, uuid|None, own_refs]

    def nearest_uuid():
        return next((f[2] for f in reversed(stack) if f[2] is not None), None)

    def close_frame(frame):
        _, _, uuid, own_refs = frame
        parent = nearest_uuid()
        if uuid is not None:
            if parent is not None:
                edges.append((parent, uuid))
            for ref in own_refs:
                edges.append((uuid, ref))
        elif parent is not None:
            for ref in own_refs:
                edges.append((parent, ref))

    with open(path, encoding='utf-8', errors='replace') as fh:
        for raw in fh:
            line = raw.rstrip('\n')

            hm = RE_HEADING.match(line)
            if hm:
                level   = len(line) - len(line.lstrip('*'))
                heading = hm.group(1).rstrip()
                while stack and stack[-1][0] >= level:
                    close_frame(stack.pop())
                stack.append([level, heading, None, []])
                continue

            pm = RE_ID_PROP.search(line)
            if pm:
                uuid = pm.group(1)
                if stack:
                    stack[-1][2] = uuid
                    labels.append((uuid, stack[-1][1], path))

            for uid in RE_ID_INLINE.findall(line):
                labels.append((uid, stack[-1][1] if stack else '', path))

            if stack:
                for ref in RE_REF.findall(line):
                    stack[-1][3].append(ref)

    while stack:
        close_frame(stack.pop())

    return labels, edges


def find_org_files(directory):
    result = []
    for dirpath, _, filenames in os.walk(directory):
        for name in filenames:
            if name.endswith('.org'):
                result.append(os.path.join(dirpath, name))
    return result


def node_label(uuid, label_table):
    entry = label_table.get(uuid)
    if entry and entry[0]:
        return f'{uuid[:8]}\n{entry[0]}'
    return uuid[:8]


def reachable_from(seeds, edges):
    """BFS over undirected edges; return set of all reachable UUIDs."""
    adj = {}
    for src, dst in edges:
        adj.setdefault(src, []).append(dst)
        adj.setdefault(dst, []).append(src)
    visited = set(seeds)
    queue = list(seeds)
    while queue:
        node = queue.pop()
        for nbr in adj.get(node, ()):
            if nbr not in visited:
                visited.add(nbr)
                queue.append(nbr)
    return visited


def main():
    args = sys.argv[1:]
    root       = args[0] if args            else os.environ.get('ROOT', '.')
    filter_arg = args[1] if len(args) > 1  else ''

    backlog_path = os.path.join(root, 'doc', 'backlog.org')
    readme_path  = os.path.join(root, 'README.org')
    doc_dir      = os.path.join(root, 'doc')

    all_labels, all_edges = [], []
    for path in [readme_path] + find_org_files(doc_dir):
        lbs, eds = scan_file(path)
        all_labels.extend(lbs)
        all_edges.extend(eds)

    # First occurrence per UUID wins.
    label_table = {}
    for uuid, heading, filepath in all_labels:
        label_table.setdefault(uuid, (heading, filepath))

    readme_uuids = {uuid for uuid, (_, fp) in label_table.items() if fp == readme_path}

    if filter_arg == 'tasks':
        filtered = {u: v for u, v in label_table.items() if v[1] == backlog_path}
    elif filter_arg == 'defs':
        reached = reachable_from(readme_uuids, all_edges)
        filtered = {u: v for u, v in label_table.items() if u in reached}
    else:
        filtered = label_table

    node_set = set(filtered)
    kept_edges = [(s, d) for s, d in all_edges if s in node_set and d in node_set]

    print('digraph doc {')
    print('  rankdir=LR;')
    print('  node [shape=box fontname="monospace" fontsize=10];')
    print()
    for uuid in filtered:
        print(f'  {dot_quote(uuid)} '
              f'[label={dot_quote(node_label(uuid, filtered))} '
              f'URL="org-id://{uuid}"];')
    print()
    for src, dst in kept_edges:
        print(f'  {dot_quote(src)} -> {dot_quote(dst)};')
    print('}')


if __name__ == '__main__':
    main()
