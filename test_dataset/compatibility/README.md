# Module-local scalar-mean reproduction

Run from the repository root with Git, pandas, NumPy and matplotlib available:

```bash
python test_dataset/compatibility/verify.py > verification.json
```

One tested setup is Python 3.11.15 with pandas 1.5.3, NumPy 1.26.4 and matplotlib 3.9.4. For example, using an available Python 3.11:

```bash
python3.11 -m venv /tmp/kilda-compat-env
/tmp/kilda-compat-env/bin/pip install pandas==1.5.3 numpy==1.26.4 matplotlib==3.9.4
/tmp/kilda-compat-env/bin/python test_dataset/compatibility/verify.py > verification.json
```

Also tested: Python 3.12.13, pandas 3.1.0, NumPy 2.5.4 and matplotlib 3.11.2. pandas 3.1 emits an unrelated `reset_index(inplace=...)` deprecation warning; this does not fail the checks.

The script retrieves two hash-pinned upstream scripts at commit `74075935a895787e2d58b0663f7f2dcf771da21c` (about 46 kB), applies `occurrence-scalar.patch` in a temporary directory, and checks synthetic arithmetic and full CLI behavior. No human data are downloaded or used. The checkout is not modified. This is a standalone before/after reproduction of that pinned version, not a general CI test of arbitrary future checkout contents.

Expected: all assertions pass; the original module CLI exits 1, the patched CLI exits 0 with CN 10.00, and all-zero cases fail explicitly without a final count table. Final JSON decision: `valid-input repair and explicit undefined-mean rejection verified`. Paths and warnings can vary; arithmetic and exit outcomes must not.

`expectations.json` supplies hand-calculated cases. For KIV `[0,10,20]` and normalization `[0,0,2,4]`, the root script's inclusive means give 13.33 and the module's nonzero means give 10. The patch preserves the module's masks, selects the numeric occurrence Series and rejects undefined means. Cross-entry-point estimator intent remains a separate maintainer question. These checks establish software behavior, not biological accuracy or full Nextflow-pipeline validity.
