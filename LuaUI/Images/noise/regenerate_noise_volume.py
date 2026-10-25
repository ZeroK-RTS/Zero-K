#!/usr/bin/env python3
"""Generate a seeded 64^3 RGBA noise volume matched to noise64_cube_3.dds.

Usage:
    python regenerate_noise_volume.py noise64_cube_3.dds --seed 2026 \
        --output noise64_cube_3_seed2026.dds

Requires Python 3.9+ and NumPy.

This is a reconstruction from the supplied texture, NOT the original asset's
verified generator. It copies the DDS header exactly and approximates its noise
with periodic, quintic-interpolated gradient fBm. The channels have base lattice
frequencies 1, 2, 4, and 8; frequency doubles and amplitude halves per octave.
Each channel's contrast and center are calibrated to the reference. Alpha is
noise data, not an opaque/transparency channel.

DDS header interpretation:
https://learn.microsoft.com/en-us/windows/win32/direct3ddds/dds-header
https://learn.microsoft.com/en-us/windows/win32/direct3ddds/dds-pixelformat
"""
from __future__ import annotations

import argparse
import hashlib
import itertools
import json
import os
from pathlib import Path
import struct
import tempfile
from typing import Any

import numpy as np

SIZE = 64
BASE_FREQUENCIES = (1, 2, 4, 8)
PERSISTENCE = 0.5
HEADER_BYTES = 128


def read_reference(path: Path) -> tuple[bytes, np.ndarray]:
    """Accept only the original asset's legacy 64^3 RGBA8 DDS layout."""
    data = path.read_bytes()
    if len(data) < HEADER_BYTES or data[:4] != b'DDS ':
        raise ValueError('Reference is not a DDS file with a complete header.')
    h = struct.unpack('<31I', data[4:HEADER_BYTES])
    if h[0] != 124 or h[18] != 32:
        raise ValueError('Unsupported DDS header size.')
    if (h[3], h[2], h[5]) != (SIZE, SIZE, SIZE):
        raise ValueError('Reference must be a 64 x 64 x 64 volume.')
    if not (h[27] & 0x200000) or (h[27] & 0x200):
        raise ValueError('Reference must be a volume, not a cubemap.')
    if h[4] != SIZE * 4 or h[6] != 1:
        raise ValueError('Expected tightly packed rows and one base level.')
    if (h[19:26] != (0x41, 0, 32, 0xff, 0xff00, 0xff0000, 0xff000000)):
        raise ValueError('Expected legacy uncompressed RGBA8 byte order.')
    expected = HEADER_BYTES + SIZE**3 * 4
    if len(data) != expected:
        raise ValueError(f'Expected {expected} bytes; found {len(data)}.')
    volume = np.frombuffer(data, dtype=np.uint8, offset=HEADER_BYTES)
    return data[:HEADER_BYTES], volume.reshape(SIZE, SIZE, SIZE, 4)


def periodic_gradient_noise(
    size: int, frequency: int, rng: np.random.Generator
) -> np.ndarray:
    """Return one periodic gradient-noise octave, stored in [z,y,x] order.

    Gradient directions use uniform spherical angles, rather than uniform
    sphere area. This approximates the source's measured directional bias:
    gradient variance along its stored Z axis is larger than along X or Y.
    Opposite lattice boundaries share gradients, so all three axes repeat.
    """
    if frequency < 1 or size % frequency:
        raise ValueError('Frequency must be positive and divide size.')
    angles = rng.random((frequency, frequency, frequency, 2)) * (2 * np.pi)
    theta, phi = angles[..., 0], angles[..., 1]
    gradients = np.stack(
        (np.cos(theta), np.sin(theta) * np.cos(phi),
         np.sin(theta) * np.sin(phi)), axis=-1,
    )
    coordinate = np.arange(size, dtype=np.float64) * frequency / size
    base = np.floor(coordinate).astype(np.int64)
    fraction = coordinate - base
    fade = fraction**3 * (fraction * (6 * fraction - 15) + 10)
    result = np.zeros((size, size, size), dtype=np.float64)

    for corner in itertools.product((0, 1), repeat=3):
        iz, iy, ix = [(base + bit) % frequency for bit in corner]
        gradient = gradients[np.ix_(iz, iy, ix)]
        wz, wy, wx = [fade if bit else 1 - fade for bit in corner]
        dot = (
            gradient[..., 0] * (fraction[:, None, None] - corner[0])
            + gradient[..., 1] * (fraction[None, :, None] - corner[1])
            + gradient[..., 2] * (fraction[None, None, :] - corner[2])
        )
        result += dot * wz[:, None, None] * wy[None, :, None] * wx[None, None, :]
    return result


def generate(reference: np.ndarray, seed: int) -> tuple[np.ndarray, list[float]]:
    if not 0 <= seed < 2**64:
        raise ValueError('Seed must be an unsigned 64-bit integer.')
    rng = np.random.Generator(np.random.PCG64(seed))
    output = np.empty_like(reference)
    gains: list[float] = []
    for channel, base_frequency in enumerate(BASE_FREQUENCIES):
        field = np.zeros((SIZE, SIZE, SIZE), dtype=np.float64)
        frequency, amplitude = base_frequency, 1.0
        # Frequencies >= SIZE evaluate to zero on this sampling lattice.
        while frequency < SIZE:
            field += amplitude * periodic_gradient_noise(SIZE, frequency, rng)
            amplitude *= PERSISTENCE
            frequency *= 2
        ref = reference[..., channel].astype(np.float64)
        std = float(field.std())
        if std <= np.finfo(np.float64).eps:
            raise ValueError('Generated a degenerate noise field.')
        gain = float(ref.std()) / std
        gains.append(gain)
        # +0.5 compensates the subsequent floor-to-byte quantization.
        center = float(ref.mean()) + 0.5
        scaled = (field - field.mean()) * gain + center
        output[..., channel] = np.clip(np.floor(scaled), 0, 255).astype(np.uint8)
    return output, gains


