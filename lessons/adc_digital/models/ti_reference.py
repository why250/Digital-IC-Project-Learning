#!/usr/bin/env python3
"""Generate interface schedules, verify RTL trace against sample-time ledger.

No DUT slot/RTL arithmetic reused. Reference values use Fraction oracle.
"""
import argparse
import json
from pathlib import Path
import random
from experiments import corrected


def require(condition, message):
    if not condition:
        raise AssertionError(message)


def pack(values, bits):
    return sum((v & ((1 << bits)-1)) << (i*bits) for i,v in enumerate(values))


def make(output):
    output.mkdir(parents=True, exist_ok=True)
    names = ['normal','random','missing','late','duplicate','wrong_lane','wrong_epoch',
             'wrong_id','sink','four_response','reset','reset_old','reset_request',
             'reset_return','reset_release','reset_correct','wrap_guard','version_guard']
    for name in names:
        rng = random.Random(177)
        samples = 512 if name in ('normal','random') else 24
        limit = samples*25+100
        bank0 = ([0]*4,[65536]*4)
        bank1 = ([-128,64,160,-96],[round(65536/a) for a in [.99,1.02,.98,1.01]])
        bank2 = ([16,-32,48,-64],[60000,70000,65000,66000])
        invalid = ([3000]*4,[65536]*4)
        updates = {10:bank1,15:bank2,100:bank2,101:bank2,201:invalid,300:bank1}
        returned = {}
        raw = [rng.randrange(-2048,2048) for _ in range(samples+5)]
        delays = [rng.randrange(1,61) if name=='random' else [18,52,9,31][n%4]
                  for n in range(samples+5)]
        if name in ('normal','random'):
            delays[4:7] = [60,35,10]  # Legal simultaneous three-lane response.
        if name=='missing': delays[0] = None
        if name=='late': delays[0] = 61
        if name=='four_response': delays[:4] = [90,65,40,15]  # Violates <=60 bound.
        for n,d in enumerate(delays):
            if d is not None:
                returned.setdefault(25*n+d,[]).append((n%4,n,raw[n],3))
        if name=='duplicate': returned.setdefault(19,[]).append((0,0,raw[0],3))
        if name=='wrong_lane': returned[18] = [(1,0,raw[0],3)]
        if name=='wrong_epoch': returned[18] = [(0,0,raw[0],2)]
        if name=='wrong_id': returned[18] = [(0,8,raw[0],3)]
        # Coordinated reset starts a new time axis/epoch at global cycle128.
        # Old and new responses are deliberately distinguished in reset_old.
        reset_start = {'reset_request':25,'reset_return':18,'reset_release':80,
                       'reset_correct':82}.get(name,125)
        restart = reset_start+3
        if name.startswith('reset'):
            returned = {t:r for t,r in returned.items() if t<reset_start}
            for n in range(samples+5):
                t = restart+25*n+[18,52,9,31][n%4]
                if t<limit: returned.setdefault(t,[]).append((n%4,n,raw[n],4))
            if name=='reset_old': returned[restart+1] = [(0,0,123,3)]
        fail = {'missing':(80,4,0), 'late':(61,3,0), 'duplicate':(19,2,0),
                'wrong_lane':(18,1,0), 'wrong_epoch':(18,1,0), 'wrong_id':(18,1,8),
                'sink':(85,6,0), 'four_response':(80,4,0),
                'reset_old':(restart+1,1,0),
                'wrap_guard':(25,7,0xfffffffc), 'version_guard':(100,7,4)}.get(name)
        pending, active, version = None,bank0,0
        outputs, expected_rows = {}, []
        events = []
        local_origin=0
        for t in range(limit):
            rst = not (name.startswith('reset') and reset_start<=t<restart)
            ep = 4 if name.startswith('reset') and t>=restart else 3
            if not rst:
                pending,active,version=None,bank0,0
                outputs = {k:v for k,v in outputs.items() if k<t}
            if name.startswith('reset') and t==restart:
                local_origin=restart
            local=t-local_origin
            halted = fail is not None and t>=fail[0]
            acc=rej=apply=0; apply_id=None
            if rst and not halted:
                if local%25==0:
                    n=local//25
                    if n%4==0 and pending is not None:
                        active=pending; pending=None; version+=1; apply=1; apply_id=n
                    o,g=active
                    y,sat=corrected(raw[n],o[n%4],g[n%4])
                    metadata=(ep<<50)|(version<<34)|(n<<2)|(n%4)
                    outputs[t+84] = (y,sat,metadata,n)
                    events.append((t,n))
                if t in updates and not name.startswith('reset'):
                    # If pending existed before this frame edge, commit rejects even if applied.
                    if t in (15,100) or updates[t]==invalid:
                        rej=1
                    else: pending=updates[t]; acc=1
            elif t in updates and rst and not name.startswith('reset'): rej=1
            # Reset during a pipeline transfer aborts its pending output.
            output_value=outputs.get(t) if rst and not halted else None
            if output_value and name.startswith('reset') and t>=reset_start and t<restart+84:
                output_value=None
            req = 0
            n=local//25
            if rst and not halted and local%25==0: req=1<<(n%4)
            entry={'req':req,'output':output_value,'acc':acc,'rej':rej,'apply':apply,'apply_id':apply_id,
                   'fault':int(halted),'fault_spec':fail,'epoch':ep,'local_tick':local,'in_reset':not rst}
            expected_rows.append(entry)
        stimulus=output/f'{name}.txt'
        with stimulus.open('w') as f:
            for t,e in enumerate(expected_rows):
                rst=int(not (name.startswith('reset') and reset_start<=t<restart))
                cfg=updates.get(t,bank0) if not name.startswith('reset') else bank0
                commit=int(t in updates and not name.startswith('reset'))
                responses=returned.get(t,[])
                rv=0; r=[0]*4; ids=[0]*4; ep=[0]*4
                for lane,n,value,epoch in responses:
                    require(not rv & 1<<lane,'two responses same lane in schedule')
                    rv |= 1<<lane; r[lane]=value; ids[lane]=n; ep[lane]=epoch
                ready=0 if name=='sink' and t==85 else 1
                snap=int(t in (500,550))
                f.write(f'{rst} {e["epoch"]:x} {commit} {pack(cfg[0],18):x} {pack(cfg[1],18):x} '
                        f'{rv:x} {pack(r,12):x} {pack(ids,32):x} {pack(ep,16):x} {ready} {snap}\n')
        (output/f'{name}.json').write_text(json.dumps({'name':name,'rows':expected_rows,'events':events,
                                                      'restart':restart,'reset_start':reset_start,
                                                      'responses':returned},indent=2)+'\n')
    print('ADC_TI_STIMULI_COMPLETE cases='+str(len(names)))


