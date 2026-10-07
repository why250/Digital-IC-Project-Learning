#!/usr/bin/env python3
"""ADC analog mathematical model -> RTL stream -> exact oracle and FFT."""
import argparse
import json
from pathlib import Path
from experiments import corrected, spectral, ti_signal


def require(condition,message):
    if not condition: raise AssertionError(message)


def packed(values):
    return sum((v & ((1<<18)-1)) << (18*i) for i,v in enumerate(values))


def generate(output, model_report):
    output.mkdir(parents=True,exist_ok=True)
    report=json.loads(model_report.read_text())
    o=report['lessons']['AD15']['offset_q']; g=report['lessons']['AD15']['inverse_gain_q']
    n,fs,b=65536,4e6,6001
    raw=ti_signal(n+4,fs,fs*b/n,1000,[-8,4,10,-6],[.99,1.02,.98,1.01])
    with (output/'raw.txt').open('w') as f:
        for r in raw: f.write(str(r)+'\n')
    (output/'coefficients.txt').write_text(f'{packed(o):x} {packed(g):x}\n')
    (output/'manifest.json').write_text(json.dumps({'n':n,'fs':fs,'bin':b,
        'offset_q':o,'gain_q':g,'raw':raw,'skip':4,'epoch':3,'version':1,
        'model_source_sha256':report['source_sha256'],
        'calibration':report['lessons']['AD13'],'evidence':'behavioral ADC + RTL, no analog signoff'},indent=2)+'\n')
    print('ADC_STREAM_INPUT_COMPLETE samples=65540')


def verify(output):
    m=json.loads((output/'manifest.json').read_text())
    rows=(output/'stream.txt').read_text().splitlines()
    require(len(rows)==m['n']+m['skip'],'stream count')
    wave=[]
    for n,line in enumerate(rows):
        sid,value,sat,version,epoch=map(int,line.split())
        require(sid==n and epoch==m['epoch'],'stream identity/epoch')
        o=m['offset_q'][n%4] if n>=4 else 0
        g=m['gain_q'][n%4] if n>=4 else 65536
        expected,es=corrected(m['raw'][n],o,g)
        require((value,sat)==(expected,es),f'stream integer mismatch {n}')
        require(version==int(n>=4),'stream coefficient version')
        require(sat==0,'stream saturation invalidates spectrum')
        if n>=4: wave.append(value/16)
    before=spectral(m['raw'][4:],m['bin']); after=spectral(wave,m['bin'])
    require(after['sfdr_db']>before['sfdr_db']+15,'RTL controlled calibration SFDR improvement')
    results={'before':before,'after_rtl':after,'samples':len(wave),'startup_skip':4,
             'window':'coherent rectangular','power_units':'ADC LSB squared',
             'meaning':'synthetic mismatch corrected by RTL; not real ADC performance'}
    (output/'spectrum.json').write_text(json.dumps(results,indent=2)+'\n')
    print(f'PASS RTL_STREAM samples={len(wave)} sfdr_before={before["sfdr_db"]:.3f} '
          f'sfdr_after={after["sfdr_db"]:.3f} sndr_after={after["sndr_db"]:.3f}')
    print('ADC_STREAM_VERIFICATION_COMPLETE')


if __name__=='__main__':
    p=argparse.ArgumentParser(); p.add_argument('--generate',type=Path); p.add_argument('--models',type=Path)
    p.add_argument('--verify',type=Path); a=p.parse_args()
    if a.generate: generate(a.generate,a.models)
    else: verify(a.verify)
