#!/usr/bin/env python3
"""Standalone regression receipt; requires numpy, pandas and matplotlib.

Fetches two hash-pinned upstream scripts (~46kB), applies the supplied patch
in a temporary directory, checks arithmetic and complete synthetic CLI runs.
Does not modify a KILDA installation or fetch human data. Prints JSON.
"""
import contextlib
import csv
import hashlib
import importlib.util
import io
import json
import math
import os
from pathlib import Path
import platform
import subprocess
import sys
import tempfile
import urllib.request
import warnings

os.environ.setdefault('MPLBACKEND', 'Agg')
import numpy as np
import pandas as pd
import matplotlib

HERE = Path(__file__).resolve().parent
PIN = '74075935a895787e2d58b0663f7f2dcf771da21c'
MODULE = 'modules/Kiv2Counts/kilda/resources/usr/bin/kilda.py'
SOURCES = {
    'module': (MODULE, '34e03b63c7d4a6b9f9ae6299465ac376782789eeae2bedc0dfa954fd77a5b627'),
    'root': ('bin/kilda.py', '5e7926ff323804fa7adc311affef9324eb22cc87fb29e1d52651d5fe9f005996'),
}


def load(path, name):
    spec = importlib.util.spec_from_file_location(name, path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def frame(counts, source, metadata=False):
    df = pd.DataFrame({'kmer': ['A' * 30 + b for b in 'ACGT'[:len(counts)]],
                       'occurrence': counts, 'source': source})
    if metadata:
        df['unrelated_numeric_metadata'] = np.arange(len(df)) + 1000
    return df


def call(module, kiv, norm, verbose=False, metadata=False):
    with warnings.catch_warnings(record=True) as caught, contextlib.redirect_stdout(io.StringIO()):
        warnings.simplefilter('always')
        try:
            result = module.get_kmer_CN(frame(kiv, 'kiv', metadata), frame(norm, 'lpa', metadata), verbose)
            value = float(result)
            out = {'status': 'finite' if math.isfinite(value) else 'nonfinite',
                   'value': value if math.isfinite(value) else None,
                   'scalar': bool(np.isscalar(result))}
        except (Exception, SystemExit) as exc:
            out = {'status': 'error', 'exception': type(exc).__name__, 'message': str(exc)[:500]}
        out['warning_types'] = sorted({type(w.message).__name__ for w in caught})
        return out


def main():
    expected = json.loads((HERE / 'expectations.json').read_text())
    report = {'pin': PIN, 'environment': {'python': platform.python_version(),
              'pandas': pd.__version__, 'numpy': np.__version__, 'matplotlib': matplotlib.__version__},
              'sources': {}, 'function_cases': {}, 'cli': {}, 'edges': {}}
    with tempfile.TemporaryDirectory(prefix='kilda-mean-') as tmp:
        wd = Path(tmp)
        for name, (relative, digest) in SOURCES.items():
            data = urllib.request.urlopen(f'https://raw.githubusercontent.com/HCL-HUBL/KILDA/{PIN}/{relative}', timeout=30).read()
            assert hashlib.sha256(data).hexdigest() == digest, 'Changed upstream source'
            path = wd / relative
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(data)
            report['sources'][name] = digest
        original = load(wd / MODULE, 'original')
        root = load(wd / 'bin/kilda.py', 'root')
        # The original is imported before mutation; CLI needs a separate copy.
        original_cli = wd / 'original.py'
        original_cli.write_bytes((wd / MODULE).read_bytes())
        for args in (['--check'], []):
            subprocess.run(['git', 'apply', *args, str(HERE / 'occurrence-scalar.patch')], cwd=wd, check=True, capture_output=True)
        # Avoid import cache reuse after a same-path edit.
        patched_cli = wd / 'patched.py'
        patched_cli.write_bytes((wd / MODULE).read_bytes())
        patched = load(patched_cli, 'patched')
        report['patch_applies'] = True
        for case in ('no_zeros', 'unequal_zero_fractions'):
            e = expected[case]
            for verbose in (False, True):
                for metadata in (False, True):
                    key = f'{case}:verbose={verbose}:metadata={metadata}'
                    outcomes = {name: call(mod, e['kiv'], e['normalization'], verbose, metadata)
                                for name, mod in [('original', original), ('patched', patched), ('root', root)]}
                    assert outcomes['original']['status'] == 'error', outcomes
                    for name, target in [('patched', e['nonzero_cn']), ('root', e['inclusive_cn'])]:
                        assert outcomes[name]['scalar'] and math.isclose(outcomes[name]['value'], target, abs_tol=1e-12), outcomes
                    report['function_cases'][key] = outcomes
        # Complete CLI path with distinct canonical 31-mers, supplied quantile
        # boundaries, and the same verbose/plot flags used by the NF module.
        kiv_kmers = ['A' * 31, 'A' * 30 + 'C', 'A' * 29 + 'CC']
        norm_kmers = ['C' * 31, 'C' * 30 + 'A', 'C' * 29 + 'AA', 'C' * 28 + 'AAA']
        (wd / 'kiv.tsv').write_text('\n'.join(kiv_kmers) + '\n')
        (wd / 'norm.tsv').write_text('\n'.join(norm_kmers) + '\n')
        (wd / 'q.txt').write_text('5\n15\n')
        (wd / 'counts.tsv').write_text(''.join(f'{k}\t{n}\n' for k, n in zip(kiv_kmers + norm_kmers, [0, 10, 20, 0, 0, 2, 4])))
        (wd / 'samples.tsv').write_text(f'synthetic\t{wd / "counts.tsv"}\n')
        for name, path in [('original', original_cli), ('patched', patched_cli), ('root', wd / 'bin/kilda.py')]:
            command = [sys.executable, str(path), '-c', str(wd / 'samples.tsv'), '-k', str(wd / 'kiv.tsv'),
                       '-l', str(wd / 'norm.tsv'), '-q', str(wd / 'q.txt'), '-o', str(wd / name), '-v', '-p']
            run = subprocess.run(command, text=True, capture_output=True, timeout=30)
            item = {'exit_code': run.returncode, 'stderr_tail': run.stderr[-1000:].replace(str(wd), '<temporary>')}
            if name == 'original':
                assert run.returncode != 0
            else:
                assert run.returncode == 0, run.stderr
                with (wd / name / 'kilda_kiv2.CNs').open() as f:
                    rows = list(csv.DictReader(f, delimiter='\t'))
                target = 10 if name == 'patched' else 13.33
                assert len(rows) == 1 and float(rows[0]['KIV2_CN']) == target
                assert (wd / name / 'plots/synthetic_cov.pdf').is_file()
                item.update(cn=float(rows[0]['KIV2_CN']), plot_generated=True)
            report['cli'][name] = item
        for label, k, n in [('all_zero_kiv', [0, 0], [2, 4]), ('all_zero_norm', [10, 20], [0, 0]),
                            ('empty_kiv', [], [2, 4]), ('empty_norm', [10, 20], [])]:
            outcomes = {name: call(mod, k, n) for name, mod in [('original', original), ('patched', patched), ('root', root)]}
            assert outcomes['patched']['status'] == 'error' and outcomes['patched']['exception'] == 'SystemExit'
            assert 'undefined' in outcomes['patched']['message']
            report['edges'][label] = outcomes
        for label, counts in [('all_zero_kiv', [0, 0, 0, 0, 0, 2, 4]),
                              ('all_zero_norm', [0, 10, 20, 0, 0, 0, 0])]:
            (wd / 'counts.tsv').write_text(''.join(f'{k}\t{n}\n' for k, n in zip(kiv_kmers + norm_kmers, counts)))
            run = subprocess.run([sys.executable, str(patched_cli), '-c', str(wd / 'samples.tsv'),
                                  '-k', str(wd / 'kiv.tsv'), '-l', str(wd / 'norm.tsv'), '-q', str(wd / 'q.txt'),
                                  '-o', str(wd / label), '-v'], text=True, capture_output=True, timeout=30)
            assert run.returncode != 0 and 'undefined' in run.stderr
            assert not (wd / label / 'kilda_kiv2.CNs').exists()
            report['cli'][label] = {'exit_code': run.returncode, 'error': run.stderr.strip(), 'final_cn_table': False}
    report['decision'] = 'valid-input repair and explicit undefined-mean rejection verified'
    print(json.dumps(report, indent=2, allow_nan=False))


if __name__ == '__main__':
    main()
