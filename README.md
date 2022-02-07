# "Prepare" Docker action

Move and prepare Packages for archiving and publishing to S3.

## Inputs

### working_dir
Working directory path containing packages.

### package_version
The new version for the package.

## Outputs

### `archive_dir`
Directory with Packages to be archived.

### `package_locale`
Locale of the package.

### `package_prefix`
Package prefix code.

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
          dest: "s3://${{ secrets.S3_BUCKET }}/$DESTINATION/${{ steps.move_packages.outputs.archive_dir }}.zip"
```
