# TODO
- [ ] Update readme

# "Prepare" Docker action

...

## Outputs

### `archive_dir`
Directory with Packages to be archived.

### `destination`
S3 destination to upload to.

## Example usage

```
jobs:
  job1:
    runs-on: ubuntu-latest
    outputs:
      matrix: ${{ steps.<id>.outputs.matrix }}
    steps:
      - uses: actions/checkout@v2
      - name: <name>
        id: <id>
        uses: dhis2-metadata/prepare@master

  job2:
    needs: job1
    runs-on: ubuntu-latest
    strategy:
      matrix:
        <name>: ${{ fromJson(needs.job1.outputs.matrix) }}
    steps:
      - uses: actions/checkout@v2
      - name: <name>
        ...
        env:
          ...
          SOURCE: ${{ matrix.<name>.source }}
          DEST: ${{ matrix.<name>.destination }}
```
