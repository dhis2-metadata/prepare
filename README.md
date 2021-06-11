# Prepare `jobs.<job_id>.strategy.matrix` docker action

This action prepares a Job Strategy Matrix as JSON, to be used for a "Publish" workflow.

## Outputs

### `matrix`
The JSON list of objects, to be used as Matrix.

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
