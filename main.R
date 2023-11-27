library(tercen)
library(dplyr, warn.conflicts = FALSE)
library(oligo)
library(pd.clariom.s.human)

ctx = tercenCtx()
if (!any(ctx$cnames == "documentId")) stop("Column factor documentId is required.")

df <- ctx$cselect()

docId = df$documentId[1]
doc = ctx$client$fileService$get(docId)
filename = tempfile()
writeBin(ctx$client$fileService$download(docId), filename)
on.exit(unlink(filename))

tmpdir <- tempfile()
on.exit(unlink(tmpdir))
unzip(filename, exdir = tmpdir)

f.names <- list.files(tmpdir, full.names = TRUE, recursive = TRUE)

raw_data <- oligo::read.celfiles(f.names)

df_probe <- as_tibble((oligo::getProbeInfo(raw_data, c('fid', 'x', 'y')))) %>%
  dplyr::transmute(
    .probe_id = as.numeric(fid),
    feature_name = man_fsetid,
    probe_x = as.numeric(x),
    probe_y = as.numeric(y)
  )

df_sample <- as_tibble(Biobase::pData(raw_data), rownames = "filename") %>%
  dplyr::mutate(.file_id = as.numeric(index)) %>% 
  select(-index)

cnames <- df_sample$.file_id
names(cnames) <- df_sample$filename

df_assay <- pm(raw_data)
colnames(df_assay) <- cnames[colnames(df_assay)]

df_assay_long <- df_assay %>%
  as_tibble() %>%
  mutate(probe_id = df_probe$.probe_id) %>%
  tidyr::pivot_longer(cols = !matches("probe_id"), names_to = "file_id", values_to = "intensity") %>%
  mutate(file_id = as.numeric(file_id))

rel_out <- df_assay_long %>%
  as_relation() %>%
  left_join_relation(as_relation(df_sample), "file_id", ".file_id") %>%
  left_join_relation(as_relation(df_probe), "probe_id", ".probe_id") %>%
  as_join_operator(list(), list())

save_relation(rel_out, ctx)