def statistics(volume: np.ndarray) -> dict[str, Any]:
    f = volume.astype(np.float64)
    channels: dict[str, Any] = {}
    for i, name in enumerate('RGBA'):
        x = f[..., i]
        zero_mean = x - x.mean()
        rms_step, rms_seam, correlations = {}, {}, {}
        for axis, label in enumerate(('z', 'y', 'x')):
            rms_step[label] = float(np.sqrt(np.mean(np.diff(x, axis=axis)**2)))
            seam = np.take(x, 0, axis=axis) - np.take(x, -1, axis=axis)
            rms_seam[label] = float(np.sqrt(np.mean(seam**2)))
            correlations[label] = {
                str(lag): float(np.mean(zero_mean * np.roll(zero_mean, lag, axis))
                                / np.mean(zero_mean**2))
                for lag in (1, 2, 4, 8, 16)
            }
        channels[name] = {
            'minimum': int(x.min()), 'maximum': int(x.max()),
            'mean': float(x.mean()), 'standard_deviation': float(x.std()),
            'interior_neighbor_rms': rms_step, 'wrap_neighbor_rms': rms_seam,
            'periodic_autocorrelation': correlations,
        }
    return {'channels': channels,
            'channel_correlation': np.corrcoef(f.reshape(-1, 4).T).tolist()}


def atomic_write(path: Path, data: bytes) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = None
    try:
        with tempfile.NamedTemporaryFile(dir=path.parent, delete=False) as file:
            temporary = Path(file.name)
            file.write(data)
            file.flush()
            os.fsync(file.fileno())
        os.replace(temporary, path)
    finally:
        if temporary is not None and temporary.exists():
            temporary.unlink()


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('reference', type=Path)
    parser.add_argument('--seed', type=int, default=2026)
    parser.add_argument('--output', '-o', type=Path)
    parser.add_argument('--report', type=Path, help='Optional JSON validation report.')
    parser.add_argument('--overwrite', action='store_true')
    args = parser.parse_args()
    output = args.output or Path(f'noise64_cube_3_seed{args.seed}.dds')
    destinations = [output] + ([args.report] if args.report is not None else [])
    if len({path.resolve() for path in destinations}) != len(destinations):
        parser.error('Output and report paths must be different.')
    for path in destinations:
        if path.resolve() == args.reference.resolve():
            parser.error('Refusing to overwrite the reference file.')
        if path.exists() and not args.overwrite:
            parser.error(f'{path} exists; choose another name or use --overwrite.')
    try:
        header, reference = read_reference(args.reference)
        volume, gains = generate(reference, args.seed)
        data = header + volume.tobytes(order='C')
        atomic_write(output, data)
        reloaded_header, reloaded = read_reference(output)
        if reloaded_header != header or not np.array_equal(reloaded, volume):
            raise ValueError('Saved file failed round-trip validation.')
        if np.array_equal(reference, reloaded):
            raise ValueError('Output unexpectedly equals the reference.')
        if args.report is not None:
            reference_bytes = args.reference.read_bytes()
            report = {
                'method_status': 'Reconstruction; original generator not available/verified.',
                'seed': args.seed, 'prng': 'NumPy PCG64',
                'numpy_version': np.__version__,
                'dimensions_xyz': [SIZE, SIZE, SIZE],
                'layout': 'Legacy DDS volume, uncompressed RGBA8, X-fastest, 1 base level',
                'base_lattice_frequencies_rgba': list(BASE_FREQUENCIES),
                'lacunarity': 2, 'persistence': PERSISTENCE,
                'sampled_octaves_rgba': [[f * 2**k for k in range(6) if f * 2**k < SIZE]
                                         for f in BASE_FREQUENCIES],
                'interpolation': 'Quintic gradient noise',
                'tileable_axes': ['x', 'y', 'z'],
                'calibration': 'Per-channel standard deviation and center matched before quantization.',
                'gain_rgba': gains,
                'limitations': [
                    'The original generator and original seed are not known.',
                    'This is not a claim of exact algorithm or spectral/histogram equivalence.',
                    'New seeded fields have different extrema and inter-channel correlations.',
                    'File/layout and numerical tests passed; not tested inside the game engine.',
                ],
                'file_size_bytes': len(data),
                'header_byte_identical_to_reference': header == reference_bytes[:128],
                'round_trip_voxel_validation': True,
                'changed_payload_fraction': float(np.mean(reference != volume)),
                'reference_sha256': hashlib.sha256(reference_bytes).hexdigest(),
                'output_sha256': hashlib.sha256(data).hexdigest(),
                'reference_statistics': statistics(reference),
                'generated_statistics': statistics(volume),
            }
            atomic_write(args.report, (json.dumps(report, indent=2) + '\n').encode('utf-8'))
        print(f'Created {output}: {len(data):,} bytes; seed {args.seed}.')
        print('Validated: identical header, complete RGBA volume, changed voxel payload.')
    except (OSError, ValueError) as error:
        parser.exit(1, f'Error: {error}\n')


if __name__ == '__main__':
    main()
