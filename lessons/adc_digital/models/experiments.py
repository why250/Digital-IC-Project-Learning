#!/usr/bin/env python3
"""AD01-AD20 reproducible numerical experiments. Python standard library only.

Analog errors are mathematical models, not transistor/PVT/clock validation.
"""
import argparse
import cmath
import hashlib
import json
import math
from pathlib import Path
import random
from fractions import Fraction

ROOT = Path(__file__).resolve().parents[1]


def check(condition, message):
    if not condition:
        raise AssertionError(message)


def fft(values):
    """Radix2 unnormalised FFT, independent of lane error generation."""
    n = len(values)
    check(n > 0 and n & (n - 1) == 0, 'FFT length')
    a = [complex(v) for v in values]
    j = 0
    for i in range(1, n):
        bit = n >> 1
        while j & bit:
            j ^= bit
            bit >>= 1
        j ^= bit
        if i < j:
            a[i], a[j] = a[j], a[i]
    span = 2
    while span <= n:
        w0 = cmath.exp(-2j * math.pi / span)
        for base in range(0, n, span):
            w = 1.0 + 0j
            for k in range(span // 2):
                u, v = a[base + k], w * a[base + k + span // 2]
                a[base + k], a[base + k + span // 2] = u + v, u - v
                w *= w0
        span *= 2
    return a


def quantize(x):
    return max(-2048, min(2047, round(x)))


def corrected(raw, offset, gain):
    # Fraction + round is an independent exact nearest-even oracle.
    value = round(Fraction((raw * 16 - offset) * gain, 65536))
    return max(-131072, min(131071, value)), int(not -131072 <= value <= 131071)


def sar(x, bits=10):
    code, trials = 0, []
    for b in reversed(range(bits)):
        trial = code | 1 << b
        trials.append(trial)
        if x >= trial:
            code = trial
    return code, trials


def flash(word):
    b = [(word >> i) & 1 for i in range(16)]
    f = b[:]
    for i in range(1, 15):
        f[i] = int(sum(b[i-1:i+2]) >= 2)
    invalid = any(f[i] == 0 and f[j] == 1 for i in range(16) for j in range(i+1, 16))
    return sum(f), int(invalid), int(f != b)


def dft_mismatch(values):
    m = len(values)
    return [sum(v * cmath.exp(-2j*math.pi*k*i/m) for i, v in enumerate(values))/m
            for k in range(m)]


def solve3(matrix, rhs):
    """Pivoted Gaussian elimination; rejects under-excited fits."""
    rows = [list(a) + [b] for a, b in zip(matrix, rhs)]
    for k in range(3):
        p = max(range(k, 3), key=lambda i: abs(rows[i][k]))
        check(abs(rows[p][k]) > 1e-9, 'rank deficient sine fit')
        rows[k], rows[p] = rows[p], rows[k]
        div = rows[k][k]
        rows[k] = [x/div for x in rows[k]]
        for i in range(3):
            if i != k:
                factor = rows[i][k]
                rows[i] = [a-factor*b for a, b in zip(rows[i], rows[k])]
    return [rows[i][3] for i in range(3)]


def sine_fit(times, values, omega):
    basis = [[math.sin(omega*t), math.cos(omega*t), 1] for t in times]
    gram = [[sum(r[i]*r[j] for r in basis) for j in range(3)] for i in range(3)]
    rhs = [sum(r[i]*y for r, y in zip(basis, values)) for i in range(3)]
    a, b, c = solve3(gram, rhs)
    return math.hypot(a, b), math.atan2(b, a), c


def ti_signal(n, fs, freq, amplitude, offsets, gains, skews=None, poles=None,
              jitter=0, noise=0, seed=20261004, integer=True):
    rng = random.Random(seed)
    skews = skews or [0]*4
    result = []
    for index in range(n):
        m = index % 4
        t = index/fs + skews[m] + rng.gauss(0, jitter)
        omega = 2*math.pi*freq
        h = 1/(1+1j*freq/poles[m]) if poles else 1+0j
        x = amplitude*abs(h)*math.sin(omega*t+cmath.phase(h))
        y = gains[m]*x + offsets[m] + rng.gauss(0, noise)
        result.append(quantize(y) if integer else y)
    return result


def spectral(values, tone_bin):
    n = len(values)
    bins = fft(values)
    # Rectangular, coherent example: power weights differ at DC/Nyquist.
    power = [abs(bins[k])**2/n**2*(1 if k in (0, n//2) else 2)
             for k in range(n//2+1)]
    signal = power[tone_bin]
    rest = [k for k in range(1, n//2+1) if k != tone_bin]
    spur = max(rest, key=lambda k: power[k])
    return {'tone_peak_lsb': math.sqrt(2*signal), 'largest_spur_bin': spur,
            'sfdr_db': 10*math.log10(signal/max(power[spur], 1e-30)),
            'sndr_db': 10*math.log10(signal/max(sum(power[k] for k in rest), 1e-30)),
            'dc_lsb': bins[0].real/n}


def vectors(output):
    output.mkdir(parents=True, exist_ok=True)
    rng = random.Random(152026)
    cases = [(100, 64, 64251), (2047, -131072, 131071),
             (-2048, 131071, 131071), (0, 1, 32768), (0, 3, 32768),
             (0, -1, 32768), (0, -3, 32768)]
    # All raw codes with several offsets, plus full coefficient signed range.
    cases += [(r, 64, 64251) for r in range(-2048, 2048)]
    cases += [(rng.randrange(-2048, 2048), rng.randrange(-131072, 131072),
               rng.randrange(-131072, 131072)) for _ in range(10000)]
    with (output/'fixed_vectors.txt').open('w') as f:
        for r, o, g in cases:
            y, sat = corrected(r, o, g)
            f.write(f'{r} {o} {g} {y} {sat}\n')
    with (output/'flash_vectors.txt').open('w') as f:
        for word in range(65536):
            code, invalid, repair = flash(word)
            f.write(f'{word} {code} {invalid} {repair}\n')
    print(f'ADC_VECTORS_COMPLETE fixed={len(cases)} flash=65536')


def run(output):
    output.mkdir(parents=True, exist_ok=True)
    result = {'seed': 20261004, 'evidence': 'mathematical/behavioral model only',
              'lessons': {}, 'parameters': {'fs': 4000000, 'core': 100000000,
                                           'n': 65536, 'bin': 6001, 'amplitude': 1000}}
    lessons = result['lessons']
    lessons['AD01'] = {'interfaces': ['sample/tag', 'conversion/return', 'coeff/version',
                                    'clock/reset', 'output/throughput']}
    for x in range(1024):
        check(sar(x+.4)[0] == x, 'SAR all codes')
    lessons['AD02'] = {'cases': 1024, 'example': sar(677.4)}
    for k in range(17):
        code, invalid, _ = flash((1 << k)-1)
        check(code == k and not invalid, 'ideal flash')
    check(flash(0xff ^ 1 << 3)[:2] == (8, 0), 'internal bubble')
    # Near transition: a one-bit error is itself another ideal code.
    check(flash(0xff ^ 1 << 7)[0] == 7, 'ambiguous boundary')
    lessons['AD03'] = {'ideal_codes': 17, 'limited_bubble': True, 'boundary_ambiguous': True}
    residue = .8
    decisions = [1, 1, 0, 1]
    for d in decisions:
        residue = 2*residue-d
    reconstruct = sum(d/2**(k+1) for k, d in enumerate(decisions))+residue/16
    check(abs(reconstruct-.8) < 1e-12, 'pipeline identity')
    lessons['AD04'] = {'residue': residue, 'reconstruct': reconstruct, 'clipping_unrecoverable': True}
    pointer, usage = 0, [0]*8
    for _ in range(8):
        for j in range(3):
            usage[(pointer+j)%8] += 1
        pointer = (pointer+3)%8
    check(usage == [3]*8, 'DWA distribution')
    errors = [-.01, .008, .006, -.004, .002, -.009, .003, .004]
    p, dwa_error, fixed_error = 0, [], []
    rng = random.Random(5)
    for _ in range(8192):
        q = rng.randrange(9)
        dwa_error.append(sum(errors[(p+j)%8] for j in range(q)))
        fixed_error.append(sum(errors[:q]))
        p = (p+q)%8
    lessons['AD05'] = {'usage': usage, 'mean_dwa_error': sum(dwa_error)/len(dwa_error),
                      'mean_fixed_error': sum(fixed_error)/len(fixed_error),
                      'dynamic_errors_and_tones_not_proven': True}
    def lowband_error_power(wave):
        spectrum=fft(wave)
        return sum(2*abs(v)**2/len(wave)**2 for v in spectrum[1:len(wave)//8+1])
    lessons['AD05']['static_random_q_lowband_power'] = {
        'fixed':lowband_error_power(fixed_error),'dwa':lowband_error_power(dwa_error),
        'band':'0 < normalized frequency <= 1/8, DC excluded'}
    pointer=0; constant_error=[]
    for _ in range(8192):
        constant_error.append(sum(errors[(pointer+j)%8] for j in range(3)))
        pointer=(pointer+3)%8
    check(all(abs(a-b)<1e-15 for a,b in zip(constant_error[8:],constant_error[:-8])),
          'constant q DWA periodic tone example')
    tone_fft=fft(constant_error)
    tone_bin=max(range(1,4097),key=lambda k:abs(tone_fft[k]))
    lessons['AD05']['constant_q_tone_bin']=tone_bin
    lessons['AD05']['constant_q_tone_normalized_frequency']=tone_bin/8192
    times = [25*n for n in range(8)]
    arrivals = sorted((t+[18,52,9,31][n%4], n) for n, t in enumerate(times))
    check([n for _, n in arrivals] == [0,2,1,3,4,6,5,7], 'arrival reordering')
    lessons['AD06'] = {'sample_ticks': times, 'same_lane_period_ticks': 100}
    lessons['AD07'] = {'arrivals': arrivals, 'release_ticks': [t+80 for t in times], 'slots': 8}
    lessons['AD08'] = {'stall_10us_backlog': 40, 'reset_contract': 'coordinated flush',
                      'physical_metastability_not_simulated': True}
    n, fs, b = 65536, 4e6, 6001
    freq = fs*b/n
    offsets, gains = [-8,4,10,-6], [.99,1.02,.98,1.01]
    ideal = ti_signal(1024, fs, freq, 1000, [0]*4, [1]*4, integer=False)
    check(max(abs(y-1000*math.sin(2*math.pi*freq*k/fs)) for k, y in enumerate(ideal)) < 1e-8,
          'zero mismatch')
    lessons['AD09'] = {'zero_mismatch_max_error': 0, 'encoding': 'signed12 nearest-even clip'}
    dc = dft_mismatch(offsets)
    check(abs(dc[1]-complex(-4.5,-2.5)) < 1e-12, 'offset DFT')
    check(max(abs(v-1) for v in fft([1]+[0]*15)) < 1e-12, 'FFT impulse normalization')
    gain_case = ti_signal(n, fs, freq, 1000, [0]*4, [1.005,.995,1.005,.995], integer=False)
    spectrum = fft(gain_case)
    ratio = abs(spectrum[n//2-b])/abs(spectrum[b])
    check(abs(ratio-.005) < 1e-10, 'two-lane gain image')
    lessons['AD10'] = {'offset_dft': [[v.real, v.imag] for v in dc],
                      'gain_image_dbc': 20*math.log10(ratio),
                      'image_bins': sorted({n//4-b, n//4+b, n//2-b})}
    # Check first-order timing prediction against exact sampled sinusoid.
    test_f = 100e6
    dt, sigma = 1e-12, 1e-12
    exact_ratio = abs(math.tan(math.pi*test_f*dt))
    approx = math.pi*test_f*dt
    check(abs(exact_ratio/approx-1) < 1e-6, 'small skew approximation')
    lessons['AD11'] = {'skew_dbc': 20*math.log10(exact_ratio),
                      'jitter_snr_db': -20*math.log10(2*math.pi*test_f*sigma)}
    jf, js = 4001*fs/16384, 5e-9
    jittered = ti_signal(16384,fs,jf,1000,[0]*4,[1]*4,jitter=js,integer=False)
    jitter_ideal = [1000*math.sin(2*math.pi*jf*k/fs) for k in range(16384)]
    measured = 10*math.log10(sum(v*v for v in jitter_ideal)/
                            sum((a-b)**2 for a,b in zip(jittered,jitter_ideal)))
    predicted = -20*math.log10(2*math.pi*jf*js)
    check(abs(measured-predicted)<.5,'Monte Carlo independent jitter budget')
    lessons['AD11']['monte_carlo'] = {'fin_hz':jf,'sigma_seconds':js,
                                     'predicted_snr_db':predicted,'measured_snr_db':measured}
    poles = [1e6, 1.1e6, .9e6, 1.05e6]
    h_low = [1/(1+1j*.05e6/fc) for fc in poles]
    h_high = [1/(1+1j*.8e6/fc) for fc in poles]
    check(abs(h_low[0]/h_low[1]-h_high[0]/h_high[1]) > .01, 'frequency dependent mismatch')
    rank_rejected = False
    try:
        sine_fit([0]*16, [1]*16, 1)
    except AssertionError:
        rank_rejected = True
    check(rank_rejected, 'underexcited fit must reject')
    lessons['AD12'] = {'rank_deficient_rejected': True,
                      'single_frequency_phase_cannot_separate_frontend_and_clock': True}
    # Controlled Gaussian dither; means computed from integer observations.
    rng = random.Random(13)
    fitted_o, fitted_g = [], []
    for o, a in zip(offsets, gains):
        plus = sum(quantize(a*512+o+rng.gauss(0, .7)) for _ in range(8192))/8192
        minus = sum(quantize(-a*512+o+rng.gauss(0, .7)) for _ in range(8192))/8192
        fitted_o.append((plus+minus)/2)
        fitted_g.append((plus-minus)/1024)
    check(max(abs(a-b) for a,b in zip(fitted_o,offsets)) < .04, 'offset estimate budget')
    check(max(abs(a-b) for a,b in zip(fitted_g,gains)) < 1e-4, 'gain estimate budget')
    lessons['AD13'] = {'offset_estimates': fitted_o, 'gain_estimates': fitted_g,
                      'dc_samples_per_point_lane': 8192, 'dither_sigma_lsb': .7,
                      'undithered_gain_example': (526+518)/1024}
    omega = 2*math.pi*freq
    skews = [0, 1e-9, -.8e-9, .4e-9]
    estimated_skews = []
    for lane in range(4):
        t = [(4*k+lane)/fs for k in range(1024)]
        y = [1000*math.sin(omega*(v+skews[lane]))+offsets[lane] for v in t]
        amp, phase, off = sine_fit(t, y, omega)
        estimated_skews.append(phase/omega)
        check(abs(amp-1000) < 1e-7 and abs(off-offsets[lane]) < 1e-7, 'sine fit')
    check(max(abs(a-b) for a,b in zip(skews,estimated_skews)) < 1e-15, 'known sine skew')
    lessons['AD14'] = {'skew_estimates_seconds': estimated_skews,
                      'assumptions': 'identical frontend phase; known frequency; bounded skew'}
    oq, iq = [round(o*16) for o in fitted_o], [round(65536/a) for a in fitted_g]
    raw = ti_signal(n, fs, freq, 1000, offsets, gains)
    cal = [corrected(v, oq[k%4], iq[k%4])[0]/16 for k,v in enumerate(raw)]
    before, after = spectral(raw,b), spectral(cal,b)
    check(before['largest_spur_bin']==n//2-b,'predicted dominant gain image')
    check(after['sfdr_db'] > before['sfdr_db']+15, 'controlled offset/gain SFDR improvement')
    # Small skew + three-tap differentiator; measure low frequency approximation.
    lf = 20000
    skewed = ti_signal(4096, fs, lf, 1000, [0]*4,[1]*4,skews=skews,integer=False)
    uncal_err, timing_err = [], []
    for k in range(1,4095):
        derivative=(skewed[k+1]-skewed[k-1])/2
        fixed=skewed[k]-skews[k%4]*fs*derivative
        ideal_k=1000*math.sin(2*math.pi*lf*k/fs)
        uncal_err.append(skewed[k]-ideal_k); timing_err.append(fixed-ideal_k)
    rms = lambda v: math.sqrt(sum(x*x for x in v)/len(v))
    check(rms(timing_err) < rms(uncal_err)/10, 'low-frequency derivative correction')
    lessons['AD15'] = {'offset_q': oq, 'inverse_gain_q': iq, 'before': before, 'after': after,
                      'timing_rms_before': rms(uncal_err), 'timing_rms_after': rms(timing_err),
                      'timing_bandwidth_limited': True}
    # Background relative mean tracking, with explicit stationary zero-mean input.
    def mean_track(signal_means):
        estimate = [0.0]*4
        for _ in range(512):
            obs = [offsets[m]+signal_means[m] for m in range(4)]
            common = sum(obs)/4
            estimate = [e+.02*(y-common-e) for e,y in zip(estimate,obs)]
        return estimate
    good, bad = mean_track([0]*4), mean_track([20,-20,20,-20])
    check(max(abs(a-b) for a,b in zip(good,offsets)) < .001, 'conditional mean convergence')
    check(max(abs(a-b) for a,b in zip(bad,offsets)) > 19, 'cyclostationary failure observed')
    lessons['AD16'] = {'stationary_estimate': good, 'violated_assumption_estimate': bad,
                      'step': .02, 'failure_detection_required': True}
    # In-flight coefficient snapshots remain independent of later active updates.
    active = [0]*4
    captured = [(k, tuple(active)) for k in range(4)]
    active = [1,2,3,4]
    check(all(c == (0,0,0,0) for _,c in captured), 'snapshot lifetime')
    lessons['AD17'] = {'per_sample_copies': True, 'frame_atomic_commit': True,
                      'rtl_evidence': 'requires run_sim.sh'}
    lessons['AD18'] = {'fft': 'rectangular coherent, single-side power except DC/Nyquist',
                      'label_and_saturation_checks_required_before_fft': True,
                      'model_truth_and_response_scheduler_separate': True}
    lessons['AD19'] = {'rtl_and_synthesis_status': 'not established by model runner',
                      'commands': ['scripts/run_sim.sh', 'scripts/run_synth.sh']}
    lessons['AD20'] = {'stream_payload_bit_s': 4e6*18,
                      'illustrative_dynamic_power_w': .2*100e-12*.8**2*100e6,
                      'power_evidence': 'assumed alpha/C/V/f, not measured or extracted'}
    result['source_sha256'] = hashlib.sha256(Path(__file__).read_bytes()).hexdigest()
    (output/'experiments.json').write_text(json.dumps(result,indent=2)+'\n')
    print(f"MODEL_SPECTRUM sfdr_before={before['sfdr_db']:.3f} sfdr_after={after['sfdr_db']:.3f}")
    print('ADC_MODELS_COMPLETE lessons=20')


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--vectors', action='store_true')
    parser.add_argument('--output', type=Path, default=ROOT/'results/models')
    args = parser.parse_args()
    if args.vectors:
        vectors(args.output)
    else:
        run(args.output)
