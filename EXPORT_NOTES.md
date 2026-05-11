# Full Repack Export

A full clean export archive was generated from the current `work` HEAD:

- `export/Halo-N-Fin_FULL_export.zip`
- `export/Halo-N-Fin_FULL_export.sha256`

A local `master` branch pointer was created and set to this same commit line to avoid merge divergence.

## Push commands

```bash
git push origin work
git push origin work:master --force-with-lease
```

## Regenerate package

```bash
mkdir -p export
git archive --format=zip --output=export/Halo-N-Fin_FULL_export.zip HEAD
sha256sum export/Halo-N-Fin_FULL_export.zip > export/Halo-N-Fin_FULL_export.sha256
```
