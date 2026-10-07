#!/usr/bin/env python3
"""Fail closed on missing evidence, unmapped primitives and timing intent."""
from pathlib import Path
from collections import Counter
import hashlib
import json
import re
import sys

root=Path(sys.argv[1]); top=sys.argv[2]
for name in ('mapped.v','mapped.sdc','timing.rpt','area.rpt','gates.rpt',
             'mapped_design_check.rpt','mapped_timing_intent.rpt'):
    if not (root/name).is_file() or not (root/name).stat().st_size:
        raise SystemExit('Missing synthesis evidence: '+name)
netlist=(root/'mapped.v').read_text()
if not re.search(r'\bmodule\s+'+re.escape(top)+r'\b',netlist):
    raise SystemExit('Top missing from netlist')
if re.search(r'\b(?:always|initial|GTECH_\w*|CDN_\w*)\b',netlist):
    raise SystemExit('Unmapped procedural/generic content')
# Tutorial library cells: verify every instance rather than just file presence.
instances=re.findall(r'^\s*(\w+)\s+(?:\\[^\s]+|\w+)\s*\(',netlist,re.M)
instances=[i for i in instances if i not in ('module','if','for')]
lib=Path('/opt/eda/cadence/DDI251/GENUS251/share/synth/tutorials/tech/tutorial.lib')
known=set(re.findall(r'\bcell\s*\(\s*"?(\w+)"?\s*\)',lib.read_text()))
if not known:
    raise SystemExit('Tutorial library cell inventory empty')
modules=set(re.findall(r'\bmodule\s+(\w+)',netlist))
unknown=set(instances)-known-modules
if not instances or unknown:
    raise SystemExit('Unknown mapped cell types: '+str(sorted(unknown)))
if any(i.startswith('latch') for i in instances):
    raise SystemExit('Unexpected mapped latch')
for report_name in ('timing_intent.rpt','mapped_timing_intent.rpt'):
    intent=(root/report_name).read_text()
    if not re.search(r'Total\s*:\s*0\b',intent):
        raise SystemExit('Timing intent is not explicitly zero: '+report_name)
design=(root/'mapped_design_check.rpt').read_text()
for keyword in ('unresolved references','empty modules','undriven combinational pin',
                'undriven sequential pin','undriven hierarchical pin','undriven port',
                'multidriven combinational pin','multidriven sequential pin',
                'multidriven hierarchical pin','multidriven port'):
    if not re.search(r'^No '+keyword, design,re.I|re.M):
        raise SystemExit('Design check has not confirmed absence: '+keyword)
timing=(root/'timing.rpt').read_text()
slacks=[float(v) for v in re.findall(r'Slack\s*[:=]*\s*(-?\d+(?:\.\d+)?)',timing,re.I)]
if not slacks:
    raise SystemExit('Setup slack not found; inspect format')
if min(slacks)<0:
    raise SystemExit('Setup failed: '+str(min(slacks)))
summary={'top':top,'mapped_cells':dict(Counter(i for i in instances if i in known)),
         'setup_slack_ps':min(slacks),'timing_intent_before_after':[0,0],
         'hold_checked':False,'library':'Genus tutorial, not tapeout PDK',
         'sha256':{name:hashlib.sha256((root/name).read_bytes()).hexdigest()
                   for name in ('mapped.v','mapped.sdc','timing.rpt')}}
(root/'verification.json').write_text(json.dumps(summary,indent=2)+'\n')
print(f'PASS SYNTH top={top} mapped_cells={sum(i in known for i in instances)} setup_slack_ps={min(slacks)}')
