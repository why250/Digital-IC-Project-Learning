#!/usr/bin/env python3
"""Render the first completed SPI frame from this lesson's VCD (stdlib only)."""
import argparse
import html
import re
from pathlib import Path

SIGNALS = ["clk", "start", "cs_n", "sclk", "mosi", "miso", "busy", "done", "tx_data", "rx_data"]

def read_vcd(path):
    identifiers, events, scope = {}, {}, []
    unit_ns, timestamp, frame_start, frame_end = 1.0, 0, None, None
    old_cs = None
    with path.open(encoding="ascii") as stream:
        for raw in stream:
            line = raw.strip()
            if line.startswith("$timescale"):
                scale = line
                while "$end" not in scale:
                    scale += " " + next(stream).strip()
                match = re.search(r"(\d+)\s*(s|ms|us|ns|ps|fs)\b", scale)
                unit_ns = int(match[1]) * {"s": 1e9, "ms": 1e6, "us": 1e3,
                                          "ns": 1, "ps": 1e-3, "fs": 1e-6}[match[2]]
            elif line.startswith("$scope"):
                scope.append(line.split()[2])
            elif line.startswith("$upscope"):
                scope.pop()
            elif line.startswith("$var"):
                parts = line.split()
                if scope == ["tb_spi_master"] and parts[4] in SIGNALS:
                    identifiers[parts[3]] = parts[4]
                    events[parts[4]] = []
            elif line.startswith("#"):
                timestamp = int(line[1:]) * unit_ns
                if frame_end is not None and timestamp > frame_end + 100:
                    break
            elif line and not line.startswith("$"):
                if line[0] in "01xz":
                    value, code = line[0], line[1:]
                elif line[0] in "bB":
                    value, code = line[1:].split()
                else:
                    continue
                name = identifiers.get(code)
                if name:
                    events[name].append((timestamp, value))
                    if name == "cs_n":
                        if old_cs == "1" and value == "0" and frame_start is None:
                            frame_start = timestamp
                        if frame_start is not None and value == "1" and frame_end is None:
                            frame_end = timestamp
                        old_cs = value
    if frame_start is None or frame_end is None:
        raise ValueError("No complete SPI frame in VCD")
    missing = set(SIGNALS) - set(events)
    if missing:
        raise ValueError("Missing signals: " + ", ".join(sorted(missing)))
    return events, frame_start, frame_end

def at(events, time):
    value = "x"
    for stamp, new_value in events:
        if stamp > time:
            break
        value = new_value
    return value

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("vcd", type=Path)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    events, frame_start, frame_end = read_vcd(args.vcd)
    begin, end = max(0, frame_start - 80), frame_end + 80
    width, left, right, row = 1600, 110, 35, 51
    height = 145 + len(SIGNALS) * row
    x = lambda stamp: left + (stamp - begin) * (width - left - right) / (end - begin)
    svg = [f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" viewBox="0 0 {width} {height}">',
           '<rect width="100%" height="100%" fill="#f8fafc"/>',
           '<style>text{font-family:Arial,sans-serif;fill:#17324d} .wave{fill:none;stroke:#126c83;stroke-width:1.5}</style>']
    rises = [stamp for stamp, value in events["sclk"]
             if frame_start <= stamp <= frame_end and value == "1"]
    if len(rises) != 8:
        raise ValueError(f"Expected 8 sampling edges, got {len(rises)}")
    tx = int("".join(at(events["mosi"], stamp) for stamp in rises), 2)
    rx = int("".join(at(events["miso"], stamp) for stamp in rises), 2)
    title = f"SPI Mode 0 | first frame | TX={tx:02X}, RX={rx:02X} | CS duration={(frame_end-frame_start)/1000:.3f} us"
    svg.append(f'<text x="25" y="30" font-size="21">{html.escape(title)}</text>')
    svg.append('<text x="25" y="55" font-size="14">All storage uses 50 MHz clk. Red lines: SPI rising-edge sampling. tx_data changes after acceptance.</text>')
    for i in range(11):
        stamp = begin + (end-begin) * i / 10
        xpos = x(stamp)
        svg.append(f'<path d="M{xpos:.2f},80 V{height-35}" stroke="#dbe3eb"/>')
        svg.append(f'<text x="{xpos:.2f}" y="76" text-anchor="middle" font-size="11">{stamp/1000:.3f} us</text>')
    for index, name in enumerate(SIGNALS):
        base = 103 + index * row
        svg.append(f'<text x="15" y="{base+18}" font-size="14">{name}</text>')
        points = [(begin, at(events[name], begin))]
        points += [(stamp, value) for stamp, value in events[name] if begin < stamp < end]
        points.append((end, points[-1][1]))
        if name in ("tx_data", "rx_data"):
            for (stamp, value), (next_stamp, _) in zip(points, points[1:]):
                a, b = x(stamp), x(next_stamp)
                svg.append(f'<rect x="{a:.2f}" y="{base}" width="{b-a:.2f}" height="28" fill="#e1f0f2" stroke="#126c83"/>')
                if b-a > 28:
                    label = f"{int(value,2):02X}" if all(c in "01" for c in value) else value
                    svg.append(f'<text x="{(a+b)/2:.2f}" y="{base+19}" text-anchor="middle" font-size="12">{html.escape(label)}</text>')
        else:
            yy = lambda value: base if value == "1" else base + 28
            commands = [f"M{x(points[0][0]):.2f},{yy(points[0][1])}"]
            for stamp, value in points[1:]:
                commands.append(f"H{x(stamp):.2f} V{yy(value)}")
            svg.append(f'<path class="wave" d="{" ".join(commands)}"/>')
    for index, stamp in enumerate(rises):
        xpos = x(stamp)
        svg.append(f'<path d="M{xpos:.2f},92 V{103+6*row}" stroke="#cc4a4a" stroke-dasharray="3 5" opacity=".65"/>')
        svg.append(f'<text x="{xpos:.2f}" y="{103+4*row-5}" text-anchor="middle" font-size="12">{at(events["mosi"],stamp)}</text>')
        svg.append(f'<text x="{xpos:.2f}" y="{103+5*row-5}" text-anchor="middle" font-size="12">{at(events["miso"],stamp)}</text>')
    svg.append(f'<text x="25" y="{height-12}" font-size="13">Read rx_data when done=1. Teaching RTL simulation; no extracted parasitics or external interface signoff.</text>')
    svg.append("</svg>")
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text("\n".join(svg) + "\n", encoding="utf-8")
    print(f"WAVEFORM first_frame tx={tx:02X} rx={rx:02X} samples=8 output={args.output}")

if __name__ == "__main__":
    main()
