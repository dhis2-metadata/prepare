# "Prepare" Docker action

Move and prepare Packages for archiving and publishing to S3.

## Outputs

### `archive_dir`
Directory with Packages to be archived.

### `destination`
S3 destination path (prefix) to upload the Packages archive to.

## Example usage

```
jobs:
  job1:
    runs-on: ubuntu-20.04
    steps:
      - name: 'Checkout feature branch'
        uses: actions/checkout@v2
        with:
          path: 'feature'

      - name: 'Prepare packages for archiving'
        id: move_packages
        uses: dhis2-metadata/prepare@v2
        with:
          working_dir: 'feature'

      - name: 'Archive packages'
        run: zip -r "${{ steps.move_packages.outputs.archive_dir }}.zip" ${{ steps.move_packages.outputs.archive_dir }}

      - name: 'Upload package'
        uses: prewk/s3-cp-action@v2
        with:
          ...
          source: "${{ steps.move_packages.outputs.archive_dir }}.zip"
          dest: "s3://${{ secrets.S3_BUCKET }}/${{ steps.move_packages.outputs.destination }}/${{ steps.move_packages.outputs.archive_dir }}.zip"
```
