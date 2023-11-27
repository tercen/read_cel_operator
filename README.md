# Import CEL data

##### Description

The operator improts CEL file (microarray data) into Tercen.

##### Usage

Input projection|.
---|---
`documentId`        | CEL file (or ZIP of CEL files) document ID 

Output relations|.
---|---
`intensity`       | Measured probe intensity
`filename`        | File name
`probe_id`        | Probe ID
`feature_name`    | Feature name
`probe_x`         | Probe x coordinate
`probe_y`         | Probe y coordinate

##### Details

The operator is based on the `read.celfiles()` function from the `oligo` R package.