def verify(expected_path, trace_path):
    expected=json.loads(expected_path.read_text())
    trace=trace_path.read_text().splitlines()
    require(len(trace)==len(expected['rows']),'trace length')
    seen=0; previous_snapshot=0; saturation_count=0; fault_events=0; previous_fault=0
    for t,(line,e) in enumerate(zip(trace,expected['rows'])):
        fields=line.split()
        require(len(fields)==16, f'trace shape at {t}')
        values=[int(v,16) if i in (1,6,15) else int(v) for i,v in enumerate(fields)]
        _,req,sample,valid,data,sat,meta,acc,rej,apply,apply_id,fault,code,fid,ftick,snap=values
        require(req==e['req'],f'{expected["name"]} request at {t}: {req} != {e["req"]}')
        origin=expected['restart'] if expected['name'].startswith('reset') and t>=expected['restart'] else 0
        if req: require(sample==(t-origin)//25,
                        f'sample identity at {t}')
        require(fault==e['fault'],f'{expected["name"]} fault at {t}: {fault} != {e["fault"]}')
        fault_events+=int(fault and not previous_fault)
        previous_fault=fault
        if fault:
            fail=e['fault_spec']
            require(code==fail[1] and fid==fail[2],f'fault reason/id at {t}')
            wanted_tick=fail[0]-(expected['restart'] if expected['name']=='reset_old' else 0)
            require(ftick==wanted_tick,f'fault timestamp {ftick} != {wanted_tick}')
        require((acc,rej,apply)==(e['acc'],e['rej'],e['apply']),f'config handshake at {t}')
        if apply: require(apply_id==e['apply_id'],f'apply id at {t}')
        out=e['output']
        require(bool(valid)==bool(out),f'{expected["name"]} valid at {t}')
        if out:
            require((data,sat,meta)==tuple(out[:3]),f'{expected["name"]} value/tag at {t}')
            seen+=1
            saturation_count+=sat
        if t in (500,550) and expected['name'] in ('normal','random'):
            requests=sum(k<t for k,_ in expected['events'])
            responses=sum(len(v) for k,v in expected['responses'].items() if int(k)<t)
            delivered=sum(k+85<t for k,_ in expected['events'])
            require(snap==(requests<<128)|(responses<<64)|delivered,f'snapshot counts at {t}')
        elif t not in (500,550) and not e['in_reset']:
            require(snap==previous_snapshot,f'snapshot was not frozen at {t}')
        previous_snapshot=snap
    (trace_path.parent/'verification.json').write_text(json.dumps({
        'case':expected['name'],'cycles':len(trace),'outputs':seen,
        'saturation_outputs':saturation_count,'fault_events':fault_events,
        'evidence':'RTL trace compared with independent sample ledger'},indent=2)+'\n')
    print(f'PASS TI case={expected["name"]} cycles={len(trace)} outputs={seen}')


if __name__=='__main__':
    p=argparse.ArgumentParser()
    p.add_argument('--generate',type=Path)
    p.add_argument('--expected',type=Path)
    p.add_argument('--trace',type=Path)
    a=p.parse_args()
    if a.generate: make(a.generate)
    else: verify(a.expected,a.trace)
